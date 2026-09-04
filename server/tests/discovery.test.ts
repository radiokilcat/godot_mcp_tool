import { describe, it, expect } from "vitest";
import { selectInstance, isAlive, type GodotInstance } from "../src/discovery.js";

/**
 * The selection rules decide which Godot project this session drives. Getting
 * them wrong does not fail loudly — it edits somebody else's scenes — which is
 * why the ambiguous case refuses rather than guessing.
 */

const instance = (over: Partial<GodotInstance> = {}): GodotInstance => ({
  port: 6510,
  token: "t",
  projectPath: "/projects/alpha",
  projectName: "alpha",
  pid: 1,
  godotVersion: "4.4.1",
  pluginVersion: "1.0.0",
  source: "/reg/alpha.json",
  ...over,
});

describe("selectInstance", () => {
  it("explains how to proceed when no editor is running", () => {
    const got = selectInstance([], "/anywhere");
    expect("error" in got && got.error).toMatch(/No running Godot editor/);
    expect("error" in got && got.error).toMatch(/GODOT_MCP_PORT/);
  });

  it("takes the only editor without consulting the working directory", () => {
    // The common case by far, and the cwd is frequently unrelated to the project.
    const only = instance();
    const got = selectInstance([only], "/somewhere/else");
    expect(got).toEqual({ instance: only });
  });

  it("disambiguates several editors by the working directory", () => {
    const alpha = instance({ projectPath: "/projects/alpha", port: 1 });
    const beta = instance({ projectPath: "/projects/beta", port: 2, projectName: "beta" });
    expect(selectInstance([alpha, beta], "/projects/beta")).toEqual({ instance: beta });
    // A directory inside the project counts as the project.
    expect(selectInstance([alpha, beta], "/projects/alpha/scenes")).toEqual({ instance: alpha });
  });

  it("does not match a project by a shared name prefix", () => {
    // "/projects/alpha-old" must not be read as inside "/projects/alpha".
    const alpha = instance({ projectPath: "/projects/alpha" });
    const alphaOld = instance({ projectPath: "/projects/alpha-old", projectName: "alpha-old" });
    const got = selectInstance([alpha, alphaOld], "/projects/alpha-old");
    expect(got).toEqual({ instance: alphaOld });
  });

  it("refuses rather than guessing when several match nothing", () => {
    const alpha = instance({ projectPath: "/projects/alpha", port: 1 });
    const beta = instance({ projectPath: "/projects/beta", port: 2, projectName: "beta" });
    const got = selectInstance([alpha, beta], "/unrelated");
    expect("error" in got).toBe(true);
    if ("error" in got) {
      // The message has to carry enough to act on: which projects, and the way out.
      expect(got.error).toContain("/projects/alpha");
      expect(got.error).toContain("/projects/beta");
      expect(got.error).toContain("GODOT_MCP_PORT");
    }
  });
});

describe("isAlive", () => {
  it("recognises this very process", () => {
    expect(isAlive(process.pid)).toBe(true);
  });

  it("reports a pid that cannot exist as dead", () => {
    expect(isAlive(0x7ffffff0)).toBe(false);
  });

  it("gives an unknown pid the benefit of the doubt", () => {
    // An entry without a usable pid should be tried, not discarded: the connection
    // attempt is the authoritative check, and discarding would strand the session.
    expect(isAlive(0)).toBe(true);
    expect(isAlive(NaN)).toBe(true);
  });
});
