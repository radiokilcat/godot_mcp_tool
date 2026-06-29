/**
 * Smart Type Parser for Godot Types
 * Parses and converts string representations of Godot types
 */

export interface GodotVector2 {
  type: "Vector2";
  x: number;
  y: number;
}

export interface GodotVector3 {
  type: "Vector3";
  x: number;
  y: number;
  z: number;
}

export interface GodotVector4 {
  type: "Vector4";
  x: number;
  y: number;
  z: number;
  w: number;
}

export interface GodotColor {
  type: "Color";
  r: number;
  g: number;
  b: number;
  a: number;
  hex?: string;
}

export interface GodotRect2 {
  type: "Rect2";
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface GodotTransform2D {
  type: "Transform2D";
  origin: GodotVector2;
  x: GodotVector2;
  y: GodotVector2;
}

export interface GodotTransform3D {
  type: "Transform3D";
  origin: GodotVector3;
  basis: GodotBasis;
}

export interface GodotBasis {
  type: "Basis";
  x: GodotVector3;
  y: GodotVector3;
  z: GodotVector3;
}

export interface GodotQuaternion {
  type: "Quaternion";
  x: number;
  y: number;
  z: number;
  w: number;
}

export type GodotType =
  | GodotVector2
  | GodotVector3
  | GodotVector4
  | GodotColor
  | GodotRect2
  | GodotTransform2D
  | GodotTransform3D
  | GodotBasis
  | GodotQuaternion
  | string
  | number
  | boolean
  | null;

/**
 * Parse a string representation of a Godot type
 * Supports:
 * - Vector2(x, y)
 * - Vector3(x, y, z)
 * - Vector4(x, y, z, w)
 * - Color(r, g, b, a) or #RRGGBB or #RRGGBBAA
 * - Rect2(x, y, width, height)
 * - Transform2D()
 * - Transform3D()
 * - Basis()
 * - Quaternion(x, y, z, w)
 */
export function parseGodotType(value: string | unknown): GodotType {
  if (typeof value !== "string") {
    return value as GodotType;
  }

  const trimmed = value.trim();

  // Try to parse as Vector2
  if (trimmed.startsWith("Vector2(") && trimmed.endsWith(")")) {
    return parseVector2(trimmed);
  }

  // Try to parse as Vector3
  if (trimmed.startsWith("Vector3(") && trimmed.endsWith(")")) {
    return parseVector3(trimmed);
  }

  // Try to parse as Vector4
  if (trimmed.startsWith("Vector4(") && trimmed.endsWith(")")) {
    return parseVector4(trimmed);
  }

  // Try to parse as Color
  if (trimmed.startsWith("Color(") && trimmed.endsWith(")")) {
    return parseColor(trimmed);
  }

  // Try to parse as hex color
  if (trimmed.match(/^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/)) {
    return parseHexColor(trimmed);
  }

  // Try to parse as Rect2
  if (trimmed.startsWith("Rect2(") && trimmed.endsWith(")")) {
    return parseRect2(trimmed);
  }

  // Try to parse as Quaternion
  if (trimmed.startsWith("Quaternion(") && trimmed.endsWith(")")) {
    return parseQuaternion(trimmed);
  }

  // Try to parse as number
  if (!isNaN(Number(trimmed)) && trimmed !== "") {
    return Number(trimmed);
  }

  // Try to parse as boolean
  if (trimmed.toLowerCase() === "true") {
    return true;
  }
  if (trimmed.toLowerCase() === "false") {
    return false;
  }

  // Try to parse as null
  if (trimmed.toLowerCase() === "null") {
    return null;
  }

  // Return as string
  return trimmed;
}

/**
 * Parse Vector2(x, y)
 */
function parseVector2(str: string): GodotVector2 {
  const match = str.match(
    /Vector2\s*\(\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*\)/
  );
  if (!match) {
    throw new Error(`Invalid Vector2 format: ${str}`);
  }

  return {
    type: "Vector2",
    x: parseFloat(match[1]),
    y: parseFloat(match[3]),
  };
}

/**
 * Parse Vector3(x, y, z)
 */
function parseVector3(str: string): GodotVector3 {
  const match = str.match(
    /Vector3\s*\(\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*\)/
  );
  if (!match) {
    throw new Error(`Invalid Vector3 format: ${str}`);
  }

  return {
    type: "Vector3",
    x: parseFloat(match[1]),
    y: parseFloat(match[3]),
    z: parseFloat(match[5]),
  };
}

/**
 * Parse Vector4(x, y, z, w)
 */
function parseVector4(str: string): GodotVector4 {
  const match = str.match(
    /Vector4\s*\(\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*\)/
  );
  if (!match) {
    throw new Error(`Invalid Vector4 format: ${str}`);
  }

  return {
    type: "Vector4",
    x: parseFloat(match[1]),
    y: parseFloat(match[3]),
    z: parseFloat(match[5]),
    w: parseFloat(match[7]),
  };
}

/**
 * Parse Color(r, g, b, a) or Color(r, g, b)
 */
function parseColor(str: string): GodotColor {
  const match = str.match(
    /Color\s*\(\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*(?:,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?))?\s*\)/
  );
  if (!match) {
    throw new Error(`Invalid Color format: ${str}`);
  }

  const r = parseFloat(match[1]);
  const g = parseFloat(match[3]);
  const b = parseFloat(match[5]);
  const a = match[7] ? parseFloat(match[7]) : 1.0;

  return {
    type: "Color",
    r: clampColor(r),
    g: clampColor(g),
    b: clampColor(b),
    a: clampColor(a),
  };
}

/**
 * Parse hex color #RRGGBB or #RRGGBBAA
 */
function parseHexColor(str: string): GodotColor {
  const hex = str.substring(1);
  let r = 0,
    g = 0,
    b = 0,
    a = 255;

  if (hex.length === 6) {
    r = parseInt(hex.substring(0, 2), 16);
    g = parseInt(hex.substring(2, 4), 16);
    b = parseInt(hex.substring(4, 6), 16);
  } else if (hex.length === 8) {
    r = parseInt(hex.substring(0, 2), 16);
    g = parseInt(hex.substring(2, 4), 16);
    b = parseInt(hex.substring(4, 6), 16);
    a = parseInt(hex.substring(6, 8), 16);
  }

  return {
    type: "Color",
    r: r / 255,
    g: g / 255,
    b: b / 255,
    a: a / 255,
    hex: str,
  };
}

/**
 * Parse Rect2(x, y, width, height)
 */
function parseRect2(str: string): GodotRect2 {
  const match = str.match(
    /Rect2\s*\(\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*\)/
  );
  if (!match) {
    throw new Error(`Invalid Rect2 format: ${str}`);
  }

  return {
    type: "Rect2",
    x: parseFloat(match[1]),
    y: parseFloat(match[3]),
    width: parseFloat(match[5]),
    height: parseFloat(match[7]),
  };
}

/**
 * Parse Quaternion(x, y, z, w)
 */
function parseQuaternion(str: string): GodotQuaternion {
  const match = str.match(
    /Quaternion\s*\(\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*,\s*([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)\s*\)/
  );
  if (!match) {
    throw new Error(`Invalid Quaternion format: ${str}`);
  }

  return {
    type: "Quaternion",
    x: parseFloat(match[1]),
    y: parseFloat(match[3]),
    z: parseFloat(match[5]),
    w: parseFloat(match[7]),
  };
}

/**
 * Clamp color component to 0-1
 */
function clampColor(value: number): number {
  return Math.max(0, Math.min(1, value));
}

/**
 * Convert a GodotType back to its string representation
 */
export function godotTypeToString(value: GodotType): string {
  if (value === null) {
    return "null";
  }

  if (typeof value === "string") {
    return value;
  }

  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }

  if (typeof value === "object" && "type" in value) {
    switch (value.type) {
      case "Vector2":
        return `Vector2(${value.x}, ${value.y})`;
      case "Vector3":
        return `Vector3(${value.x}, ${value.y}, ${value.z})`;
      case "Vector4":
        return `Vector4(${value.x}, ${value.y}, ${value.z}, ${value.w})`;
      case "Color":
        return `Color(${value.r}, ${value.g}, ${value.b}, ${value.a})`;
      case "Rect2":
        return `Rect2(${value.x}, ${value.y}, ${value.width}, ${value.height})`;
      case "Quaternion":
        return `Quaternion(${value.x}, ${value.y}, ${value.z}, ${value.w})`;
      default:
        return JSON.stringify(value);
    }
  }

  return JSON.stringify(value);
}
