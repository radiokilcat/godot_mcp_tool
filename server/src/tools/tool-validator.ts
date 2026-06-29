/**
 * Tool Definition Validator
 * Validates tool definitions against the schema
 */

import {
  Tool,
  ToolInputSchema,
  ToolParameter,
} from "../types/tool-schema.js";

export interface ValidationError {
  path: string;
  message: string;
  severity: "error" | "warning";
}

export interface ValidationResult {
  isValid: boolean;
  errors: ValidationError[];
  warnings: ValidationError[];
}

const VALID_CATEGORIES = [
  "project",
  "scene",
  "node",
  "script",
  "editor",
  "input",
  "runtime",
  "animation",
  "animation_tree",
  "3d_scene",
  "physics",
  "particle",
  "navigation",
  "audio",
  "tilemap",
  "theme_ui",
  "shader",
  "resource",
  "batch_refactor",
  "analysis",
  "testing_qa",
  "profiling",
  "export",
];

const VALID_TYPES = [
  "string",
  "number",
  "integer",
  "boolean",
  "array",
  "object",
  "null",
];

/**
 * Validate a tool definition
 */
export function validateTool(tool: unknown): ValidationResult {
  const errors: ValidationError[] = [];
  const warnings: ValidationError[] = [];

  if (!tool || typeof tool !== "object") {
    errors.push({
      path: "root",
      message: "Tool must be an object",
      severity: "error",
    });
    return { isValid: false, errors, warnings };
  }

  const t = tool as Partial<Tool>;

  // Required fields
  if (!t.name || typeof t.name !== "string") {
    errors.push({
      path: "name",
      message: "Tool name is required and must be a string",
      severity: "error",
    });
  }

  if (!t.version || typeof t.version !== "string") {
    errors.push({
      path: "version",
      message: "Tool version is required and must be a string",
      severity: "error",
    });
  }

  if (!t.category || !VALID_CATEGORIES.includes(t.category)) {
    errors.push({
      path: "category",
      message: `Tool category must be one of: ${VALID_CATEGORIES.join(", ")}`,
      severity: "error",
    });
  }

  if (!t.description || typeof t.description !== "string") {
    errors.push({
      path: "description",
      message: "Tool description is required and must be a string",
      severity: "error",
    });
  }

  // Input schema
  if (!t.inputSchema) {
    errors.push({
      path: "inputSchema",
      message: "Input schema is required",
      severity: "error",
    });
  } else {
    const schemaErrors = validateInputSchema(t.inputSchema, "inputSchema");
    errors.push(...schemaErrors);
  }

  // Optional fields validation
  if (t.longDescription && typeof t.longDescription !== "string") {
    errors.push({
      path: "longDescription",
      message: "Long description must be a string",
      severity: "error",
    });
  }

  if (t.tags && !Array.isArray(t.tags)) {
    errors.push({
      path: "tags",
      message: "Tags must be an array of strings",
      severity: "error",
    });
  }

  if (t.examples && !Array.isArray(t.examples)) {
    errors.push({
      path: "examples",
      message: "Examples must be an array",
      severity: "error",
    });
  }

  // Warnings
  if (!t.longDescription) {
    warnings.push({
      path: "longDescription",
      message: "Long description is recommended for better documentation",
      severity: "warning",
    });
  }

  if (!t.examples || t.examples.length === 0) {
    warnings.push({
      path: "examples",
      message: "At least one example is recommended",
      severity: "warning",
    });
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Validate input schema
 */
function validateInputSchema(
  schema: unknown,
  path: string
): ValidationError[] {
  const errors: ValidationError[] = [];

  if (!schema || typeof schema !== "object") {
    errors.push({
      path,
      message: "Input schema must be an object",
      severity: "error",
    });
    return errors;
  }

  const s = schema as Partial<ToolInputSchema>;

  if (s.type !== "object") {
    errors.push({
      path: `${path}.type`,
      message: "Input schema type must be 'object'",
      severity: "error",
    });
  }

  if (!s.properties || typeof s.properties !== "object") {
    errors.push({
      path: `${path}.properties`,
      message: "Input schema properties must be defined",
      severity: "error",
    });
    return errors;
  }

  // Validate each parameter
  for (const [paramName, param] of Object.entries(s.properties)) {
    const paramErrors = validateParameter(
      param,
      `${path}.properties.${paramName}`
    );
    errors.push(...paramErrors);
  }

  return errors;
}

/**
 * Validate a parameter definition
 */
function validateParameter(
  param: unknown,
  path: string
): ValidationError[] {
  const errors: ValidationError[] = [];

  if (!param || typeof param !== "object") {
    errors.push({
      path,
      message: "Parameter must be an object",
      severity: "error",
    });
    return errors;
  }

  const p = param as Partial<ToolParameter>;

  if (!p.name || typeof p.name !== "string") {
    errors.push({
      path: `${path}.name`,
      message: "Parameter name is required and must be a string",
      severity: "error",
    });
  }

  if (!p.type || !VALID_TYPES.includes(p.type)) {
    errors.push({
      path: `${path}.type`,
      message: `Parameter type must be one of: ${VALID_TYPES.join(", ")}`,
      severity: "error",
    });
  }

  if (!p.description || typeof p.description !== "string") {
    errors.push({
      path: `${path}.description`,
      message: "Parameter description is required and must be a string",
      severity: "error",
    });
  }

  return errors;
}

/**
 * Generate a tool schema template
 */
export function generateToolTemplate(
  name: string,
  category: string
): Partial<Tool> {
  return {
    name,
    version: "1.0.0",
    category: category as Tool["category"],
    description: "TODO: Add description",
    longDescription: "TODO: Add long description",
    inputSchema: {
      type: "object",
      properties: {},
      required: [],
    },
    outputSchema: {
      type: "object",
      description: "TODO: Add output description",
    },
    examples: [],
    tags: [],
    supportsUndo: true,
    async: true,
  };
}
