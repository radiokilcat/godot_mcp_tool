/**
 * Godot process management — spawn the console exe (capturable stdout), kill the tree.
 */

import { createWriteStream } from "node:fs";
import { spawn, spawnSync } from "node:child_process";

export function launchEditor({ consoleExe, projectDir, logPath, headless, port }) {
  const args = ["--editor", "--path", projectDir];
  if (headless) {
    args.push("--headless");
  } else {
    args.push("--windowed", "--resolution", "1280x720", "--position", "50,50");
  }

  const logStream = createWriteStream(logPath, { flags: "a" });
  logStream.write(`===== editor launch ${new Date().toISOString()} =====\n`);

  const child = spawn(consoleExe, args, {
    env: { ...process.env, GODOT_MCP_PORT: String(port) },
    stdio: ["ignore", "pipe", "pipe"],
  });

  const state = { pid: child.pid, exited: false, exitCode: null, child };
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

/** /T kills spawned children too (running game instances from play_scene). */
export function killTree(pid) {
  spawnSync("taskkill", ["/PID", String(pid), "/T", "/F"], { encoding: "utf8" });
}

/** Wait until the spawned editor actually exits (taskkill returns before handles are released). */
export async function waitForExit(state, timeoutMs = 15_000) {
  const deadline = Date.now() + timeoutMs;
  while (!state.exited && Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, 500));
  }
  return state.exited;
}
