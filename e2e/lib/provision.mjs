/**
 * Provision — download and cache a Godot 4.x win64 distribution.
 * Cache layout: .e2e_work/cache/Godot_v{ver}-stable_win64/{exe, _console.exe, _sc_}
 */

import { createWriteStream, existsSync, mkdirSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

export async function provision({ version, workDir, log }) {
  const base = `Godot_v${version}-stable_win64`;
  const distDir = join(workDir, "cache", base);
  const exe = join(distDir, `${base}.exe`);
  const consoleExe = join(distDir, `${base}_console.exe`);
  const scMarker = join(distDir, "_sc_");

  if (existsSync(consoleExe)) {
    log(`[provision] cache hit: ${distDir}`);
    if (!existsSync(scMarker)) writeFileSync(scMarker, "");
    return { exe, consoleExe, distDir };
  }

  mkdirSync(distDir, { recursive: true });
  const zipName = `${base}.exe.zip`;
  const zipPath = join(workDir, "cache", zipName);
  const urls = [
    `https://github.com/godotengine/godot-builds/releases/download/${version}-stable/${zipName}`,
    `https://github.com/godotengine/godot/releases/download/${version}-stable/${zipName}`,
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

  log(`[provision] extracting ${zipName}`);
  const r = spawnSync(
    "powershell.exe",
    [
      "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command",
      `Expand-Archive -LiteralPath "${zipPath}" -DestinationPath "${distDir}" -Force`,
    ],
    { encoding: "utf8", timeout: 300_000 }
  );
  if (r.status !== 0) {
    throw new Error(`Expand-Archive failed (exit ${r.status}): ${r.stderr || r.stdout}`);
  }
  if (!existsSync(consoleExe) || !existsSync(exe)) {
    throw new Error(`Extraction did not produce expected executables in ${distDir}`);
  }

  try { unlinkSync(zipPath); } catch { /* non-fatal */ }
  // Self-contained mode: editor settings/caches live next to the exe,
  // the user's real Godot configuration is never touched.
  writeFileSync(scMarker, "");
  log(`[provision] ready: ${distDir}`);
  return { exe, consoleExe, distDir };
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
