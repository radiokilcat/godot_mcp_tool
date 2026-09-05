#!/usr/bin/env node
/**
 * Does a session survive the editor being restarted? (progress.md 6.2b.2)
 *
 *   node e2e/reconnect.mjs [--godot 4.4.1] [--keep-work]
 *
 * Restarting the editor is an ordinary part of working in Godot, and until now
 * nothing checked what happens to an attached MCP session when it does. The
 * failure mode is silent: the session simply never comes back, and the user sees
 * tools that stopped working for no stated reason.
 *
 * The transport inversion (6.5) made this sharper rather than softer. The
 * reconnect loop was rewritten from scratch on the other side of the wire, and
 * the restarted editor comes back on a *different port with a different token* —
 * so recovery depends on the client rediscovering rather than caching its target.
 * That is the specific claim this exercises.
 *
 * The server is therefore started in discovery mode. Pinning GODOT_MCP_PORT, as
 * the main suite does, would make the test vacuous: a pinned client would keep
 * dialling the old port and could never recover, and a test that pinned the *new*
 * port after the fact would be testing nothing at all.
 *
 * Exit codes: 0 all checks pass, 1 a check failed, 2 could not run.
 */

import { mkdirSync, rmSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

import { provision } from "./lib/provision.mjs";
import { generateProject, preImport } from "./lib/project.mjs";
import { launchEditor, killTree, waitForExit } from "./lib/godot-process.mjs";
import { McpTestClient } from "./lib/client.mjs";
import { waitForInstance, readInstances } from "./lib/discovery.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, "..");
const workDir = join(repoRoot, ".e2e_work");
const projectDir = join(workDir, "reconnect");
const logPath = join(workDir, "logs", "reconnect.log");
const log = (m) => console.log(m);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const { values: opts } = parseArgs({
  options: {
    godot: { type: "string", default: "4.4.1" },
    "keep-work": { type: "boolean", default: false },
  },
});

let passed = 0;
const failures = [];
function check(label, ok, detail = "") {
  if (ok) { passed += 1; log(`  PASS  ${label}`); }
  else { failures.push(label); log(`  FAIL  ${label}${detail ? " — " + detail : ""}`); }
}

let binary = null;
let editor = null;
let client = null;
let exitCode = 0;

function startEditor() {
  return launchEditor({ binary, projectDir, logPath, headless: true, port: 0 });
}

/** Poll a tool call until it succeeds, or give up. */
async function waitForTools(timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let last = null;
  while (Date.now() < deadline) {
    const r = await client.callTool("get_project_info", {}, 10_000);
    if (r.ok) return r;
    last = r;
    await sleep(500);
  }
  return last ?? { ok: false, error: "never attempted" };
}

try {
  mkdirSync(join(workDir, "logs"), { recursive: true });
  ({ binary } = await provision({ version: opts.godot, workDir, log }));
  generateProject({ repoRoot, templatesDir: join(__dirname, "templates"), projectDir, version: opts.godot, log });
  preImport({ binary, projectDir, logPath, port: 0, log });

  log("\n--- first launch ---");
  editor = startEditor();
  const first = await waitForInstance({ projectDir, isEditorAlive: () => !editor.exited, log });
  log(`[reconnect] editor hosting on ${first.port}`);

  client = new McpTestClient({
    serverDir: join(repoRoot, "server"),
    cwd: projectDir, // discovery mode: no port pinned
    serverLogPath: join(workDir, "logs", "reconnect-server.log"),
  });
  await client.connect();
  await client.waitReady(60_000, { isEditorAlive: () => !editor.exited });

  const before = await client.callTool("get_project_info", {});
  check("the session works before the restart", before.ok, before.error);
  check("the server found the editor by working directory alone", before.ok);

  log("\n--- editor killed ---");
  killTree(editor.pid);
  await waitForExit(editor);
  editor = null;

  const whileDown = await client.callTool("get_project_info", {}, 10_000);
  check("a call while the editor is down fails instead of hanging", !whileDown.ok, "it succeeded");
  check("and says the editor is unreachable rather than something opaque",
    !whileDown.ok && /editor|connect|discover|running/i.test(whileDown.error ?? ""),
    whileDown.error);

  log("\n--- editor restarted ---");
  editor = startEditor();
  // Wait for a *different* editor: the killed one's entry is still on disk — a
  // process killed outright never runs _exit_tree, so it never withdraws — and
  // matching it would hand back a dead port with a stale token.
  const second = await waitForInstance({
    projectDir,
    isEditorAlive: () => !editor.exited,
    notPid: first.pid,
    log,
  });
  log(`[reconnect] editor is back on ${second.port}`);
  check("the restarted editor is a different process", second.pid !== first.pid);
  check("and issued a fresh token", second.token !== first.token);

  // The point of the whole file: the same server process, never restarted, must
  // find the new port and the new token by itself.
  const after = await waitForTools(60_000);
  check("the session recovers without restarting the MCP server", after.ok, after.error);
  check("and tools work again", after.ok && Boolean(after.result?.project_name), after.error);

  log("\n--- the stale entry does not linger ---");
  const forThisProject = readInstances().filter((i) => String(i.project_path).includes("reconnect"));
  check("exactly one instance is published for this project", forThisProject.length === 1,
    `found ${forThisProject.length}`);

  log(`\n[reconnect] ${passed} passed / ${failures.length} failed`);
  if (failures.length > 0) exitCode = 1;
} catch (err) {
  console.error(`[reconnect] INFRASTRUCTURE ERROR: ${err?.stack ?? err}`);
  exitCode = 2;
} finally {
  if (client) await client.close().catch(() => {});
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
