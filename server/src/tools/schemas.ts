/**
 * Parameter schemas shared by the tool categories.
 *
 * These lived as copies in navigation/particles/physics/scene-3d, which is how
 * they drifted before (6.6.14 had to patch four files at once). They are also the
 * most expensive thing in `tools/list`: 33 parameters used an `anyOf` of three
 * fully spelled-out branches, 10 134 characters — a tenth of the whole payload
 * the model loads before the user has asked anything (9.7.1).
 *
 * The compact form says the same thing. A JSON Schema `type` may be a list, and
 * the array keywords still apply when the value happens to be an array, so
 * `[1, 2]` is still rejected for a Vector3 — which matters, because the plugin
 * would silently coerce it to the default and report success, exactly the class
 * of bug 6.6.14 was.
 */

export const vector2Schema = {
  type: ["object", "string", "array"],
  items: { type: "number" },
  minItems: 2,
  maxItems: 2,
  description: "Vector2 as {x, y}, \"Vector2(100, 200)\", or [x, y]",
} as const;

export const vector3Schema = {
  type: ["object", "string", "array"],
  items: { type: "number" },
  minItems: 3,
  maxItems: 3,
  description: "Vector3 as {x, y, z}, \"Vector3(0, 2, 5)\", or [x, y, z]",
} as const;

/** For tools that take either, choosing by the node's dimension. */
export const vectorSchema = {
  type: ["object", "string", "array"],
  items: { type: "number" },
  minItems: 2,
  maxItems: 3,
  description: "Vector2 or Vector3 as {x, y[, z]}, \"Vector3(0, 2, 5)\", or [x, y[, z]]",
} as const;

export const layersSchema = {
  type: ["integer", "array"],
  minimum: 0,
  items: { type: "integer", minimum: 1, maximum: 32 },
  description: "Bitmask (3 = layers 1+2) or 1-based layer numbers ([1, 3])",
} as const;

export const colorSchema = {
  type: ["object", "string", "array"],
  description: "Color as \"#ff0000\", \"Color(1, 0, 0)\", {r, g, b, a} or [r, g, b, a]",
} as const;

/**
 * Give a shared schema a parameter-specific description without losing the one
 * that says which literal forms are accepted. Spreading alone silently drops one
 * of the two, depending on the order the properties happen to be written in.
 */
export function described<T extends { description: string }>(
  schema: T,
  meaning: string
): T & { description: string } {
  return { ...schema, description: `${meaning} ${schema.description}` };
}
