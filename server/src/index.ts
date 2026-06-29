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

// Import tool handlers
import { projectTools } from "./tools/project.js";
import { sceneTools } from "./tools/scene.js";
import { nodeTools } from "./tools/node.js";
import { scriptTools } from "./tools/script.js";
import { editorTools } from "./tools/editor.js";
import { inputTools } from "./tools/input.js";

// Initialize Godot WebSocket bridge (starts listening on port 6505)
import "./godot-connection.js";

const VERSION = "1.0.0";

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
const toolRegistry = new Map<
  string,
  {
    name: string;
    description: string;
    inputSchema?: {
      type: string;
      properties?: Record<string, unknown>;
      required?: string[];
    };
    handler: (args: Record<string, unknown>) => Promise<unknown>;
  }
>();

/**
 * Register tool handlers from all categories
 */
function registerAllTools(): void {
  const toolCategories = [
    projectTools,
    sceneTools,
    nodeTools,
    scriptTools,
    editorTools,
    inputTools,
    // Additional categories will be imported here as they're implemented
  ];

  for (const category of toolCategories) {
    for (const [name, tool] of Object.entries(category)) {
      if (typeof tool === "object" && tool !== null && "handler" in tool) {
        toolRegistry.set(
          name,
          tool as {
            name: string;
            description: string;
            inputSchema?: { type: string; properties?: Record<string, unknown>; required?: string[] };
            handler: (args: Record<string, unknown>) => Promise<unknown>;
          }
        );
      }
    }
  }

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

  try {
    const result = await tool.handler(args || {});
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
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
 * Start the MCP server
 */
async function main(): Promise<void> {
  console.error(`[MCP Server] Godot MCP Server v${VERSION}`);
  console.error(`[MCP Server] Initializing...`);

  registerAllTools();

  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error(`[MCP Server] Ready — listening for MCP requests via stdio`);
}

// Start server
main().catch((error) => {
  console.error("[MCP Server] Fatal error:", error);
  process.exit(1);
});
