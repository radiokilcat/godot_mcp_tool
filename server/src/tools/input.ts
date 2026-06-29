/**
 * Input tools - 7 tools
 * Tools for simulating and managing input: key/mouse events, actions, record/replay, mapping
 */

import { ToolCategory } from "../types/index.js";
import { godotConnection } from "../godot-connection.js";

export const inputTools: ToolCategory = {
  simulate_key_press: {
    name: "simulate_key_press",
    description: "Inject a keyboard event into the running game",
    inputSchema: {
      type: "object",
      properties: {
        key: {
          type: "string",
          description: "Key name, e.g. 'Space', 'Enter', 'A', 'Escape', 'Left', 'F1'",
        },
        pressed: {
          type: "boolean",
          description: "true = key down, false = key up (default: true)",
        },
        shift: { type: "boolean", description: "Shift modifier (default: false)" },
        ctrl:  { type: "boolean", description: "Ctrl modifier (default: false)" },
        alt:   { type: "boolean", description: "Alt modifier (default: false)" },
        echo:  { type: "boolean", description: "Treat as auto-repeat echo event (default: false)" },
      },
      required: ["key"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("simulate_key_press", args);
    },
  },

  simulate_mouse_click: {
    name: "simulate_mouse_click",
    description: "Inject a mouse button event at a screen position",
    inputSchema: {
      type: "object",
      properties: {
        x: { type: "number", description: "X position in the viewport (pixels)" },
        y: { type: "number", description: "Y position in the viewport (pixels)" },
        button: {
          type: "string",
          enum: ["left", "right", "middle"],
          description: "Which mouse button (default: left)",
        },
        pressed: {
          type: "boolean",
          description: "true = button down, false = button up (default: true). Pass false for a full click.",
        },
        double_click: {
          type: "boolean",
          description: "Simulate a double-click (default: false)",
        },
      },
      required: ["x", "y"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("simulate_mouse_click", args);
    },
  },

  simulate_mouse_move: {
    name: "simulate_mouse_move",
    description: "Inject a mouse motion event to move the cursor to a screen position",
    inputSchema: {
      type: "object",
      properties: {
        x: { type: "number", description: "Target X position (pixels)" },
        y: { type: "number", description: "Target Y position (pixels)" },
        relative_x: { type: "number", description: "Relative X movement delta" },
        relative_y: { type: "number", description: "Relative Y movement delta" },
      },
      required: ["x", "y"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("simulate_mouse_move", args);
    },
  },

  trigger_input_action: {
    name: "trigger_input_action",
    description: "Press or release a named Input action (e.g. 'ui_accept', 'jump')",
    inputSchema: {
      type: "object",
      properties: {
        action: {
          type: "string",
          description: "Action name as defined in Project Settings > Input Map",
        },
        pressed: {
          type: "boolean",
          description: "true = press, false = release (default: true)",
        },
        strength: {
          type: "number",
          description: "Analog strength 0.0–1.0 (default: 1.0)",
        },
      },
      required: ["action"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("trigger_input_action", args);
    },
  },

  record_input_sequence: {
    name: "record_input_sequence",
    description: "Record all keyboard and mouse events for a given duration, then return the sequence",
    inputSchema: {
      type: "object",
      properties: {
        duration: {
          type: "number",
          description: "How many seconds to record (default: 3, max: 30)",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("record_input_sequence", args);
    },
  },

  replay_input_sequence: {
    name: "replay_input_sequence",
    description: "Replay a recorded or manually defined input sequence",
    inputSchema: {
      type: "object",
      properties: {
        events: {
          type: "array",
          description: "Array of events from record_input_sequence or manually defined",
          items: {
            type: "object",
            properties: {
              type:   { type: "string", description: "'key', 'mouse_button', or 'action'" },
              delay:  { type: "number", description: "Seconds to wait before this event (default: 0)" },
              key:    { type: "string", description: "Key name (for type='key')" },
              pressed:{ type: "boolean" },
              action: { type: "string", description: "Action name (for type='action')" },
              x:      { type: "number" },
              y:      { type: "number" },
              button: { type: "string" },
            },
          },
        },
        speed_scale: {
          type: "number",
          description: "Speed multiplier: 2.0 plays back 2× faster, 0.5 plays back 2× slower. Default: 1.0",
        },
      },
      required: ["events"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("replay_input_sequence", args);
    },
  },

  configure_input_mapping: {
    name: "configure_input_mapping",
    description: "List, add, or remove Input Map actions and their key bindings",
    inputSchema: {
      type: "object",
      properties: {
        operation: {
          type: "string",
          enum: ["list", "add", "remove", "add_key_binding", "get_events"],
          description: "Operation to perform (default: list)",
        },
        action_name: {
          type: "string",
          description: "Action name for add/remove/add_key_binding/get_events",
        },
        key: {
          type: "string",
          description: "Key to bind to action (for add_key_binding)",
        },
      },
    },
    handler: async (args) => {
      return await godotConnection.callTool("configure_input_mapping", args);
    },
  },
};
