import { describe, it, expect } from "vitest";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

import { renderApiReference } from "../src/docs/api-reference.js";
import { collectExamples, REPO_ROOT } from "../src/docs/generate.js";
import { categoriesByName, buildToolRegistry, CategoryName } from "../src/registry.js";

/**
 * The API reference is generated, so the only way it can be wrong is by being
 * stale — someone adds a parameter, ships it, and the page keeps describing the
 * old signature. That failure is silent and it is worse than having no page at
 * all, because an agent reading a parameter that no longer exists spends its
 * turn on a call that cannot work. This is the check that makes it loud.
 */

const examples = collectExamples(join(REPO_ROOT, "e2e", "blocks"));
const pages = renderApiReference(examples);

describe("generated API reference", () => {
  it("matches what is checked in (run `npm run docs` if this fails)", () => {
    for (const [name, body] of pages) {
      const path = join(REPO_ROOT, "docs", "api", name);
      expect(existsSync(path), `docs/api/${name} is missing`).toBe(true);
      const expected = body.endsWith("\n") ? body : body + "\n";
      expect(readFileSync(path, "utf8"), `docs/api/${name} is out of date`).toBe(expected);
    }
  });

  it("has a page for every category plus the index", () => {
    const names = Object.keys(categoriesByName) as CategoryName[];
    for (const name of names) expect(pages.has(`${name}.md`)).toBe(true);
    expect(pages.has("README.md")).toBe(true);
    expect(pages.size).toBe(names.length + 1);
  });

  it("gives every tool a worked example", () => {
    // The e2e suite exercises 163/163 tools, so a tool without an example means
    // either a tool nothing tests or a name the blocks spell differently.
    const missing = [...buildToolRegistry().keys()].filter((t) => !examples.has(t));
    expect(missing).toEqual([]);
  });

  it("cites a numbered test for its examples rather than a bare setup step", () => {
    // Setup steps carry no assertions, so an example taken from one is a call
    // that merely did not error. A handful is fine; a drift here means tools are
    // being covered only incidentally.
    const fromSetup = [...examples.entries()].filter(([, e]) => e.id === null);
    expect(fromSetup.length).toBeLessThanOrEqual(5);
  });

  it("documents every parameter the tool actually declares", () => {
    for (const [toolName, tool] of buildToolRegistry()) {
      const declared = Object.keys(tool.inputSchema?.properties ?? {});
      if (declared.length === 0) continue;
      const category = (Object.keys(categoriesByName) as CategoryName[]).find(
        (c) => toolName in categoriesByName[c]
      );
      const page = pages.get(`${category}.md`) ?? "";
      for (const param of declared) {
        expect(page, `${toolName}.${param} is undocumented`).toContain(`| \`${param}\` |`);
      }
    }
  });
});
