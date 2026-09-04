import { callTool } from "../godot-connection.js";

export const exportTools = {
  list_export_presets: {
    name: "list_export_presets",
    description:
      "List all export presets defined in the project's export_presets.cfg. " +
      "Returns name, platform, runnable flag, configured export path, and per-preset options for each preset.",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("list_export_presets", args),
  },

  export_project: {
    name: "export_project",
    description:
      "Export the Godot project using a named export preset. " +
      "Runs 'godot --headless --export-release <preset> <output>' (or --export-debug when debug=true). " +
      "The preset must already be configured in Project > Export. " +
      "output_path overrides the preset's configured export_path; if both are omitted the tool returns an error.",
    inputSchema: {
      type: "object",
      properties: {
        preset_name: {
          type: "string",
          description: "Exact name of the export preset to use (case-sensitive).",
        },
        output_path: {
          type: "string",
          description:
            "Absolute or project-relative path for the exported file (e.g. 'build/game.exe'). " +
            "If omitted, the preset's configured export_path is used.",
        },
        debug: {
          type: "boolean",
          description: "If true, use --export-debug instead of --export-release (default false).",
        },
      },
      required: ["preset_name"],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("export_project", args),
  },

  get_template_info: {
    name: "get_template_info",
    description:
      "Return information about installed Godot export templates for the current engine version. " +
      "Shows the template directory path, whether templates are installed, and which platform " +
      "entries are present. If templates are missing, returns instructions for installing them.",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("get_template_info", args),
  },
};
