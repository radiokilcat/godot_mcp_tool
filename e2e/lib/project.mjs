/**
 * Project — generate the disposable test project the editor opens.
 */

import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync, appendFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { spawnSync } from "node:child_process";

export function generateProject({ repoRoot, templatesDir, projectDir, version, log }) {
  rmSync(projectDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 1000 });
  mkdirSync(projectDir, { recursive: true });

  const [major, minor] = version.split(".");
  const tpl = readFileSync(join(templatesDir, "project.godot.tpl"), "utf8");
  // features tag must match the target minor — a mismatch triggers a blocking dialog on open
  writeFileSync(join(projectDir, "project.godot"), tpl.replaceAll("{FEATURES}", `${major}.${minor}`));
  cpSync(join(templatesDir, "icon.svg"), join(projectDir, "icon.svg"));

  cpSync(join(repoRoot, "addons", "godot_mcp"), join(projectDir, "addons", "godot_mcp"), {
    recursive: true,
  });

  mkdirSync(join(projectDir, "tests"), { recursive: true });
  cpSync(join(templatesDir, "test_example.gd"), join(projectDir, "tests", "test_example.gd"));

  log(`[project] generated at ${projectDir} (features ${major}.${minor})`);
}

/** Headless import pass so the first editor open is clean (no import churn/dialogs). */
export function preImport({ binary, projectDir, logPath, port, log }) {
  log(`[project] pre-import pass (headless)…`);
  // The appendFileSync below is the first thing to touch the log directory, and
  // on a fresh checkout it does not exist — `.e2e_work` is gitignored entirely.
  // Only run.mjs happened to create it, so this failed for check-syntax and
  // unit.mjs on every clean machine while passing on any developer's, where the
  // directory was left over from an earlier run. Create it where the file is
  // written rather than in each caller, which is what let the callers diverge.
  mkdirSync(dirname(logPath), { recursive: true });
  const r = spawnSync(binary, ["--headless", "--import", "--path", projectDir], {
    encoding: "utf8",
    timeout: 180_000,
    // The plugin loads during import too, so it needs the same port as the main pass —
    // on the default it would attach to whatever live setup owns 6505 and, since the
    // server replaces its existing client, knock a developer's editor off mid-session.
    env: { ...process.env, GODOT_MCP_PORT: String(port) },
  });
  appendFileSync(logPath, `\n===== pre-import =====\n${r.stdout ?? ""}${r.stderr ?? ""}\n`);
  if (r.error) throw new Error(`pre-import failed to launch: ${r.error.message}`);
  log(`[project] pre-import done (exit ${r.status})`);
}
