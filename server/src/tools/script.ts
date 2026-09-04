/**
 * Script tools - 8 tools
 * Tools for GDScript operations: read, create, edit, attach, validate, search, info, reload
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

export const scriptTools: ToolCategory = {
  read_script: {
    name: "read_script",
    description: "Read the full source code of a GDScript file",
    inputSchema: {
      type: "object",
      properties: {
        script_path: {
          type: "string",
          description: "Path to the script, e.g. 'res://scripts/Player.gd'",
        },
      },
      required: ["script_path"],
    },
    handler: async (args) => {
      return await callTool("read_script", args);
    },
  },

  create_script: {
    name: "create_script",
    description: "Create a new GDScript file with optional extends and class_name",
    inputSchema: {
      type: "object",
      properties: {
        script_path: {
          type: "string",
          description: "Save path, e.g. 'res://scripts/Enemy.gd'",
        },
        extends_type: {
          type: "string",
          description: "Base class to extend, e.g. 'Node2D', 'CharacterBody2D'",
        },
        class_name_str: {
          type: "string",
          description: "Optional class_name declaration",
        },
        content: {
          type: "string",
          description: "Full script body to write. If omitted, a minimal template is generated.",
        },
      },
      required: ["script_path"],
    },
    handler: async (args) => {
      return await callTool("create_script", args);
    },
  },

  edit_script: {
    name: "edit_script",
    description: "Edit a GDScript file: replace all content or a specific line range",
    inputSchema: {
      type: "object",
      properties: {
        script_path: {
          type: "string",
          description: "Path to the script to edit",
        },
        content: {
          type: "string",
          description: "New content to write",
        },
        start_line: {
          type: "number",
          description: "First line to replace (1-based). Omit to replace entire file.",
        },
        end_line: {
          type: "number",
          description: "Last line to replace (1-based, inclusive). Omit to replace entire file.",
        },
      },
      required: ["script_path", "content"],
    },
    handler: async (args) => {
      return await callTool("edit_script", args);
    },
  },

  attach_script: {
    name: "attach_script",
    description: "Attach a GDScript to a node in the active scene (supports UndoRedo). Creates the file if it does not exist.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node to attach the script to",
        },
        script_path: {
          type: "string",
          description: "Path to an existing or new script file",
        },
        extends_type: {
          type: "string",
          description: "Base class for the new script if it needs to be created",
        },
      },
      required: ["node_path", "script_path"],
    },
    handler: async (args) => {
      return await callTool("attach_script", args);
    },
  },

  validate_syntax: {
    name: "validate_syntax",
    description: "Validate GDScript syntax without saving. Pass source code or a file path.",
    inputSchema: {
      type: "object",
      properties: {
        source_code: {
          type: "string",
          description: "GDScript source code to validate",
        },
        script_path: {
          type: "string",
          description: "Path to a script file to validate (alternative to source_code)",
        },
      },
    },
    handler: async (args) => {
      return await callTool("validate_syntax", args);
    },
  },

  search_in_scripts: {
    name: "search_in_scripts",
    description: "Search for a text pattern in all .gd files, returns matches with file path and line number",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Text to search for",
        },
        path: {
          type: "string",
          description: "Root folder to search under (default: res://)",
        },
        case_sensitive: {
          type: "boolean",
          description: "Whether the search is case-sensitive (default: false)",
        },
      },
      required: ["query"],
    },
    handler: async (args) => {
      return await callTool("search_in_scripts", args);
    },
  },

  get_script_info: {
    name: "get_script_info",
    description: "Get metadata about a GDScript: class name, base class, methods, signals, properties",
    inputSchema: {
      type: "object",
      properties: {
        script_path: {
          type: "string",
          description: "Path to the script file",
        },
      },
      required: ["script_path"],
    },
    handler: async (args) => {
      return await callTool("get_script_info", args);
    },
  },

  reload_scripts: {
    name: "reload_scripts",
    description: "Reload all GDScripts in the editor (equivalent to editor Reload Scripts action)",
    handler: async (_args) => {
      return await callTool("reload_scripts", {});
    },
  },
};
