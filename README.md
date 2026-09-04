# Godot MCP Tool

> AI Assistant integration for the Godot Editor via the Model Context Protocol (MCP)

An MCP server that lets AI assistants (Claude and other MCP clients) drive the Godot
Editor through **163 tools across 23 categories** — scenes, nodes, scripts, animation,
3D, physics, shaders, runtime inspection, automated testing, and more.

Every release is exercised by a **230-test end-to-end suite that boots a real Godot
editor** and runs all 163 registered tools against it — see [Testing](#testing).

## Architecture

```
AI Assistant (Claude / other MCP client)
    ↓ (MCP protocol, stdio)
Node.js MCP Server
    ↓ (WebSocket :6505)
Godot Editor Plugin (GDScript)
```

## Tool categories (163 total)

| Category | Tools | Focus |
|----------|-------|-------|
| **Project** | 7 | Project info, file search, settings, UID conversion |
| **Scene** | 10 | Scene tree, create/open/save/delete, play/stop, instancing |
| **Node** | 14 | Add/delete/duplicate, properties, signals, groups |
| **Script** | 8 | Read/create/edit, attach, validate syntax, search |
| **Editor** | 8 | Screenshots, error log, execute scripts, editor state |
| **Input** | 7 | Key/mouse/action simulation, sequences, input mapping |
| **Runtime** | 19 | Game inspection, recording/replay, navigate, UI click |
| **Animation** | 6 | Create animations, tracks, keyframes, easing |
| **AnimationTree** | 8 | State machines, transitions, blend trees |
| **3D Scene** | 6 | Meshes, cameras, lights, environment, GridMap |
| **Physics** | 6 | Bodies, collision shapes, layers, raycasts |
| **Particle** | 5 | GPU particles, materials, gradients, presets |
| **Navigation** | 6 | Regions, agents, baking, layer management |
| **Audio** | 6 | Players, bus layout, effects |
| **TileMap** | 6 | Set/fill/query cells, tile set info |
| **Theme/UI** | 6 | Colors, fonts, constants, StyleBox |
| **Shader** | 6 | Create/edit shaders, assign materials, parameters |
| **Resource** | 6 | Read/edit/create .tres, autoloads |
| **Batch/Refactor** | 8 | Find by type, cross-scene updates, dependencies |
| **Analysis** | 4 | Scene complexity, signal flow, unused resources |
| **Testing/QA** | 6 | Automated tests, assertions, screenshot compare |
| **Profiling** | 2 | Performance monitors, FPS/memory/draw calls |
| **Export** | 3 | Presets, export commands, template info |

## Key features

- **UndoRedo integration** — all mutations support Ctrl+Z in the editor
- **Smart type parsing** — `Vector2(100, 200)`, `#ff0000`, `Color(1,0,0)` are auto-converted
- **Auto-reconnect** — exponential backoff (1s → 60s)
- **Heartbeat** — ping/pong keeps the connection alive
- **Structured errors** — contextual hints on failure
- **2D & 3D** — full support for both workflows
- **Version-gating** — tools declare a supported Godot range; incompatible calls return a clear error instead of failing inside the editor (verified on Godot 4.4.1 and 4.7.2; targets 4.0+)

## Quick start

### Prerequisites

- **Godot 4.x** (verified on 4.4.1 and 4.7.2; targets 4.0+)
- **Node.js 18+**

### 1. Install the plugin

Copy the plugin into your Godot project and enable it:

```bash
cp -r addons/godot_mcp /path/to/your/godot/project/addons/
```

Then in Godot: **Project → Project Settings → Plugins → Godot MCP → Enable**.

### 2. Build the server

```bash
cd server
npm install
npm run build
```

### 3. Point your MCP client at it

Add to your client's MCP config (e.g. `.mcp.json`), using an **absolute path** to the
built entry point:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["/absolute/path/to/godot_mcp_tool/server/dist/index.js"]
    }
  }
}
```

The server listens for the editor plugin on WebSocket port `6505` (override with the
`GODOT_MCP_PORT` environment variable — set it for both the server and the editor).

Open your Godot project with the plugin enabled, and your assistant now has access to
all the tools.

## Testing

Four layers, fastest first. The first three together cost about ten seconds and need no
editor, so run them before reaching for the suite:

```bash
cd server && npm test              # ~1 s   514 tests: version/timeout/bridge logic, all 163 tool schemas
node e2e/unit.mjs                  # ~2 s   78 checks: plugin coercion rules, headless GDScript
node e2e/check-syntax.mjs          # ~6 s   every plugin script compiles, names file and line
node e2e/run.mjs --godot 4.4.1     # ~4 min the full suite below
```

The parse gate earns its place: a typo in any one plugin file stops `plugin.gd` compiling,
so *every* tool disappears and the only symptom the suite reports is `Tool not found`.

**End-to-end suite** — downloads a Godot distribution, generates a throwaway project,
boots the editor, runs every tool through the full MCP stack, writes a report, and
cleans up:

```bash
node e2e/run.mjs --godot 4.4.1
```

Useful flags: `--blocks 3,9` (run specific blocks), `--test AT-03` (single test),
`--headless` (rendering-dependent tests auto-skip), `--godot 4.4.1,4.7.2` (version
matrix), `--port 6510` (isolate from a live setup on 6505), `--keep-work` (keep the
generated project for debugging). Exit codes are CI-friendly: `0` all pass, `1` test
failures, `2` infrastructure error.

Design and internals: [docs/e2e_test_infrastructure.md](docs/e2e_test_infrastructure.md).
The executable spec is `e2e/blocks/*.json`; [docs/mcp_test_plan.md](docs/mcp_test_plan.md) is
the original prose plan, kept for background and stale in places.

## Project structure

```
godot_mcp_tool/
├── addons/godot_mcp/     # Godot plugin (GDScript)
├── server/               # Node.js MCP server (TypeScript)
│   └── src/tools/        # Tool categories
├── e2e/                  # End-to-end test runner + block definitions
├── docs/                 # E2E design, and the changelog of closed work
└── progress.md           # Open tasks (closed ones: docs/changelog.md)
```

### Development

```bash
cd server
npm run build      # compile TypeScript
npm run watch      # compile in watch mode
npm run lint       # ESLint
npm test           # 514 unit tests (vitest), ~1 s
```

The four test layers are described under [Testing](#testing).

## Clients

Works with any MCP-compatible client. Tested primarily with Claude Code / Claude Desktop;
the tool set also fits Cursor and Windsurf. A **Lite Mode** (a 76-tool core subset) is
planned for clients with tool-count limits — see [progress.md](progress.md).

## Status

- All 163 tools implemented (23 categories)
- Godot 4.4.1 and 4.7.2 compatibility verified — plugin loads clean, all tools registered
- End-to-end suite green: **230/230 tests, 163/163 tools covered** on both 4.4.1 and 4.7.2
- Planned: Lite Mode, expanded API docs, and npm packaging — see [progress.md](progress.md)
- What has already shipped, and why each decision was made: [docs/changelog.md](docs/changelog.md)

## Troubleshooting

**Connection issues** — confirm the editor is open with the plugin enabled, that
WebSocket port `6505` is free (or set `GODOT_MCP_PORT`), and check the Godot Output
panel for `[Godot MCP]` log lines.

**The bridge is loopback-only** — it binds `127.0.0.1`, because anything that connects is
trusted as the plugin and there is no authentication yet. To attach an editor on another
machine, set `GODOT_MCP_HOST` for both the server and the editor process, and only on a
network you control.

**Tool not found** — verify the plugin is enabled and the server built successfully
(`server/dist/index.js` exists).

## Contributing

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and feature
requests: [GitHub Issues](https://github.com/radiokilcat/godot_mcp_tool/issues).

## License

MIT — see [LICENSE](LICENSE).

---

**Made for the Godot community.**
