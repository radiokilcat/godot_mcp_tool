/**
 * Tool type definitions
 */

export interface ToolDefinition {
  name: string;
  description: string;
  inputSchema?: {
    type: string;
    properties?: Record<string, unknown>;
    required?: string[];
  };
  handler: (args: Record<string, unknown>) => Promise<unknown>;
  /** Minimum/maximum Godot engine version this tool supports (e.g. "4.3"). Checked against the connected plugin's reported version before dispatch. */
  minGodotVersion?: string;
  maxGodotVersion?: string;
}

export interface ToolCategory {
  [toolName: string]: ToolDefinition;
}

export interface GodotResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  suggestions?: string[];
}

export interface GodotNode {
  path: string;
  name: string;
  type: string;
  script?: string;
  parent?: string;
  children?: GodotNode[];
  properties?: Record<string, unknown>;
}

export interface GodotScene {
  path: string;
  name: string;
  rootNode?: GodotNode;
  nodeCount?: number;
  isOpen?: boolean;
}
