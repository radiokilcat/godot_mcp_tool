#!/usr/bin/env node
/**
 * Godot MCP E2E runner.
 *
 *   node e2e/run.mjs --godot 4.4.1
 *
 * Flags:
 *   --godot 4.4.1[,4.2.2]  version matrix (sequential)
 *   --headless             run editor headless (rendering-dependent tests auto-skip)
 *   --blocks 1,2,15        run only these blocks
 *   --test P-03            run only one test id (setup/cleanup still run)
 *   --port 6510            WS bridge port (isolated from live 6505 setups)
 *   --keep-work            keep .e2e_work/project for post-mortem
 *   --purge-cache          delete cached Godot distributions and exit
 *
 * Exit codes: 0 all pass/skip, 1 test failures, 2 infrastructure error.
 */

import { mkdirSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import net from "node:net";

import { provision } from "./lib/provision.mjs";
import { generateProject, preImport } from "./lib/project.mjs";
import { launchEditor, killTree, waitForExit } from "./lib/godot-process.mjs";
import { McpTestClient } from "./lib/client.mjs";
import { loadBlocks, runBlocks } from "./lib/executor.mjs";
import { writeReports, computeTotals } from "./lib/report.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, "..");
const workDir = join(repoRoot, ".e2e_work");
const log = (msg) => console.log(msg);

const { values: opts } = parseArgs({
  options: {
    godot: { type: "string", default: "4.4.1" },
    headless: { type: "boolean", default: false },
    blocks: { type: "string" },
    test: { type: "string" },
    port: { type: "string", default: "6510" },
    "keep-work": { type: "boolean", default: false },
    "purge-cache": { type: "boolean", default: false },
  },
});

if (opts["purge-cache"]) {
  rmSync(join(workDir, "cache"), { recursive: true, force: true });
  log("[e2e] cache purged");
  process.exit(0);
}

const port = Number(opts.port);
let worstExit = 0;

for (const version of opts.godot.split(",").map((s) => s.trim())) {
  const code = await runForVersion(version);
  worstExit = Math.max(worstExit, code);
}
process.exit(worstExit);

async function runForVersion(version) {
  log(`\n========== E2E run — Godot ${version} ==========`);
  const startedAt = new Date().toISOString();
  const started = Date.now();
  const projectDir = join(workDir, "project");
  const logsDir = join(workDir, "logs");
  mkdirSync(logsDir, { recursive: true });
  const godotLog = join(logsDir, `godot-${version}.log`);
  const serverLog = join(logsDir, `mcp-server-${version}.log`);

  const run = {
    startedAt,
    requestedGodotVersion: version,
    actualGodotVersion: null,
    pluginVersion: null,
    platform: `${process.platform} ${process.arch}`,
    port,
    headless: opts.headless,
    blocks: [],
    totals: null,
    coverage: null,
    infraError: null,
    durationSec: 0,
  };

  let editor = null;
  let client = null;
  let exitCode = 0;

  const teardown = async () => {
    if (client) await client.callTool("stop_scene", {}, 5_000).catch(() => {});
    if (client) await client.close();
    client = null;
    if (editor && !editor.exited) {
      killTree(editor.pid);
      await waitForExit(editor);
    }
    editor = null;
    if (!opts["keep-work"]) {
      try {
        // Windows releases editor file locks lazily — retry
        rmSync(projectDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 2000 });
      } catch (err) {
        log(`[e2e] warning: could not delete ${projectDir}: ${err.message}`);
      }
    } else {
      log(`[e2e] --keep-work: project left at ${projectDir}`);
    }
  };

  const onSigint = async () => {
    log("\n[e2e] SIGINT — tearing down…");
    await teardown();
    process.exit(130);
  };
  process.once("SIGINT", onSigint);

  try {
    await assertPortFree(port);

    // 1. PROVISION
    const { consoleExe } = await provision({ version, workDir, log });

    // 2. GENERATE
    generateProject({
      repoRoot,
      templatesDir: join(__dirname, "templates"),
      projectDir,
      version,
      log,
    });
    preImport({ consoleExe, projectDir, logPath: godotLog, port, log });

    // 3. LAUNCH
    client = new McpTestClient({ serverDir: join(repoRoot, "server"), port, serverLogPath: serverLog });
    await client.connect();
    log(`[e2e] MCP server up (stdio), bridge port ${port}`);

    editor = launchEditor({ consoleExe, projectDir, logPath: godotLog, headless: opts.headless, port });
    log(`[e2e] editor launched (pid ${editor.pid}), waiting for plugin handshake…`);

    const versionInfo = await client.waitReady(90_000, { isEditorAlive: () => !editor.exited });
    run.actualGodotVersion = versionInfo?.string ?? versionInfo?.version ?? null;
    log(`[e2e] editor ready: ${JSON.stringify(versionInfo)}`);

    // 4. EXECUTE
    const [major, minor] = version.split(".");
    const tokens = { GODOT_VERSION: version, GODOT_MAJOR_MINOR: `${major}.${minor}` };
    const blocks = loadBlocks(join(__dirname, "blocks"), opts.blocks);
    log(`[e2e] running ${blocks.length} block(s)`);

    const { blockResults, usedTools } = await runBlocks({
      client,
      blocks,
      tokens,
      headless: opts.headless,
      log,
      onlyTest: opts.test,
    });
    run.blocks = blockResults;
    run.totals = computeTotals(blockResults);

    const allTools = await client.listToolNames().catch(() => []);
    run.coverage = {
      totalTools: allTools.length,
      exercised: usedTools.filter((t) => allTools.includes(t)).length,
      notCovered: allTools.filter((t) => !usedTools.includes(t)),
    };

    if (run.totals.failed > 0) exitCode = 1;
  } catch (err) {
    run.infraError = err?.stack ?? String(err);
    run.totals ??= computeTotals(run.blocks);
    log(`[e2e] INFRASTRUCTURE ERROR: ${err.message}`);
    exitCode = 2;
  } finally {
    process.removeListener("SIGINT", onSigint);
    await teardown();
  }

  // 5. REPORT
  run.durationSec = Math.round((Date.now() - started) / 1000);
  const { jsonPath, mdPath } = writeReports({ workDir, run });
  const t = run.totals;
  log(`\n[e2e] Godot ${version}: ${t.passed} passed / ${t.failed} failed / ${t.skipped} skipped (${t.total})`);
  log(`[e2e] report: ${mdPath}`);
  log(`[e2e] json:   ${jsonPath}`);
  return exitCode;
}

function assertPortFree(p) {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.once("error", (err) =>
      reject(
        err.code === "EADDRINUSE"
          ? new Error(`Port ${p} is busy — another MCP server or a previous run is still up. Pick --port or stop it.`)
          : err
      )
    );
    srv.listen(p, "127.0.0.1", () => srv.close(() => resolve()));
  });
}
