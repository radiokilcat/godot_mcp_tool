/**
 * Linux specifics for the e2e harness.
 */

import { join } from "node:path";
import { chmodSync } from "node:fs";
import { spawnSync } from "node:child_process";

export const name = "linux";

function target(arch) {
  return arch === "arm64" ? "linux.arm64" : "linux.x86_64";
}

export function archiveName(version, arch = process.arch) {
  return `Godot_v${version}-stable_${target(arch)}.zip`;
}

export function distName(version, arch = process.arch) {
  return `Godot_v${version}-stable_${target(arch)}`;
}

/** One binary, and it already prints to stdout — no console variant needed. */
export function binaryPath(distDir, version, arch = process.arch) {
  return join(distDir, distName(version, arch));
}

export function selfContainedDir(distDir) {
  return distDir;
}

export function extract(zipPath, distDir) {
  // `unzip` rather than a Node zip library: it is present on every distro image
  // and on the GitHub runners, and adding a dependency to the harness would mean
  // the e2e suite could no longer run from a bare checkout.
  const r = spawnSync("unzip", ["-o", "-q", zipPath, "-d", distDir], {
    encoding: "utf8",
    timeout: 300_000,
  });
  if (r.error) throw new Error(`unzip is required to extract Godot: ${r.error.message}`);
  if (r.status !== 0) throw new Error(`unzip failed (exit ${r.status}): ${r.stderr || r.stdout}`);
}

/** The zip does carry the executable bit, but restoring it is cheap insurance. */
export function afterExtract(distDir, version, arch = process.arch) {
  chmodSync(binaryPath(distDir, version, arch), 0o755);
}

/**
 * Spawn the editor as its own process-group leader so killTree can signal the
 * whole group — the POSIX equivalent of `taskkill /T`, and the only way to also
 * take down a game instance the editor started.
 */
export const spawnOptions = { detached: true };

export function killTree(pid) {
  try {
    process.kill(-pid, "SIGKILL");
  } catch (err) {
    // ESRCH: the group is already gone, which is the outcome we wanted.
    if (err.code !== "ESRCH") throw err;
  }
}
