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
  isPrivate: false,
  source: "/reg/alpha.json",
  ...over,
});

describe("selectInstance", () => {
  it("explains how to proceed when no editor is running", () => {
    const got = selectInstance([], "/anywhere");
    expect("error" in got && got.error).toMatch(/No running Godot editor/);
    expect("error" in got && got.error).toMatch(/GODOT_MCP_PORT/);
  });

  it("never selects an editor whose port was pinned", () => {
    // A harness editor is the only one running for minutes at a time, so without
    // this every idle session on the machine attaches to a generated project that
    // is deleted at the end of the run — and its calls land inside somebody's test.
    const harness = instance({ isPrivate: true });
    const got = selectInstance([harness], "/projects/alpha");
    expect("error" in got && got.error).toMatch(/pinned/);
    expect("error" in got && got.error).toMatch(/GODOT_MCP_PORT/);
  });

  it("picks the ordinary editor when a harness editor is running beside it", () => {
    const harness = instance({ isPrivate: true, port: 6510, projectPath: "/tmp/e2e" });
    const mine = instance({ port: 7000, projectPath: "/projects/alpha" });
    // The cwd deliberately matches neither, to prove the harness entry is dropped
    // before the count is taken rather than merely losing the cwd comparison.
    expect(selectInstance([harness, mine], "/somewhere/else")).toEqual({ instance: mine });
  });

  it("does not report a harness editor as an ambiguous choice", () => {
    const harness = instance({ isPrivate: true, projectPath: "/tmp/e2e", projectName: "e2e" });
    const alpha = instance({ projectPath: "/projects/alpha", port: 1 });
    const beta = instance({ projectPath: "/projects/beta", port: 2, projectName: "beta" });
    const got = selectInstance([harness, alpha, beta], "/somewhere/else");
    expect("error" in got && got.error).toMatch(/2 Godot editors are running/);
    expect("error" in got && got.error).not.toMatch(/e2e/);
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
