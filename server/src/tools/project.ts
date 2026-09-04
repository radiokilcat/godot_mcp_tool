/**
 * Project tools - 7 tools
 * Tools for project-level operations: info, search, settings, UID conversion
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

export const projectTools: ToolCategory = {
  get_project_info: {
    name: "get_project_info",
    description: "Get basic project information: name, version, Godot version, path, main scene",
    handler: async (_args) => {
      return await callTool("get_project_info", {});
    },
  },

  list_project_files: {
    name: "list_project_files",
    description: "List files in the project (optionally filtered by folder path or file extension)",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Folder path to list (default: res://)",
        },
        filter: {
          type: "string",
          description: "File extension filter, e.g. '.gd' or '.tscn'",
        },
        max_results: {
          type: "integer",
          description: "Maximum files to return (default 500, negative for no limit). The response carries truncated: true when the listing stopped early.",
        },
      },
    },
    handler: async (args) => {
      return await callTool("list_project_files", args);
    },
  },

  search_files: {
    name: "search_files",
    description: "Search for files by name or text content",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query string",
        },
        type: {
          type: "string",
          enum: ["name", "content"],
          description: "Search by filename (default) or file content",
        },
        max_results: {
          type: "integer",
          description: "Maximum matches to return (default 500, negative for no limit). The response carries truncated: true when the search stopped early.",
        },
      },
      required: ["query"],
    },
    handler: async (args) => {
      return await callTool("search_files", args);
    },
  },

  get_project_settings: {
    name: "get_project_settings",
    description: "Get one or all project settings. Pass setting_path for a specific setting (e.g. 'physics/2d/default_gravity'), omit for common defaults",
    inputSchema: {
      type: "object",
      properties: {
        setting_path: {
          type: "string",
          description: "Specific setting path, e.g. 'physics/2d/default_gravity'",
        },
      },
    },
    handler: async (args) => {
      return await callTool("get_project_settings", args);
    },
  },

  set_project_setting: {
    name: "set_project_setting",
    description: "Set a project setting and save project.godot",
    inputSchema: {
      type: "object",
      properties: {
        setting_path: {
          type: "string",
          description: "Setting path, e.g. 'application/config/name'",
        },
        value: {
          description: "New value (string, number, bool, or array)",
        },
      },
      required: ["setting_path", "value"],
    },
    handler: async (args) => {
      return await callTool("set_project_setting", args);
    },
  },

  convert_uid: {
    name: "convert_uid",
    description: "Convert between Godot UID (uid://...) and resource path (res://...)",
    inputSchema: {
      type: "object",
      properties: {
        uid: {
          type: "string",
          description: "Resource UID, e.g. 'uid://abc123'",
        },
        path: {
          type: "string",
          description: "Resource path, e.g. 'res://scenes/Player.tscn'",
        },
      },
    },
    handler: async (args) => {
      return await callTool("convert_uid", args);
    },
  },

  get_project_metadata: {
    name: "get_project_metadata",
    description: "Get project metadata: renderer, viewport size, gravity, OS features",
    handler: async (_args) => {
      return await callTool("get_project_metadata", {});
    },
  },
};
