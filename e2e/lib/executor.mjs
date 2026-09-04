/**
 * Executor — runs test blocks strictly sequentially (the plugin rejects
 * concurrent calls) with $VAR substitution, disconnect recovery, and
 * failure isolation per the test-plan conventions.
 */

import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { evaluateAsserts, evaluateFileAsserts, resolveField } from "./asserts.mjs";

export function loadBlocks(blocksDir, blockFilter) {
  const files = readdirSync(blocksDir).filter((f) => f.endsWith(".json")).sort();
  let blocks = files.map((f) => JSON.parse(readFileSync(join(blocksDir, f), "utf8")));
  if (blockFilter) {
    const wanted = new Set(blockFilter.split(",").map((s) => Number(s.trim())));
    blocks = blocks.filter((b) => wanted.has(b.block));
  }
  return blocks;
}

/** Deep-substitute $VARS and {TOKENS} in args/assert values. */
export function substitute(value, ctx) {
  if (typeof value === "string") {
    const exact = /^\$([A-Za-z0-9_]+)$/.exec(value);
    if (exact && exact[1] in ctx.vars) return ctx.vars[exact[1]]; // preserves type
    return value
      .replace(/\$([A-Za-z0-9_]+)/g, (m, name) => (name in ctx.vars ? String(ctx.vars[name]) : m))
      .replace(/\{([A-Z0-9_]+)\}/g, (m, name) => (name in ctx.tokens ? String(ctx.tokens[name]) : m));
  }
  if (Array.isArray(value)) return value.map((v) => substitute(v, ctx));
  if (value !== null && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, substitute(v, ctx)]));
  }
  return value;
}

export async function runBlocks({ client, blocks, tokens, headless, log, onlyTest, projectDir }) {
  const ctx = { vars: {}, tokens };
  const usedTools = new Set();
  const blockResults = [];

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

  const call = async (tool, args, timeoutMs, delayMs) => {
    if (delayMs) await sleep(delayMs);
    usedTools.add(tool);
    let r = await client.callTool(tool, substitute(args ?? {}, ctx), timeoutMs ?? 30_000);
    // reload_scripts-style tools briefly drop the WS connection: re-gate, retry once
    if (!r.ok && /not connected|disconnected/i.test(r.error)) {
      log(`    [recover] connection dropped, waiting for reconnect…`);
      await client.waitReady(30_000).catch(() => {});
      r = await client.callTool(tool, substitute(args ?? {}, ctx), timeoutMs ?? 30_000);
    }
    return r;
  };

  for (const block of blocks) {
    log(`\nBLOCK ${block.block} — ${block.name}`);
    const bres = { block: block.block, name: block.name, setupError: null, tests: [] };
    blockResults.push(bres);

    let skipReason = null;
    if (block.requires?.rendering && headless) {
      skipReason = "block requires rendering (headless run)";
    } else if (block.requires?.minGodot && cmpVersion(tokens.GODOT_VERSION, block.requires.minGodot) < 0) {
      skipReason = `block requires Godot >= ${block.requires.minGodot}`;
    }

    for (const step of skipReason ? [] : block.setup ?? []) {
      const r = await call(step.tool, step.args, step.timeoutMs, step.delayMs);
      if (!r.ok && !step.ignoreError) {
        bres.setupError = `${step.tool}: ${r.error}`;
        skipReason = "block setup failed";
        log(`  SETUP FAILED: ${bres.setupError}`);
        break;
      }
    }

    for (const t of block.tests) {
      if (onlyTest && t.id !== onlyTest) continue;

      const rec = { id: t.id, tool: t.tool, status: "pass", ms: 0, error: null, failures: [] };
      bres.tests.push(rec);

      if (skipReason) {
        rec.status = "skip";
        rec.error = skipReason;
      } else if (t.requires?.rendering && headless) {
        rec.status = "skip";
        rec.error = "requires rendering (headless run)";
      } else if (t.requires?.minGodot && cmpVersion(tokens.GODOT_VERSION, t.requires.minGodot) < 0) {
        rec.status = "skip";
        rec.error = `requires Godot >= ${t.requires.minGodot}`;
      } else {
        const r = await call(t.tool, t.args, t.timeoutMs, t.delayMs);
        rec.ms = r.ms;

        if (t.allowError && !r.ok) {
          // "success OR structured error" tests from the plan: a graceful error passes
          rec.note = `passed via allowError: ${r.error}`;
        } else if (t.expectError) {
          if (r.ok) {
            rec.status = "fail";
            rec.error = `expected an error, but the call succeeded: ${JSON.stringify(r.result).slice(0, 200)}`;
          } else if (t.errorContains && !r.error.includes(substitute(t.errorContains, ctx))) {
            rec.status = "fail";
            rec.error = `error text mismatch — expected to contain "${t.errorContains}", got: ${r.error}`;
          }
        } else if (!r.ok) {
          rec.status = "fail";
          rec.error = r.error;
        } else {
          rec.failures = evaluateAsserts(substitute(t.asserts ?? [], ctx), r.result);
          if (rec.failures.length > 0) rec.status = "fail";

          if (rec.status === "pass" && t.verify) {
            const v = await call(t.verify.tool, t.verify.args, t.verify.timeoutMs);
            if (!v.ok) {
              rec.status = "fail";
              rec.error = `verify call failed: ${v.error}`;
            } else {
              const vf = evaluateAsserts(substitute(t.verify.asserts ?? [], ctx), v.result);
              if (vf.length > 0) {
                rec.status = "fail";
                rec.failures.push(...vf.map((f) => `verify: ${f}`));
              }
            }
          }

          if (rec.status === "pass" && t.save) {
            for (const [name, path] of Object.entries(t.save)) {
              ctx.vars[name] = resolveField(r.result, path);
            }
          }
        }

        // Effect-level check, deliberately outside the branches above: it applies
        // equally to a call that succeeded and to one that was expected to fail,
        // because "the call errored AND left nothing behind" is the interesting
        // half of a negative test.
        if (rec.status === "pass" && t.expectFiles) {
          if (!projectDir) {
            rec.status = "fail";
            rec.error = "expectFiles used but the runner passed no projectDir";
          } else {
            const ff = evaluateFileAsserts(substitute(t.expectFiles, ctx), projectDir);
            if (ff.length > 0) {
              rec.status = "fail";
              rec.failures.push(...ff);
            }
          }
        }
      }

      const suffix = rec.status === "pass" ? `(${rec.ms} ms)` : rec.error ?? rec.failures[0] ?? "";
      log(`  ${t.id} ${t.tool} … ${rec.status.toUpperCase()} ${suffix}`);
    }

    for (const step of skipReason === "block setup failed" || !skipReason ? block.cleanup ?? [] : []) {
      const r = await call(step.tool, step.args, step.timeoutMs, step.delayMs);
      if (!r.ok) log(`  [cleanup] ${step.tool} failed (non-fatal): ${r.error}`);
    }
  }

  return { blockResults, usedTools: [...usedTools] };
}

function cmpVersion(a, b) {
  const pa = String(a).split(".").map(Number);
  const pb = String(b).split(".").map(Number);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d !== 0) return d;
  }
  return 0;
}
