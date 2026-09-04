/**
 * Editor tools - 8 tools (reload_scripts is in script tools)
 * Tools for editor-level operations: screenshot, log, execute, settings, version, state, selection, focus
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

export const editorTools: ToolCategory = {
  take_screenshot: {
    name: "take_screenshot",
    description:
      "Capture a screenshot and save it to a file. Use viewport 'camera' to render the open scene through one of its own cameras — that is the view the player gets, and the only way to check an orthographic camera's framing. " +
      "The running game's own window cannot be captured: it is a separate OS process.",
    inputSchema: {
      type: "object",
      properties: {
        save_path: {
          type: "string",
          description: "Where to save the PNG (default: res://screenshot.png)",
        },
        viewport: {
          type: "string",
          enum: ["editor", "2d", "3d", "camera"],
          description:
            "What to capture: 'editor' (whole window), '2d' or '3d' (the editor's own viewports), or 'camera' (render the scene through a Camera3D/Camera2D in it). Default: editor",
        },
        camera_path: {
          type: "string",
          description:
            "viewport 'camera' only: scene-relative path of the Camera3D/Camera2D to render through. Defaults to the scene's current/enabled camera, else the first one found.",
        },
        width: {
          type: "number",
          description:
            "viewport 'camera' only: render width in pixels (default: the project's viewport width, 16-4096).",
        },
        height: {
          type: "number",
          description:
            "viewport 'camera' only: render height in pixels (default: the project's viewport height, 16-4096).",
        },
        transparent_bg: {
          type: "boolean",
          description: "viewport 'camera' only: render with a transparent background (default: false).",
        },
      },
    },
    handler: async (args) => {
      return await callTool("take_screenshot", args);
    },
  },

  get_error_log: {
    name: "get_error_log",
    description:
      "Get recent errors and warnings from the newest Godot log file. " +
      "The editor process writes no log — this reads what a running project logged, so play the scene first to see whether it starts clean.",
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
          description:
            "Filter log entries (default: all). 'errors' and 'warnings' keep the indented location/backtrace lines that follow each entry.",
        },
        log_path: {
          type: "string",
          description:
            "Read this file instead of the newest log Godot wrote (res://, user:// or an absolute path).",
        },
      },
    },
    handler: async (args) => {
      return await callTool("get_error_log", args);
    },
  },

  execute_script: {
    name: "execute_script",
    description:
      "Execute a GDScript snippet in the editor context (runs as EditorScript). " +
      "Returns whatever _run() returns as 'result', and the text passed to mcp_print(...) as 'output'. " +
      "await is supported: the call waits for the coroutine to finish.",
    inputSchema: {
      type: "object",
      properties: {
        code: {
          type: "string",
          description:
            "GDScript code to execute. Wrapped in func _run(): automatically if needed. " +
            "Use mcp_print(...) (same signature as print) to send text back in 'output' — plain print() only reaches Godot's Output panel. " +
            "Return a value from _run() to get it back as 'result'. " +
            "await works (e.g. await RenderingServer.frame_post_draw); the code after it runs before the tool responds.",
        },
        timeout: {
          type: "number",
          description:
            "Seconds to wait for the script to finish (default: 10, max: 60). On timeout the tool returns the output collected so far and the script keeps running in the editor. Note the MCP client gives up after 15s regardless.",
        },
      },
      required: ["code"],
    },
    handler: async (args) => {
      return await callTool("execute_script", args);
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
      return await callTool("open_editor_settings", args);
    },
  },

  get_editor_version: {
    name: "get_editor_version",
    description: "Get the current Godot editor version information",
    handler: async (_args) => {
      return await callTool("get_editor_version", {});
    },
  },

  get_editor_state: {
    name: "get_editor_state",
    description: "Get the current editor state: active scene, selected nodes, current main screen panel",
    handler: async (_args) => {
      return await callTool("get_editor_state", {});
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
      return await callTool("select_node_in_editor", args);
    },
  },

  focus_editor: {
    name: "focus_editor",
    description: "Bring the Godot editor window to the foreground",
    handler: async (_args) => {
      return await callTool("focus_editor", {});
    },
  },
};
