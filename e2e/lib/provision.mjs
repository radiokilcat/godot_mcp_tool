/**
 * Provision — download and cache a Godot 4.x distribution for the host platform.
 * Cache layout: .e2e_work/cache/<dist name>/{binary, _sc_}
 *
 * Everything platform-shaped (archive name, binary location, how to unpack, where
 * the self-contained marker goes) lives in ./platform; this file is the flow.
 */

import { createWriteStream, existsSync, mkdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";

import { platformFor } from "./platform/index.mjs";

export async function provision({ version, workDir, log, platform = platformFor() }) {
  const distDir = join(workDir, "cache", platform.distName(version));
  const binary = platform.binaryPath(distDir, version);
  const scMarker = join(platform.selfContainedDir(distDir), "_sc_");

  if (existsSync(binary)) {
    log(`[provision] cache hit: ${distDir}`);
    if (!existsSync(scMarker)) writeFileSync(scMarker, "");
    return { binary, distDir };
  }

  mkdirSync(distDir, { recursive: true });
  const archive = platform.archiveName(version);
  const zipPath = join(workDir, "cache", archive);
  const urls = [
    `https://github.com/godotengine/godot-builds/releases/download/${version}-stable/${archive}`,
    `https://github.com/godotengine/godot/releases/download/${version}-stable/${archive}`,
  ];

  let downloaded = false;
  let lastErr = null;
  for (const url of urls) {
    try {
      log(`[provision] downloading ${url}`);
      await download(url, zipPath, log);
      downloaded = true;
      break;
    } catch (err) {
      lastErr = err;
      log(`[provision] failed: ${err.message}`);
    }
  }
  if (!downloaded) throw new Error(`Could not download Godot ${version}: ${lastErr?.message}`);

  log(`[provision] extracting ${archive} (${platform.name})`);
  platform.extract(zipPath, distDir);
  if (!existsSync(binary)) {
    throw new Error(`Extraction did not produce the expected binary at ${binary}`);
  }
  platform.afterExtract(distDir, version);

  try { unlinkSync(zipPath); } catch { /* non-fatal */ }
  // Self-contained mode: editor settings/caches live next to the binary, so the
  // user's real Godot configuration is never touched.
  writeFileSync(scMarker, "");
  log(`[provision] ready: ${distDir}`);
  return { binary, distDir };
}

async function download(url, dest, log) {
  const res = await fetch(url, { redirect: "follow" });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const total = Number(res.headers.get("content-length") || 0);
  const out = createWriteStream(dest);
  let done = 0;
  let lastLogged = 0;
  try {
    for await (const chunk of res.body) {
      if (!out.write(chunk)) await new Promise((r) => out.once("drain", r));
      done += chunk.length;
      if (done - lastLogged >= 10 * 1024 * 1024) {
        lastLogged = done;
        const totalMb = total ? ` / ${(total / 1048576).toFixed(0)} MB` : "";
        log(`[provision]   ${(done / 1048576).toFixed(0)} MB${totalMb}`);
      }
    }
  } finally {
    await new Promise((r) => out.end(r));
  }
  if (total && done !== total) throw new Error(`Incomplete download: ${done}/${total} bytes`);
}
