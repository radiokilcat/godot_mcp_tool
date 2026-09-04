/**
 * Windows specifics for the e2e harness.
 *
 * The one that is not obvious: Godot ships two executables on Windows, and only
 * `_console.exe` writes to stdout. The plain .exe detaches from the console, so
 * the harness would capture nothing — no editor log, and no way to see a parse
 * error. Every other platform has a single binary that already prints.
 */

import { join } from "node:path";
import { spawnSync } from "node:child_process";

export const name = "win32";

export function archiveName(version, arch = process.arch) {
  const target = arch === "arm64" ? "windows_arm64" : "win64";
  return `Godot_v${version}-stable_${target}.exe.zip`;
}

/** Directory name the archive is cached under (the archive name minus .zip). */
export function distName(version, arch = process.arch) {
  return archiveName(version, arch).replace(/\.exe\.zip$/, "");
}

export function binaryPath(distDir, version, arch = process.arch) {
  return join(distDir, `${distName(version, arch)}_console.exe`);
}

/** Godot looks for the self-contained marker beside the executable. */
export function selfContainedDir(distDir) {
  return distDir;
}

export function extract(zipPath, distDir) {
  const r = spawnSync(
    "powershell.exe",
    [
      "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command",
      `Expand-Archive -LiteralPath "${zipPath}" -DestinationPath "${distDir}" -Force`,
    ],
    { encoding: "utf8", timeout: 300_000 }
  );
  if (r.status !== 0) {
    throw new Error(`Expand-Archive failed (exit ${r.status}): ${r.stderr || r.stdout}`);
  }
}

/** Nothing to do: the zip carries no permission bits Windows cares about. */
export function afterExtract() {}

/** Windows has no process groups to spawn into; the tree is killed by PID. */
export const spawnOptions = {};

/** /T takes spawned children too — a running game started by play_scene. */
export function killTree(pid) {
  spawnSync("taskkill", ["/PID", String(pid), "/T", "/F"], { encoding: "utf8" });
}
