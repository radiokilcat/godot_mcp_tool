# Godot MCP Tool — v1.0.0

First tagged release. An MCP server that lets AI assistants (Claude and other MCP clients)
drive the Godot Editor directly — scenes, nodes, scripts, animation, 3D, physics, shaders,
runtime inspection, automated testing, and more.

## What's in it

- **163 tools across 23 categories** — project, scene, node, script, editor, input, runtime,
  animation, animation-tree, 3D scene, physics, particles, navigation, audio, tilemap, theme,
  shader, resource, batch/refactor, analysis, testing, profiling and export. See the
  [API reference](docs/api/README.md) for every tool with its parameters and a worked example.
- **The editor hosts the bridge; MCP sessions dial in.** Each open Godot project picks its own
  port and publishes it with a per-launch token, so several sessions can attach to one editor,
  a session recovers automatically if the editor restarts, and nothing is left listening once
  the editor closes.
- **UndoRedo integration** — mutations are committed as editor actions, undoable with Ctrl+Z.
- **Smart type parsing** — `Vector2(100, 200)`, `#ff0000`, `Color(1,0,0)` and friends are
  auto-converted consistently across every tool that takes them.
- **Structured, contextual errors** instead of raw engine exceptions where possible.
- **2D & 3D**, full support for both workflows.
- **`GODOT_MCP_PROFILE=core`** trims the tool list by category for clients with a tool-count
  limit — 115 tools, 40% fewer tokens than the full set.

## Tested

Every tool has at least one asserting end-to-end test — not just "called", but checked against
what actually landed in the editor and on disk. Six layers, all green before this tag:

| Layer | Command | Result |
|---|---|---|
| Server unit | `npm test` in `server/` | 552 passed |
| Plugin unit | `node e2e/unit.mjs` | 94 passed |
| Parse gate | `node e2e/check-syntax.mjs` | clean |
| End-to-end | `node e2e/run.mjs --godot 4.4.1` | 261 passed, 163/163 tools |
| Multi-session | `node e2e/multi-session.mjs` | 11 passed |
| Reconnect | `node e2e/reconnect.mjs` | 9 passed |

CI runs all of these on Linux, Windows and macOS on every push. Also spot-checked by hand
against **Godot 4.2.2** (236/236 non-skipped, 25 correctly self-skipped for engine APIs that
need 4.3+) to back the "targets 4.0+" claim beyond the CI matrix's single pinned version
(4.4.1).

## Known limitations

- **CI's version matrix is one Godot version (4.4.1).** The 4.2.2 and 4.7.2 checks in this
  release are manual, local runs, not a standing guardrail.
- **Cursor and Windsurf are unverified**, not unsupported — neither has been run against a live
  editor here. Their permission-preset formats also aren't written yet (see progress.md 4.2/5.2).
- **`ToolDefinition.minGodotVersion`/`maxGodotVersion` is wired up but unused** — no tool
  currently declares a range, so a call against an unsupported engine version gets whatever raw
  error the engine produces rather than the clean guidance the mechanism is meant to give.
- **An intermittent `stop_scene`-adjacent timeout** was seen across four consecutive local runs
  and then stopped reproducing; recorded, not fixed, in progress.md (6.8).

## Installing

See the [Quick start](README.md#quick-start) in the README, or the full
[installation guide](docs/installation.md) for per-OS paths, troubleshooting and every
environment variable.

## Requirements

Godot 4.x (verified on 4.2.2, 4.4.1 and 4.7.2) and Node.js 18+.
