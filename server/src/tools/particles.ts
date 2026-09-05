/**
 * Particle tools - 5 tools
 * Tools for creating and configuring GPU particle systems, materials, gradients, and presets.
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";
import { vector3Schema } from "./schemas.js";

export const particleTools: ToolCategory = {
  create_particle_system: {
    name: "create_particle_system",
    description:
      "Add a GPUParticles3D or GPUParticles2D node to the scene. Creates an empty particle system — use set_particle_material or load_particle_preset to configure it.",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node. Omit or use '.' for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new node (default: 'GPUParticles3D' or 'GPUParticles2D')",
        },
        dimension: {
          type: "string",
          enum: ["3d", "2d"],
          description: "Whether to create a 3D or 2D particle system (default: '3d')",
        },
        amount: {
          type: "integer",
          description: "Maximum number of particles alive at once (default: 100)",
        },
        lifetime: {
          type: "number",
          description: "Particle lifetime in seconds (default: 1.0)",
        },
        emitting: {
          type: "boolean",
          description: "Start emitting particles immediately (default: true)",
        },
        one_shot: {
          type: "boolean",
          description: "Emit all particles once and stop, rather than looping (default: false)",
        },
        position: {
          ...vector3Schema,
          description: "Local position of the particle node",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("create_particle_system", args);
    },
  },

  set_particle_material: {
    name: "set_particle_material",
    description:
      "Create or update the ParticleProcessMaterial on a GPUParticles node. Controls particle physics: direction, velocity, gravity, scale, color, and emission shape.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the GPUParticles3D or GPUParticles2D node",
        },
        direction: {
          ...vector3Schema,
          description: "Emission direction vector (default: {x:0, y:1, z:0})",
        },
        spread: {
          type: "number",
          description: "Cone spread angle in degrees around direction (default: 45.0, 0 = straight line, 180 = full hemisphere)",
        },
        gravity: {
          ...vector3Schema,
          description: "Gravity applied to particles (default: {x:0, y:-9.8, z:0})",
        },
        initial_velocity_min: {
          type: "number",
          description: "Minimum initial particle speed (default: 1.0)",
        },
        initial_velocity_max: {
          type: "number",
          description: "Maximum initial particle speed (default: 1.0)",
        },
        angular_velocity_min: {
          type: "number",
          description: "Minimum rotation speed in degrees/second",
        },
        angular_velocity_max: {
          type: "number",
          description: "Maximum rotation speed in degrees/second",
        },
        scale_min: {
          type: "number",
          description: "Minimum particle scale (default: 1.0)",
        },
        scale_max: {
          type: "number",
          description: "Maximum particle scale (default: 1.0)",
        },
        damping_min: {
          type: "number",
          description: "Minimum velocity damping applied over lifetime",
        },
        damping_max: {
          type: "number",
          description: "Maximum velocity damping applied over lifetime",
        },
        color: {
          type: "string",
          description: "Base particle color as HTML hex string, e.g. '#ff8800' (default: white)",
        },
        emission_shape: {
          type: "string",
          enum: ["point", "sphere", "sphere_surface", "box", "ring"],
          description: "Emission volume shape (default: 'point')",
        },
        emission_sphere_radius: {
          type: "number",
          description: "Radius of sphere/sphere_surface emission shape",
        },
        emission_box_extents: {
          ...vector3Schema,
          description: "Half-extents of the box emission volume",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("set_particle_material", args);
    },
  },

  set_particle_gradient: {
    name: "set_particle_gradient",
    description:
      "Assign a color gradient to a particle system's material. The gradient controls color or initial color over each particle's lifetime. Requires the node to already have a ParticleProcessMaterial (call set_particle_material first).",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the GPUParticles3D or GPUParticles2D node",
        },
        colors: {
          type: "array",
          description:
            "Array of color stops defining the gradient. Each entry: {\"offset\": 0.0–1.0, \"color\": \"#rrggbb\"}. Must have at least 2 entries.",
          items: {
            type: "object",
            properties: {
              offset: { type: "number", minimum: 0, maximum: 1 },
              color: { type: "string" },
            },
            required: ["offset", "color"],
          },
        },
        gradient_type: {
          type: "string",
          enum: ["color_ramp", "color_initial_ramp"],
          description:
            "'color_ramp' (default) — color varies over particle lifetime. 'color_initial_ramp' — color varies by emission angle.",
        },
      },
      required: ["node_path", "colors"],
    },
    handler: async (args) => {
      return await callTool("set_particle_gradient", args);
    },
  },

  load_particle_preset: {
    name: "load_particle_preset",
    description:
      "Apply a built-in particle effect preset to a GPUParticles node. Replaces the current process material, amount, and lifetime with preset values. Fully undoable.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the GPUParticles3D or GPUParticles2D node",
        },
        preset: {
          type: "string",
          enum: ["fire", "smoke", "sparks", "rain", "snow", "explosion", "magic"],
          description:
            "Preset to apply. 'explosion' also enables one_shot mode. Each preset configures direction, spread, gravity, velocity, scale, and color.",
        },
      },
      required: ["node_path", "preset"],
    },
    handler: async (args) => {
      return await callTool("load_particle_preset", args);
    },
  },

  get_particle_info: {
    name: "get_particle_info",
    description:
      "Get the current configuration of a GPUParticles node: amount, lifetime, emit state, and ParticleProcessMaterial properties (direction, velocity, color, emission shape, gradient presence).",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the GPUParticles3D or GPUParticles2D node",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_particle_info", args);
    },
  },
};
