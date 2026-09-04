# Contributing to Godot MCP Tool

Thanks for your interest! This project has two components — a **Godot plugin**
(GDScript, in `addons/godot_mcp/`) and a **Node.js MCP server** (TypeScript, in
`server/`) — that talk over a local WebSocket.

## Setup

Prerequisites: **Godot 4.x** (verified on 4.4.1) and **Node.js 18+**.

```bash
git clone https://github.com/radiokilcat/godot_mcp_tool.git
cd godot_mcp_tool/server
npm install
npm run build
```

To run against a live editor, copy `addons/godot_mcp/` into a Godot project (or open
this repo as a Godot project), enable the plugin in Project Settings, and point your
MCP client at `server/dist/index.js`.

## Before opening a PR

Run all three checks — they mirror what CI runs:

```bash
cd server
npm run lint      # ESLint
npm run build     # TypeScript must compile clean
npm test          # unit tests (type parser)
```

For anything that touches tool behavior, also run the end-to-end suite against a real
editor:

```bash
node e2e/run.mjs --godot 4.4.1
```

It downloads Godot (cached after the first run), generates a throwaway project, boots
the editor, runs every tool, and writes a report to `.e2e_work/reports/`. Exit code `0`
means all tests passed. Use `--blocks N` or `--test ID` to iterate on a subset.

## Adding or changing a tool

A tool exists in two places that must stay in sync:

1. **Server side** (`server/src/tools/<category>.ts`) — the MCP schema (name,
   description, `inputSchema`, optional `minGodotVersion`/`maxGodotVersion`) and a thin
   handler that forwards to the plugin.
2. **Plugin side** (`addons/godot_mcp/tools/<category>_tools.gd`) — the actual
   implementation, registered in that file's `register()`.

Then add a test to the matching `e2e/blocks/NN-*.json` block so the new behavior is
covered by the suite.

**Gotcha we learned the hard way:** a runtime error inside a GDScript function typed
`-> Dictionary` silently returns `{}` instead of propagating. So an e2e assertion must
check a concrete field (e.g. `success == true`), never just "the call did not error."

## Conventions

- Keep new code in the style of the file around it.
- All editor mutations should support UndoRedo where practical.
- Guard version-specific engine APIs via `version_utils.gd` rather than assuming a
  minimum Godot version.
- Update [progress.md](progress.md) when you complete a task — it tracks open work only.
  Closed work, with the reasoning behind each decision, lives in [docs/changelog.md](docs/changelog.md).

## Reporting bugs

Open a [GitHub issue](https://github.com/radiokilcat/godot_mcp_tool/issues) with your
Godot version, the tool involved, the arguments you passed, and the error text. If you
can reproduce it through the e2e runner, the failing block/test id is the most helpful
thing you can include.
