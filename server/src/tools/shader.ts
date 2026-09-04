/**
 * Shader tools - 6 tools
 * Tools for creating, editing, and inspecting Godot shaders (.gdshader files)
 * and assigning ShaderMaterials to scene nodes.
 *
 * File-based tools (create_shader, edit_shader) write to disk immediately.
 * Node-mutation tools (assign_material, set_shader_param) support Ctrl+Z undo.
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

export const shaderTools: ToolCategory = {
  create_shader: {
    name: "create_shader",
    description:
      "Create a new Godot shader file (.gdshader) with optional skeleton code. Optionally creates a companion ShaderMaterial .tres file. Returns an error if the file already exists unless overwrite is true.",
    inputSchema: {
      type: "object",
      properties: {
        shader_path: {
          type: "string",
          description:
            "Path where the .gdshader file will be saved, e.g. 'res://shaders/my_shader.gdshader'",
        },
        shader_type: {
          type: "string",
          enum: ["spatial", "canvas_item", "particles", "sky", "fog"],
          description:
            "Shader type. 'spatial' (default) for 3D surfaces, 'canvas_item' for 2D/UI, 'particles' for GPU particles, 'sky' for sky shaders, 'fog' for volumetric fog.",
        },
        code: {
          type: "string",
          description:
            "Optional full shader source code. If omitted, a minimal skeleton is generated. If provided without a 'shader_type' directive, one is prepended automatically.",
        },
        overwrite: {
          type: "boolean",
          description:
            "Set to true to replace an existing shader file. Defaults to false to prevent accidental overwrites.",
        },
        material_path: {
          type: "string",
          description:
            "Optional path to also save a companion ShaderMaterial .tres file, e.g. 'res://materials/my_material.tres'",
        },
      },
      required: ["shader_path"],
    },
    handler: async (args) => {
      return await callTool("create_shader", args);
    },
  },

  edit_shader: {
    name: "edit_shader",
    description:
      "Replace or append to the source code of an existing .gdshader file. Changes take effect immediately — any node using a ShaderMaterial referencing this shader will recompile.",
    inputSchema: {
      type: "object",
      properties: {
        shader_path: {
          type: "string",
          description: "Path to the existing .gdshader file to edit",
        },
        code: {
          type: "string",
          description:
            "New shader source code. Replaces the entire file contents by default. Set append: true to add to the end instead.",
        },
        append: {
          type: "boolean",
          description:
            "If true, the provided code is appended to the existing file instead of replacing it. Defaults to false.",
        },
      },
      required: ["shader_path", "code"],
    },
    handler: async (args) => {
      return await callTool("edit_shader", args);
    },
  },

  assign_material: {
    name: "assign_material",
    description:
      "Assign a ShaderMaterial to a node in the current scene. Provide either shader_path (creates a new in-memory ShaderMaterial, optionally saved with save_material_path) or material_path (loads an existing .tres ShaderMaterial). Works on GeometryInstance3D nodes (use surface_index) and CanvasItem nodes. Supports Ctrl+Z undo.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Scene-relative path to the node (must be GeometryInstance3D such as MeshInstance3D, or a CanvasItem such as Sprite2D)",
        },
        shader_path: {
          type: "string",
          description:
            "Path to a .gdshader file to create a new in-memory ShaderMaterial from",
        },
        material_path: {
          type: "string",
          description:
            "Path to an existing ShaderMaterial .tres file to load and assign",
        },
        surface_index: {
          type: "integer",
          description:
            "Surface slot index for GeometryInstance3D nodes (e.g. MeshInstance3D). Defaults to 0.",
        },
        save_material_path: {
          type: "string",
          description:
            "When using shader_path, also save the newly created ShaderMaterial to this .tres path so it persists across sessions",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("assign_material", args);
    },
  },

  set_shader_param: {
    name: "set_shader_param",
    description:
      "Set the value of a uniform parameter on a node's ShaderMaterial. Supports Ctrl+Z undo. Value types: number (float/int), boolean, [x,y] array (vec2), [x,y,z] array (vec3), [r,g,b,a] array (Color), '#rrggbb' hex string (Color), or 'res://...' path (sampler2D Texture).",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Scene-relative path to the node whose ShaderMaterial will be updated",
        },
        param_name: {
          type: "string",
          description:
            "Name of the uniform variable in the shader, e.g. 'albedo_color', 'roughness', 'tiling'",
        },
        param_value: {
          description:
            "Value to set. Use a number for float/int, [x,y] for vec2, [x,y,z] for vec3, [r,g,b,a] for Color (0–1 range), '#rrggbb' string for Color hex, or 'res://...' path string for Texture (sampler2D) uniforms.",
        },
        surface_index: {
          type: "integer",
          description:
            "Surface slot index for GeometryInstance3D nodes. Defaults to 0.",
        },
      },
      required: ["node_path", "param_name", "param_value"],
    },
    handler: async (args) => {
      return await callTool("set_shader_param", args);
    },
  },

  get_shader_info: {
    name: "get_shader_info",
    description:
      "Return the source code, shader type, and uniform list for a shader. Can inspect via a .gdshader file path, a ShaderMaterial .tres file path, or a node path. When called with a node_path or material_path, also returns the current value of each uniform parameter.",
    inputSchema: {
      type: "object",
      properties: {
        shader_path: {
          type: "string",
          description: "Path to a .gdshader file",
        },
        material_path: {
          type: "string",
          description: "Path to a ShaderMaterial .tres file",
        },
        node_path: {
          type: "string",
          description:
            "Scene-relative path to a node with a ShaderMaterial assigned",
        },
        surface_index: {
          type: "integer",
          description:
            "Surface slot for GeometryInstance3D nodes when using node_path. Defaults to 0.",
        },
      },
    },
    handler: async (args) => {
      return await callTool("get_shader_info", args);
    },
  },

  validate_shader: {
    name: "validate_shader",
    description:
      "Validate a Godot shader for structural correctness: checks for a valid 'shader_type' declaration and whether Godot recognizes the declared mode. Note: full GLSL syntax errors inside function bodies are not detectable via GDScript — check Godot's Output panel for GPU compile errors after assigning the shader to a material.",
    inputSchema: {
      type: "object",
      properties: {
        shader_path: {
          type: "string",
          description: "Path to an existing .gdshader file to validate",
        },
        code: {
          type: "string",
          description:
            "Inline shader source code to validate (alternative to shader_path; useful for checking code before saving)",
        },
      },
    },
    handler: async (args) => {
      return await callTool("validate_shader", args);
    },
  },
};
