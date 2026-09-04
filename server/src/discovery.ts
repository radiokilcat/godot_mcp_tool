/**
 * Finding the editor to talk to (progress.md 6.5.6).
 *
 * After the transport inversion the editor listens and this process dials in, so
 * it has to discover a port and a token. Nothing in the MCP configuration says
 * where the Godot project is — `.mcp.json` carries an absolute path to this
 * server and nothing else — so the plugin publishes a small JSON file per running
 * editor under ~/.godot-mcp/instances/ and this reads them.
 *
 * The token in those files is a credential: it is the only thing between
 * `execute_script` and any web page the developer has open, because WebSocket
 * ignores same-origin and a page may connect to ws://127.0.0.1:<port> freely.
 */

import { readdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve, sep } from "node:path";

export interface GodotInstance {
  port: number;
  token: string;
  projectPath: string;
  projectName: string;
  pid: number;
  godotVersion: string;
  pluginVersion: string;
  /** Where this came from, for error messages. */
  source: string;
}

export function instancesDir(): string {
  return join(homedir(), ".godot-mcp", "instances");
}

/** Read every published instance, skipping anything unreadable or malformed. */
export function readInstances(dir = instancesDir()): GodotInstance[] {
  let names: string[];
  try {
    names = readdirSync(dir).filter((n) => n.endsWith(".json"));
  } catch {
    return []; // no directory yet: no editor has ever published
  }

  const found: GodotInstance[] = [];
  for (const name of names) {
    const path = join(dir, name);
    try {
      const raw = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
      const port = Number(raw.port);
      const token = String(raw.token ?? "");
      if (!Number.isInteger(port) || port <= 0 || !token) continue;
      found.push({
        port,
        token,
        projectPath: String(raw.project_path ?? ""),
        projectName: String(raw.project_name ?? ""),
        pid: Number(raw.pid ?? 0),
        godotVersion: String(raw.godot_version ?? ""),
        pluginVersion: String(raw.plugin_version ?? ""),
        source: path,
      });
    } catch {
      // A half-written or hand-edited file is not worth failing the session over.
    }
  }
  return found;
}

/**
 * An editor that died without withdrawing its entry leaves the file behind, and
 * connecting to its port would hang until the timeout. Checking the pid is the
 * cheap half of the answer; the connection attempt is the other half.
 */
export function isAlive(pid: number): boolean {
  if (!Number.isInteger(pid) || pid <= 0) return true; // unknown: let the connect decide
  try {
    process.kill(pid, 0);
    return true;
  } catch (err) {
    // EPERM means it exists and belongs to someone else — still alive.
    return (err as NodeJS.ErrnoException).code === "EPERM";
  }
}

function within(parent: string, child: string): boolean {
  if (!parent || !child) return false;
  const a = resolve(parent);
  const b = resolve(child);
  return a === b || b.startsWith(a.endsWith(sep) ? a : a + sep);
}

/**
 * Pick one instance. Pure, so the rules are testable without a filesystem.
 *
 * With one editor open there is nothing to decide. With several, the working
 * directory is the only hint available — a client is normally launched from the
 * project it is meant to drive. When even that does not separate them, failing
 * with the list beats silently driving the wrong project: the failure mode of
 * guessing is edits landing in someone else's scene.
 */
export function selectInstance(
  instances: GodotInstance[],
  cwd = process.cwd()
): { instance: GodotInstance } | { error: string } {
  if (instances.length === 0) {
    return {
      error:
        "No running Godot editor found. Open your project with the Godot MCP plugin enabled — " +
        `it publishes a file under ${instancesDir()} when it starts. ` +
        "To bypass discovery, set GODOT_MCP_PORT (and GODOT_MCP_TOKEN if the editor requires one).",
    };
  }
  if (instances.length === 1) return { instance: instances[0] };

  const matches = instances.filter(
    (i) => within(i.projectPath, cwd) || within(cwd, i.projectPath)
  );
  if (matches.length === 1) return { instance: matches[0] };

  const listed = instances
    .map((i) => `  - ${i.projectName || "(unnamed)"} on port ${i.port} — ${i.projectPath}`)
    .join("\n");
  return {
    error:
      `${instances.length} Godot editors are running and none matches this working directory ` +
      `(${cwd}), so the target is ambiguous:\n${listed}\n` +
      "Set GODOT_MCP_PORT and GODOT_MCP_TOKEN to choose one.",
  };
}

/**
 * The instance this process should connect to, honouring the environment first.
 * `GODOT_MCP_PORT` predates discovery and the e2e harness depends on it (6.4.8).
 */
export function resolveTarget(cwd = process.cwd()): { instance: GodotInstance } | { error: string } {
  const envPort = Number(process.env.GODOT_MCP_PORT ?? "");
  if (Number.isInteger(envPort) && envPort > 0) {
    return {
      instance: {
        port: envPort,
        token: process.env.GODOT_MCP_TOKEN ?? "",
        projectPath: "",
        projectName: "",
        pid: 0,
        godotVersion: "",
        pluginVersion: "",
        source: "GODOT_MCP_PORT",
      },
    };
  }
  return selectInstance(readInstances().filter((i) => isAlive(i.pid)), cwd);
}
