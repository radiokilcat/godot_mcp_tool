import { callTool } from "../godot-connection.js";

export const testingTools = {
  run_automated_tests: {
    name: "run_automated_tests",
    description:
      "Run GDScript test files under a given directory. " +
      "Each .gd file is loaded and every method whose name starts with 'test_' is called. " +
      "A method passes if it returns true (or nothing); it fails if it returns false or a dict with 'error'. " +
      "Returns a summary with per-file and per-method pass/fail counts.",
    inputSchema: {
      type: "object",
      properties: {
        test_path: {
          type: "string",
          description:
            "res:// path prefix to search for test files (default 'res://tests/'). " +
            "All .gd files under this path are included.",
        },
        test_filter: {
          type: "string",
          description:
            "Optional substring filter. Only files whose path contains this string are executed.",
        },
        timeout_sec: {
          type: "number",
          description:
            "Reserved for future use. Accepted but not yet enforced — " +
            "a blocking test method will stall indefinitely regardless of this value.",
        },
      },
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("run_automated_tests", args),
  },

  assert_node_state: {
    name: "assert_node_state",
    description:
      "Assert that one or more properties of a node in the currently open scene match expected values. " +
      "Use the 'assertions' array for multiple checks, or 'property'+'expected' for a single check. " +
      "Returns {passed: bool, assertions: [{property, expected, actual, passed}]}.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "NodePath relative to the scene root (e.g. 'Player', 'UI/HealthBar'). " +
            "Use '.' or '' for the root node.",
        },
        assertions: {
          type: "array",
          description:
            "Array of {property: string, expected: any} objects to check. " +
            "If omitted, use the top-level 'property' and 'expected' fields for a single assertion.",
          items: {
            type: "object",
            properties: {
              property: { type: "string", description: "Property name (e.g. 'visible', 'position')." },
              expected: { description: "Expected value to compare against (string, number, boolean, or object)." },
            },
            required: ["property", "expected"],
          },
        },
        property: {
          type: "string",
          description: "Property name for a single-assertion shortcut (ignored when 'assertions' is provided).",
        },
        expected: {
          description: "Expected value for the single-assertion shortcut (string, number, boolean, or object).",
        },
      },
      required: ["node_path"],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("assert_node_state", args),
  },

  compare_screenshots: {
    name: "compare_screenshots",
    description:
      "Compare two screenshot files pixel-by-pixel and report the difference ratio. " +
      "Returns {diff_ratio, threshold, passed} where diff_ratio is the fraction of differing pixels [0.0–1.0]. " +
      "Useful for visual regression testing — take a baseline screenshot, make changes, take another, then compare.",
    inputSchema: {
      type: "object",
      properties: {
        path_a: {
          type: "string",
          description: "Path to the baseline screenshot (res:// or absolute OS path).",
        },
        path_b: {
          type: "string",
          description: "Path to the screenshot to compare against the baseline.",
        },
        threshold: {
          type: "number",
          description:
            "Maximum allowed diff_ratio before the comparison fails (default 0.01 = 1%). " +
            "Set to 0.0 to require a pixel-perfect match.",
        },
      },
      required: ["path_a", "path_b"],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("compare_screenshots", args),
  },

  record_test: {
    name: "record_test",
    description:
      "Start or stop recording a test interaction sequence, or add individual events to an in-progress recording. " +
      "Use action='start' to begin, action='add_event' to append an event dict, action='stop' to finish. " +
      "The returned 'events' array from action='stop' can be passed to replay_test.",
    inputSchema: {
      type: "object",
      properties: {
        action: {
          type: "string",
          enum: ["start", "stop", "add_event", "status"],
          description: "Recording control: 'start' | 'stop' | 'add_event' | 'status'.",
        },
        test_name: {
          type: "string",
          description: "Name for the recording (used with action='start').",
        },
        event: {
          type: "object",
          description:
            "Event dict to append when action='add_event'. " +
            "Must include 'type': 'key_press' | 'mouse_click' | 'mouse_move' | 'action' | 'wait'.",
          properties: {
            type: {
              type: "string",
              enum: ["key_press", "mouse_click", "mouse_move", "action", "wait"],
            },
          },
        },
      },
      required: ["action"],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("record_test", args),
  },

  replay_test: {
    name: "replay_test",
    description:
      "Replay a list of recorded test events into the editor. " +
      "Supports event types: key_press (keycode, ctrl, shift, alt), " +
      "mouse_click (x, y, button), mouse_move (x, y), " +
      "action (action_name), wait (seconds). " +
      "Returns {replayed, total, errors, status}.",
    inputSchema: {
      type: "object",
      properties: {
        events: {
          type: "array",
          description:
            "Array of event dicts to replay in order. " +
            "Each must have a 'type' field. " +
            "Use the output of record_test (action='stop') as input.",
          items: {
            type: "object",
            properties: {
              type: {
                type: "string",
                enum: ["key_press", "mouse_click", "mouse_move", "action", "wait"],
                description: "Event type.",
              },
            },
            required: ["type"],
          },
        },
      },
      required: ["events"],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("replay_test", args),
  },

  get_test_report: {
    name: "get_test_report",
    description:
      "Return the most recent test report produced by run_automated_tests. " +
      "Returns the full report dict including per-file and per-method results, " +
      "or an error if no report has been generated yet.",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("get_test_report", args),
  },
};
