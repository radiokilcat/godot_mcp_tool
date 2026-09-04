/**
 * Godot process management — spawn the editor with capturable output, kill the
 * tree. Platform differences (process groups vs taskkill) live in ./platform.
 */

import { createWriteStream } from "node:fs";
import { spawn } from "node:child_process";

import { platformFor } from "./platform/index.mjs";

export function launchEditor({ binary, projectDir, logPath, headless, port, platform = platformFor() }) {
  const args = ["--editor", "--path", projectDir];
  if (headless) {
    args.push("--headless");
  } else {
    args.push("--windowed", "--resolution", "1280x720", "--position", "50,50");
  }

  const logStream = createWriteStream(logPath, { flags: "a" });
  logStream.write(`===== editor launch ${new Date().toISOString()} =====\n`);

  const child = spawn(binary, args, {
    env: { ...process.env, GODOT_MCP_PORT: String(port) },
    stdio: ["ignore", "pipe", "pipe"],
    // On POSIX this makes the editor a process-group leader, which is what lets
    // killTree signal it together with anything it spawned.
    ...platform.spawnOptions,
  });

  const state = { pid: child.pid, exited: false, exitCode: null, child, platform };
  child.stdout.on("data", (d) => logStream.write(d));
  child.stderr.on("data", (d) => logStream.write(d));
  child.on("exit", (code) => {
    state.exited = true;
    state.exitCode = code;
    logStream.write(`\n[e2e] editor process exited, code=${code}\n`);
  });
  child.on("error", () => { state.exited = true; });
  return state;
}

/** Kill the editor and anything it started — a game instance from play_scene. */
export function killTree(pid, platform = platformFor()) {
  platform.killTree(pid);
}

/** Wait until the editor actually exits (a kill returns before handles are released). */
export async function waitForExit(state, timeoutMs = 15_000) {
  const deadline = Date.now() + timeoutMs;
  while (!state.exited && Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, 500));
  }
  return state.exited;
}
