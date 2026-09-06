/**
 * Writes docs/api/ from the tool definitions. See api-reference.ts for why the
 * reference is generated and why the examples come out of the e2e blocks.
 *
 * Run it with `npm run docs` in server/. The freshness test in
 * tests/api-docs.test.ts uses the same two functions, so what CI compares is
 * what this writes.
 */

import { readdirSync, readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import { renderApiReference, ToolExample } from "./api-reference.js";

/** Repo root, from either src/docs/ or dist/docs/ — both are three levels down. */
export const REPO_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..", "..");

interface BlockStep {
  tool?: string;
  args?: unknown;
  id?: string;
  verify?: BlockStep;
}

interface Block {
  setup?: BlockStep[];
  tests?: BlockStep[];
  cleanup?: BlockStep[];
}

/**
 * First call of each tool across the e2e blocks, in file order.
 *
 * A numbered test wins over a setup step even when the setup step comes first:
 * the test is the one with an id to cite and assertions behind it, which is what
 * makes the example worth printing. Blocks are read in sorted order so the
 * output does not depend on the filesystem's.
 */
export function collectExamples(blocksDir: string): Map<string, ToolExample> {
  const examples = new Map<string, ToolExample>();
  const files = readdirSync(blocksDir).filter((f) => f.endsWith(".json")).sort();

  const record = (step: BlockStep | undefined, file: string, id: string | null): void => {
    if (!step?.tool) return;
    const existing = examples.get(step.tool);
    if (existing && (existing.id !== null || id === null)) return;
    examples.set(step.tool, { file, id, args: step.args ?? {} });
  };

  for (const name of files) {
    const file = `e2e/blocks/${name}`;
    const block = JSON.parse(readFileSync(join(blocksDir, name), "utf8")) as Block;
    for (const step of block.setup ?? []) record(step, file, null);
    for (const step of block.cleanup ?? []) record(step, file, null);
    for (const test of block.tests ?? []) {
      record(test, file, test.id ?? null);
      record(test.verify, file, test.id ? `${test.id} (verify)` : null);
    }
  }
  return examples;
}

/** @returns the files written, relative to the repo root. */
export function writeApiReference(root: string = REPO_ROOT): string[] {
  const pages = renderApiReference(collectExamples(join(root, "e2e", "blocks")));
  const outDir = join(root, "docs", "api");
  mkdirSync(outDir, { recursive: true });

  const written: string[] = [];
  for (const [name, body] of pages) {
    writeFileSync(join(outDir, name), body.endsWith("\n") ? body : body + "\n", "utf8");
    written.push(`docs/api/${name}`);
  }
  return written.sort();
}

const invokedDirectly =
  process.argv[1] !== undefined &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href;

if (invokedDirectly) {
  const written = writeApiReference();
  console.log(`[docs] wrote ${written.length} files under docs/api/`);
}
