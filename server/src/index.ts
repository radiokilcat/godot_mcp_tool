/**
 * Godot MCP Server
 * Main entry point for the MCP server that communicates with Godot Editor
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

import { buildToolRegistry } from "./registry.js";

// The Godot WebSocket bridge. Importing this no longer binds anything — main()
// opens it explicitly (progress.md 9.4.3).
import { openBridge, getBridge, closeBridge } from "./godot-connection.js";
import { satisfiesVersionRange } from "./utils/version-utils.js";
import { ToolDefinition } from "./types/index.js";

const VERSION = "1.0.0";

// Tool results are read by a model, not a human, and indentation is pure cost:
// on a deep scene tree pretty-printing more than triples the payload. Set
// GODOT_MCP_PRETTY=1 when reading raw responses by hand.
const PRETTY_RESULTS = process.env.GODOT_MCP_PRETTY === "1";

// Initialize MCP Server
const server = new Server(
  {
    name: "godot-mcp",
    version: VERSION,
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Track all available tools
let toolRegistry = new Map<string, ToolDefinition>();

/**
 * Register tool handlers from all categories
 */
function registerAllTools(): void {
  toolRegistry = buildToolRegistry();
  console.error(`[MCP Server] Registered ${toolRegistry.size} tools`);
}

/**
 * Handle list_tools request
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  const tools = Array.from(toolRegistry.entries()).map(([name, tool]) => ({
    name,
    description: tool.description,
    inputSchema: tool.inputSchema ?? { type: "object", properties: {} },
  }));

  return { tools };
});

/**
 * Handle call_tool request
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name: toolName, arguments: args } = request.params;
  const tool = toolRegistry.get(toolName);

  if (!tool) {
    throw new Error(`Tool not found: ${toolName}`);
  }

  if (tool.minGodotVersion || tool.maxGodotVersion) {
    const godotVersion = getBridge().godotVersion;
    if (!satisfiesVersionRange(godotVersion, tool.minGodotVersion, tool.maxGodotVersion)) {
      const range = [
        tool.minGodotVersion ? `>= ${tool.minGodotVersion}` : null,
        tool.maxGodotVersion ? `<= ${tool.maxGodotVersion}` : null,
      ].filter(Boolean).join(" and ");
      throw new Error(
        `Tool '${toolName}' requires Godot ${range}, but the connected editor is running ${godotVersion}.`
      );
    }
  }

  try {
    const result = await tool.handler(args || {});
    return {
      content: [
        {
          type: "text",
          text: PRETTY_RESULTS ? JSON.stringify(result, null, 2) : JSON.stringify(result),
        },
      ],
    };
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : String(error);
    throw new Error(`Tool execution failed: ${errorMessage}`);
  }
});

/**
 * Wire process teardown to the bridge.
 *
 * The MCP client owns this process' lifetime, but nothing here noticed when it
 * let go: the SDK's stdio transport listens for 'data' and 'error' on stdin and
 * never for EOF, while the WebSocket server keeps the event loop alive on its
 * own. A closed client therefore left an orphan holding the bridge port, which
 * blocked every later session until it was killed by hand (progress.md 6.5.1).
 */
function installShutdownHandlers(): void {
  let shuttingDown = false;

  const shutdown = (reason: string, code = 0): void => {
    if (shuttingDown) return;
    shuttingDown = true;
    console.error(`[MCP Server] Shutting down (${reason})`);
    process.exitCode = code;

    closeBridge();
    void server.close().catch(() => { /* transport already gone */ });

    // With the port released nothing should keep the loop alive, so the process
    // normally exits on its own from here. This timer is unref'd: it fires only
    // if some handle is still open, and forces the exit that would otherwise hang.
    setTimeout(() => process.exit(code), 1_000).unref();
  };

  // The client closing its end of the pipe is the ordinary way a session ends.
  process.stdin.on("end", () => shutdown("client closed stdin"));
  process.stdin.on("close", () => shutdown("client closed stdin"));

  // EPIPE means the client vanished without an orderly EOF (killed parent,
  // broken pipe). Unhandled, it is also a fatal error event on stdout.
  process.stdout.on("error", (err: NodeJS.ErrnoException) => {
    if (err.code === "EPIPE") shutdown("stdout pipe closed");
    else console.error(`[MCP Server] stdout error: ${err.message}`);
  });

  const signals: NodeJS.Signals[] = ["SIGINT", "SIGTERM", "SIGHUP"];
  // SIGBREAK exists only on Windows; registering it elsewhere throws.
  if (process.platform === "win32") signals.push("SIGBREAK");
  for (const signal of signals) {
    process.on(signal, () => shutdown(signal));
  }

  // Last resort for any exit path that bypasses the above (an uncaught fatal, an
  // explicit process.exit): release the socket synchronously on the way out.
  process.on("exit", () => closeBridge());
}

/**
 * Start the MCP server
 */
async function main(): Promise<void> {
  console.error(`[MCP Server] Godot MCP Server v${VERSION}`);
  console.error(`[MCP Server] Initializing...`);

  registerAllTools();
  // Open the bridge before the MCP handshake: the plugin dials in on its own
  // schedule (backing off to 60s), so it must find a listener the moment the
  // process starts, not when the first tool call happens to arrive.
  openBridge();
  installShutdownHandlers();

  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error(`[MCP Server] Ready — listening for MCP requests via stdio`);
}

// Start server
main().catch((error) => {
  console.error("[MCP Server] Fatal error:", error);
  process.exit(1);
});
