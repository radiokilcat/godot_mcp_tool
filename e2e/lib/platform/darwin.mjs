/**
 * macOS specifics for the e2e harness.
 *
 * The awkward one: macOS ships an .app bundle rather than a bare binary, so both
 * the executable and the self-contained marker live inside it. Godot looks for
 * `_sc_` beside the executable, which here means Godot.app/Contents/MacOS/ — not
 * the directory the archive was unpacked into.
 */

import { join } from "node:path";
import { chmodSync } from "node:fs";
import { spawnSync } from "node:child_process";

export const name = "darwin";

/** A single universal build covers both Intel and Apple Silicon. */
export function archiveName(version) {
  return `Godot_v${version}-stable_macos.universal.zip`;
}

export function distName(version) {
  return `Godot_v${version}-stable_macos.universal`;
}

const APP_BINARY = join("Godot.app", "Contents", "MacOS", "Godot");

export function binaryPath(distDir) {
  return join(distDir, APP_BINARY);
}

export function selfContainedDir(distDir) {
  return join(distDir, "Godot.app", "Contents", "MacOS");
}

export function extract(zipPath, distDir) {
  // ditto, not unzip: it preserves the bundle's resource forks and code
  // signature, and an unsigned or mangled Godot.app is refused by Gatekeeper.
  const r = spawnSync("ditto", ["-x", "-k", zipPath, distDir], {
    encoding: "utf8",
    timeout: 300_000,
  });
  if (r.error) throw new Error(`ditto is required to extract Godot: ${r.error.message}`);
  if (r.status !== 0) throw new Error(`ditto failed (exit ${r.status}): ${r.stderr || r.stdout}`);
}

export function afterExtract(distDir) {
  chmodSync(binaryPath(distDir), 0o755);
}

/** Same reasoning as linux: a process group is the POSIX `taskkill /T`. */
export const spawnOptions = { detached: true };

export function killTree(pid) {
  try {
    process.kill(-pid, "SIGKILL");
  } catch (err) {
    if (err.code !== "ESRCH") throw err;
  }
}
