import { godotConnection } from "../godot-connection.js";

export const batchTools = {
  find_by_node_type: {
    name: "find_by_node_type",
    description:
      "Search all scenes in the project for nodes of a given built-in class (e.g. Sprite2D, MeshInstance3D). " +
      "For custom GDScript classes use find_by_script instead. " +
      "Returns a list of {scene, node_path, node_name, node_type} matches.",
    inputSchema: {
      type: "object",
      properties: {
        node_type: {
          type: "string",
          description: "Built-in Godot class name to search for (e.g. 'Sprite2D', 'CharacterBody3D').",
        },
        scene_filter: {
          type: "string",
          description: "Optional substring to filter scene paths (e.g. 'levels/' searches only scenes in a levels folder).",
        },
        include_inherited: {
          type: "boolean",
          description: "If true (default), also match subclasses of the given type.",
        },
        max_results: {
          type: "integer",
          description: "Maximum number of results to return (default 500).",
        },
      },
      required: ["node_type"],
    },
    handler: async (args: Record<string, unknown>) => godotConnection.callTool("find_by_node_type", args),
  },

  find_by_script: {
    name: "find_by_script",
    description:
      "Search all scenes for nodes that have a specific GDScript file attached. " +
      "Returns a list of {scene, node_path, node_name, node_type} matches.",
    inputSchema: {
      type: "object",
      properties: {
        script_path: {
          type: "string",
          description: "res:// path to the script file (e.g. 'res://scripts/player.gd').",
        },
        scene_filter: {
          type: "string",
          description: "Optional substring to filter scene paths.",
        },
        max_results: {
          type: "integer",
          description: "Maximum number of results to return (default 500).",
        },
      },
      required: ["script_path"],
    },
    handler: async (args: Record<string, unknown>) => godotConnection.callTool("find_by_script", args),
  },

  find_by_group: {
    name: "find_by_group",
    description:
      "Search all scenes for nodes that belong to a specific node group. " +
      "Returns a list of {scene, node_path, node_name, node_type} matches.",
    inputSchema: {
      type: "object",
      properties: {
        group_name: {
          type: "string",
          description: "Name of the group to search for (e.g. 'enemies', 'pickups').",
        },
        scene_filter: {
          type: "string",
          description: "Optional substring to filter scene paths.",
        },
        max_results: {
          type: "integer",
          description: "Maximum number of results to return (default 500).",
        },
      },
      required: ["group_name"],
    },
    handler: async (args: Record<string, unknown>) => godotConnection.callTool("find_by_group", args),
  },

  bulk_rename: {
    name: "bulk_rename",
    description:
      "Rename nodes whose names match a pattern. In 'current_scene' scope, uses UndoRedo (Ctrl+Z supported). " +
      "In 'all_scenes' scope, modifies and re-saves scene files directly (no UndoRedo). " +
      "Use dry_run:true in all_scenes mode to preview changes before saving.",
    inputSchema: {
      type: "object",
      properties: {
        match: {
          type: "string",
          description: "Substring (or regex pattern if regex:true) to find in node names.",
        },
        replacement: {
          type: "string",
          description: "Replacement string. For regex mode, supports backreferences ($1, $2, etc.).",
        },
        regex: {
          type: "boolean",
          description: "If true, treat 'match' as a regular expression (default false).",
        },
        scope: {
          type: "string",
          enum: ["current_scene", "all_scenes"],
          description: "Where to apply renames: 'current_scene' (default) or 'all_scenes'.",
        },
        scene_filter: {
          type: "string",
          description: "Only used when scope is 'all_scenes'. Substring to filter which scene files to process.",
        },
        dry_run: {
          type: "boolean",
          description: "Only used when scope is 'all_scenes'. Preview changes without saving (default false).",
        },
      },
      required: ["match", "replacement"],
    },
    handler: async (args: Record<string, unknown>) => godotConnection.callTool("bulk_rename", args),
  },

  cross_scene_update: {
    name: "cross_scene_update",
    description:
      "Update a property on all nodes of a given type across multiple scene files. " +
      "Use dry_run:true to preview which nodes would be changed before committing. " +
      "Note: scenes are instantiated and re-packed, bypassing UndoRedo.",
    inputSchema: {
      type: "object",
      properties: {
        node_type: {
          type: "string",
          description: "Built-in class name of nodes to update (e.g. 'Label', 'AudioStreamPlayer').",
        },
        property: {
          type: "string",
          description: "Property name to set on each matching node (e.g. 'modulate', 'volume_db').",
        },
        value: {
          description: "New value to assign to the property.",
        },
        scene_filter: {
          type: "string",
          description: "Optional substring to filter which scene files to process.",
        },
        dry_run: {
          type: "boolean",
          description: "If true, return which nodes would be updated without saving (default false).",
        },
      },
      required: ["node_type", "property", "value"],
    },
    handler: async (args: Record<string, unknown>) => godotConnection.callTool("cross_scene_update", args),
  },

  find_dependencies: {
    name: "find_dependencies",
    description:
      "List the resources that a given resource or scene depends on. " +
      "With recursive:true, returns the full transitive dependency tree.",
    inputSchema: {
      type: "object",
      properties: {
        resource_path: {
          type: "string",
          description: "res:// path to the resource or scene to inspect (e.g. 'res://scenes/player.tscn').",
        },
        recursive: {
          type: "boolean",
          description: "If true, follow dependencies transitively and return the full dependency tree (default false).",
        },
      },
      required: ["resource_path"],
    },
    handler: async (args: Record<string, unknown>) => godotConnection.callTool("find_dependencies", args),
  },

  orphaned_resources: {
    name: "orphaned_resources",
    description:
      "Find resources in the project that are not referenced by any scene or other resource. " +
      "Useful for cleaning up unused assets. By default scans .tres, .res, and .gdshader files.",
    inputSchema: {
      type: "object",
      properties: {
        extensions: {
          type: "array",
          items: { type: "string" },
          description: "File extensions to check for orphans (default: ['.tres', '.res', '.gdshader']).",
        },
        include_scripts: {
          type: "boolean",
          description: "Also include .gd script files in the orphan check (default false).",
        },
        include_scenes: {
          type: "boolean",
          description: "Also include .tscn scene files in the orphan check (default false).",
        },
      },
      required: [],
    },
    handler: async (args: Record<string, unknown>) => godotConnection.callTool("orphaned_resources", args),
  },

  refactor_signals: {
    name: "refactor_signals",
    description:
      "Rename signal handler method connections across scene files. " +
      "Finds all signal connections that call 'old_method' and rewires them to 'new_method'. " +
      "Use dry_run:true to preview changes. Note: bypasses UndoRedo.",
    inputSchema: {
      type: "object",
      properties: {
        old_method: {
          type: "string",
          description: "Current method name that signals are connected to (e.g. '_on_button_pressed').",
        },
        new_method: {
          type: "string",
          description: "New method name to rewire the signal connections to.",
        },
        signal_name: {
          type: "string",
          description: "Optional: only refactor connections for a specific signal name.",
        },
        scene_filter: {
          type: "string",
          description: "Optional substring to filter which scene files to process.",
        },
        dry_run: {
          type: "boolean",
          description: "If true, report which connections would change without saving (default false).",
        },
      },
      required: ["old_method", "new_method"],
    },
    handler: async (args: Record<string, unknown>) => godotConnection.callTool("refactor_signals", args),
  },
};
