/**
 * GodotConnection — WebSocket server that the Godot plugin connects to.
 * Bridges MCP tool calls to Godot and returns results.
 */

import { WebSocketServer, WebSocket } from "ws";
import { randomUUID } from "crypto";

const DEFAULT_TOOL_TIMEOUT_MS = 15_000;
// Never wait longer than this, whatever a caller asks for: the plugin clamps its
// own waits well below it, so a larger number only strands the bridge.
const MAX_TOOL_TIMEOUT_MS = 600_000;
// A tool that takes a duration spends it on purpose; the budget has to cover that
// plus scheduling the work and serialising the reply, which the caller's number
// does not account for.
const TIMEOUT_SLACK_MS = 10_000;
// Arguments naming, in seconds, how long the tool will deliberately take.
const DURATION_ARGS = ["timeout", "duration"];
// Tools with no such argument whose work is inherently longer than a round trip.
// Kept here rather than on each ToolDefinition because the timeout belongs to the
// transport that enforces it, and every handler reaches the editor through this
// one call.
const SLOW_TOOLS: Record<string, number> = {
  export_project: 600_000, // spawns a headless engine; a real export runs for minutes
  run_automated_tests: 120_000,
  bake_navigation: 120_000,
  replay_gameplay: 120_000,
  replay_input_sequence: 120_000,
  replay_test: 120_000,
};

/**
 * How long to wait for one call. A flat 15s was shorter than what several tools
 * are documented to do — `listen_to_signal` allows 30s, `execute_script` 60s — so
 * those calls could not succeed, and the plugin stayed busy for the remainder,
 * answering every following call with "another tool call is already in progress".
 */
export function timeoutForCall(tool: string, args: Record<string, unknown>): number {
  for (const key of DURATION_ARGS) {
    const value = args[key];
    if (typeof value === "number" && Number.isFinite(value) && value > 0) {
      return Math.min(
        MAX_TOOL_TIMEOUT_MS,
        Math.max(DEFAULT_TOOL_TIMEOUT_MS, value * 1000 + TIMEOUT_SLACK_MS)
      );
    }
  }
  return SLOW_TOOLS[tool] ?? DEFAULT_TOOL_TIMEOUT_MS;
}
// Overridable so test harnesses can run in parallel with a live setup on the default port
function defaultPort(): number {
  return Number(process.env.GODOT_MCP_PORT ?? "") || 6505;
}
// Whatever connects here is trusted as the Godot plugin — there is no authentication
// yet (progress.md 9.5) — so the bridge must not be reachable from the network. Node
// binds every interface when no host is given. Loopback is pinned to IPv4 because the
// plugin dials 127.0.0.1: binding "localhost" can resolve to ::1 on Windows and leave
// the editor knocking on an address nobody is listening to. Override only to attach an
// editor running on another machine, and only on a network you control.
function defaultHost(): string {
  return process.env.GODOT_MCP_HOST || "127.0.0.1";
}

interface PendingCall {
  resolve: (value: unknown) => void;
  reject: (err: Error) => void;
  timer: ReturnType<typeof setTimeout>;
}

/**
 * What a tool handler needs from the bridge. Narrower than the class on purpose:
 * it is the seam a test (or 6.5.5's client-side transport) substitutes, and it
 * deliberately excludes anything that owns a socket.
 */
export interface GodotBridge {
  readonly isConnected: boolean;
  readonly godotVersion: string | null;
  readonly pluginVersion: string | null;
  callTool(tool: string, args?: Record<string, unknown>): Promise<unknown>;
  close(): void;
}

export class GodotConnection implements GodotBridge {
  private wss: WebSocketServer;
  private socket: WebSocket | null = null;
  private pending = new Map<string, PendingCall>();
  private _godotVersion: string | null = null;
  private _pluginVersion: string | null = null;
  private _bindError: string | null = null;
  private _closed = false;
  private port: number;
  private host: string;

  /** Binds immediately — constructing this object is what opens the port. */
  constructor(options: { port?: number; host?: string } = {}) {
    this.port = options.port ?? defaultPort();
    this.host = options.host ?? defaultHost();
    this.wss = new WebSocketServer({ port: this.port, host: this.host });
    this.wss.on("connection", (ws) => this._onConnection(ws));
    // Only announce the port once the bind actually succeeded — listen() is async,
    // so logging in the constructor claims success before it is known.
    this.wss.on("listening", () => {
      console.error(`[Godot] WebSocket server listening on ws://${this.host}:${this.port}`);
    });
    // Without this handler a failed bind surfaces as an unhandled 'error' event and
    // kills the process before the MCP handshake completes, so the client reports
    // nothing but "connection closed". Stay up and report the cause through the
    // tools instead.
    this.wss.on("error", (err: NodeJS.ErrnoException) => {
      this._bindError = err.code === "EADDRINUSE"
        ? `Port ${this.port} is already in use — another Godot MCP server is still running. ` +
          `Stop that process, or set GODOT_MCP_PORT to a free port for both this server ` +
          `and the Godot plugin.`
        : `WebSocket server failed: ${err.message}`;
      console.error(`[Godot] ${this._bindError}`);
    });
  }

  private _onConnection(ws: WebSocket): void {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) {
      console.error("[Godot] Replacing existing connection");
      this.socket.close();
    }
    this.socket = ws;
    console.error("[Godot] Godot plugin connected");

    ws.on("message", (raw) => this._onMessage(raw.toString()));
    ws.on("close", () => {
      if (this.socket === ws) {
        this.socket = null;
        this._godotVersion = null;
        this._pluginVersion = null;
        console.error("[Godot] Godot plugin disconnected");
        // Reject all pending calls
        for (const [id, call] of this.pending) {
          clearTimeout(call.timer);
          call.reject(new Error("Godot disconnected"));
          this.pending.delete(id);
        }
      }
    });
    ws.on("error", (err) => {
      console.error(`[Godot] WebSocket error: ${err.message}`);
    });
  }

  private _onMessage(raw: string): void {
    let msg: Record<string, unknown>;
    try {
      msg = JSON.parse(raw) as Record<string, unknown>;
    } catch {
      console.error("[Godot] Failed to parse message:", raw);
      return;
    }

    const type = msg.type as string;

    if (type === "ping") {
      this.socket?.send(JSON.stringify({ type: "pong" }));
      return;
    }

    if (type === "ready") {
      this._godotVersion = (msg.godot_version as string) ?? null;
      this._pluginVersion = (msg.plugin_version as string) ?? null;
      console.error(`[Godot] Ready — Godot ${msg.godot_version}, plugin ${msg.plugin_version}`);
      return;
    }

    if (type === "tool_result") {
      const id = msg.id as string;
      const call = this.pending.get(id);
      if (!call) return;
      clearTimeout(call.timer);
      this.pending.delete(id);
      if (msg.error) {
        call.reject(new Error(String(msg.error)));
      } else {
        call.resolve(msg.result);
      }
    }
  }

  get isConnected(): boolean {
    return this.socket !== null && this.socket.readyState === WebSocket.OPEN;
  }

  /** Godot engine version string reported by the plugin at handshake (e.g. "4.4.1.stable"), or null before connection. */
  get godotVersion(): string | null {
    return this._godotVersion;
  }

  /** Plugin version string reported by the plugin at handshake, or null before connection. */
  get pluginVersion(): string | null {
    return this._pluginVersion;
  }

  async callTool(tool: string, args: Record<string, unknown> = {}): Promise<unknown> {
    // Check this first: with a failed bind the editor can never connect, and the
    // generic "plugin not enabled" hint below would send the user after the wrong fix.
    if (this._bindError) {
      throw new Error(this._bindError);
    }

    if (!this.isConnected) {
      throw new Error(
        "Godot editor is not connected. " +
        "Make sure the Godot MCP plugin is enabled and the editor is open."
      );
    }

    const id = randomUUID();
    const timeoutMs = timeoutForCall(tool, args);
    return new Promise<unknown>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Tool call timed out after ${timeoutMs}ms: ${tool}`));
      }, timeoutMs);

      this.pending.set(id, { resolve, reject, timer });
      this.socket!.send(JSON.stringify({ type: "tool_call", id, tool, args }));
    });
  }

  /**
   * Release the bridge port and drop the editor connection. Idempotent, and safe
   * to call from a process 'exit' handler (everything that matters is synchronous).
   *
   * `wss.close()` alone is not enough: the internally created HTTP server only
   * finishes closing once every established connection has ended, and an attached
   * editor never ends one — the port would stay bound for the life of the process.
   * Terminating the sockets first is what actually frees it.
   */
  close(): void {
    if (this._closed) return;
    this._closed = true;

    for (const [id, call] of this.pending) {
      clearTimeout(call.timer);
      call.reject(new Error("Godot MCP server is shutting down"));
      this.pending.delete(id);
    }

    for (const client of this.wss.clients) {
      client.terminate();
    }
    this.socket = null;
    this.wss.close();
  }
}

/**
 * The process-wide bridge.
 *
 * This used to be `export const godotConnection = new GodotConnection()`, which
 * bound the port as a side effect of *importing* the module — and every one of the
 * 23 tool modules imports it. So merely enumerating tool schemas opened a
 * machine-wide port and evicted whatever editor was attached to a live session
 * (progress.md 9.4.3). Creation is now explicit: `openBridge()` from main(), and
 * `setBridge()` for a test that wants handlers without a socket.
 */
let bridge: GodotBridge | null = null;

/** Bind the port. Called once from main(); the plugin dials in, so it cannot wait for the first tool call. */
export function openBridge(options?: { port?: number; host?: string }): GodotBridge {
  if (!bridge) bridge = new GodotConnection(options);
  return bridge;
}

/** Substitute the bridge — for tests, and for 6.5.5 where the transport is constructed elsewhere. */
export function setBridge(next: GodotBridge | null): void {
  bridge = next;
}

/**
 * The bridge as seen by a tool handler. Fails loudly rather than binding a port
 * behind the caller's back: reaching here with no bridge means main() did not run,
 * which is a wiring bug, not a condition to paper over at runtime.
 */
export function getBridge(): GodotBridge {
  if (!bridge) {
    throw new Error(
      "Godot bridge is not open — openBridge() was never called. " +
      "This is a server wiring bug; in a test, call setBridge() with a stub first."
    );
  }
  return bridge;
}

/** Close the bridge if one was ever opened. Safe from a process 'exit' handler. */
export function closeBridge(): void {
  bridge?.close();
}

/**
 * Every tool handler's single line to the editor.
 *
 * `async` so that a missing bridge arrives as a rejection like every other
 * failure: a plain function would let getBridge() throw *synchronously* out of
 * something typed as returning a Promise, so a caller using `.catch()` without
 * `await` would take the process down instead of handling it.
 */
export async function callTool(tool: string, args: Record<string, unknown> = {}): Promise<unknown> {
  return getBridge().callTool(tool, args);
}
