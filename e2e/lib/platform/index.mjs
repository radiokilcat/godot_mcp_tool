/**
 * Platform selection for the e2e harness (progress.md 9.6).
 *
 * The suite used to be Windows-only by construction rather than by omission:
 * provision downloaded `..._win64` and unpacked with `powershell Expand-Archive`,
 * teardown killed the editor with `taskkill /T /F`, and everything keyed off
 * `*_console.exe`. So CI was impossible and no outside contributor could run it,
 * while the README promised cross-platform support.
 *
 * Each module answers the same five questions: what the release archive is
 * called, where the binary and the self-contained marker end up, how to unpack,
 * and how to kill the editor together with anything it spawned.
 */

import * as win32 from "./win32.mjs";
import * as linux from "./linux.mjs";
import * as darwin from "./darwin.mjs";

const platforms = { win32, linux, darwin };

export function platformFor(id = process.platform) {
  const platform = platforms[id];
  if (!platform) {
    throw new Error(
      `The e2e harness has no support for platform "${id}". ` +
      `Supported: ${Object.keys(platforms).join(", ")}. ` +
      `Add e2e/lib/platform/${id}.mjs exporting the same interface.`
    );
  }
  return platform;
}

/** Exposed for tests, which need to reason about hosts they are not running on. */
export const allPlatforms = platforms;
