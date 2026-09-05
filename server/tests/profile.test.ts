import { describe, it, expect } from "vitest";
import {
  selectedCategories,
  buildToolRegistry,
  categoriesByName,
  CORE_CATEGORIES,
  type CategoryName,
} from "../src/registry.js";

/**
 * Profile selection (progress.md 9.7.1). `tools/list` is loaded into the model's
 * context before the user asks anything, so a client that never touches particles
 * or tilemaps should not be paying for their schemas every session.
 */

const allNames = Object.keys(categoriesByName) as CategoryName[];

describe("selectedCategories", () => {
  it("registers everything by default", () => {
    expect(selectedCategories({}).names).toEqual(allNames);
  });

  it("honours the core profile, case-insensitively", () => {
    expect(selectedCategories({ GODOT_MCP_PROFILE: "core" }).names).toEqual(CORE_CATEGORIES);
    expect(selectedCategories({ GODOT_MCP_PROFILE: " CORE " }).names).toEqual(CORE_CATEGORIES);
  });

  it("treats an unrecognised profile as full rather than empty", () => {
    expect(selectedCategories({ GODOT_MCP_PROFILE: "lite" }).names).toEqual(allNames);
  });

  it("takes an explicit list, which beats the profile", () => {
    const got = selectedCategories({
      GODOT_MCP_CATEGORIES: "scene, node ,script",
      GODOT_MCP_PROFILE: "core",
    });
    expect(got.names).toEqual(["scene", "node", "script"]);
  });

  it("reports unknown names instead of silently dropping them", () => {
    const got = selectedCategories({ GODOT_MCP_CATEGORIES: "scene,nodes,scrpt" });
    expect(got.names).toEqual(["scene"]);
    expect(got.unknown).toEqual(["nodes", "scrpt"]);
  });

  it("falls back to everything when the whole list is typos", () => {
    // Registering nothing would present as "the server has no tools", which reads
    // as a broken build rather than as a bad environment variable.
    const got = selectedCategories({ GODOT_MCP_CATEGORIES: "scnee,nodes" });
    expect(got.names).toEqual(allNames);
    expect(got.unknown).toEqual(["scnee", "nodes"]);
  });
});

describe("buildToolRegistry with a selection", () => {
  it("registers only the categories asked for", () => {
    const registry = buildToolRegistry(["project"]);
    expect(registry.size).toBe(Object.keys(categoriesByName.project).length);
    expect(registry.has("get_project_info")).toBe(true);
    expect(registry.has("add_mesh")).toBe(false);
  });

  it("core is a strict subset of full and keeps the everyday tools", () => {
    const full = buildToolRegistry();
    const core = buildToolRegistry(CORE_CATEGORIES);
    expect(core.size).toBeLessThan(full.size);
    for (const name of core.keys()) expect(full.has(name)).toBe(true);
    // The tools any session reaches for first must survive the cut.
    for (const essential of ["get_scene_tree", "add_node", "set_node_property", "execute_script", "save_scene"]) {
      expect(core.has(essential), `core dropped ${essential}`).toBe(true);
    }
  });

  it("core is materially cheaper, which is the entire point", () => {
    const size = (names?: CategoryName[]) => {
      let chars = 0;
      for (const [name, tool] of buildToolRegistry(names)) {
        chars += JSON.stringify({
          name,
          description: tool.description,
          inputSchema: tool.inputSchema ?? {},
        }).length;
      }
      return chars;
    };
    // Measured at ~37% when this landed. The threshold is deliberately loose: it
    // guards against the saving quietly evaporating, not against it changing.
    expect(size(CORE_CATEGORIES)).toBeLessThan(size() * 0.75);
  });
});
