#!/usr/bin/env node
/**
 * GDScript unit tests (progress.md 6.1.3).
 *
 *   node e2e/unit.mjs [--godot 4.4.1] [--keep-work]
 *
 * The plugin's coercion rules — vector/colour parsing, _as_bool, _value_to_json —
 * are pure and have no editor dependency, but they are GDScript, so vitest cannot
 * reach them. This runs them in a headless engine against a generated project:
 * no editor window, no MCP server, no WebSocket bridge, a couple of seconds.
 *
 * The e2e suite covers the same rules only indirectly, through whichever tool
 * happens to call them, and takes four minutes to say so.
 *
 * Exit codes: 0 all pass, 1 test failures, 2 could not run.
 */

import { existsSync, cpSync, mkdirSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";
import { spawnSync } from "node:child_process";

import { provision } from "./lib/provision.mjs";
import { generateProject, preImport } from "./lib/project.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(__dirname, "..");
const workDir = join(repoRoot, ".e2e_work");
const log = (msg) => console.log(msg);

const { values: opts } = parseArgs({
  options: {
    godot: { type: "string", default: "4.4.1" },
    "keep-work": { type: "boolean", default: false },
  },
});

const projectDir = join(workDir, "unit");
let exitCode = 0;

try {
  mkdirSync(workDir, { recursive: true });
  const dist = await provision({ version: opts.godot, workDir, log });
  generateProject({
    repoRoot,
    templatesDir: join(__dirname, "templates"),
    projectDir,
    version: opts.godot,
    log,
  });

  // The tests live inside the project so the addon's class_name declarations
  // resolve the same way they do at runtime.
  cpSync(join(__dirname, "gdscript"), join(projectDir, "gdscript_tests"), { recursive: true });

  // Registers those class_name declarations; without it every reference to
  // GodotMCPTypeUtils reads as "not declared in the current scope".
  preImport({
    binary: dist.binary,
    projectDir,
    logPath: join(workDir, "logs", "unit.log"),
    port: 6510,
    log,
  });

  log(`[gdunit] running GDScript unit tests with Godot ${opts.godot}…`);
  const r = spawnSync(
    dist.binary,
    ["--headless", "--path", projectDir, "--script", "res://gdscript_tests/run_unit_tests.gd"],
    { encoding: "utf8", timeout: 120_000 }
  );

  const output = `${r.stdout ?? ""}${r.stderr ?? ""}`;
  // Warnings count, not just errors. The leak this suite exists to catch —
  // "ObjectDB instances leaked at exit", i.e. an object still referenced by a
  // suspended coroutine — is reported by Godot as a WARNING, and an earlier
  // version matching only SCRIPT ERROR swallowed it, leaving nothing on screen but
  // its orphaned "at: cleanup (core/object/object.cpp)" location line. A clean run
  // prints neither, so matching both costs nothing.
  const isEngineDiagnostic = (line) => /\b(ERROR|WARNING):/.test(line);
  for (const line of output.split("\n")) {
    const text = line.trim();
    if (text.includes("[gdunit]") || isEngineDiagnostic(text) || text.startsWith("at: ")) {
      log(`  ${text}`);
    }
  }

  if (r.error) throw new Error(`could not launch Godot: ${r.error.message}`);
  if (!output.includes("[gdunit]")) {
    // The script never reached its summary — a parse error, or Godot refused to
    // run it at all. Do not report that as a passing suite.
    throw new Error(`the test script produced no result. Full output:\n${output}`);
  }

  // Unlike the e2e suite, nothing here feeds the engine bad input on purpose, so
  // any pushed error is a defect even when every assertion passed. This is how
  // `bool(null)` in _as_bool was found: the checks were green and the engine was
  // printing "Nonexistent 'bool' constructor" on every call.
  const engineErrors = output.split("\n").filter(isEngineDiagnostic);
  if (engineErrors.length > 0) {
    log(`[gdunit] ${engineErrors.length} engine diagnostic(s) during a run that asked for none`);
    exitCode = 1;
  }

  if (r.status !== 0) exitCode = 1;
} catch (err) {
  console.error(`[gdunit] INFRASTRUCTURE ERROR: ${err?.message ?? err}`);
  exitCode = 2;
} finally {
  if (!opts["keep-work"] && existsSync(projectDir)) {
    rmSync(projectDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 500 });
  }
}

process.exit(exitCode);
