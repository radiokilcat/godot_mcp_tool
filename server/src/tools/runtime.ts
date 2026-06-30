/**
 * Runtime tools - 19 tools
 * Tools for inspecting and controlling the game while it runs
 */

import { ToolCategory } from "../types/index.js";
import { godotConnection } from "../godot-connection.js";

export const runtimeTools: ToolCategory = {
  get_game_state: {
    name: "get_game_state",
    description: "Get the current game state: running/paused, active scene, FPS, time scale",
    handler: async (_args) => {
      return await godotConnection.callTool("get_game_state", {});
    },
  },

  list_loaded_resources: {
    name: "list_loaded_resources",
    description: "List resource files in the project filtered by type or path prefix",
    inputSchema: {
      type: "object",
      properties: {
        type_filter: {
          type: "string",
          description: "Filter by file extension, e.g. '.tres', '.res', '.png'",
        },
        path_prefix: {
          type: "string",
          description: "Only include resources under this path (default: res://)",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("list_loaded_resources", args);
    },
  },

  inspect_node_at_runtime: {
    name: "inspect_node_at_runtime",
    description: "Get full property snapshot of a node (current values, not just schema)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string", description: "Node path in the active scene" },
        include_children: {
          type: "boolean",
          description: "Include immediate children info (default: false)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("inspect_node_at_runtime", args);
    },
  },

  get_performance_metrics: {
    name: "get_performance_metrics",
    description: "Get engine performance monitors: FPS, memory, draw calls, node count",
    inputSchema: {
      type: "object",
      properties: {
        monitors: {
          type: "array",
          items: { type: "string" },
          description: "Specific monitors to query (default: all common ones). E.g. ['fps','memory_static','draw_calls']",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("get_performance_metrics", args);
    },
  },

  record_gameplay: {
    name: "record_gameplay",
    description: "Record gameplay input events for a duration (game must be running)",
    inputSchema: {
      type: "object",
      properties: {
        duration: {
          type: "number",
          description: "Recording duration in seconds (default: 5, max: 60)",
        },
        include_snapshots: {
          type: "boolean",
          description: "Include periodic performance snapshots (default: false)",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("record_gameplay", args);
    },
  },

  replay_gameplay: {
    name: "replay_gameplay",
    description: "Replay a previously recorded gameplay session (game must be running)",
    inputSchema: {
      type: "object",
      properties: {
        events: {
          type: "array",
          description: "Events array from record_gameplay",
        },
        speed_scale: {
          type: "number",
          description: "Speed multiplier for delays (default: 1.0)",
        },
      },
      required: ["events"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("replay_gameplay", args);
    },
  },

  navigate_to_node: {
    name: "navigate_to_node",
    description: "Select and scroll to a node in the editor's Scene panel",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string", description: "Node path to navigate to" },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("navigate_to_node", args);
    },
  },

  click_ui_element: {
    name: "click_ui_element",
    description: "Simulate a click on a UI Control node (calls press() for buttons or emits gui_input)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the Control node to click",
        },
        method: {
          type: "string",
          enum: ["press", "toggle", "gui_input"],
          description: "Interaction method (default: press)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("click_ui_element", args);
    },
  },

  get_node_tree_runtime: {
    name: "get_node_tree_runtime",
    description: "Get the scene tree with runtime information (script state, visible, groups)",
    inputSchema: {
      type: "object",
      properties: {
        max_depth: {
          type: "number",
          description: "Max depth to traverse (default: 3)",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("get_node_tree_runtime", args);
    },
  },

  pause_game: {
    name: "pause_game",
    description: "Pause the running game (sets SceneTree.paused = true)",
    handler: async (_args) => {
      return await godotConnection.callTool("pause_game", {});
    },
  },

  resume_game: {
    name: "resume_game",
    description: "Resume the paused game (sets SceneTree.paused = false)",
    handler: async (_args) => {
      return await godotConnection.callTool("resume_game", {});
    },
  },

  set_game_speed: {
    name: "set_game_speed",
    description: "Set Engine.time_scale to speed up or slow down the game (1.0 = normal)",
    inputSchema: {
      type: "object",
      properties: {
        time_scale: {
          type: "number",
          description: "Speed multiplier. 0 = freeze, 0.5 = half speed, 2.0 = double speed",
        },
      },
      required: ["time_scale"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("set_game_speed", args);
    },
  },

  list_autoloads: {
    name: "list_autoloads",
    description: "List all autoload singletons defined in the project",
    handler: async (_args) => {
      return await godotConnection.callTool("list_autoloads", {});
    },
  },

  call_function: {
    name: "call_function",
    description: "Call a method on a node in the active scene and return the result",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string", description: "Node path" },
        method: { type: "string", description: "Method name to call" },
        args: {
          type: "array",
          description: "Arguments to pass to the method (default: [])",
        },
      },
      required: ["node_path", "method"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("call_function", args);
    },
  },

  get_variable_value: {
    name: "get_variable_value",
    description: "Get the current value of a node property or exported variable",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string", description: "Node path" },
        variable: { type: "string", description: "Property or variable name" },
      },
      required: ["node_path", "variable"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("get_variable_value", args);
    },
  },

  set_variable_value: {
    name: "set_variable_value",
    description: "Set the value of a node property or exported variable at runtime",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string", description: "Node path" },
        variable: { type: "string", description: "Property or variable name" },
        value: { description: "New value to assign" },
      },
      required: ["node_path", "variable", "value"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("set_variable_value", args);
    },
  },

  get_signal_connections: {
    name: "get_signal_connections",
    description: "List all signal connections on a node (outgoing and incoming)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string", description: "Node path" },
        direction: {
          type: "string",
          enum: ["outgoing", "incoming", "both"],
          description: "Which connections to return (default: outgoing)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("get_signal_connections", args);
    },
  },

  emit_signal: {
    name: "emit_signal",
    description: "Emit a signal on a node with optional arguments",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string", description: "Node path" },
        signal_name: { type: "string", description: "Signal name to emit" },
        args: {
          type: "array",
          description: "Arguments to pass with the signal (default: [])",
        },
      },
      required: ["node_path", "signal_name"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("emit_signal", args);
    },
  },

  listen_to_signal: {
    name: "listen_to_signal",
    description: "Wait for a signal to fire on a node (async, with timeout)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: { type: "string", description: "Node path" },
        signal_name: { type: "string", description: "Signal to wait for" },
        timeout: {
          type: "number",
          description: "Max seconds to wait before giving up (default: 5)",
        },
      },
      required: ["node_path", "signal_name"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("listen_to_signal", args);
    },
  },
};
