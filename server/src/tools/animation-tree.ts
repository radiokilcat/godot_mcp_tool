/**
 * AnimationTree tools - 8 tools
 * Tools for creating and editing AnimationTree, StateMachine, BlendTree, BlendSpace
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

export const animationTreeTools: ToolCategory = {
  create_animation_tree: {
    name: "create_animation_tree",
    description:
      "Create an AnimationTree node in the current scene and attach a tree root (state machine, blend tree, or blend space)",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to the parent node. Omit or use '.' for scene root.",
        },
        node_name: {
          type: "string",
          description: "Name for the new AnimationTree node (default: 'AnimationTree')",
        },
        anim_player_path: {
          type: "string",
          description: "NodePath to the AnimationPlayer that this AnimationTree will drive",
        },
        tree_root_type: {
          type: "string",
          enum: ["state_machine", "blend_tree", "blend_space_1d", "blend_space_2d"],
          description: "Type of root animation node to create (default: state_machine)",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await callTool("create_animation_tree", args);
    },
  },

  create_state_machine: {
    name: "create_state_machine",
    description:
      "Set the tree_root of an AnimationTree to a new AnimationNodeStateMachine, optionally adding initial animation states",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationTree node",
        },
        states: {
          type: "array",
          description:
            "Initial states to add. Each entry: { name: string, animation?: string }",
          items: {
            type: "object",
            properties: {
              name: { type: "string", description: "State name" },
              animation: {
                type: "string",
                description: "Animation name from AnimationPlayer to assign to this state",
              },
            },
            required: ["name"],
          },
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("create_state_machine", args);
    },
  },

  add_transition: {
    name: "add_transition",
    description:
      "Add a transition between two states in an AnimationNodeStateMachine. Use 'Start' and 'End' for the built-in entry/exit nodes.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationTree node",
        },
        from_state: {
          type: "string",
          description: "Source state name (use 'Start' for the built-in entry node)",
        },
        to_state: {
          type: "string",
          description: "Destination state name (use 'End' for the built-in exit node)",
        },
        xfade_time: {
          type: "number",
          description: "Cross-fade blend time in seconds (default: 0.0)",
        },
        switch_mode: {
          type: "string",
          enum: ["immediate", "sync", "at_end"],
          description: "When the transition triggers (default: immediate)",
        },
        advance_condition: {
          type: "string",
          description:
            "Name of a boolean parameter that triggers the transition automatically when true",
        },
      },
      required: ["node_path", "from_state", "to_state"],
    },
    handler: async (args) => {
      return await callTool("add_transition", args);
    },
  },

  add_blend_tree: {
    name: "add_blend_tree",
    description:
      "Set the tree_root of an AnimationTree to a new AnimationNodeBlendTree, optionally adding blend nodes",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationTree node",
        },
        nodes: {
          type: "array",
          description:
            "Blend nodes to add. Each entry: { name, type, animation?, x?, y? }",
          items: {
            type: "object",
            properties: {
              name: { type: "string", description: "Node name within the blend tree" },
              type: {
                type: "string",
                enum: [
                  "animation",
                  "blend2",
                  "blend3",
                  "one_shot",
                  "time_scale",
                  "transition",
                ],
                description: "Node type (default: animation)",
              },
              animation: {
                type: "string",
                description: "Animation name (only for type=animation)",
              },
              x: { type: "number", description: "Visual X position in editor graph" },
              y: { type: "number", description: "Visual Y position in editor graph" },
            },
            required: ["name"],
          },
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("add_blend_tree", args);
    },
  },

  set_active_state: {
    name: "set_active_state",
    description:
      "Enable/disable an AnimationTree (active param), or set the initial/entry state of a StateMachine by adding a Start→state transition (state_name param)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationTree node",
        },
        active: {
          type: "boolean",
          description: "Set AnimationTree.active to this value",
        },
        state_name: {
          type: "string",
          description:
            "Add a Start→state_name transition, making this state the initial entry state",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("set_active_state", args);
    },
  },

  get_state_machine_info: {
    name: "get_state_machine_info",
    description:
      "Get detailed info about an AnimationTree: tree_root type, states, transitions, blend points",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationTree node",
        },
        include_transitions: {
          type: "boolean",
          description:
            "Include transition data for StateMachine roots (default: true)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_state_machine_info", args);
    },
  },

  edit_blend_space: {
    name: "edit_blend_space",
    description:
      "Add, remove, reposition, or list blend points in a BlendSpace1D or BlendSpace2D tree root",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationTree node whose tree_root is a BlendSpace",
        },
        action: {
          type: "string",
          enum: ["add_point", "remove_point", "set_point", "list_points"],
          description: "Operation to perform",
        },
        animation: {
          type: "string",
          description: "Animation name for the blend point (add_point only)",
        },
        index: {
          type: "number",
          description: "Blend point index (remove_point / set_point)",
        },
        pos: {
          type: "number",
          description: "Position along the 1D blend axis (BlendSpace1D only)",
        },
        x: {
          type: "number",
          description: "X position on the 2D blend plane (BlendSpace2D only)",
        },
        y: {
          type: "number",
          description: "Y position on the 2D blend plane (BlendSpace2D only)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("edit_blend_space", args);
    },
  },

  delete_animation_tree_node: {
    name: "delete_animation_tree_node",
    description:
      "Delete a state from a StateMachine (state_name param), or remove the AnimationTree node itself from the scene (no state_name)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AnimationTree node",
        },
        state_name: {
          type: "string",
          description:
            "State to remove from the StateMachine. Omit to delete the AnimationTree node itself.",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("delete_animation_tree_node", args);
    },
  },
};
