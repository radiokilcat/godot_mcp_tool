# Godot MCP Tool

> AI Assistant integration for the Godot Editor via the Model Context Protocol (MCP)

An MCP server that lets AI assistants (Claude and other MCP clients) drive the Godot
Editor through **163 tools across 23 categories** — scenes, nodes, scripts, animation,
3D, physics, shaders, runtime inspection, automated testing, and more.

Every tool is exercised against a **real Godot editor** on every run of the end-to-end
suite, on both Godot 4.4.1 and 4.7.2. See [Testing](#testing).

## Architecture

```
AI Assistant (Claude / other MCP client)
    ↓ (MCP protocol, stdio)
Node.js MCP Server  ──┐
                      ├─→ connect to ws://127.0.0.1:<port>/<token>
Node.js MCP Server  ──┘        (another session, same editor)
    ↑
Godot Editor Plugin (GDScript) — hosts the bridge, publishes port + token
```

**The editor hosts the bridge**, and MCP server processes dial in. It is that way
round because the port is a machine-wide resource and the editor is the long-lived
end: sessions come and go without fighting over it, several can attach at once,
and each open project listens on its own port. The plugin advertises its port and
a per-launch token in `~/.godot-mcp/instances/`, which is how a server finds it.

## What it can do

163 tools in 23 categories: project, scene, node, script, editor, input, runtime,
animation, animation-tree, 3D scene, physics, particles, navigation, audio, tilemap,
theme, shader, resource, batch/refactor, analysis, testing, profiling and export.

**[API reference →](docs/api/README.md)** — every tool with its parameters and a worked
example. It is generated from the tool definitions, and the examples are the calls the
end-to-end suite makes against a real editor, so neither can quietly drift from the code.

## Key features

- **UndoRedo integration** — mutations are committed as editor actions, undoable with Ctrl+Z
- **Smart type parsing** — `Vector2(100, 200)`, `#ff0000`, `Color(1,0,0)` are auto-converted
- **Auto-reconnect** — a session rediscovers the editor on every attempt, so an editor
  restarted mid-session is picked up on its new port
- **Structured errors** — contextual hints on failure
- **2D & 3D** — full support for both workflows
- **Version-gating** — tools declare a supported Godot range and refuse outside it, instead
  of failing somewhere inside the editor

## Quick start

Needs **Godot 4.x** (verified on 4.4.1 and 4.7.2; targets 4.0+) and **Node.js 18+**.

**1. Install the plugin.** Copy it into your project, then enable it in Godot under
**Project → Project Settings → Plugins → Godot MCP**.

```bash
cp -r addons/godot_mcp /path/to/your/godot/project/addons/
```

**2. Build the server.**

```bash
cd server && npm install && npm run build
```

**3. Point your MCP client at it** — in `.mcp.json` or your client's equivalent, with an
**absolute path** to the built entry point:

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

There is no port to configure: the editor picks one and publishes it with a per-launch
token to `~/.godot-mcp/instances/`, and the server reads that. Open your project with the
plugin enabled, and your assistant has the tools.

**[Installation guide →](docs/installation.md)** — per-platform paths, every environment
variable, and what each failure actually means.

## Trimming the tool list

`tools/list` is loaded into the model's context before you ask anything, so its size is
paid every session whether or not a tool is called. All 163 tools cost about **27.7k
tokens**. If you never touch particles, tilemaps or themes, don't carry their schemas:

```bash
GODOT_MCP_PROFILE=core       # 115 tools, ~17.4k tokens (-40%)
GODOT_MCP_CATEGORIES=project,scene,node,script,editor    # or pick exactly what you want
```

Set them in the `env` block of your client config; the default is everything. Which
categories `core` keeps, and the slug for each:
[installation guide](docs/installation.md#choosing-which-tools-to-register).

## Testing

Six layers, fastest first. The first three cost about ten seconds together and need no
editor, so run them before reaching for the suite.

| Command (from the repo root) | Covers | Time |
|---|---|---|
| `cd server && npm test` | version/timeout/bridge logic, 163 tool schemas, generated docs | ~1 s |
| `node e2e/unit.mjs` | plugin coercion rules, headless GDScript | ~2 s |
| `node e2e/check-syntax.mjs` | every plugin script compiles, names file and line | ~6 s |
| `node e2e/run.mjs --godot 4.4.1` | all 163 tools against a live editor, plus on-disk effects | ~4 min |
| `node e2e/multi-session.mjs` | two sessions on one editor, queueing, token checks | ~40 s |
| `node e2e/reconnect.mjs` | a session surviving an editor restart | ~60 s |

The end-to-end suite downloads a Godot distribution, generates a throwaway project, boots
the editor, runs every tool through the full MCP stack, writes a report and cleans up. It
runs on Windows, Linux and macOS; CI exercises the fast layers on all three and the
headless suite on Linux and Windows.

The parse gate earns its place: a typo in any one plugin file stops `plugin.gd` compiling,
so *every* tool disappears and the only symptom the suite reports is `Tool not found`.

Flags, exit codes and design:
[docs/e2e_test_infrastructure.md](docs/e2e_test_infrastructure.md). The executable spec is
`e2e/blocks/*.json`; [docs/mcp_test_plan.md](docs/mcp_test_plan.md) is the original prose
plan, kept for background and stale in places.

## Security

The bridge binds `127.0.0.1` and a client must present the token from the discovery file.
Both matter: WebSocket is exempt from same-origin, so any web page you have open may
connect to `ws://127.0.0.1:<port>`, and `execute_script` runs arbitrary GDScript in your
editor. A page cannot read the token off disk, which is what closes that door. Setting
`GODOT_MCP_HOST` to attach across machines removes the first of those two defences — do it
only on a network you control.

## Project structure

```
godot_mcp_tool/
├── addons/godot_mcp/     # Godot plugin (GDScript)
├── server/               # Node.js MCP server (TypeScript)
│   └── src/tools/        # Tool categories
├── e2e/                  # End-to-end test runner + block definitions
├── docs/                 # API reference, installation, e2e design, changelog
└── progress.md           # Open tasks (closed ones: docs/changelog.md)
```

## Status

- All 163 tools implemented, across 23 categories
- End-to-end suite green: **249/249 tests, 163/163 tools covered** on Godot 4.4.1 and 4.7.2
- Open work: [progress.md](progress.md). What shipped and why each decision was made:
  [docs/changelog.md](docs/changelog.md)

Tested primarily with Claude Code and Claude Desktop. Nothing in the server is
client-specific and the tool set fits Cursor and Windsurf, but neither has been run
against a live editor here yet.

## Troubleshooting

**No `[Godot MCP] Listening on …` in the Godot Output panel** — the plugin never started.
Check it is enabled in Project Settings → Plugins.

**"N Godot editors are running…"** — two or more projects are open and the working
directory does not identify one. Set `GODOT_MCP_PORT` and `GODOT_MCP_TOKEN` from the entry
you want in `~/.godot-mcp/instances/`.

**"Tool not found"** — the plugin is not enabled, the server was not rebuilt
(`server/dist/index.js` must exist), or the tool's category is not registered.

The full list, with what each symptom means:
[installation guide](docs/installation.md#troubleshooting).

## Contributing

Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and feature
requests: [GitHub Issues](https://github.com/radiokilcat/godot_mcp_tool/issues).

## License

MIT — see [LICENSE](LICENSE).

---

**Made for the Godot community.**
