/**
 * Node tools - 14 tools
 * Tools for node-level operations: add, delete, duplicate, move, properties, signals, groups
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

export const nodeTools: ToolCategory = {
  add_node: {
    name: "add_node",
    description: "Add a new node as a child in the active scene (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Parent node path relative to scene root (use '.' for root)",
        },
        node_type: {
          type: "string",
          description: "Node class name, e.g. 'Sprite2D', 'CollisionShape2D', 'RigidBody3D'",
        },
        node_name: {
          type: "string",
          description: "Name for the new node. Defaults to the node type.",
        },
      },
      required: ["parent_path", "node_type"],
    },
    handler: async (args) => {
      return await callTool("add_node", args);
    },
  },

  delete_node: {
    name: "delete_node",
    description: "Delete a node and its children from the active scene (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node relative to scene root",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("delete_node", args);
    },
  },

  duplicate_node: {
    name: "duplicate_node",
    description: "Duplicate a node and all its children (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node to duplicate",
        },
        new_name: {
          type: "string",
          description: "Name for the duplicate. Defaults to original name + '2'.",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("duplicate_node", args);
    },
  },

  move_node: {
    name: "move_node",
    description: "Move a node to a different parent or reorder it within the same parent (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node to move",
        },
        new_parent_path: {
          type: "string",
          description: "Path to the new parent node",
        },
        index: {
          type: "number",
          description: "Child index position within the new parent (-1 = last)",
        },
      },
      required: ["node_path", "new_parent_path"],
    },
    handler: async (args) => {
      return await callTool("move_node", args);
    },
  },

  rename_node: {
    name: "rename_node",
    description: "Rename a node in the active scene (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node to rename",
        },
        new_name: {
          type: "string",
          description: "New name for the node",
        },
      },
      required: ["node_path", "new_name"],
    },
    handler: async (args) => {
      return await callTool("rename_node", args);
    },
  },

  get_node_properties: {
    name: "get_node_properties",
    description:
      "Get editor-visible properties and their current values for a node. Pass 'names' to " +
      "read specific properties — a bare node reports ~40 of them.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node",
        },
        names: {
          type: "array",
          items: { type: "string" },
          description:
            "Only return these properties, e.g. ['position', 'scale']. Omit for all of them. " +
            "Names that do not match are listed back under 'not_found'.",
        },
        include_categories: {
          type: "boolean",
          description: "Include property category headers in output (default: false)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_node_properties", args);
    },
  },

  set_node_property: {
    name: "set_node_property",
    description: "Set a property on a node. Godot types can be passed as strings: 'Vector2(10, 20)', '#ff0000', 'Color(1,0,0)' (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node",
        },
        property: {
          type: "string",
          description: "Property name, e.g. 'position', 'modulate', 'scale'",
        },
        value: {
          description: "New value. Pass strings for Godot types: 'Vector2(10,20)', '#ff0000'",
        },
      },
      required: ["node_path", "property", "value"],
    },
    handler: async (args) => {
      return await callTool("set_node_property", args);
    },
  },

  get_node_signals: {
    name: "get_node_signals",
    description: "Get all signals defined on a node, including existing connections",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_node_signals", args);
    },
  },

  connect_signal: {
    name: "connect_signal",
    description: "Connect a signal from a source node to a method on a target node (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        source_node_path: {
          type: "string",
          description: "Node that emits the signal",
        },
        signal_name: {
          type: "string",
          description: "Signal name, e.g. 'pressed', 'body_entered'",
        },
        target_node_path: {
          type: "string",
          description: "Node that receives the signal",
        },
        callback_name: {
          type: "string",
          description: "Method name on the target node to call",
        },
      },
      required: ["source_node_path", "signal_name", "target_node_path", "callback_name"],
    },
    handler: async (args) => {
      return await callTool("connect_signal", args);
    },
  },

  add_to_group: {
    name: "add_to_group",
    description: "Add a node to a group (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node",
        },
        group_name: {
          type: "string",
          description: "Group name to add the node to",
        },
      },
      required: ["node_path", "group_name"],
    },
    handler: async (args) => {
      return await callTool("add_to_group", args);
    },
  },

  remove_from_group: {
    name: "remove_from_group",
    description: "Remove a node from a group (supports UndoRedo)",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node",
        },
        group_name: {
          type: "string",
          description: "Group name to remove the node from",
        },
      },
      required: ["node_path", "group_name"],
    },
    handler: async (args) => {
      return await callTool("remove_from_group", args);
    },
  },

  get_node_groups: {
    name: "get_node_groups",
    description: "Get all groups a node belongs to",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_node_groups", args);
    },
  },

  get_node_parent: {
    name: "get_node_parent",
    description: "Get the parent node of a given node",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_node_parent", args);
    },
  },

  get_node_children: {
    name: "get_node_children",
    description: "Get all immediate children of a node",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the node",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_node_children", args);
    },
  },
};
