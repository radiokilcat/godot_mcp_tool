# Installation and configuration

The [README quick start](../README.md#quick-start) is the three-step version. This is the
long one: per-platform paths, every configuration knob, how to tell the install actually
works, and what each failure means.

- [What you need](#what-you-need)
- [1. Install the plugin](#1-install-the-plugin)
- [2. Build the server](#2-build-the-server)
- [3. Point your client at it](#3-point-your-client-at-it)
- [4. Check it works](#4-check-it-works)
- [Configuration reference](#configuration-reference)
- [Choosing which tools to register](#choosing-which-tools-to-register)
- [Troubleshooting](#troubleshooting)
- [Upgrading and removing](#upgrading-and-removing)

## What you need

| | Version | Notes |
|---|---|---|
| Godot | 4.x | Verified on **4.4.1** and **4.7.2**; targets 4.0+ |
| Node.js | 18 or newer | The server is ESM and uses `node:` built-ins |

Nothing else is installed globally, and no port has to be free in advance — the editor
picks its own.

## 1. Install the plugin

Copy `addons/godot_mcp/` into your Godot project so that it lands at
`<your project>/addons/godot_mcp/`:

```bash
# macOS / Linux
cp -r addons/godot_mcp /path/to/your/godot/project/addons/
```

```powershell
# Windows (PowerShell)
Copy-Item -Recurse addons\godot_mcp C:\path\to\your\godot\project\addons\
```

Then enable it in the editor: **Project → Project Settings → Plugins → Godot MCP →
Enable**.

The Output panel should show, immediately:

```
[Godot MCP] Listening on ws://127.0.0.1:54321 (advertised in <home>/.godot-mcp/instances/<hash>.json)
```

That line is the install working. The port is chosen by the editor and differs every
launch — you never configure it. If the line is absent the plugin did not start; see
[Troubleshooting](#troubleshooting).

## 2. Build the server

```bash
cd server
npm install
npm run build
```

This produces `server/dist/index.js`, which is what your client runs. Rebuild after
pulling changes — the client executes the built file, not the TypeScript sources.

## 3. Point your client at it

Every MCP client takes the same shape. Use an **absolute path** to `dist/index.js`;
clients start the server with an unpredictable working directory.

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

On Windows, write the path with escaped backslashes (`"C:\\path\\to\\..."`) or forward
slashes — both work in JSON.

| Client | Where the config goes |
|---|---|
| **Claude Code** | `.mcp.json` at the root of the project you are working in |
| **Claude Desktop** (macOS) | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| **Claude Desktop** (Windows) | `%APPDATA%\Claude\claude_desktop_config.json` |
| **Cursor, Windsurf, other MCP clients** | Same `mcpServers` block, in whatever file that client documents |

Claude Code and Claude Desktop are what this project is developed against. The tool set
fits Cursor and Windsurf and nothing in the server is client-specific, but neither has
been run against a live editor here — that is open task 4.2 in
[progress.md](../progress.md), and it is listed as unverified rather than supported.

There is **no port or token to configure**. The editor publishes both to
`~/.godot-mcp/instances/<hash>.json` when it starts, and the server reads that file. With
one editor open there is nothing to choose; with several, the server picks the one whose
project matches its working directory, and otherwise refuses and lists what is running
rather than guessing.

## 4. Check it works

Open your Godot project with the plugin enabled, then ask your assistant for something
cheap and read-only:

> What Godot project am I in?

That runs `get_project_info` and comes back with the project name, path and engine
version. The editor's Output panel logs every call as it arrives:

```
[Godot MCP] MCP client 1 connected (1 attached)
[Godot MCP] client 1 → get_project_info
```

If the client connects but no `client N →` line ever appears, the assistant is not
calling the tools — check that the server is listed as connected in your client, not that
the bridge is broken.

## Configuration reference

All configuration is environment variables, set in the `env` block of your client config:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["/absolute/path/to/server/dist/index.js"],
      "env": { "GODOT_MCP_PROFILE": "core" }
    }
  }
}
```

| Variable | Read by | Default | What it does |
|---|---|---|---|
| `GODOT_MCP_PROFILE` | server | unset | `core` registers 14 of the 23 categories (115 tools) instead of all 163. See [below](#choosing-which-tools-to-register). |
| `GODOT_MCP_CATEGORIES` | server | unset | Explicit comma-separated category list, e.g. `project,scene,node`. Wins over `GODOT_MCP_PROFILE`. An all-typo list falls back to everything rather than registering nothing. |
| `GODOT_MCP_PORT` | both | unset | Pins the port instead of using discovery. On the **plugin** side it fixes the listen port; on the **server** side it bypasses the discovery file entirely. Set it on both ends or neither. |
| `GODOT_MCP_TOKEN` | server | unset | The auth token to present, for use with `GODOT_MCP_PORT`. Without discovery the server has no other way to learn it. |
| `GODOT_MCP_HOST` | both | `127.0.0.1` | Bind address for the plugin, dial address for the server. Only change it to attach across machines, and only on a network you control. |
| `GODOT_MCP_PRETTY` | server | unset | `1` pretty-prints tool results. For reading raw responses by hand; it costs tokens in normal use. |

`GODOT_MCP_PORT` and `GODOT_MCP_TOKEN` exist for the cases discovery cannot cover — the
end-to-end harness pins them, and they are the escape hatch when several editors are open.
Everything else works without them.

## Choosing which tools to register

`tools/list` is loaded into the model's context before you have asked anything, so its
size is paid every session whether or not a tool is ever called. All 163 tools cost about
**27.7k tokens**.

```json
"env": { "GODOT_MCP_PROFILE": "core" }
```

`core` keeps project, scene, node, script, editor, input, runtime, animation, scene-3d,
physics, shader, resource, batch and analysis — 115 tools, about **17.4k tokens (-40%)**.
It drops the categories a project only reaches for occasionally: particles, tilemaps,
themes, audio, navigation, animation trees, testing, profiling and export.

To pick exactly what you want, list the category slugs instead:

```json
"env": { "GODOT_MCP_CATEGORIES": "project,scene,node,script,editor" }
```

The slugs, tool counts and everything each category contains are in the
[API reference](api/README.md).

## Troubleshooting

**No `[Godot MCP] Listening on …` line in the Output panel.** The plugin never started.
Check that the files are at `<project>/addons/godot_mcp/plugin.cfg` (not nested one level
deeper — copying the folder into an existing `addons/godot_mcp/` produces
`addons/godot_mcp/godot_mcp/`), and that the plugin is ticked in Project Settings →
Plugins. The Godot version must be 4.x.

**The line is there but the assistant cannot connect.** Look in
`~/.godot-mcp/instances/` for a `.json` entry whose `project_path` is your project. If it
is missing, the plugin logged an error about publishing the discovery file — set
`GODOT_MCP_PORT` and `GODOT_MCP_TOKEN` on both ends from the port in the Output line.

**"N Godot editors are running and none matches this working directory".** Two or more
projects are open and the server cannot tell which one you mean. Either start the client
from the project directory, or read the port and token out of the entry you want and set
`GODOT_MCP_PORT` and `GODOT_MCP_TOKEN`.

**Tools vanish after the editor restarts.** They should not — the server rediscovers the
editor on every attempt, so a restart on a new port and token is picked up without
restarting the session. If it does not recover, you have pinned `GODOT_MCP_PORT` to a port
the new editor did not take.

**"Tool not found".** Either the plugin is not enabled, or the server was not rebuilt
(`server/dist/index.js` must exist), or the tool's category is not registered — check
whether you set `GODOT_MCP_PROFILE` or `GODOT_MCP_CATEGORIES`.

**A tool reports an unsupported Godot version.** Tools declare a supported engine range
and refuse outside it rather than failing somewhere inside the editor. The per-tool ranges
are in the [API reference](api/README.md).

**Connecting from another machine.** The bridge binds loopback and requires the
per-launch token. Both matter: WebSocket is exempt from same-origin, so any page open in
your browser can reach `ws://127.0.0.1:<port>`, and `execute_script` runs arbitrary
GDScript in your editor. What stops it is that a page cannot read the token off disk. If
you set `GODOT_MCP_HOST` to expose the bridge, you are removing the first of those two
defences — do it only on a network you control.

## Upgrading and removing

To upgrade, replace `addons/godot_mcp/` in your project and rebuild the server:

```bash
cd server && npm install && npm run build
```

Restart the editor so the plugin reloads. The discovery file is rewritten on every launch,
so nothing has to be cleaned up between versions.

To remove it: disable the plugin in Project Settings, delete
`<project>/addons/godot_mcp/`, and drop the `godot` entry from your client config.
`~/.godot-mcp/` can be deleted too; it holds only the per-launch discovery files.
