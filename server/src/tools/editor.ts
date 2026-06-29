/**
 * Editor tools - 8 tools (reload_scripts is in script tools)
 * Tools for editor-level operations: screenshot, log, execute, settings, version, state, selection, focus
 */

import { ToolCategory } from "../types/index.js";
import { godotConnection } from "../godot-connection.js";

export const editorTools: ToolCategory = {
  take_screenshot: {
    name: "take_screenshot",
    description: "Capture a screenshot of the Godot editor viewport and save it to a file",
    inputSchema: {
      type: "object",
      properties: {
        save_path: {
          type: "string",
          description: "Where to save the PNG (default: res://screenshot.png)",
        },
        viewport: {
          type: "string",
          enum: ["editor", "2d", "3d"],
          description: "Which viewport to capture: 'editor' (whole window), '2d', or '3d' (default: editor)",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("take_screenshot", args);
    },
  },

  get_error_log: {
    name: "get_error_log",
    description: "Get recent errors and warnings from the Godot output log",
    inputSchema: {
      type: "object",
      properties: {
        last_n_lines: {
          type: "number",
          description: "Number of lines to return from the end of the log (default: 100)",
        },
        filter: {
          type: "string",
          enum: ["all", "errors", "warnings"],
          description: "Filter log entries (default: all)",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("get_error_log", args);
    },
  },

  execute_script: {
    name: "execute_script",
    description: "Execute a GDScript snippet in the editor context (runs as EditorScript)",
    inputSchema: {
      type: "object",
      properties: {
        code: {
          type: "string",
          description: "GDScript code to execute. Will be wrapped in func _run(): automatically if needed.",
        },
      },
      required: ["code"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("execute_script", args);
    },
  },

  open_editor_settings: {
    name: "open_editor_settings",
    description: "Get current Godot editor settings as a dictionary (optionally filter by prefix)",
    inputSchema: {
      type: "object",
      properties: {
        prefix: {
          type: "string",
          description: "Setting prefix to filter, e.g. 'text_editor' or 'interface/theme'",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("open_editor_settings", args);
    },
  },

  get_editor_version: {
    name: "get_editor_version",
    description: "Get the current Godot editor version information",
    handler: async (_args) => {
      return await godotConnection.callTool("get_editor_version", {});
    },
  },

  get_editor_state: {
    name: "get_editor_state",
    description: "Get the current editor state: active scene, selected nodes, current main screen panel",
    handler: async (_args) => {
      return await godotConnection.callTool("get_editor_state", {});
    },
  },

  select_node_in_editor: {
    name: "select_node_in_editor",
    description: "Select one or more nodes in the editor's Scene panel",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node to select",
        },
        additional_paths: {
          type: "array",
          items: { type: "string" },
          description: "Additional node paths to add to the selection (multi-select)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("select_node_in_editor", args);
    },
  },

  focus_editor: {
    name: "focus_editor",
    description: "Bring the Godot editor window to the foreground",
    handler: async (_args) => {
      return await godotConnection.callTool("focus_editor", {});
    },
  },
};
