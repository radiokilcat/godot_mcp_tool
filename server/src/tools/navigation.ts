/**
 * Navigation tools - 6 tools
 * Tools for creating navigation regions, agents, baking meshes, querying paths,
 * and managing navigation layers.
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";
import { described, vectorSchema, layersSchema } from "./schemas.js";

export const navigationTools: ToolCategory = {
  add_navigation_region: {
    name: "add_navigation_region",
    description:
      "Add a NavigationRegion3D or NavigationRegion2D node with an empty navigation mesh/polygon. Call bake_navigation afterward to populate the walkable area from scene geometry.",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to parent node (default: scene root)",
        },
        node_name: {
          type: "string",
          description:
            "Name for the new node (default: 'NavigationRegion3D' or 'NavigationRegion2D')",
        },
        dimension: {
          type: "string",
          enum: ["3d", "2d"],
          description: "Whether to create a 3D or 2D region (default: '3d')",
        },
        navigation_layers: {
          ...layersSchema,
          description:
            "Navigation layers this region belongs to (default: layer 1). Agents can only traverse regions on matching layers.",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("add_navigation_region", args);
    },
  },

  add_navigation_agent: {
    name: "add_navigation_agent",
    description:
      "Add a NavigationAgent3D or NavigationAgent2D to a parent node. The agent computes paths and steers its parent toward a target_position. Attach it to a CharacterBody or similar movement node.",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description:
            "Path to the character node that will own this agent (default: scene root)",
        },
        node_name: {
          type: "string",
          description:
            "Name for the agent node (default: 'NavigationAgent3D' or 'NavigationAgent2D')",
        },
        dimension: {
          type: "string",
          enum: ["3d", "2d"],
          description: "Whether to create a 3D or 2D agent (default: '3d')",
        },
        max_speed: {
          type: "number",
          description: "Maximum movement speed in units/second (default: 200.0)",
        },
        path_desired_distance: {
          type: "number",
          description:
            "Distance in units at which a path waypoint is considered reached (default: 1.0)",
        },
        target_desired_distance: {
          type: "number",
          description:
            "Distance in units at which the final target is considered reached (default: 1.0)",
        },
        navigation_layers: {
          ...layersSchema,
          description: "Navigation layers the agent can traverse (default: layer 1)",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("add_navigation_agent", args);
    },
  },

  bake_navigation: {
    name: "bake_navigation",
    description:
      "Bake the navigation mesh or polygon for a NavigationRegion node. For 3D, scans MeshInstance3D children and builds a walkable mesh; for 2D, bakes from the polygon outline. Must have geometry in the region's subtree to produce a non-empty result.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to the NavigationRegion3D or NavigationRegion2D node to bake",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("bake_navigation", args);
    },
  },

  set_navigation_layer: {
    name: "set_navigation_layer",
    description:
      "Set the navigation_layers bitmask on a NavigationRegion, NavigationAgent, or NavigationObstacle node. Agents only traverse regions on matching layers, enabling multi-floor or multi-group navigation.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to the NavigationRegion3D/2D or NavigationAgent3D/2D node",
        },
        navigation_layers: layersSchema,
      },
      required: ["node_path", "navigation_layers"],
    },
    handler: async (args) => {
      return await callTool("set_navigation_layer", args);
    },
  },

  get_navigation_path: {
    name: "get_navigation_path",
    description:
      "Query the navigation server for a walkable path between two positions. Returns an ordered array of waypoints. Requires at least one NavigationRegion with a baked mesh in the scene; returns an empty path if no walkable route exists.",
    inputSchema: {
      type: "object",
      properties: {
        from: described(vectorSchema, "Start position."),
        to: described(vectorSchema, "Target position."),
        dimension: {
          type: "string",
          enum: ["3d", "2d"],
          description:
            "Navigation server to use: '3d' (default) or '2d'. Must match the region type.",
        },
        navigation_layers: {
          ...layersSchema,
          description:
            "Restrict the path to regions on these navigation layers (default: layer 1)",
        },
      },
      required: ["from", "to"],
    },
    handler: async (args) => {
      return await callTool("get_navigation_path", args);
    },
  },

  get_navigation_info: {
    name: "get_navigation_info",
    description:
      "Get navigation configuration for a specific node, or scan the entire scene and return all NavigationRegion and NavigationAgent nodes with their layer and mesh settings.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to a NavigationRegion or NavigationAgent node for per-node details. Omit to scan the whole scene.",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("get_navigation_info", args);
    },
  },
};
