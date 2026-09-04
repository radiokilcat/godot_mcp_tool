/**
 * Assertion DSL — mirrors the conventions of docs/mcp_test_plan.md.
 * Ops: eq, neq, notNull, isNull, notEmpty, contains, gte, lte, matches,
 *      allElementsMatch, jsonContains.
 *
 * Two kinds of assertion, and the difference is the point (progress.md 6.1):
 *   - `asserts` / `verify` check what a tool *says*, over the bridge.
 *   - `expectFiles` checks what actually landed *on disk*, below the tool that
 *     reported it. 6.6.1 and 6.6.8 both answered `success: true` for work that
 *     never happened, and no response-level assertion can catch that.
 */

import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";

/**
 * Resolve a dot-path in a result object. Literal keys win over path splitting
 * at every level, so fields like "application/config/description" or keys
 * containing dots resolve correctly.
 */
export function resolveField(obj, path) {
  if (!path) return obj;
  let cur = obj;
  let rest = path;
  while (rest !== "") {
    if (cur === null || cur === undefined) return undefined;
    if (typeof cur === "object" && rest in cur) return cur[rest];
    const i = rest.indexOf(".");
    if (i === -1) return typeof cur === "object" ? cur[rest] : undefined;
    const head = rest.slice(0, i);
    cur = Array.isArray(cur) ? cur[Number(head)] : cur[head];
    rest = rest.slice(i + 1);
  }
  return cur;
}

/** @returns {string[]} human-readable failure descriptions (empty = all passed) */
export function evaluateAsserts(asserts, result) {
  const failures = [];
  for (const a of asserts) {
    const actual = resolveField(result, a.field);
    const fail = (why) =>
      failures.push(`\`${a.field || "$result"}\` ${a.op}${a.value !== undefined ? ` ${JSON.stringify(a.value)}` : ""} — ${why} (actual: ${short(actual)})`);

    switch (a.op) {
      case "eq":
        if (!looseEq(actual, a.value)) fail("not equal");
        break;
      case "neq":
        if (looseEq(actual, a.value)) fail("equal but must differ");
        break;
      case "notNull":
        if (actual === null || actual === undefined) fail("is null/absent");
        break;
      case "isNull":
        if (actual !== null && actual !== undefined) fail("expected null/absent");
        break;
      case "notEmpty":
        if (isEmpty(actual)) fail("is empty");
        break;
      case "contains":
        if (!contains(actual, a.value)) fail("does not contain");
        break;
      case "notContains":
        if (contains(actual, a.value)) fail("contains but must not");
        break;
      case "gte":
        if (!(Number(actual) >= Number(a.value))) fail("below threshold");
        break;
      case "lte":
        if (!(Number(actual) <= Number(a.value))) fail("above threshold");
        break;
      case "matches":
        if (!new RegExp(a.value).test(String(actual))) fail("regex does not match");
        break;
      case "allElementsMatch": {
        if (!Array.isArray(actual)) { fail("not an array"); break; }
        const re = new RegExp(a.value);
        const bad = actual.filter((el) => !re.test(String(el)));
        if (bad.length > 0) fail(`${bad.length} element(s) do not match, e.g. ${short(bad[0])}`);
        break;
      }
      case "jsonContains":
        if (!JSON.stringify(actual ?? null).includes(a.value)) fail("JSON does not contain");
        break;
      case "jsonNotContains":
        if (JSON.stringify(actual ?? null).includes(a.value)) fail("JSON contains but must not");
        break;
      default:
        fail(`unknown assert op "${a.op}"`);
    }
  }
  return failures;
}

/**
 * Map a Godot path to the real file the test project holds. Only `res://` is
 * supported on purpose: `user://` resolves inside the self-contained Godot
 * distribution rather than the project, so a test asserting there would be
 * checking a path that moves with the engine build.
 */
export function resolveProjectPath(projectDir, path) {
  if (path.startsWith("res://")) return join(projectDir, path.slice("res://".length));
  if (path.startsWith("user://")) {
    throw new Error(`expectFiles cannot resolve "${path}" — user:// lives outside the project`);
  }
  return join(projectDir, path);
}

/**
 * Effect-level assertions against the generated project's filesystem.
 * @returns {string[]} human-readable failure descriptions (empty = all passed)
 */
export function evaluateFileAsserts(fileAsserts, projectDir) {
  const failures = [];
  for (const a of fileAsserts) {
    let target;
    try {
      target = resolveProjectPath(projectDir, a.path);
    } catch (err) {
      failures.push(`on disk: ${err.message}`);
      continue;
    }

    const present = existsSync(target);
    const fail = (why) => failures.push(`on disk \`${a.path}\` ${a.op} — ${why}`);
    // Read lazily: the content ops need text, `exists`/`absent`/`minSize` do not,
    // and a PNG should not be slurped as a string just to check it is there.
    const text = () => readFileSync(target, "utf8");

    if (a.op === "exists") {
      if (!present) fail(`file not found at ${target}`);
      continue;
    }
    if (a.op === "absent") {
      if (present) fail(`file exists at ${target} but must not`);
      continue;
    }
    if (!present) {
      fail(`file not found at ${target}`);
      continue;
    }

    switch (a.op) {
      case "contains":
        if (!text().includes(String(a.value))) fail(`text not found in ${excerpt(text())}`);
        break;
      case "notContains":
        if (text().includes(String(a.value))) fail(`text is present but must not be`);
        break;
      case "matches":
        if (!new RegExp(a.value, "m").test(text())) fail(`regex does not match ${excerpt(text())}`);
        break;
      case "minSize": {
        const size = statSync(target).size;
        if (size < Number(a.value)) fail(`only ${size} bytes`);
        break;
      }
      default:
        fail(`unknown file assert op "${a.op}"`);
    }
  }
  return failures;
}

/**
 * A failed file assertion is nearly useless without the file: the whole point is
 * that the tool's own answer cannot be trusted, so "did not match" leaves nothing
 * to reason from. Generated scenes and project.godot are small, so quote them.
 */
function excerpt(content) {
  const limit = 600;
  const body = content.length > limit ? content.slice(0, limit) + "\n… (truncated)" : content;
  return `${content.length} bytes:\n--- file ---\n${body}\n--- end ---`;
}

function looseEq(a, b) {
  // Godot stores most numeric properties as 32-bit floats, so a value written
  // as 1.8 reads back as 1.79999995231628. Compare numbers with a relative
  // tolerance wide enough for that round trip.
  if (typeof a === "number" && typeof b === "number") {
    return a === b || Math.abs(a - b) <= 1e-6 * Math.max(1, Math.abs(a), Math.abs(b));
  }
  if (a !== null && typeof a === "object") return JSON.stringify(a) === JSON.stringify(b);
  return a === b;
}

function isEmpty(v) {
  if (v === null || v === undefined) return true;
  if (Array.isArray(v) || typeof v === "string") return v.length === 0;
  if (typeof v === "object") return Object.keys(v).length === 0;
  return false;
}

function contains(haystack, needle) {
  if (typeof haystack === "string") return haystack.includes(String(needle));
  if (Array.isArray(haystack)) {
    return haystack.some(
      (el) => looseEq(el, needle) || (typeof el === "string" && el.includes(String(needle)))
    );
  }
  return false;
}

function short(v) {
  const s = JSON.stringify(v);
  if (s === undefined) return "undefined";
  return s.length > 120 ? s.slice(0, 120) + "…" : s;
}
