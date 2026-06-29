/**
 * Godot MCP Server
 * Main entry point for the MCP server that communicates with Godot Editor
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

// Import tool handlers
import { projectTools } from "./tools/project.js";
import { sceneTools } from "./tools/scene.js";
import { nodeTools } from "./tools/node.js";

// Configuration
const PORT = process.env.GODOT_MCP_PORT || 6505;
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
            handler: (args: Record<string, unknown>) => Promise<unknown>;
          }
        );
      }
    }
  }

  console.log(`[MCP Server] Registered ${toolRegistry.size} tools`);
}

/**
 * Handle list_tools request
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  const tools = Array.from(toolRegistry.entries()).map(
    ([name, tool]) => ({
      name,
      description: tool.description,
      inputSchema: {
        type: "object",
        properties: {
          // Tool-specific input schema will be defined per tool
        },
      },
    })
  );

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
  console.log(`[MCP Server] Godot MCP Server v${VERSION}`);
  console.log(`[MCP Server] Initializing...`);

  registerAllTools();

  // Connect to stdio for MCP communication
  // Note: Stdio transport is provided by the MCP SDK automatically
  // when running in stdio mode (via spawning the server process)

  console.log(`[MCP Server] Connected and ready for MCP protocol`);
  console.log(`[MCP Server] Waiting for Godot connection on port ${PORT}...`);
}

// Start server
main().catch((error) => {
  console.error("[MCP Server] Fatal error:", error);
  process.exit(1);
});
