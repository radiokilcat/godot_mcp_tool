/**
 * Report — JSON (machine) + Markdown (human) with per-block tables,
 * failure details, and tool-coverage diff.
 */

import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

export function writeReports({ workDir, run }) {
  const reportsDir = join(workDir, "reports");
  mkdirSync(reportsDir, { recursive: true });
  const stamp = run.startedAt.replace(/[:.]/g, "-").slice(0, 19);
  const jsonPath = join(reportsDir, `e2e-${stamp}.json`);
  const mdPath = join(reportsDir, `e2e-${stamp}.md`);

  writeFileSync(jsonPath, JSON.stringify(run, null, 2));
  writeFileSync(mdPath, renderMarkdown(run));
  return { jsonPath, mdPath };
}

export function computeTotals(blockResults) {
  const totals = { passed: 0, failed: 0, skipped: 0, total: 0 };
  for (const b of blockResults) {
    for (const t of b.tests) {
      totals.total++;
      if (t.status === "pass") totals.passed++;
      else if (t.status === "fail") totals.failed++;
      else totals.skipped++;
    }
  }
  return totals;
}

function renderMarkdown(run) {
  const t = run.totals;
  const lines = [];
  lines.push(`# E2E Report — ${run.startedAt}`);
  lines.push("");
  lines.push(
    `Godot ${run.actualGodotVersion ?? run.requestedGodotVersion} | plugin ${run.pluginVersion ?? "?"} | ${run.platform} | duration ${run.durationSec}s`
  );
  lines.push("");
  lines.push(`**Result: ${t.passed} passed / ${t.failed} failed / ${t.skipped} skipped (${t.total})**`);
  lines.push("");
  lines.push(`| block | passed | failed | skipped | note |`);
  lines.push(`|---|---|---|---|---|`);
  for (const b of run.blocks) {
    const bp = b.tests.filter((x) => x.status === "pass").length;
    const bf = b.tests.filter((x) => x.status === "fail").length;
    const bs = b.tests.filter((x) => x.status === "skip").length;
    lines.push(`| ${b.block} ${b.name} | ${bp} | ${bf} | ${bs} | ${b.setupError ? `setup failed: ${b.setupError}` : ""} |`);
  }
  lines.push("");

  const failures = run.blocks.flatMap((b) => b.tests.filter((x) => x.status === "fail").map((x) => ({ b, x })));
  if (failures.length > 0) {
    lines.push(`## Failures`);
    for (const { b, x } of failures) {
      lines.push("");
      lines.push(`### ${x.id} ${x.tool} — FAILED (${x.ms} ms) [block ${b.block} ${b.name}]`);
      if (x.error) lines.push(`- error: ${x.error}`);
      for (const f of x.failures ?? []) lines.push(`- assert: ${f}`);
    }
    lines.push("");
  }

  if (run.coverage) {
    lines.push(`## Tool coverage`);
    lines.push("");
    lines.push(`Exercised ${run.coverage.exercised} of ${run.coverage.totalTools} registered tools.`);
    if (run.coverage.notCovered.length > 0) {
      lines.push("");
      lines.push(`<details><summary>Not exercised (${run.coverage.notCovered.length})</summary>`);
      lines.push("");
      for (const name of run.coverage.notCovered) lines.push(`- ${name}`);
      lines.push("");
      lines.push(`</details>`);
    }
    lines.push("");
  }

  if (run.infraError) {
    lines.push(`## Infrastructure error`);
    lines.push("");
    lines.push("```");
    lines.push(run.infraError);
    lines.push("```");
  }

  return lines.join("\n") + "\n";
}
