/**
 * 3D Scene tools - 6 tools
 * Tools for adding and querying 3D objects: meshes, cameras, lights, environment, gridmap.
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";
import { vector3Schema } from "./schemas.js";

export const scene3dTools: ToolCategory = {
  add_mesh: {
    name: "add_mesh",
    description:
      "Add a MeshInstance3D node with a primitive mesh (box, sphere, cylinder, plane, capsule, torus, quad, prism) to the current 3D scene",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node. Omit or use '.' for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new MeshInstance3D node (default: 'MeshInstance3D')",
        },
        mesh_type: {
          type: "string",
          enum: ["box", "sphere", "cylinder", "plane", "capsule", "torus", "quad", "prism"],
          description: "Primitive mesh type to create (default: 'box')",
        },
        position: {
          ...vector3Schema,
          description: "Position in local space (default: origin)",
        },
        rotation: {
          ...vector3Schema,
          description: "Rotation in degrees (default: zero)",
        },
        scale: {
          ...vector3Schema,
          description: "Scale (default: 1,1,1)",
        },
        mesh_properties: {
          type: "object",
          description:
            "Properties of the primitive mesh resource itself, e.g. {\"radius\": 0.35, \"height\": 1.8} for a capsule or {\"size\": \"Vector3(2, 0.2, 2)\"} for a box. Without these the mesh keeps Godot's defaults. Unknown names come back in 'unknown_properties'.",
        },
        material: {
          type: "string",
          description:
            "res:// path to an existing Material to put on the mesh's surface (takes precedence over material_color)",
        },
        material_color: {
          type: "string",
          description:
            "Albedo colour for a StandardMaterial3D created for this mesh, e.g. '#c0392b'",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("add_mesh", args);
    },
  },

  add_camera: {
    name: "add_camera",
    description:
      "Add a Camera3D node to the current 3D scene with configurable projection, FOV or orthographic size, and clipping planes. " +
      "Use take_screenshot with viewport 'camera' to see what it frames.",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node. Omit or use '.' for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new Camera3D node (default: 'Camera3D')",
        },
        fov: {
          type: "number",
          description: "Field of view in degrees for perspective projection (default: 75). Ignored by an orthogonal camera.",
        },
        size: {
          type: "number",
          description:
            "Height of the view in world units for an orthogonal camera (default: 1) — the only parameter that frames it. Ignored by a perspective camera.",
        },
        projection: {
          type: "string",
          enum: ["perspective", "orthogonal", "frustum"],
          description: "Projection type (default: 'perspective')",
        },
        near: {
          type: "number",
          description: "Near clipping plane distance (default: 0.05)",
        },
        far: {
          type: "number",
          description: "Far clipping plane distance (default: 4000)",
        },
        current: {
          type: "boolean",
          description: "Make this the active camera for the viewport (default: false)",
        },
        position: {
          ...vector3Schema,
          description: "Position in local space",
        },
        rotation: {
          ...vector3Schema,
          description: "Rotation in degrees",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("add_camera", args);
    },
  },

  add_light: {
    name: "add_light",
    description:
      "Add a 3D light node (DirectionalLight3D, OmniLight3D, or SpotLight3D) to the current scene",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node. Omit or use '.' for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new light node. Defaults to the light type class name.",
        },
        light_type: {
          type: "string",
          enum: ["directional", "omni", "spot"],
          description: "Type of light to create (default: 'directional')",
        },
        color: {
          type: "string",
          description: "Light color as HTML hex string, e.g. '#ffffff' (default: white)",
        },
        energy: {
          type: "number",
          description: "Light energy/intensity multiplier (default: 1.0)",
        },
        cast_shadow: {
          type: "boolean",
          description: "Whether this light casts shadows (default: false)",
        },
        position: {
          ...vector3Schema,
          description: "Position in local space",
        },
        rotation: {
          ...vector3Schema,
          description: "Rotation in degrees",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("add_light", args);
    },
  },

  set_environment: {
    name: "set_environment",
    description:
      "Create or configure the WorldEnvironment node: background mode/color, ambient light, fog, and tonemapping. Finds an existing WorldEnvironment in the scene or creates a new one.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to an existing WorldEnvironment node. Omit to auto-find or create one.",
        },
        node_name: {
          type: "string",
          description: "Name for a newly created WorldEnvironment node (default: 'WorldEnvironment')",
        },
        background_mode: {
          type: "string",
          enum: ["clear_color", "color", "sky", "canvas", "keep", "camera_feed"],
          description: "Background rendering mode",
        },
        background_color: {
          type: "string",
          description: "Background color as HTML hex string, e.g. '#87ceeb' (used when background_mode is 'color')",
        },
        background_energy: {
          type: "number",
          description: "Background energy multiplier",
        },
        ambient_light_color: {
          type: "string",
          description: "Ambient light color as HTML hex string",
        },
        ambient_light_energy: {
          type: "number",
          description: "Ambient light energy (0 = no ambient, 1 = full)",
        },
        fog_enabled: {
          type: "boolean",
          description: "Enable or disable volumetric fog",
        },
        fog_density: {
          type: "number",
          description: "Fog density (higher = thicker fog)",
        },
        tonemap_mode: {
          type: "string",
          enum: ["linear", "reinhard", "filmic", "aces"],
          description: "Tone mapping operator",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("set_environment", args);
    },
  },

  add_gridmap: {
    name: "add_gridmap",
    description:
      "Add a GridMap node to the current 3D scene, optionally loading a MeshLibrary resource",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node. Omit or use '.' for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new GridMap node (default: 'GridMap')",
        },
        cell_size: {
          ...vector3Schema,
          description: "Size of each cell in world units (default: 1,1,1)",
        },
        mesh_library: {
          type: "string",
          description:
            "res:// path to a MeshLibrary resource to assign to the GridMap (optional)",
        },
        position: {
          ...vector3Schema,
          description: "Position in local space",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("add_gridmap", args);
    },
  },

  get_3d_scene_info: {
    name: "get_3d_scene_info",
    description:
      "Scan the current scene and return all Node3D nodes with their type, transform, and type-specific properties (mesh, camera FOV, light color, etc.)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Root node path to start scanning from. Omit to scan the entire scene.",
        },
        depth: {
          type: "number",
          description: "Maximum recursion depth (default: 64)",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("get_3d_scene_info", args);
    },
  },
};
