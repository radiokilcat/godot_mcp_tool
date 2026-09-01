# E2E Test Infrastructure — Design

**Goal:** a single command that provisions a Godot 4.x editor from scratch, runs every MCP tool against it, produces a report, and cleans up after itself.

```
node e2e/check-syntax.mjs --godot 4.4.1   # ~6s syntax gate, run this first
node e2e/run.mjs --godot 4.4.1
```

Related: [mcp_test_plan.md](mcp_test_plan.md) is the test *content* (178 tests, 23 blocks); this document is the *harness* that executes it unattended.

**Run the syntax gate first.** A parse error in any single plugin file makes `plugin.gd` fail to compile, so the entire tool registry disappears and the suite's only symptom is `Tool not found: <anything>` after a four-minute run. `check-syntax.mjs` loads `plugin.gd` with `--check-only`, which compiles the whole dependency graph, and prints the offending file and line in about a second (six with project generation). `--all` additionally checks each `.gd` on its own, for files nothing references yet. Exit codes: 0 clean, 1 syntax errors, 2 could not run.

---

## 1. Pipeline

```
┌─────────────┐   ┌──────────────┐   ┌───────────────┐   ┌────────────┐   ┌─────────┐
│ 1. PROVISION │ → │ 2. GENERATE  │ → │ 3. LAUNCH     │ → │ 4. EXECUTE │ → │ 5. TEAR │
│ download &   │   │ test project │   │ MCP server +  │   │ test blocks│   │ DOWN &  │
│ cache Godot  │   │ + plugin copy│   │ Godot editor  │   │ + asserts  │   │ REPORT  │
└─────────────┘   └──────────────┘   └───────────────┘   └────────────┘   └─────────┘
```

Every stage is idempotent and crash-safe: a `SIGINT`/uncaught error at any point jumps to teardown.

## 2. Workspace layout

All artifacts live under a git-ignored folder in the repo root:

```
.e2e_work/
  cache/                      # SURVIVES cleanup (re-downloading ~60 MB per run is wasteful)
    Godot_v4.4.1-stable_win64/
      Godot_v4.4.1-stable_win64.exe
      Godot_v4.4.1-stable_win64_console.exe
      _sc_                    # empty file → self-contained mode: editor settings stay
                              # here, the user's real Godot config is never touched
  project/                    # DELETED on cleanup — regenerated each run
    project.godot
    icon.svg
    addons/godot_mcp/         # copied from repo working tree (tests current code)
    tests/                    # fixture scripts for run_automated_tests block
  logs/                       # kept for the current run, rotated (last 3 runs)
    godot-stdout.log          # editor output incl. [Godot MCP] plugin logs
    mcp-server.log
  reports/                    # SURVIVES cleanup
    e2e-2026-07-08T14-30-00.json
    e2e-2026-07-08T14-30-00.md
```

## 3. Stage details

### 3.1 Provision — download Godot

- URL template (official builds repo, covers all 4.x incl. prereleases):
  `https://github.com/godotengine/godot-builds/releases/download/{ver}-stable/Godot_v{ver}-stable_win64.exe.zip`
  Fallback: same path on `godotengine/godot` releases.
- Download with Node `fetch` → temp file → verify zip integrity → extract into `cache/`.
- **Cache hit** = exe already present → skip download entirely.
- Drop an `_sc_` marker file next to the exe (self-contained mode) so editor settings/caches are isolated per cached distribution.
- `--godot` accepts a comma list (`--godot 4.2.2,4.4.1`) → the whole pipeline runs once per version, sequentially; the report gains a version dimension.

### 3.2 Generate test project

Written from templates with version substitution (a mismatched `config/features` tag triggers a blocking dialog on editor open — must match the target minor):

```ini
; project.godot
config_version=5

[application]
config/name="mcp_e2e"
config/features=PackedStringArray("{MAJOR}.{MINOR}")
config/icon="res://icon.svg"

[editor_plugins]
enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg")
```

- `addons/godot_mcp/` **copied** (not junction-linked) from the repo — full isolation; the run can't dirty the working tree.
- Fixture files the test plan expects to pre-exist (e.g. `icon.svg`, a `tests/test_example.gd` for the Testing/QA block, a small `.wav`/`.ogg` for Audio) are part of the template set. Everything else the blocks create through the tools themselves.
- **Pre-import pass** before opening the editor, to avoid first-run import churn and dialogs:
  `Godot_...exe --headless --import --path .e2e_work/project` (bounded by a 120 s timeout).

### 3.3 Launch

**Port isolation:** the runner uses WS port **6510** (`--port` to change), passed as `GODOT_MCP_PORT` env to both the spawned server and the spawned editor (both honor it since 2026-07-08; default stays 6505). A live MCP setup on the developer's machine keeps running untouched; a preflight bind-check aborts early with a clear message if the chosen port is busy.

Order matters only for log cleanliness — the plugin auto-reconnects with backoff regardless:

1. **MCP server** — the runner spawns `node server/dist/index.js` over **stdio** and connects with `Client` from `@modelcontextprotocol/sdk` (already a dependency). This exercises the *full production stack*: MCP schema layer → version gating (`version-utils.ts`) → WebSocket bridge → plugin → tool code.
   - `--bridge-only` mode (debug aid): skip the MCP layer, import `server/dist/godot-connection.js` directly and drive `callTool()`. Useful to bisect "MCP layer bug vs plugin bug".
2. **Godot editor** — spawn the **`_console.exe`** variant (the regular Windows exe detaches from the console; the console wrapper makes stdout capturable) with:
   `--editor --path .e2e_work/project --windowed --resolution 1280x720 --position 50,50`
   stdout/stderr piped to `logs/godot-stdout.log`.
   - `--headless` runner flag adds `--headless` to Godot; tests tagged `requires: rendering` (screenshots, input simulation, play_scene-dependent runtime tools) are then auto-**SKIPPED**, not failed.
3. **Readiness gate** — poll `get_editor_version` through the MCP client every 2 s, up to 90 s. Success ⇒ plugin handshake complete (`ready` received, version captured). Timeout ⇒ abort with the tail of `godot-stdout.log` in the report.

### 3.4 Execute

**Test definitions are data, not markdown.** `docs/mcp_test_plan.md` stays the human-readable spec; each of its 23 blocks is ported once into a machine-readable file:

```
e2e/blocks/01-project.json … 23-export.json
```

```jsonc
{
  "block": 1,
  "name": "Project Tools",
  "setup": [],
  "tests": [
    {
      "id": "P-07",
      "tool": "set_project_setting",
      "args": { "setting": "application/config/description", "value": "MCP Test Project" },
      "asserts": [ { "field": "success", "op": "eq", "value": true } ],
      "verify": {
        "tool": "get_project_settings",
        "asserts": [ { "field": "application/config/description", "op": "eq", "value": "MCP Test Project" } ]
      }
    },
    {
      "id": "S-04",
      "tool": "open_scene",
      "args": { "path": "$SCENE_PATH" },              // $VAR substitution from earlier saves
      "save": { "SCENE_ROOT": "root_name" },
      "requires": { "minGodot": "4.3", "rendering": false },
      "negative": false,
      "timeoutMs": 15000
    }
  ],
  "cleanup": [ { "tool": "delete_scene", "args": { "path": "$SCENE_PATH" } } ]
}
```

Assertion DSL mirrors the plan's conventions 1:1 — `eq`, `neq`, `notNull`, `contains`, `gte`, `lte`, `matches` (regex), `errorContains` (negative tests: *absence* of an error when one is expected = FAIL), plus `allElementsMatch` for the "all files end with .gd" style checks. Field paths are dot-paths into the JSON result (`result.nodes.0.name`).

Execution rules:

- **Strictly sequential** — the plugin rejects concurrent calls (`_tool_busy`).
- Per-test timeout: default 20 s (bridge times out at 15 s, so the runner's timeout only fires if the bridge itself hangs).
- **Failure isolation:** a failed test records the exact error text and continues; a failed SETUP step marks the whole block SKIPPED (its tests can't be meaningful) and moves to the next block; CLEANUP always runs.
- **Disconnect tolerance:** tools like `reload_scripts` briefly drop the WS connection. After any "Godot disconnected / not connected" error the runner re-runs the readiness gate (up to 30 s) and retries the test **once** before recording a failure.
- **Runtime-block hygiene:** any block that calls `play_scene` gets an unconditional `stop_scene` in its cleanup, so a crashed game process can't leak into later blocks.
- Known environment-dependent tools (`export_project` without templates installed) are marked `expectGracefulError: true` — pass = structured error, not a hang or crash.
- **Coverage check:** after the run, diff the tool list from MCP `tools/list` against every `tool` referenced across blocks → "tools never exercised" section in the report. Guards against the tool count growing while the plan lags.

### 3.5 Teardown & report

Teardown (always runs, also on Ctrl+C / crash, steps individually try/caught):

1. `stop_scene` best-effort (kill any running game).
2. Close MCP client → server process exits.
3. Kill the editor: `taskkill /PID <pid> /T /F` (the `/T` catches child game processes).
4. Delete `.e2e_work/project/` with retries (Windows releases file locks lazily; 5 attempts × 2 s).
5. `cache/` and `reports/` are kept. `--purge-cache` deletes the distribution too; `--keep-work` skips step 4 for post-mortem debugging.

Report — JSON (machine) + Markdown (human), same data:

```markdown
# E2E Report — 2026-07-08 14:30
Godot 4.4.1-stable | plugin 1.0.0 | win64 | duration 6m 12s
**Result: 171 passed / 3 failed / 4 skipped (178)**

| block | passed | failed | skipped |
|---|---|---|---|
| 1 Project | 8 | 0 | 0 |
| … |

## Failures
### T-03 set_tile_cell — FAILED (1240 ms)
args: {...}
assert: `success == true` → got error: "TileMap node not found: ..."
godot log ±10 lines around the call: ...
```

- Failed tests embed the matching slice of `godot-stdout.log` (the runner timestamps each call, so log lines are correlatable).
- Exit code: `0` all passed/skipped, `1` any failure, `2` infrastructure error (download/launch/handshake) — CI-friendly.

## 4. Runner layout

```
e2e/
  run.mjs                # CLI: --godot 4.4.1[,4.2.2] --headless --bridge-only
                         #      --blocks 1,2,15  --test T-03  --keep-work --purge-cache
  check-syntax.mjs       # CLI: --godot 4.4.1 --all --keep-work
                         #      GDScript parse gate, ~6s; run before the suite
  lib/
    provision.mjs        # URL resolve, download, unzip, cache, _sc_
    project.mjs          # template rendering, addon copy, fixtures, pre-import
    godot-process.mjs    # spawn console exe, log capture, kill tree
    client.mjs           # MCP stdio client wrapper + bridge-only mode + readiness gate
    executor.mjs         # block loop, $VAR store, retries, disconnect recovery
    asserts.mjs          # assertion DSL evaluator
    report.mjs           # JSON + Markdown writers, coverage diff
  blocks/
    01-project.json … 23-export.json
  templates/
    project.godot.tpl  icon.svg  tests/test_example.gd  assets/beep.wav
```

- Plain Node ≥ 18 (built-in `fetch`), ESM, **no new runtime dependencies** — `@modelcontextprotocol/sdk` and unzip (`tar`/`unzipper` alternative: shell out to PowerShell `Expand-Archive`, zero deps) come from `server/node_modules` or the shell.
- Not vitest: a 6-minute strictly-ordered stateful pipeline with external processes fights a unit-test framework; a purpose-built runner is smaller than the config it would need.

## 5. Risks / open items

| Risk | Mitigation |
|---|---|
| First-run editor dialogs (feature-tag mismatch, import) | features tag generated per version; `--import` pre-pass |
| Headless mode breaks rendering-dependent tools | `requires.rendering` tag → auto-skip; default run is windowed |
| Windows file locks block cleanup | retry loop; `--keep-work` escape hatch |
| Editor crash mid-run | process-exit watchdog → remaining tests marked SKIPPED (reason: editor died), report still written, exit code 2 |
| Blocks drift from mcp_test_plan.md | plan doc gains a header note: blocks/*.json are the executable source of truth; coverage diff catches missing tools |
| 4.0–4.3 assert values differ (e.g. `godot_version contains "4.4"`) | version-parameterized asserts: `"value": "{GODOT_MAJOR_MINOR}"` substitution |

## 6. Implementation order (~1.5–2 days)

1. `provision` + `project` + `godot-process` + readiness gate — an editor opens from nothing (½ day)
2. `client` + `executor` + `asserts` + report skeleton — Block 1 (Project) green end-to-end (½ day)
3. Port blocks 2–23 from mcp_test_plan.md to JSON (½–1 day, mechanical)
4. Coverage diff, disconnect recovery, crash watchdog, `--headless` matrix polish
