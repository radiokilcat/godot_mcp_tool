#!/usr/bin/env node
/**
 * GDScript syntax gate.
 *
 *   node e2e/check-syntax.mjs [--godot 4.4.1] [--all] [--keep-work]
 *
 * A parse error in any one plugin file makes plugin.gd fail to compile, so the
 * whole tool registry disappears and the only symptom the suite reports is
 * "Tool not found: <anything>" — four minutes to discover a typo. Loading
 * plugin.gd with --check-only compiles its whole dependency graph and names the
 * offending file and line in about a second, so run this before the suite.
 *
 * --all also checks every .gd file on its own, which catches a file that
 * nothing in the plugin graph references yet.
 *
 * Exit codes: 0 clean, 1 syntax errors, 2 could not run the check.
 */

import { existsSync, readdirSync, rmSync, mkdirSync } from "node:fs";
import { join, dirname, relative } from "node:path";
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
    all: { type: "boolean", default: false },
    "keep-work": { type: "boolean", default: false },
  },
});

/** Every .gd file under addons/godot_mcp, as res:// paths. */
function pluginScripts() {
  const root = join(repoRoot, "addons", "godot_mcp");
  const found = [];
  const walk = (dir) => {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const full = join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (entry.name.endsWith(".gd")) {
        found.push("res://" + relative(repoRoot, full).split("\\").join("/"));
      }
    }
  };
  walk(root);
  return found.sort();
}

/**
 * Parse errors Godot printed, as {file, line, message}. The message comes on
 * one line and its location on the next:
 *   SCRIPT ERROR: Parse Error: Identifier "foo" not declared in the current scope.
 *      at: GDScript::reload (res://addons/godot_mcp/tools/audio_tools.gd:311)
 */
function parseErrors(output) {
  const errors = [];
  let pending = null;
  for (const raw of output.split("\n")) {
    const line = raw.trim();
    const match = line.match(/^SCRIPT ERROR: (?:Parse|Compile) Error: (.*)$/);
    if (match) {
      if (pending) errors.push({ file: "", line: 0, message: pending });
      pending = match[1];
      continue;
    }
    if (pending && line.startsWith("at: ")) {
      const at = line.match(/\(([^()]*):(\d+)\)\s*$/);
      errors.push({
        file: at ? at[1] : "",
        line: at ? Number(at[2]) : 0,
        message: pending,
      });
      pending = null;
    }
  }
  if (pending) errors.push({ file: "", line: 0, message: pending });
  // "Failed to compile depended scripts" only repeats what the real error above
  // already said, and it points at line 0 of the importer.
  return errors.filter((e) => !e.message.startsWith("Failed to compile depended scripts"));
}

function check(binary, projectDir, scriptPath) {
  const r = spawnSync(
    binary,
    ["--headless", "--path", projectDir, "--check-only", "--script", scriptPath],
    { encoding: "utf8", timeout: 120_000 }
  );
  return parseErrors(`${r.stdout ?? ""}\n${r.stderr ?? ""}`);
}

const projectDir = join(workDir, "syntax-check");
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
  // Registers the addon's class_name declarations; without it every reference
  // to one reads as "not declared in the current scope".
  preImport({
    binary: dist.binary,
    projectDir,
    logPath: join(workDir, "logs", "syntax-check.log"),
    port: 6510,
    log,
  });

  const targets = opts.all ? pluginScripts() : ["res://addons/godot_mcp/plugin.gd"];
  log(`[syntax] checking ${targets.length} script(s) with Godot ${opts.godot}…`);

  const failures = [];
  for (const target of targets) {
    for (const err of check(dist.binary, projectDir, target)) {
      const where = err.file ? `${err.file}:${err.line}` : target;
      const key = `${where} ${err.message}`;
      if (!failures.some((f) => f.key === key)) failures.push({ key, where, message: err.message });
    }
  }

  if (failures.length === 0) {
    log(`[syntax] OK — no parse errors`);
  } else {
    exitCode = 1;
    log(`\n[syntax] ${failures.length} parse error(s):\n`);
    for (const f of failures) log(`  ${f.where}\n    ${f.message}`);
  }
} catch (err) {
  console.error(`[syntax] INFRASTRUCTURE ERROR: ${err?.message ?? err}`);
  exitCode = 2;
} finally {
  if (!opts["keep-work"] && existsSync(projectDir)) {
    rmSync(projectDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 500 });
  }
}

process.exit(exitCode);
