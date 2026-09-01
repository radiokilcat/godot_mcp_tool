/**
 * Assertion DSL — mirrors the conventions of docs/mcp_test_plan.md.
 * Ops: eq, neq, notNull, isNull, notEmpty, contains, gte, lte, matches,
 *      allElementsMatch, jsonContains.
 */

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
