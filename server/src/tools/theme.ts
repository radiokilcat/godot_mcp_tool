/**
 * Theme/UI tools - 6 tools
 * Tools for creating and modifying Godot Theme resources (.tres files):
 * colors, fonts, integer constants, and StyleBox definitions.
 *
 * All tools operate on .tres Theme files. Changes are saved immediately
 * via ResourceSaver — they are not tracked by EditorUndoRedo.
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

export const themeTools: ToolCategory = {
  create_theme: {
    name: "create_theme",
    description:
      "Create a new empty Theme resource and save it as a .tres file. Optionally set a default font and default font size. Returns an error if the file already exists unless overwrite is true.",
    inputSchema: {
      type: "object",
      properties: {
        theme_path: {
          type: "string",
          description:
            "Project-relative path where the theme will be saved, e.g. 'res://theme/my_theme.tres'",
        },
        overwrite: {
          type: "boolean",
          description:
            "Set to true to replace an existing theme file. Defaults to false to prevent accidental data loss.",
        },
        default_font: {
          type: "string",
          description:
            "Optional path to the default font resource, e.g. 'res://fonts/MyFont.ttf'",
        },
        default_font_size: {
          type: "integer",
          description: "Optional default font size in pixels (e.g. 16)",
        },
      },
      required: ["theme_path"],
    },
    handler: async (args) => {
      return await callTool("create_theme", args);
    },
  },

  set_theme_color: {
    name: "set_theme_color",
    description:
      "Set a named color override for a specific Control type in a Theme file. Common examples: set 'font_color' on 'Label', 'font_hover_color' on 'Button'. Saves the theme immediately.",
    inputSchema: {
      type: "object",
      properties: {
        theme_path: {
          type: "string",
          description: "Path to the .tres Theme file, e.g. 'res://theme/my_theme.tres'",
        },
        theme_type: {
          type: "string",
          description:
            "Control class name this color applies to, e.g. 'Button', 'Label', 'LineEdit'",
        },
        color_name: {
          type: "string",
          description:
            "Name of the color property, e.g. 'font_color', 'font_hover_color', 'font_disabled_color'",
        },
        color: {
          type: "string",
          description:
            "Color value as hex string ('#rrggbb' or '#rrggbbaa') or as an [r, g, b] array with values 0–1",
        },
      },
      required: ["theme_path", "theme_type", "color_name", "color"],
    },
    handler: async (args) => {
      return await callTool("set_theme_color", args);
    },
  },

  set_theme_font: {
    name: "set_theme_font",
    description:
      "Assign a font resource to a named font slot for a specific Control type in a Theme file. Optionally set the font size for that slot. Saves the theme immediately.",
    inputSchema: {
      type: "object",
      properties: {
        theme_path: {
          type: "string",
          description: "Path to the .tres Theme file",
        },
        theme_type: {
          type: "string",
          description: "Control class name, e.g. 'Button', 'Label'",
        },
        font_name: {
          type: "string",
          description: "Name of the font slot, e.g. 'font' (the default slot for most Controls)",
        },
        font_path: {
          type: "string",
          description:
            "Path to the font resource, e.g. 'res://fonts/MyFont.ttf' or 'res://fonts/MyFont.tres'",
        },
        font_size: {
          type: "integer",
          description: "Optional font size in pixels for this slot",
        },
      },
      required: ["theme_path", "theme_type", "font_name", "font_path"],
    },
    handler: async (args) => {
      return await callTool("set_theme_font", args);
    },
  },

  set_theme_constant: {
    name: "set_theme_constant",
    description:
      "Set an integer constant override for a specific Control type in a Theme file. Constants control spacing, icon sizes, and other integer properties. Saves the theme immediately.",
    inputSchema: {
      type: "object",
      properties: {
        theme_path: {
          type: "string",
          description: "Path to the .tres Theme file",
        },
        theme_type: {
          type: "string",
          description: "Control class name, e.g. 'Button', 'ItemList', 'Tree'",
        },
        constant_name: {
          type: "string",
          description:
            "Name of the constant, e.g. 'outline_size', 'h_separation', 'v_separation', 'icon_max_width'",
        },
        value: {
          type: "integer",
          description: "Integer value for the constant",
        },
      },
      required: ["theme_path", "theme_type", "constant_name", "value"],
    },
    handler: async (args) => {
      return await callTool("set_theme_constant", args);
    },
  },

  set_stylebox: {
    name: "set_stylebox",
    description:
      "Create and assign a StyleBox to a named slot for a specific Control type in a Theme file. Use 'flat' for colored/bordered boxes, 'line' for a single divider line, 'empty' for invisible padding. Saves the theme immediately.",
    inputSchema: {
      type: "object",
      properties: {
        theme_path: {
          type: "string",
          description: "Path to the .tres Theme file",
        },
        theme_type: {
          type: "string",
          description: "Control class name, e.g. 'Button', 'PanelContainer', 'TabContainer'",
        },
        stylebox_name: {
          type: "string",
          description:
            "Name of the StyleBox slot, e.g. 'normal', 'hover', 'pressed', 'disabled', 'panel', 'focus'",
        },
        stylebox_type: {
          type: "string",
          enum: ["flat", "line", "empty"],
          description:
            "'flat' (default) — solid box with optional border, corners, shadow. 'line' — single-pixel divider. 'empty' — invisible, used for padding.",
        },
        properties: {
          type: "object",
          description:
            "StyleBox properties to set. For 'flat': bg_color, border_color, border_width (all sides), border_width_left/right/top/bottom, corner_radius (all corners), corner_radius_top_left/top_right/bottom_left/bottom_right, draw_center, anti_aliased, shadow_color, shadow_size, shadow_offset ([x,y]), expand_margin (all sides), expand_margin_left/right/top/bottom. For 'line': color, thickness, vertical.",
          additionalProperties: true,
        },
      },
      required: ["theme_path", "theme_type", "stylebox_name"],
    },
    handler: async (args) => {
      return await callTool("set_stylebox", args);
    },
  },

  get_theme_info: {
    name: "get_theme_info",
    description:
      "Return all overrides defined in a Theme file, organized by Control type. Shows colors, fonts, font sizes, integer constants, and StyleBox names/types. Use this to inspect a theme before modifying it.",
    inputSchema: {
      type: "object",
      properties: {
        theme_path: {
          type: "string",
          description: "Path to the .tres Theme file, e.g. 'res://theme/my_theme.tres'",
        },
      },
      required: ["theme_path"],
    },
    handler: async (args) => {
      return await callTool("get_theme_info", args);
    },
  },
};
