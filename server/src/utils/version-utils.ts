/**
 * Godot Engine Version Utilities
 * Parses/compares Godot version strings (e.g. "4.4.1.stable") so tool
 * definitions can declare a minimum engine version and get a clear error
 * instead of a confusing failure inside Godot.
 */

export interface GodotVersion {
  major: number;
  minor: number;
  patch: number;
}

/**
 * Parse a Godot version string like "4.4.1.stable", "4.3.stable.official",
 * or a bare "4.3" into its numeric major/minor/patch parts.
 */
export function parseGodotVersion(version: string): GodotVersion | null {
  const match = version.match(/^(\d+)\.(\d+)(?:\.(\d+))?/);
  if (!match) return null;
  return {
    major: parseInt(match[1], 10),
    minor: parseInt(match[2], 10),
    patch: match[3] ? parseInt(match[3], 10) : 0,
  };
}

/** -1 if a < b, 0 if equal, 1 if a > b */
export function compareGodotVersions(a: GodotVersion, b: GodotVersion): number {
  if (a.major !== b.major) return a.major > b.major ? 1 : -1;
  if (a.minor !== b.minor) return a.minor > b.minor ? 1 : -1;
  if (a.patch !== b.patch) return a.patch > b.patch ? 1 : -1;
  return 0;
}

/**
 * True if `actual` satisfies `min` (>=) and `max` (<=), when given. Unparsable
 * or missing versions are treated as satisfying the check — this gates known
 * incompatibilities, not an unknown or not-yet-connected state.
 */
export function satisfiesVersionRange(
  actual: string | null,
  min?: string,
  max?: string
): boolean {
  if (!actual) return true;
  const actualVer = parseGodotVersion(actual);
  if (!actualVer) return true;

  if (min) {
    const minVer = parseGodotVersion(min);
    if (minVer && compareGodotVersions(actualVer, minVer) < 0) return false;
  }
  if (max) {
    const maxVer = parseGodotVersion(max);
    if (maxVer && compareGodotVersions(actualVer, maxVer) > 0) return false;
  }
  return true;
}
