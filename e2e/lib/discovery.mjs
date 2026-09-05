/**
 * Finding the editor the harness just launched (progress.md 6.5.9).
 *
 * With the transport inverted the editor owns the port, so the harness can no
 * longer decide it in advance and hand it to both ends — it has to wait for the
 * plugin to publish, then read the token out of the registry.
 *
 * The match is on the project path, not "the newest entry": a developer's own
 * editor may well be running on this machine, and driving that instead of the
 * disposable test project would edit their real scenes.
 */

import { readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";

export function instancesDir() {
  return join(homedir(), ".godot-mcp", "instances");
}

/** Every published instance, ignoring anything unreadable or half-written. */
export function readInstances(dir = instancesDir()) {
  let names;
  try {
    names = readdirSync(dir).filter((n) => n.endsWith(".json"));
  } catch {
    return [];
  }
  const out = [];
  for (const name of names) {
    try {
      out.push({ ...JSON.parse(readFileSync(join(dir, name), "utf8")), _file: join(dir, name) });
    } catch { /* being written right now, or hand-edited */ }
  }
  return out;
}

const samePath = (a, b) => resolve(String(a ?? "")) === resolve(String(b ?? ""));

/** An editor killed outright never runs _exit_tree, so its entry outlives it. */
function pidIsAlive(pid) {
  const n = Number(pid);
  if (!Number.isInteger(n) || n <= 0) return true;
  try {
    process.kill(n, 0);
    return true;
  } catch (err) {
    return err.code === "EPERM";
  }
}

/**
 * Wait for the plugin in `projectDir` to advertise itself.
 *
 * `notPid` waits for a *different* editor than the one given — needed after a
 * restart, because the previous editor's entry is still on disk until the new one
 * overwrites it, and returning that would hand back a dead port and a stale token.
 *
 * @returns {Promise<{port:number, token:string, pid:number, file:string}>}
 */
export async function waitForInstance({ projectDir, timeoutMs = 90_000, isEditorAlive, notPid, log }) {
  const deadline = Date.now() + timeoutMs;
  let announced = false;
  while (Date.now() < deadline) {
    if (isEditorAlive && !isEditorAlive()) {
      throw new Error("The editor exited before it published a bridge instance.");
    }
    const match = readInstances().find(
      (i) =>
        samePath(i.project_path, projectDir) &&
        pidIsAlive(i.pid) &&
        (notPid === undefined || Number(i.pid) !== Number(notPid))
    );
    if (match?.port && match?.token) {
      return {
        port: Number(match.port),
        token: String(match.token),
        pid: Number(match.pid),
        file: match._file,
      };
    }
    if (!announced && log) {
      log(`[e2e] waiting for the editor to publish its bridge in ${instancesDir()}…`);
      announced = true;
    }
    await new Promise((r) => setTimeout(r, 250));
  }
  throw new Error(
    `The editor did not publish a bridge instance for ${projectDir} within ${timeoutMs}ms. ` +
    `Looked in ${instancesDir()}.`
  );
}
