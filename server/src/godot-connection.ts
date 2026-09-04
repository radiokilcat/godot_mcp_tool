/**
 * The bridge to the Godot editor — a reconnecting WebSocket *client*.
 *
 * The direction used to be the other way round: this process listened and the
 * plugin dialled in. That put a machine-wide port in the hands of the shortest
 * lived process in the chain, so only the first MCP session worked, a second
 * session was a corpse with a polite message, and two open projects clobbered
 * each other's socket. With the editor listening (6.5), the listener lives
 * exactly as long as the thing it represents, N sessions attach for free, and
 * each project gets its own port.
 *
 * The retry logic below is deliberately a mirror of what this change deleted from
 * plugin.gd — the problem did not go away, it moved to the side that should own it.
 */

import { WebSocket } from "ws";
import { randomUUID } from "crypto";

import { resolveTarget, type GodotInstance } from "./discovery.js";

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

const RECONNECT_BASE_MS = 500;
const RECONNECT_MAX_MS = 15_000;
// One editor serves N clients now, so a call can wait behind another session's.
// The plugin queues rather than rejecting (6.5.7), and this covers the wait.
const QUEUE_SLACK_MS = 30_000;

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

interface PendingCall {
  resolve: (value: unknown) => void;
  reject: (err: Error) => void;
  timer: ReturnType<typeof setTimeout>;
}

/**
 * What a tool handler needs from the bridge. Narrower than the class on purpose:
 * it is the seam a test substitutes, and it deliberately excludes anything that
 * owns a socket.
 */
export interface GodotBridge {
  readonly isConnected: boolean;
  readonly godotVersion: string | null;
  readonly pluginVersion: string | null;
  callTool(tool: string, args?: Record<string, unknown>): Promise<unknown>;
  close(): void;
}

export class GodotConnection implements GodotBridge {
  private socket: WebSocket | null = null;
  private pending = new Map<string, PendingCall>();
  private _godotVersion: string | null = null;
  private _pluginVersion: string | null = null;
  private _closed = false;
  private _attempts = 0;
  private _retryTimer: ReturnType<typeof setTimeout> | null = null;
  /** Why the last attempt failed, so a tool call can explain itself. */
  private _lastError: string | null = null;
  private _target: GodotInstance | null = null;

  constructor(private readonly host = process.env.GODOT_MCP_HOST || "127.0.0.1") {
    this.connect();
  }

  /**
   * Rediscovery happens on every attempt, not once at startup: the editor may be
   * restarted mid-session, and it comes back on a different port with a different
   * token. Caching the first answer would mean a session never recovers from a
   * simple editor restart.
   */
  private connect(): void {
    if (this._closed || this.socket) return;

    const target = resolveTarget();
    if ("error" in target) {
      this._lastError = target.error;
      this.scheduleRetry();
      return;
    }
    this._target = target.instance;

    // The token travels in the path because a Godot listener cannot read request
    // headers — verified against the engine, see progress.md 9.5.
    const url = `ws://${this.host}:${target.instance.port}/${encodeURIComponent(target.instance.token)}`;
    const socket = new WebSocket(url, { maxPayload: 8 * 1024 * 1024 });
    this.socket = socket;

    socket.on("open", () => {
      this._attempts = 0;
      this._lastError = null;
      console.error(`[Godot] Connected to editor on port ${target.instance.port}`);
    });

    socket.on("message", (raw) => this.onMessage(raw.toString()));

    socket.on("close", (code, reason) => {
      if (this.socket !== socket) return;
      this.socket = null;
      this._godotVersion = null;
      this._pluginVersion = null;
      this.rejectAll(
        code === 4001
          ? "The editor rejected this connection: invalid or missing token."
          : "Godot disconnected"
      );
      if (code === 4001) {
        // Not retryable by waiting, but the editor may be restarted with a fresh
        // token, and the next attempt rediscovers — so still retry, just say why.
        this._lastError =
          `The editor rejected the token from ${this._target?.source ?? "discovery"}. ` +
          "If you set GODOT_MCP_TOKEN by hand, check it matches the running editor.";
        console.error(`[Godot] ${this._lastError}`);
      } else if (reason?.length) {
        console.error(`[Godot] Disconnected: ${reason.toString()}`);
      }
      this.scheduleRetry();
    });

    socket.on("error", (err) => {
      this._lastError = err.message;
      // 'close' always follows, and that is where the retry is scheduled.
    });
  }

  private scheduleRetry(): void {
    if (this._closed || this._retryTimer) return;
    this._attempts += 1;
    const delay = Math.min(RECONNECT_MAX_MS, RECONNECT_BASE_MS * 2 ** (this._attempts - 1));
    this._retryTimer = setTimeout(() => {
      this._retryTimer = null;
      this.connect();
    }, delay);
    // Unref'd: a pending retry must never be the reason this process stays alive
    // after the MCP client has gone (6.5.1).
    this._retryTimer.unref?.();
  }

  private onMessage(raw: string): void {
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

  private rejectAll(reason: string): void {
    for (const [id, call] of this.pending) {
      clearTimeout(call.timer);
      call.reject(new Error(reason));
      this.pending.delete(id);
    }
  }

  get isConnected(): boolean {
    return this.socket !== null && this.socket.readyState === WebSocket.OPEN;
  }

  /** Godot engine version string reported by the plugin at handshake, or null before connection. */
  get godotVersion(): string | null {
    return this._godotVersion;
  }

  /** Plugin version string reported by the plugin at handshake, or null before connection. */
  get pluginVersion(): string | null {
    return this._pluginVersion;
  }

  async callTool(tool: string, args: Record<string, unknown> = {}): Promise<unknown> {
    if (!this.isConnected) {
      throw new Error(
        this._lastError ??
          "Godot editor is not connected. Make sure the Godot MCP plugin is enabled and the editor is open."
      );
    }

    const id = randomUUID();
    const timeoutMs = timeoutForCall(tool, args) + QUEUE_SLACK_MS;
    return new Promise<unknown>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Tool call timed out after ${timeoutMs}ms: ${tool}`));
      }, timeoutMs);

      this.pending.set(id, { resolve, reject, timer });
      this.socket!.send(JSON.stringify({ type: "tool_call", id, tool, args }));
    });
  }

  /** Idempotent, and safe to call from a process 'exit' handler. */
  close(): void {
    if (this._closed) return;
    this._closed = true;
    if (this._retryTimer) {
      clearTimeout(this._retryTimer);
      this._retryTimer = null;
    }
    this.rejectAll("Godot MCP server is shutting down");
    this.socket?.terminate();
    this.socket = null;
  }
}

/**
 * The process-wide bridge.
 *
 * Creation is explicit (9.4.3): this used to be a module-level `new`, which meant
 * *importing* a tool module opened a machine-wide port, and every one of the 23
 * tool modules imports it.
 */
let bridge: GodotBridge | null = null;

/** Start connecting. Called once from main(). */
export function openBridge(): GodotBridge {
  if (!bridge) bridge = new GodotConnection();
  return bridge;
}

/** Substitute the bridge — for tests, and anywhere the transport is constructed elsewhere. */
export function setBridge(next: GodotBridge | null): void {
  bridge = next;
}

/**
 * The bridge as seen by a tool handler. Fails loudly rather than connecting
 * behind the caller's back: reaching here with no bridge means main() did not
 * run, which is a wiring bug, not a condition to paper over at runtime.
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
