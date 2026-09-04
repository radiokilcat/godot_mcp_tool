#!/usr/bin/env node
/**
 * The property the transport inversion exists to provide (progress.md 6.5).
 *
 *   node e2e/multi-session.mjs [--godot 4.4.1] [--keep-work]
 *
 * The main suite drives one client and would pass just as well against the old
 * direction, so it proves nothing about this: that two MCP sessions can attach to
 * one editor at once, that concurrent calls queue instead of one of them being
 * told "another tool call is already in progress", and that the shared secret
 * actually keeps an unauthenticated client out.
 *
 * Exit codes: 0 all checks pass, 1 a check failed, 2 could not run.
 */

import { mkdirSync, rmSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { createRequire } from "node:module";

import { provision } from "./lib/provision.mjs";
import { generateProject, preImport } from "./lib/project.mjs";
import { launchEditor, killTree, waitForExit } from "./lib/godot-process.mjs";
import { McpTestClient } from "./lib/client.mjs";
import { waitForInstance } from "./lib/discovery.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, "..");
const workDir = join(repoRoot, ".e2e_work");
const projectDir = join(workDir, "multi");
const log = (m) => console.log(m);

const { values: opts } = parseArgs({
  options: {
    godot: { type: "string", default: "4.4.1" },
    "keep-work": { type: "boolean", default: false },
  },
});

let passed = 0;
const failures = [];
function check(label, condition, detail = "") {
  if (condition) {
    passed += 1;
    log(`  PASS  ${label}`);
  } else {
    failures.push(`${label}${detail ? " — " + detail : ""}`);
    log(`  FAIL  ${label}${detail ? " — " + detail : ""}`);
  }
}

let editor = null;
const clients = [];
let exitCode = 0;

try {
  mkdirSync(workDir, { recursive: true });
  const { binary } = await provision({ version: opts.godot, workDir, log });
  generateProject({
    repoRoot,
    templatesDir: join(__dirname, "templates"),
    projectDir,
    version: opts.godot,
    log,
  });
  preImport({ binary, projectDir, logPath: join(workDir, "logs", "multi.log"), port: 0, log });

  editor = launchEditor({
    binary,
    projectDir,
    logPath: join(workDir, "logs", "multi.log"),
    headless: true,
    // 0: let the editor pick, which is the real behaviour outside the suite and
    // the reason two open projects stop colliding.
    port: 0,
  });
  log(`[multi] editor launched (pid ${editor.pid})`);

  const instance = await waitForInstance({
    projectDir,
    isEditorAlive: () => !editor.exited,
    log,
  });
  log(`[multi] editor hosting on port ${instance.port}\n`);

  log("--- the editor picks its own port ---");
  check("port was assigned by the OS, not hard-coded", instance.port > 0 && instance.port !== 6505,
    `got ${instance.port}`);

  log("\n--- two sessions attach to one editor ---");
  for (const name of ["A", "B"]) {
    const c = new McpTestClient({
      serverDir: join(repoRoot, "server"),
      port: instance.port,
      token: instance.token,
      serverLogPath: join(workDir, "logs", `multi-server-${name}.log`),
    });
    await c.connect();
    await c.waitReady(60_000, { isEditorAlive: () => !editor.exited });
    clients.push(c);
    log(`[multi] session ${name} ready`);
  }
  check("both sessions completed the handshake", clients.length === 2);

  const first = await clients[0].callTool("get_project_info", {});
  const second = await clients[1].callTool("get_project_info", {});
  check("session A can call tools", first.ok, first.error);
  check("session B can call tools", second.ok, second.error);
  check("both see the same project",
    first.ok && second.ok && first.result?.project_name === second.result?.project_name);

  log("\n--- concurrent calls queue instead of being rejected ---");
  // Under the old single-flight rule the loser got "Another tool call is already
  // in progress". Both of these are deliberately slow enough to overlap.
  const slow = { code: "func _run():\n\tawait Engine.get_main_loop().process_frame\n\treturn 1\n" };
  const [ra, rb] = await Promise.all([
    clients[0].callTool("execute_script", slow, 30_000),
    clients[1].callTool("execute_script", slow, 30_000),
  ]);
  check("concurrent call from A succeeded", ra.ok, ra.error);
  check("concurrent call from B succeeded", rb.ok, rb.error);
  check("neither was told the editor was busy",
    !/already in progress/i.test(`${ra.error ?? ""}${rb.error ?? ""}`));

  log("\n--- one session leaving does not disturb the other ---");
  await clients[1].close();
  const afterClose = await clients[0].callTool("get_project_info", {});
  check("session A still works after B disconnects", afterClose.ok, afterClose.error);

  log("\n--- the shared secret is enforced ---");
  const req = createRequire(join(repoRoot, "server", "package.json"));
  const { WebSocket } = req("ws");
  const rejection = await new Promise((resolve) => {
    const ws = new WebSocket(`ws://127.0.0.1:${instance.port}/definitely-not-the-token`);
    const done = (v) => { try { ws.terminate(); } catch { /* already gone */ } resolve(v); };
    ws.on("close", (code, reason) => done({ code, reason: reason.toString() }));
    ws.on("error", () => { /* close follows */ });
    setTimeout(() => done({ code: 0, reason: "timed out" }), 10_000);
  });
  check("a wrong token is closed with the auth code", rejection.code === 4001,
    `got code ${rejection.code} (${rejection.reason})`);

  const accepted = await new Promise((resolve) => {
    const ws = new WebSocket(`ws://127.0.0.1:${instance.port}/${instance.token}`);
    const done = (v) => { try { ws.terminate(); } catch { /* already gone */ } resolve(v); };
    ws.on("open", () => done(true));
    ws.on("close", () => done(false));
    ws.on("error", () => done(false));
    setTimeout(() => done(false), 10_000);
  });
  check("the right token is accepted", accepted);

  log(`\n[multi] ${passed} passed / ${failures.length} failed`);
  if (failures.length > 0) exitCode = 1;
} catch (err) {
  console.error(`[multi] INFRASTRUCTURE ERROR: ${err?.stack ?? err}`);
  exitCode = 2;
} finally {
  for (const c of clients) await c.close().catch(() => {});
  if (editor && !editor.exited) {
    killTree(editor.pid);
    await waitForExit(editor);
  }
  if (!opts["keep-work"] && existsSync(projectDir)) {
    try {
      rmSync(projectDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 2000 });
    } catch { /* Windows releases editor locks lazily */ }
  }
}

process.exit(exitCode);
