import { describe, it, expect } from "vitest";
import { toolCategories, buildToolRegistry } from "../src/registry.js";
import type { ToolDefinition } from "../src/types/index.js";

/**
 * Structural checks over all 163 tool definitions. Cheap where the e2e suite is
 * not: this runs in milliseconds without an editor, and it is the guard for
 * 9.7.1, which will rewrite these schemas wholesale to cut the tools/list cost.
 *
 * Importing the tool modules is only safe because of 9.4.3 — it used to open the
 * bridge port as a side effect, so this file would have raced a live session.
 */

const registry = buildToolRegistry();
const entries = [...registry.entries()];

describe("tool registry", () => {
  it("registers the tool count the docs and coverage report claim", () => {
    expect(registry.size).toBe(163);
    expect(toolCategories).toHaveLength(23);
  });

  it("has no name collisions between categories", () => {
    // buildToolRegistry lets a later category overwrite an earlier one silently,
    // so the flattened size must equal the sum of the parts.
    const declared = toolCategories.reduce(
      (n, category) => n + Object.values(category).filter((t) => t && typeof t === "object" && "handler" in t).length,
      0
    );
    expect(registry.size).toBe(declared);
  });

  it.each(entries)("%s is a well-formed definition", (name, tool: ToolDefinition) => {
    expect(typeof tool.handler).toBe("function");
    expect(tool.description?.trim()).toBeTruthy();
    // The name is the map key; a definition disagreeing with its key means one of
    // the two is a copy-paste slip, and the client only ever sees the key.
    if (tool.name) expect(tool.name).toBe(name);
  });

  it.each(entries)("%s declares a usable input schema", (_name, tool: ToolDefinition) => {
    if (!tool.inputSchema) return; // index.ts substitutes an empty object schema
    expect(tool.inputSchema.type).toBe("object");

    const properties = tool.inputSchema.properties ?? {};
    for (const required of tool.inputSchema.required ?? []) {
      // A required name that is not among the properties is invisible to the
      // client's own validation and only fails once it reaches Godot.
      expect(Object.keys(properties)).toContain(required);
    }
  });

  it.each(entries)("%s documents every parameter", (_name, tool: ToolDefinition) => {
    for (const [param, schema] of Object.entries(tool.inputSchema?.properties ?? {})) {
      const described = (schema as { description?: string }).description?.trim();
      expect(described, `parameter "${param}" has no description`).toBeTruthy();
    }
  });

  it("uses snake_case tool names throughout", () => {
    const odd = [...registry.keys()].filter((n) => !/^[a-z][a-z0-9_]*$/.test(n));
    expect(odd).toEqual([]);
  });

  it("declares version bounds only in a parsable form", () => {
    for (const [name, tool] of entries) {
      for (const bound of [tool.minGodotVersion, tool.maxGodotVersion]) {
        if (bound === undefined) continue;
        expect(bound, `${name} has an unparsable version bound`).toMatch(/^\d+\.\d+(\.\d+)?$/);
      }
    }
  });
});
