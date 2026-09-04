/**
 * Scene tools - 10 tools
 * Tools for scene-level operations: tree, create, save, open, delete, play/stop, instancing
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

export const sceneTools: ToolCategory = {
  get_scene_tree: {
    name: "get_scene_tree",
    description: "Get the scene tree of the currently edited scene or a specific scene file",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description: "Path to scene file (e.g. 'res://scenes/Main.tscn'). Omit to use the active scene.",
        },
        max_depth: {
          type: "number",
          description: "Max tree depth to return (default: unlimited)",
        },
      },
    },
    handler: async (args) => {
      return await callTool("get_scene_tree", args);
    },
  },

  create_scene: {
    name: "create_scene",
    description: "Create and save a new scene with a root node",
    inputSchema: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description: "Scene name (also used as root node name)",
        },
        root_type: {
          type: "string",
          description: "Root node type, e.g. 'Node2D', 'Node3D', 'Control', 'Node'",
        },
        path: {
          type: "string",
          description: "Save path, e.g. 'res://scenes/Player.tscn'. Defaults to res://<name>.tscn",
        },
        open_after_create: {
          type: "boolean",
          description: "Open the scene in the editor after creating (default: true)",
        },
      },
      required: ["name", "root_type"],
    },
    handler: async (args) => {
      return await callTool("create_scene", args);
    },
  },

  save_scene: {
    name: "save_scene",
    description:
      "Save the scene currently open in the editor to disk. Node mutations (add_node, " +
      "set_node_property, add_mesh, ...) only change the in-memory scene — call this to commit them.",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description:
            "Optional 'save as' path, e.g. 'res://scenes/Main.tscn'. Omit to save over the " +
            "scene's existing file. Required if the scene has never been saved. " +
            "Intermediate directories are created automatically.",
        },
      },
    },
    handler: async (args) => {
      return await callTool("save_scene", args);
    },
  },

  open_scene: {
    name: "open_scene",
    description: "Open a scene file in the Godot editor",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description: "Path to scene file, e.g. 'res://scenes/Main.tscn'",
        },
      },
      required: ["scene_path"],
    },
    handler: async (args) => {
      return await callTool("open_scene", args);
    },
  },

  delete_scene: {
    name: "delete_scene",
    description: "Delete a scene file from the project",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description: "Path to scene file to delete",
        },
      },
      required: ["scene_path"],
    },
    handler: async (args) => {
      return await callTool("delete_scene", args);
    },
  },

  play_scene: {
    name: "play_scene",
    description: "Run a scene in the Godot player",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description: "Scene to play. Omit for current scene, 'main' for main scene.",
        },
      },
    },
    handler: async (args) => {
      return await callTool("play_scene", args);
    },
  },

  stop_scene: {
    name: "stop_scene",
    description: "Stop the currently running scene",
    handler: async (_args) => {
      return await callTool("stop_scene", {});
    },
  },

  instantiate_scene: {
    name: "instantiate_scene",
    description: "Instantiate a scene as a child node inside the active scene (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description: "Path to the scene to instantiate, e.g. 'res://prefabs/Enemy.tscn'",
        },
        parent_path: {
          type: "string",
          description: "Node path of the parent in the active scene (e.g. '.' for root)",
        },
        node_name: {
          type: "string",
          description: "Name for the instance. Defaults to scene filename stem.",
        },
      },
      required: ["scene_path", "parent_path"],
    },
    handler: async (args) => {
      return await callTool("instantiate_scene", args);
    },
  },

  get_scene_info: {
    name: "get_scene_info",
    description: "Get metadata about a scene: root type, node count, whether it is open",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description: "Path to scene file",
        },
      },
      required: ["scene_path"],
    },
    handler: async (args) => {
      return await callTool("get_scene_info", args);
    },
  },

  list_open_scenes: {
    name: "list_open_scenes",
    description: "List all scenes currently open in the editor",
    handler: async (_args) => {
      return await callTool("list_open_scenes", {});
    },
  },
};
