import { godotConnection } from "../godot-connection.js";

export const resourceTools = {
  read_resource: {
    name: "read_resource",
    description:
      "Load a Godot resource file (.tres, .res, or any ResourceLoader-supported path) and return all its stored properties. Use this to inspect a resource before editing it.",
    inputSchema: {
      type: "object",
      properties: {
        resource_path: {
          type: "string",
          description: "Path to the resource file, e.g. 'res://data/my.tres'",
        },
      },
      required: ["resource_path"],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("read_resource", args),
  },

  edit_resource: {
    name: "edit_resource",
    description:
      "Modify one or more properties of an existing resource file and save it to disk. Property values are type-coerced to match the resource's declared property types. Call read_resource first to see available property names and their current values.",
    inputSchema: {
      type: "object",
      properties: {
        resource_path: {
          type: "string",
          description: "Path to the resource file to modify",
        },
        properties: {
          type: "object",
          description:
            "Dict mapping property names to new values. Supports bool, int, float, string, Vector2/3 as [x,y]/[x,y,z] arrays or {x,y}/{x,y,z} dicts, Color as [r,g,b,a] or hex string, resource paths starting with 'res://'.",
          additionalProperties: true,
        },
      },
      required: ["resource_path", "properties"],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("edit_resource", args),
  },

  create_resource: {
    name: "create_resource",
    description:
      "Create a new instance of any Godot ClassDB resource type and save it as a .tres file. The class must be a Resource subclass registered in ClassDB (e.g. 'Environment', 'AudioStreamWAV', 'StyleBoxFlat', 'Resource').",
    inputSchema: {
      type: "object",
      properties: {
        resource_class: {
          type: "string",
          description:
            "Godot class name to instantiate, e.g. 'Environment', 'AudioStreamWAV', 'StyleBoxFlat', 'Resource'",
        },
        resource_path: {
          type: "string",
          description:
            "Destination path for the .tres file, e.g. 'res://data/my_env.tres'",
        },
        properties: {
          type: "object",
          description: "Optional initial property values to set before saving",
          additionalProperties: true,
        },
        overwrite: {
          type: "boolean",
          description:
            "Replace an existing file at resource_path. Defaults to false.",
        },
      },
      required: ["resource_class", "resource_path"],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("create_resource", args),
  },

  save_resource: {
    name: "save_resource",
    description:
      "Load a resource and re-save it. When dest_path is omitted, force-resaves to the same path (useful to upgrade resource format or flush pending changes). When dest_path is provided, copies/converts the resource to that path.",
    inputSchema: {
      type: "object",
      properties: {
        source_path: {
          type: "string",
          description: "Path to the resource to load and save",
        },
        dest_path: {
          type: "string",
          description:
            "Optional destination path. If omitted, saves back to source_path.",
        },
      },
      required: ["source_path"],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("save_resource", args),
  },

  get_project_autoloads: {
    name: "get_project_autoloads",
    description:
      "Return all autoload singletons registered in the project settings (reads ProjectSettings). Each entry includes name, script/scene path, and whether it is instantiated as a node. Use set_autoload to add or remove entries.",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("get_project_autoloads", args),
  },

  set_autoload: {
    name: "set_autoload",
    description:
      "Add, update, or remove an autoload singleton in the project settings. Changes take effect in the editor immediately. Use action 'remove' to delete an existing autoload; action 'add' (default) to add or overwrite one.",
    inputSchema: {
      type: "object",
      properties: {
        name: {
          type: "string",
          description:
            "Autoload singleton name (must be a valid GDScript identifier, e.g. 'GameManager')",
        },
        action: {
          type: "string",
          enum: ["add", "modify", "remove"],
          description:
            "'add' (default) adds or updates the autoload; 'modify' is an alias for 'add'; 'remove' deletes the autoload entry.",
        },
        path: {
          type: "string",
          description:
            "Path to the script or scene file to autoload, e.g. 'res://scripts/game_manager.gd'. Required when action is 'add' or 'modify'.",
        },
      },
      required: ["name"],
    },
    handler: async (args: Record<string, unknown>) =>
      godotConnection.callTool("set_autoload", args),
  },
};
