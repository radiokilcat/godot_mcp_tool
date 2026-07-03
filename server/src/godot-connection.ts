/**
 * GodotConnection — WebSocket server that the Godot plugin connects to.
 * Bridges MCP tool calls to Godot and returns results.
 */

import { WebSocketServer, WebSocket } from "ws";
import { randomUUID } from "crypto";

const TOOL_TIMEOUT_MS = 15_000;
const WS_PORT = 6505;

interface PendingCall {
  resolve: (value: unknown) => void;
  reject: (err: Error) => void;
  timer: ReturnType<typeof setTimeout>;
}

class GodotConnection {
  private wss: WebSocketServer;
  private socket: WebSocket | null = null;
  private pending = new Map<string, PendingCall>();
  private _godotVersion: string | null = null;
  private _pluginVersion: string | null = null;

  constructor() {
    this.wss = new WebSocketServer({ port: WS_PORT });
    this.wss.on("connection", (ws) => this._onConnection(ws));
    console.error(`[Godot] WebSocket server listening on ws://localhost:${WS_PORT}`);
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
    if (!this.isConnected) {
      throw new Error(
        "Godot editor is not connected. " +
        "Make sure the Godot MCP plugin is enabled and the editor is open."
      );
    }

    const id = randomUUID();
    return new Promise<unknown>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Tool call timed out after ${TOOL_TIMEOUT_MS}ms: ${tool}`));
      }, TOOL_TIMEOUT_MS);

      this.pending.set(id, { resolve, reject, timer });
      this.socket!.send(JSON.stringify({ type: "tool_call", id, tool, args }));
    });
  }

  close(): void {
    this.wss.close();
  }
}

export const godotConnection = new GodotConnection();
