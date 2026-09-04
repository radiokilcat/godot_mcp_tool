import { describe, it, expect } from "vitest";
import {
  parseGodotVersion,
  compareGodotVersions,
  satisfiesVersionRange,
} from "../src/utils/version-utils.js";

describe("parseGodotVersion", () => {
  it("parses the shapes the plugin actually reports at handshake", () => {
    // These are the real strings: get_editor_version returns "4.4.1-stable (official)"
    // and Engine.get_version_info() based paths produce the dotted forms.
    expect(parseGodotVersion("4.4.1.stable")).toEqual({ major: 4, minor: 4, patch: 1 });
    expect(parseGodotVersion("4.4.1-stable (official)")).toEqual({ major: 4, minor: 4, patch: 1 });
    expect(parseGodotVersion("4.3.stable.official")).toEqual({ major: 4, minor: 3, patch: 0 });
    expect(parseGodotVersion("4.7.2")).toEqual({ major: 4, minor: 7, patch: 2 });
  });

  it("defaults a missing patch to 0 rather than NaN", () => {
    expect(parseGodotVersion("4.3")).toEqual({ major: 4, minor: 3, patch: 0 });
  });

  it("returns null for anything without a major.minor", () => {
    expect(parseGodotVersion("")).toBeNull();
    expect(parseGodotVersion("stable")).toBeNull();
    expect(parseGodotVersion("4")).toBeNull();
  });

  it("does not read a two-digit minor as two components", () => {
    expect(parseGodotVersion("4.10.0")).toEqual({ major: 4, minor: 10, patch: 0 });
  });
});

describe("compareGodotVersions", () => {
  const v = (major: number, minor: number, patch: number) => ({ major, minor, patch });

  it("orders by major, then minor, then patch", () => {
    expect(compareGodotVersions(v(4, 4, 1), v(4, 4, 1))).toBe(0);
    expect(compareGodotVersions(v(4, 4, 1), v(4, 4, 0))).toBe(1);
    expect(compareGodotVersions(v(4, 3, 9), v(4, 4, 0))).toBe(-1);
    expect(compareGodotVersions(v(3, 9, 9), v(4, 0, 0))).toBe(-1);
  });

  it("compares minors numerically, not as text", () => {
    // "4.10" < "4.9" under string ordering, which is the bug this guards.
    expect(compareGodotVersions(v(4, 10, 0), v(4, 9, 0))).toBe(1);
  });
});

describe("satisfiesVersionRange", () => {
  it("honours min and max inclusively", () => {
    expect(satisfiesVersionRange("4.4.1", "4.3")).toBe(true);
    expect(satisfiesVersionRange("4.2.0", "4.3")).toBe(false);
    expect(satisfiesVersionRange("4.4.1", undefined, "4.4")).toBe(false);
    expect(satisfiesVersionRange("4.4.0", undefined, "4.4")).toBe(true);
    expect(satisfiesVersionRange("4.3.0", "4.3", "4.3")).toBe(true);
  });

  it("passes when the version is unknown or unparsable", () => {
    // Deliberate: this gates *known* incompatibilities. Before the handshake
    // godotVersion is null, and failing closed would reject every call made
    // while the editor is still connecting.
    expect(satisfiesVersionRange(null, "4.3")).toBe(true);
    expect(satisfiesVersionRange("who knows", "4.3")).toBe(true);
  });

  it("passes when no bounds are given", () => {
    expect(satisfiesVersionRange("4.0.0")).toBe(true);
  });
});
