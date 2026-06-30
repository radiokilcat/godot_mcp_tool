/**
 * Animation tools - 6 tools
 * Tools for creating and editing AnimationPlayer animations
 */

import { ToolCategory } from "../types/index.js";
import { godotConnection } from "../godot-connection.js";

export const animationTools: ToolCategory = {
  create_animation: {
    name: "create_animation",
    description: "Create a new animation in an AnimationPlayer node",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationPlayer node",
        },
        animation_name: {
          type: "string",
          description: "Name for the new animation",
        },
        length: {
          type: "number",
          description: "Duration of the animation in seconds (default: 1.0)",
        },
        loop_mode: {
          type: "string",
          enum: ["none", "linear", "pingpong"],
          description: "Loop mode (default: none)",
        },
      },
      required: ["node_path", "animation_name"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("create_animation", args);
    },
  },

  add_animation_track: {
    name: "add_animation_track",
    description: "Add a track to an existing animation (property, method, or Bezier track)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationPlayer node",
        },
        animation_name: {
          type: "string",
          description: "Name of the animation to add a track to",
        },
        track_type: {
          type: "string",
          enum: ["value", "method", "bezier", "audio", "animation"],
          description: "Type of track to add (default: value)",
        },
        target_path: {
          type: "string",
          description: "NodePath to the target node (relative to AnimationPlayer's root), e.g. 'Sprite2D:position'",
        },
        interpolation: {
          type: "string",
          enum: ["nearest", "linear", "cubic", "linear_angle", "cubic_angle"],
          description: "Interpolation mode for value tracks (default: linear)",
        },
      },
      required: ["node_path", "animation_name", "target_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("add_animation_track", args);
    },
  },

  add_keyframe: {
    name: "add_keyframe",
    description: "Add a keyframe to a track in an animation",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationPlayer node",
        },
        animation_name: {
          type: "string",
          description: "Animation name",
        },
        track_index: {
          type: "number",
          description: "Track index (0-based). Use get_animation_info to find indices.",
        },
        time: {
          type: "number",
          description: "Time position of the keyframe in seconds",
        },
        value: {
          description: "Value for the keyframe. Strings like 'Vector2(10,20)' are auto-converted.",
        },
        transition: {
          type: "number",
          description: "Transition easing (0.0–1.0 for ease-in/out). Default: 1.0",
        },
      },
      required: ["node_path", "animation_name", "track_index", "time", "value"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("add_keyframe", args);
    },
  },

  set_easing: {
    name: "set_easing",
    description: "Set the easing/transition curve of a keyframe in an animation track",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationPlayer node",
        },
        animation_name: {
          type: "string",
          description: "Animation name",
        },
        track_index: {
          type: "number",
          description: "Track index (0-based)",
        },
        key_index: {
          type: "number",
          description: "Keyframe index within the track",
        },
        transition: {
          type: "number",
          description: "Transition value. 1.0 = linear, <1 = ease-in, >1 = ease-out. Negative values create bounce effects.",
        },
      },
      required: ["node_path", "animation_name", "track_index", "key_index"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("set_easing", args);
    },
  },

  get_animation_info: {
    name: "get_animation_info",
    description: "Get detailed info about an animation: tracks, keyframes, length, loop mode",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationPlayer node",
        },
        animation_name: {
          type: "string",
          description: "Animation name. Omit to list all animation names.",
        },
        include_keyframes: {
          type: "boolean",
          description: "Include keyframe data for each track (default: false)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("get_animation_info", args);
    },
  },

  delete_animation: {
    name: "delete_animation",
    description: "Delete an animation or remove a track from an animation",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationPlayer node",
        },
        animation_name: {
          type: "string",
          description: "Animation name to delete or modify",
        },
        track_index: {
          type: "number",
          description: "If provided, only this track is removed instead of the whole animation",
        },
      },
      required: ["node_path", "animation_name"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("delete_animation", args);
    },
  },
};
