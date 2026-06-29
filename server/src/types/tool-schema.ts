/**
 * Tool Definition Schema
 * Defines the structure and metadata for MCP tools
 */

export interface ToolParameter {
  name: string;
  type:
    | "string"
    | "number"
    | "integer"
    | "boolean"
    | "array"
    | "object"
    | "null";
  description: string;
  required?: boolean;
  default?: unknown;
  enum?: unknown[];
  minimum?: number;
  maximum?: number;
  pattern?: string;
  items?: ToolParameter;
  properties?: Record<string, ToolParameter>;
}

export interface ToolInputSchema {
  type: "object";
  properties: Record<string, ToolParameter>;
  required?: string[];
  additionalProperties?: boolean;
}

export interface ToolOutputSchema {
  type: string;
  description?: string;
  properties?: Record<string, unknown>;
}

export interface ToolCategory {
  name: string;
  description: string;
  tools: Tool[];
}

export interface Tool {
  // Identity
  name: string;
  version: string;

  // Metadata
  category:
    | "project"
    | "scene"
    | "node"
    | "script"
    | "editor"
    | "input"
    | "runtime"
    | "animation"
    | "animation_tree"
    | "3d_scene"
    | "physics"
    | "particle"
    | "navigation"
    | "audio"
    | "tilemap"
    | "theme_ui"
    | "shader"
    | "resource"
    | "batch_refactor"
    | "analysis"
    | "testing_qa"
    | "profiling"
    | "export";

  description: string;
  longDescription?: string;

  // API
  inputSchema: ToolInputSchema;
  outputSchema?: ToolOutputSchema;

  // Behavior
  requiresScene?: boolean;
  requiresNode?: boolean;
  supportsUndo?: boolean;
  async?: boolean;

  // Documentation
  examples?: ToolExample[];
  notes?: string[];
  warnings?: string[];
  relatedTools?: string[];

  // Metadata
  tags?: string[];
  experimental?: boolean;
  deprecated?: boolean;
  deprecatedMessage?: string;
}

export interface ToolExample {
  description: string;
  input: Record<string, unknown>;
  output: unknown;
}

/**
 * Complete tool registry schema
 */
export interface ToolRegistry {
  version: string;
  godotVersion: string;
  categories: ToolCategory[];
  totalTools: number;
}

/**
 * Lite mode tool set for clients with tool limits
 */
export interface LiteToolSet {
  version: string;
  coreToolCount: number;
  toolNames: string[];
}
