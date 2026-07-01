import { godotConnection } from "../godot-connection.js";

export const analysisTools = {
  analyze_scene_complexity: {
    name: "analyze_scene_complexity",
    description:
      "Analyze a scene's structural complexity and return metrics: node count, max depth, " +
      "number of scripted nodes, instanced sub-scenes, signal connections, unique external resources, " +
      "and a frequency breakdown of node types. " +
      "Uses the currently open scene when 'scene_path' is omitted.",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description:
            "res:// path to the scene to analyze (e.g. 'res://scenes/level_1.tscn'). " +
            "Omit to analyze the currently open scene.",
        },
      },
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("analyze_scene_complexity", args),
  },

  trace_signal_flow: {
    name: "trace_signal_flow",
    description:
      "List all signal connections in a scene showing source node, signal name, target node, and handler method. " +
      "Optionally filter to connections involving a specific node path. " +
      "Uses the currently open scene when 'scene_path' is omitted.",
    inputSchema: {
      type: "object",
      properties: {
        scene_path: {
          type: "string",
          description: "res:// path to the scene to inspect. Omit to use the currently open scene.",
        },
        node_path: {
          type: "string",
          description:
            "Optional node path (e.g. 'Player' or 'UI/Button'). " +
            "When provided, only connections where this node is the source or target are returned.",
        },
        include_flags: {
          type: "boolean",
          description: "If true, include the raw connection flags integer in each result (default false).",
        },
      },
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("trace_signal_flow", args),
  },

  find_unused_resources: {
    name: "find_unused_resources",
    description:
      "Find raw asset files (images, audio, fonts, 3D models) in the project that are not referenced " +
      "by any scene or resource file. Useful for cleaning up orphaned assets. " +
      "Note: assets only referenced via GDScript load() at runtime cannot be detected statically.",
    inputSchema: {
      type: "object",
      properties: {
        extensions: {
          type: "array",
          items: { type: "string" },
          description:
            "File extensions to scan for unused assets " +
            "(default: ['.png', '.jpg', '.jpeg', '.webp', '.svg', '.bmp', '.ogg', '.mp3', '.wav', " +
            "'.ttf', '.otf', '.woff', '.glb', '.gltf', '.obj']).",
        },
        scene_filter: {
          type: "string",
          description:
            "Optional substring to restrict the reference scan to matching scene/resource paths. " +
            "Useful to check usage within a specific folder (e.g. 'levels/').",
        },
      },
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("find_unused_resources", args),
  },

  get_code_metrics: {
    name: "get_code_metrics",
    description:
      "Compute code quality metrics for one or more GDScript files: " +
      "line counts (total/code/comment/blank), function count, class count, signal count, " +
      "export count, branch count (if/elif/match), loop count (for/while), and comment ratio. " +
      "Provide 'script_path' for a single file, 'directory' to scan a folder, " +
      "or omit both to scan the entire project.",
    inputSchema: {
      type: "object",
      properties: {
        script_path: {
          type: "string",
          description:
            "res:// path to a single GDScript file to analyze (e.g. 'res://scripts/player.gd'). " +
            "If provided, 'directory' is ignored.",
        },
        directory: {
          type: "string",
          description:
            "res:// prefix to restrict the scan to scripts in a specific folder " +
            "(e.g. 'res://scripts/'). Ignored when 'script_path' is set.",
        },
        max_files: {
          type: "integer",
          description: "Maximum number of scripts to analyze when scanning a directory or the whole project (default 200).",
        },
      },
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("get_code_metrics", args),
  },
};
