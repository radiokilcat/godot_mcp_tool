import { describe, it, expect, afterEach } from "vitest";
import {
  timeoutForCall,
  callTool,
  getBridge,
  setBridge,
  type GodotBridge,
} from "../src/godot-connection.js";

/**
 * This file exists because of 9.4.3: until the bridge stopped being constructed
 * at import time, importing anything under src/tools/ opened a machine-wide port,
 * so none of this could be unit-tested at all.
 */

afterEach(() => setBridge(null));

/** A bridge that records what it was asked and answers without a socket. */
function stubBridge(overrides: Partial<GodotBridge> = {}): GodotBridge & { calls: Array<{ tool: string; args: unknown }> } {
  const calls: Array<{ tool: string; args: unknown }> = [];
  return {
    calls,
    isConnected: true,
    godotVersion: "4.4.1.stable",
    pluginVersion: "1.0.0",
    async callTool(tool: string, args?: Record<string, unknown>) {
      calls.push({ tool, args });
      return { success: true };
    },
    close() { /* nothing to release */ },
    ...overrides,
  };
}

describe("bridge wiring", () => {
  it("throws instead of opening a port when no bridge was opened", async () => {
    // The important half: the failure is loud. Lazily binding here would put the
    // import-time port back, just triggered by the first call rather than the import.
    expect(() => getBridge()).toThrow(/openBridge\(\) was never called/);
    await expect(callTool("get_project_info")).rejects.toThrow(/openBridge\(\) was never called/);
  });

  it("routes callTool through the injected bridge", async () => {
    const stub = stubBridge();
    setBridge(stub);

    await expect(callTool("add_node", { node_type: "Label" })).resolves.toEqual({ success: true });
    expect(stub.calls).toEqual([{ tool: "add_node", args: { node_type: "Label" } }]);
  });

  it("defaults missing args to an empty object", async () => {
    const stub = stubBridge();
    setBridge(stub);

    await callTool("get_project_info");
    expect(stub.calls[0].args).toEqual({});
  });

  it("propagates the bridge's failure rather than swallowing it", async () => {
    setBridge(stubBridge({
      async callTool() { throw new Error("Godot editor is not connected."); },
    }));

    await expect(callTool("get_scene_tree")).rejects.toThrow("Godot editor is not connected.");
  });
});

describe("timeoutForCall (9.4.1 policy)", () => {
  const DEFAULT = 15_000;

  it("uses the default budget for an ordinary call", () => {
    expect(timeoutForCall("get_project_info", {})).toBe(DEFAULT);
  });

  it("derives the budget from a tool's own timeout argument, plus slack", () => {
    // The bug this encodes: a flat 15s meant execute_script's documented 60s
    // could never return, and the plugin stayed busy for the remainder.
    expect(timeoutForCall("execute_script", { timeout: 60 })).toBe(70_000);
    expect(timeoutForCall("listen_to_signal", { timeout: 30 })).toBe(40_000);
  });

  it("accepts `duration` as well as `timeout`", () => {
    expect(timeoutForCall("record_gameplay", { duration: 20 })).toBe(30_000);
  });

  it("never drops below the default for a very short argument", () => {
    // 0.5s + 10s slack is under the floor; a short deliberate wait must not
    // shrink the budget for scheduling and serialising the reply.
    expect(timeoutForCall("execute_script", { timeout: 0.5 })).toBe(DEFAULT);
  });

  it("clamps at ten minutes however large the argument", () => {
    expect(timeoutForCall("execute_script", { timeout: 99_999 })).toBe(600_000);
  });

  it("ignores a non-numeric, zero or negative argument", () => {
    expect(timeoutForCall("execute_script", { timeout: "60" })).toBe(DEFAULT);
    expect(timeoutForCall("execute_script", { timeout: 0 })).toBe(DEFAULT);
    expect(timeoutForCall("execute_script", { timeout: -5 })).toBe(DEFAULT);
    expect(timeoutForCall("execute_script", { timeout: NaN })).toBe(DEFAULT);
  });

  it("gives the inherently slow tools their own budget without an argument", () => {
    expect(timeoutForCall("export_project", {})).toBe(600_000);
    expect(timeoutForCall("run_automated_tests", {})).toBe(120_000);
    expect(timeoutForCall("bake_navigation", {})).toBe(120_000);
    expect(timeoutForCall("replay_gameplay", {})).toBe(120_000);
  });

  it("lets an explicit argument override the slow-tool table", () => {
    expect(timeoutForCall("bake_navigation", { timeout: 300 })).toBe(310_000);
  });
});
