/**
 * Physics tools - 6 tools
 * Tools for adding and configuring physics bodies, collision shapes, and raycasts.
 */

import { ToolCategory } from "../types/index.js";
import { godotConnection } from "../godot-connection.js";

const vector2Schema = {
  type: "object",
  properties: {
    x: { type: "number" },
    y: { type: "number" },
  },
};

const vector3Schema = {
  type: "object",
  properties: {
    x: { type: "number" },
    y: { type: "number" },
    z: { type: "number" },
  },
};

const layersSchema = {
  description:
    "Collision layers as an integer bitmask (e.g. 1 = layer 1, 3 = layers 1+2) " +
    "or an array of 1-based layer numbers (e.g. [1, 3] enables layers 1 and 3)",
  anyOf: [
    { type: "integer", minimum: 0 },
    { type: "array", items: { type: "integer", minimum: 1, maximum: 32 } },
  ],
};

export const physicsTools: ToolCategory = {
  add_rigid_body: {
    name: "add_rigid_body",
    description:
      "Add a physics body node (RigidBody3D/2D, StaticBody3D/2D, CharacterBody3D/2D, AnimatableBody3D/2D) to the current scene",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node. Omit or use '.' for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new node. Defaults to the class name (e.g. 'RigidBody3D').",
        },
        body_type: {
          type: "string",
          enum: ["rigid", "static", "character", "animatable"],
          description: "Physics body type (default: 'rigid')",
        },
        dimension: {
          type: "string",
          enum: ["3d", "2d"],
          description: "Whether to create a 3D or 2D physics body (default: '3d')",
        },
        mass: {
          type: "number",
          description: "Body mass in kg — only for rigid bodies (default: 1.0)",
        },
        gravity_scale: {
          type: "number",
          description: "Gravity multiplier — only for rigid bodies (default: 1.0)",
        },
        collision_layer: {
          ...layersSchema,
        },
        collision_mask: {
          ...layersSchema,
        },
        position: {
          ...vector3Schema,
          description: "Position in local space (3D). For 2D use x/y only.",
        },
        rotation: {
          ...vector3Schema,
          description: "Rotation in degrees (3D Euler). For 2D pass a single number.",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await godotConnection.callTool("add_rigid_body", args);
    },
  },

  add_collision_shape: {
    name: "add_collision_shape",
    description:
      "Add a CollisionShape3D or CollisionShape2D node with a primitive shape resource. Typically added as a child of a physics body.",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node (typically a PhysicsBody). Omit for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new node (default: 'CollisionShape3D' or 'CollisionShape2D')",
        },
        shape_type: {
          type: "string",
          enum: ["box", "sphere", "capsule", "cylinder", "rectangle", "circle", "segment"],
          description:
            "Shape type. 3D: box, sphere, capsule, cylinder. 2D: rectangle, circle, capsule, segment. (default: 'box' for 3D, 'rectangle' for 2D)",
        },
        dimension: {
          type: "string",
          enum: ["3d", "2d"],
          description: "Whether to create a 3D or 2D collision shape (default: '3d')",
        },
        size: {
          ...vector3Schema,
          description: "Box size (3D) or rectangle size (2D, use x/y). Default: 1,1,1 (3D) or 20,20 (2D).",
        },
        radius: {
          type: "number",
          description: "Radius for sphere, capsule, cylinder, or circle shapes (default: 0.5 for 3D, 10 for 2D)",
        },
        height: {
          type: "number",
          description: "Height for capsule or cylinder shapes (default: 2.0 for 3D, 30 for 2D)",
        },
        point_a: {
          ...vector2Schema,
          description: "Start point for SegmentShape2D (default: -10,0)",
        },
        point_b: {
          ...vector2Schema,
          description: "End point for SegmentShape2D (default: 10,0)",
        },
        position: {
          ...vector3Schema,
          description: "Local position offset of the collision shape",
        },
        rotation: {
          ...vector3Schema,
          description: "Local rotation in degrees (3D only)",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await godotConnection.callTool("add_collision_shape", args);
    },
  },

  set_collision_layer: {
    name: "set_collision_layer",
    description:
      "Set the collision_layer bitmask on a CollisionObject (PhysicsBody or Area). Determines which physics layer(s) the object occupies.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the CollisionObject node (PhysicsBody, Area, etc.)",
        },
        layers: {
          ...layersSchema,
        },
      },
      required: ["node_path", "layers"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("set_collision_layer", args);
    },
  },

  set_collision_mask: {
    name: "set_collision_mask",
    description:
      "Set the collision_mask bitmask on a CollisionObject or RayCast. Determines which layer(s) the object detects collisions with.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the CollisionObject or RayCast node",
        },
        layers: {
          ...layersSchema,
        },
      },
      required: ["node_path", "layers"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("set_collision_mask", args);
    },
  },

  add_raycast: {
    name: "add_raycast",
    description:
      "Add a RayCast3D or RayCast2D node to the scene. The ray fires from the node's origin toward target_position in local space.",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node. Omit or use '.' for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new node (default: 'RayCast3D' or 'RayCast2D')",
        },
        dimension: {
          type: "string",
          enum: ["3d", "2d"],
          description: "Whether to create a 3D or 2D raycast (default: '3d')",
        },
        target_position: {
          ...vector3Schema,
          description:
            "End point of the ray in local space. Default: (0,-1,0) for 3D, (0,100) for 2D.",
        },
        enabled: {
          type: "boolean",
          description: "Whether the raycast is active (default: true)",
        },
        collision_mask: {
          ...layersSchema,
        },
        position: {
          ...vector3Schema,
          description: "Local position of the RayCast node",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await godotConnection.callTool("add_raycast", args);
    },
  },

  get_physics_info: {
    name: "get_physics_info",
    description:
      "Get physics properties of a node: collision layer/mask, body type, mass, velocity (RigidBody), raycast state, and child CollisionShape details",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the physics node (PhysicsBody, Area, RayCast, etc.)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("get_physics_info", args);
    },
  },
};
