/**
 * McpTestClient — drives the production MCP server (server/dist/index.js) over stdio
 * using the official SDK client, exactly like a real MCP client would.
 *
 * The SDK is resolved out of server/node_modules via createRequire so e2e/ needs
 * no npm install of its own.
 */

import { createRequire } from "node:module";
import { pathToFileURL } from "node:url";
import { join } from "node:path";
import { createWriteStream } from "node:fs";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export class McpTestClient {
  constructor({ serverDir, port, serverLogPath }) {
    this.serverDir = serverDir;
    this.port = port;
    this.serverLogPath = serverLogPath;
    this.client = null;
  }

  async connect() {
    const req = createRequire(join(this.serverDir, "package.json"));
    const { Client } = await import(
      pathToFileURL(req.resolve("@modelcontextprotocol/sdk/client/index.js")).href
    );
    const { StdioClientTransport } = await import(
      pathToFileURL(req.resolve("@modelcontextprotocol/sdk/client/stdio.js")).href
    );

    const transport = new StdioClientTransport({
      command: process.execPath,
      args: [join(this.serverDir, "dist", "index.js")],
      env: { ...process.env, GODOT_MCP_PORT: String(this.port) },
      stderr: "pipe",
    });

    this.client = new Client({ name: "godot-mcp-e2e", version: "1.0.0" });
    await this.client.connect(transport);

    if (transport.stderr && this.serverLogPath) {
      const log = createWriteStream(this.serverLogPath, { flags: "a" });
      transport.stderr.on("data", (d) => log.write(d));
    }
  }

  /**
   * Call a tool. Never throws.
   * @returns {{ok: true, result: unknown, ms: number} | {ok: false, error: string, ms: number}}
   */
  async callTool(name, args = {}, timeoutMs = 30_000) {
    const started = Date.now();
    try {
      const res = await Promise.race([
        this.client.callTool({ name, arguments: args }),
        sleep(timeoutMs).then(() => {
          throw new Error(`e2e client timeout after ${timeoutMs}ms`);
        }),
      ]);
      const ms = Date.now() - started;
      const text = res?.content?.find((c) => c.type === "text")?.text ?? "";
      if (res?.isError) return { ok: false, error: text || "unknown tool error", ms };
      let result;
      try {
        result = text === "" ? null : JSON.parse(text);
      } catch {
        result = text; // non-JSON payloads pass through as raw text
      }
      return { ok: true, result, ms };
    } catch (err) {
      return { ok: false, error: err?.message ?? String(err), ms: Date.now() - started };
    }
  }

  async listToolNames() {
    const res = await this.client.listTools();
    return (res.tools ?? []).map((t) => t.name);
  }

  /**
   * Readiness gate: poll a cheap tool until the editor plugin has completed
   * its WebSocket handshake with the server.
   */
  async waitReady(totalMs = 90_000, { isEditorAlive } = {}) {
    const deadline = Date.now() + totalMs;
    let lastError = "no attempts made";
    while (Date.now() < deadline) {
      if (isEditorAlive && !isEditorAlive()) {
        throw new Error(`Editor process exited while waiting for handshake (last error: ${lastError})`);
      }
      const r = await this.callTool("get_editor_version", {}, 8_000);
      if (r.ok) return r.result;
      lastError = r.error;
      await sleep(2_000);
    }
    throw new Error(`Godot editor did not become ready within ${totalMs}ms (last error: ${lastError})`);
  }

  async close() {
    try {
      await this.client?.close();
    } catch { /* server already gone is fine */ }
  }
}
