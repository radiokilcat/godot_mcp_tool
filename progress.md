# progress.md — Godot MCP Tool, open work

**Project start:** 2026-06-29
**History:** closed phases, their rationale, and the dated log of what shipped live in
[docs/changelog.md](docs/changelog.md). This file carries **open work only** — it is read at
the start of nearly every session, so it stays short on purpose (task 9.7.2).

## Where the project stands

- **163 tools across 23 categories, all implemented** (Phases 1-3, closed — see the changelog).
- **Four test layers, fastest first** — run them in this order, each is a superset of the
  previous one's cost:

  | | Command | Covers | Time |
  |---|---|---|---|
  | Unit (server) | `npm test` in `server/` | version-utils, timeout policy, bridge seam, 163 tool schemas, e2e platform layer | ~1 s |
  | Unit (plugin) | `node e2e/unit.mjs` | vector/colour parsing, `_as_bool`, `_max_results`, `_value_to_json` | ~2 s |
  | Parse gate | `node e2e/check-syntax.mjs` | every plugin script compiles, named file and line | ~6 s |
  | E2E | `node e2e/run.mjs --godot 4.4.1` | all 163 tools against a live editor, plus on-disk effects | ~4 min |

  Run all four before calling a change done; the first three cost about 10 seconds together.

- **E2E: 230 passed / 0 failed, 163/163 tools exercised**, green on Godot **4.4.1** and **4.7.2**;
  527 server unit tests and 80 GDScript ones alongside. `e2e/blocks/*.json` is the executable
  spec, not docs/mcp_test_plan.md.
- **CI runs all four layers** (.github/workflows/ci.yml): the fast three on Linux, Windows and
  macOS, the headless suite on Linux and Windows. Windows is the only host verified locally.
- **The suite now checks effects, not just responses** (6.1.1/6.1.2): `verify` re-reads through a
  second tool call, `expectFiles` asserts what landed on disk. That is what a tool answering
  `success: true` for work it did not do cannot survive — it caught two such bugs on its first run.

---

## Phase 4: Lite Mode Implementation

### [ ] 4.1 - Create Lite Mode Tool Set
- [ ] Select 76 core tools from full set
- [ ] Document lite mode capabilities
- [ ] Create conditional tool loading
- **Priority:** MEDIUM
- **Effort:** 2-3 hours

### [ ] 4.2 - Test Lite Mode with Cursor/Windsurf
- [ ] Test with Cursor client
- [ ] Test with Windsurf client
- [ ] Verify performance
- **Priority:** MEDIUM
- **Effort:** 2-3 hours

**Note:** 9.7.1 argues the real saving is in the schemas rather than in counting to 76 — read it
before starting this phase.

---

## Phase 5: Documentation & Configuration

### [ ] 5.1 - Create Comprehensive API Documentation
- [ ] Document all 163 tools
- [ ] Create examples for each category
- [ ] Generate API reference
- **Priority:** HIGH
- **Effort:** 4-5 hours

### [ ] 5.2 - Create Permission Presets
- [ ] Define Claude Code auto-approval preset
- [ ] Create Cursor preset
- [ ] Create Windsurf preset
- [ ] Create custom preset template
- **Priority:** MEDIUM
- **Effort:** 1-2 hours

### [ ] 5.3 - Create Installation Guide
- [ ] Step-by-step installation
- [ ] Troubleshooting guide
- [ ] Configuration guide
- **Priority:** HIGH
- **Effort:** 2-3 hours

*(5.4 closed 2026-09-02 by 9.1.6 — see the changelog.)*

---

## Phase 6: Testing & Quality Assurance

### [ ] 6.1 - Effect-level assertions (rescoped 2026-08-31, was "Unit Testing")
Original scope was per-category unit tests plus 80% coverage. 6.4 made that largely moot for
tool bodies — they are exercised end-to-end against a live editor. What 6.4 does **not** do is
check that a call changed anything: it asserts the tool's *response*, and 6.6 showed the
response is exactly what lies (6.6.1 and 6.6.8 both return `success: true` for work that never
happened). That is the gap worth closing.
- [x] Write tests for type parser — tests/type-parser.test.ts, 26 tests
- [x] 6.1.1 - **Effect-assertion vocabulary. Done 2026-09-03.** Two of the three the task named
  already existed as `verify` (a second tool call after the mutation, used by 26 tests) — reading
  a setting back and re-reading the node tree are both that. The missing one was the filesystem,
  so a test now takes `expectFiles`: a list of `{path, op, value}` against the generated project's
  real files, with ops `exists` / `absent` / `contains` / `notContains` / `matches` / `minSize`.
  It runs after `verify` and, deliberately, **also on `expectError` tests** — "the call failed AND
  left nothing behind" is the half of a negative test that response assertions cannot express.
  Only `res://` resolves: `user://` points inside the self-contained engine build, not the project,
  so a test asserting there would follow the Godot distribution rather than the code under test.
  A failed content assertion **quotes the file** (600 chars) — without it "regex does not match"
  is useless precisely when the tool's own answer is what is in doubt.
- [x] 6.1.2 - **Applied to the silent no-op tools. Done 2026-09-03.** `set_project_setting`
  (P-07, P-07b), `execute_script` (E-08i, E-08j), `create_scene` (S-02, S-11), `save_scene`
  (S-09d, S-12), `delete_scene` (S-10), the node mutations (N-16) and the `add_*` family
  (3D-06b), plus `refactor_signals` (BR-08, BR-08b). 223 tests, up from 218.
  - **P-07b closes the check 6.6.7 deferred here:** int-vs-float is invisible over JSON, so only
    the on-disk literal proves the coercion. It needs an *anchored* regex — `contains "…=1281"`
    also matches `1281.0`, which is the exact bug.
  - **E-08i/E-08j are 6.6.1 in effect form:** a script that writes a file *after* an `await`, and
    its negative twin whose write is real but whose line 2 does not parse.
  - **N-16 and 3D-06b each collapse a whole block into one save:** every mutation before them
    lives only in the editor's memory, so the `.tscn` is the first place their combined result is
    observable outside the tools that reported it.
- **This immediately found two real bugs — see 6.1.4 — which is the entire argument for the task:**
  the suite was green at 218/218 across 163/163 tools with both of them present.
- [x] 6.1.4 - **`connect_signal` and `refactor_signals` did not persist connections
  (found and fixed 2026-09-03 by the new assertions).** Both called `Object.connect()` without
  `CONNECT_PERSIST`. Only connections carrying that flag are recorded by `PackedScene.pack()`,
  which is why the editor's own signal dialog sets it. The connection was otherwise completely
  real — it fired, and `get_node_signals` listed it — so **every response-level check passed**;
  it disappeared when the scene was saved and reopened.
  - `connect_signal` (node_tools.gd:356): connect a signal through MCP, save, reopen — gone.
    Caught by N-16, whose file excerpt showed the `[connection]` line simply absent.
  - `refactor_signals` (batch_tools.gd:558) was worse: it reads connections out of `SceneState`,
    which by definition holds only persistent ones, then reconnected *without* the flag and
    re-packed — so **a rename silently deleted the connection** while reporting `updated: 1`.
    Its only e2e coverage was `dry_run: true` against method names absent from the fixture, so
    the write path had never once executed.
  - **Both fixes carry a regression test verified to fail without them:** N-16, and BR-08b on a
    new fixture (a script with both method names, a Button, a persisted connection, saved).
    Reverting the batch fix fails BR-08b with the connection missing from the 272-byte scene.
- [x] 6.1.3 - **Unit tests. Done 2026-09-03.** Two harnesses, because the pure rules live in two
  languages and neither needs an editor:
  - **Server, vitest — `npm test` in server/, 514 tests in ~0.7 s.** `version-utils` (the parse is
    regex-based and the comparison must be numeric: `4.10` vs `4.9`); the 9.4.1 timeout policy,
    for which `timeoutForCall` is now exported — it is real policy that is easy to break silently;
    the 9.4.3 bridge seam (`getBridge()` throws rather than binding, `setBridge()` substitutes,
    `callTool` routes and propagates failure); and 493 structural checks over all 163 tool
    definitions — no name collisions, every parameter documented, `required` names that exist in
    `properties`, snake_case names, parsable version bounds. That last group is the guard for
    9.7.1, which will rewrite these schemas wholesale.
  - **Plugin, headless GDScript — `node e2e/unit.mjs`, 68 checks in ~2 s**, green on 4.4.1 and
    4.7.2. Covers what 9.3 unified and what the copies used to disagree about: `to_vector2`/
    `to_vector3`/`to_color` across every shape a client sends (including the `"Vector3(0, 2, 5)"`
    shorthand of 6.6.14 and the `"Color(1, 0, 0)"` one that used to push an engine error),
    `floats_in` not reading the digits in a type name as components, `_as_bool` (all three forms,
    including the numeric `1` that eight of nine copies answered `false` for), and `_value_to_json`
    returning structured transforms rather than `str(v)`.
  - `passWithNoTests` is gone from server/vitest.config.ts, along with its `../tests/**` include
    pointing at the directory 9.2 deleted.
- **Two things this found, neither reachable from a response assertion:**
  - **`callTool` threw synchronously** while typed as returning a `Promise` — `getBridge()` raising
    out of a non-`async` function. A caller using `.catch()` without `await` would have taken the
    process down instead of handling it. Now `async`, so a missing bridge arrives as a rejection.
  - **`_as_bool(null)` pushed an engine error on every call:** `bool(null)` is not a valid
    constructor call in GDScript, so it answered `false` *and* printed "Invalid call. Nonexistent
    'bool' constructor" — the same Output-panel spam 9.8 went through the tools to remove. An
    explicit JSON `null` on any boolean argument hit it. Guarded before the `bool()` call.
  - Hence `e2e/unit.mjs` **fails on any `SCRIPT ERROR`, not just on a failed check**: nothing in a
    unit run feeds the engine bad input on purpose, so a pushed error is a defect even when every
    assertion passes. That is exactly how the `_as_bool` bug surfaced — 68/68 green and the engine
    printing an error each time.
- **The harness itself was verified in all three failure modes:** a deliberate wrong expectation
  (exit 1, names the case with expected vs actual), a parse error (reported, not silently green),
  and a pushed engine error (exit 1).
- **Priority:** DONE — 6.1 is closed (6.1.1, 6.1.2, 6.1.3, plus 6.1.4 found along the way).
- **Verified:** **223 passed / 0 failed, 163/163 tools** on 4.4.1 and 4.7.2 (was 218), plus
  514 server unit tests and 68 GDScript ones.
- **One engine fact worth keeping:** Godot 4.7 writes `[node name="X" type="Y" unique_id=982333479]`
  where 4.4 writes `[node name="X" type="Y"]`. A node-header assertion must therefore stop after
  the type and never match the closing bracket — the first version of these four assertions passed
  on 4.4.1 and failed on 4.7.2 for no reason connected to the code under test.

### [ ] 6.2b - Untested paths left over from 6.2 (2026-08-31)
- [ ] 6.2b.1 - **UndoRedo is asserted nowhere.** `grep -ri undo e2e/blocks/` returns nothing, yet "all mutations support Ctrl+Z" is a headline feature. Needs a block that mutates, undoes via the editor's UndoRedo, and re-reads the tree.
- [ ] 6.2b.2 - **Auto-reconnect is not exercised.** The only retry in the suite is client-side in e2e/lib/executor.mjs; the plugin's exponential backoff (1s→60s) has never been tested. Needs a block that kills the bridge mid-run and asserts the plugin comes back.
- **Priority:** MEDIUM

### [ ] 6.5 - Bridge port lifecycle & the multi-session story (discovered 2026-08-31; planned 2026-08-31)
- [x] 6.5.1 - **Graceful shutdown**: `GodotConnection.close()` exists but is wired to no signal, so a closing client leaves an orphaned node process holding 6505 — which then blocks every later session until it is killed by hand. Hook `SIGTERM`/`SIGINT`/`exit`. **Fixed 2026-09-02:** signals were only half the story — an MCP client normally ends a session by closing the pipe, not by signalling, and the SDK's stdio transport listens for `data`/`error` on stdin and never for EOF (verified in the SDK source), while the WebSocket server keeps the event loop alive on its own. `installShutdownHandlers()` (index.ts) now shuts down on stdin `end`/`close`, on `EPIPE` from stdout (a client that vanished without an orderly EOF — also a fatal unhandled error event otherwise), on `SIGINT`/`SIGTERM`/`SIGHUP` (plus `SIGBREAK` on Windows only — registering it elsewhere throws), and releases the socket from a process `exit` handler for any path that bypasses those. `close()` became idempotent, rejects in-flight calls, and **terminates the client sockets before `wss.close()`** — that turned out to be the load-bearing part: ws's internally created HTTP server only finishes closing once every established connection has ended, so with an editor attached the original one-line `close()` would have left the port bound anyway.
- **Verified** on the built server with a fake editor doing the real handshake: stdin EOF → exit 0 and port free in ~13 ms, both with and without an editor attached. Control run (the bridge imported without the handlers) was still alive 3 s after EOF, i.e. the old behaviour. Not covered on this machine: signal delivery — Windows `process.kill` terminates outright rather than raising `SIGINT`/`SIGTERM` in the child, so those paths are code-reviewed, not executed.
- [x] 6.5.2 - **Decide the multi-session story.** Original options were (a) auto-picked port + discovery file, (b) a long-lived broker owning 6505 with thin per-session stdio shims. **Decided 2026-08-31: neither — invert the transport instead (6.5.3-6.5.7).** Analysis below.

**Diagnosis (source-confirmed 2026-08-31)**

The transport direction is inverted relative to the lifetimes involved: the *Node server*
listens (godot-connection.ts:28, bound in the singleton's constructor at import time —
index.ts:39) and the *Godot plugin* dials in (websocket_client.gd:62). The machine-wide
resource is therefore owned by the most ephemeral process in the chain. Three consequences:

*(Line references above are as of 2026-08-31. 9.4.3 has since moved the bind out of import time
into an explicit `openBridge()` in main(), and the tool files call a `callTool()` free function
rather than the singleton — but the direction, and every consequence below, is unchanged.)*

- **Only the first session works.** Session two hits `EADDRINUSE`, sets `_bindError`, and never
  retries the bind (godot-connection.ts:39-46). Even after session one exits and frees the
  port, session two stays dead until the MCP client restarts it. This is not "each session
  runs its own server" — it is "exactly one runs, the rest are corpses with a polite message".
- **One editor socket, last writer wins.** A new connection closes the previous one
  (godot-connection.ts:50-53), so two open Godot projects clobber each other.
- **Slow recovery.** Plugin reconnect backs off to 60s (plugin.gd:321-328), so after the owning
  server dies the editor can take a minute to find its replacement.

**Key enabler:** the Node server is entirely stateless. All 23 files in server/src/tools/ are
thin proxies over `godotConnection.callTool`; a grep for module-level mutable state finds none.
Every piece of real state (gameplay recordings, signal listeners, test reports) lives in
GDScript. There is nothing to share on the Node side except the transport itself — which is
what makes the inversion cheap and removes the whole point of a broker.

**What sharing does and does not buy**

Sharing the *connection* is correct: the shared resource is the editor, one per machine (per
project), and it should own the channel. Sharing the *work* buys almost nothing — the editor is
single-threaded and the plugin already serialises calls, by *rejection* rather than queueing
(plugin.gd:255-257). Worse, editor state is global: one current scene, one selection, one
UndoRedo stack. Two sessions driving one editor will undo each other's edits and swap scenes
under each other. The goal is "sessions come and go without fighting over a port", not "many
agents work in parallel".

**Options considered**

| | Approach | Effort | Main cost |
|---|---|---|---|
| A ✅ | Invert: the **Godot plugin** hosts the WS server, MCP processes are clients | ~1 day | Rewrite the transport on both sides |
| B | Long-lived Node broker owning 6505 + thin per-session stdio shims | 2-3 days | Daemon lifecycle, zombies, version skew after a rebuild |
| C | One process, MCP over Streamable HTTP | ~1.5 days | Client shows a broken server whenever the daemon is down |
| D | Band-aid: retry the bind + per-project port | ~1 hour | No sharing at all; only stops the permanent breakage |

**Decision: A.** It deletes the lifecycle problem instead of managing it — nobody has to "start
the shared server", because the editor is already running and the listener dies with it. N:1
falls out for free, each project listens on its own port (killing the cross-project clobbering
above), and the Node side stays stdio, so `.mcp.json` does not change at all. B was rejected
because its one real advantage — shared server-side state — does not exist here.

**Implementation**
- [ ] 6.5.3 - **Godot-side listener**: replace websocket_client.gd with a server built on `TCPServer` + `WebSocketPeer.accept_stream()`, polling a pool of peers in `_process` (~120 lines).
- [ ] 6.5.4 - **plugin.gd for N peers**: address sends to a peer instead of the single `_send_message` path, drop the reconnect/backoff block (plugin.gd:321-328), heartbeat per peer or server-side pong only (~60 lines).
- [ ] 6.5.5 - **Node side becomes a client**: godot-connection.ts turns into a reconnecting WS client — essentially a mirror of the logic being deleted from plugin.gd (~80 lines).
- [ ] 6.5.6 - **Port discovery**: a project setting or a file under `res://.godot/` that the server reads, so two open projects do not collide again through a different door (~40 lines). Keep the `GODOT_MCP_PORT` override — e2e depends on it (6.4.8).
- [ ] 6.5.7 - **Queue instead of reject**: turn `_tool_busy` (plugin.gd:255-257) into a FIFO queue; with two clients attached, rejection becomes routine rather than exceptional. Raise `TOOL_TIMEOUT_MS` (godot-connection.ts:9) accordingly — 15s now has to cover queue wait, not just execution.
- [ ] 6.5.8 - **Multi-session semantics**: at minimum log a `client_id` on every mutation; consider an advisory lease on mutating tools. Decide this *before* shipping 6.5.3-6.5.7, not after — otherwise the failure mode is rare, timing-dependent "something undid my edit".
- [ ] 6.5.9 - **e2e harness**: the pipeline starts the MCP server before the editor (docs/e2e_test_infrastructure.md, stage 3). With the inversion that order flips, and the server has to wait for the editor's port to appear.
- **Priority:** MEDIUM — **deferred**, scheduled after the 6.6 blockers (6.6.1-6.6.5). 6.5.1 landed on its own (2026-09-02) and takes the everyday pain out of the port collision: a closed session no longer leaves a squatter, so the remaining breakage is only two *concurrent* sessions.
- **Effort:** ~1 day for 6.5.3-6.5.7, plus 6.5.9 on top.

*(6.2, 6.3, 6.4 and the whole 6.6 field report are closed — see the changelog. 6.4 built the
E2E infrastructure; 6.6 is the field report whose 15 fixes the current behaviour rests on.)*

---

## Phase 7: Performance & Optimization

### [ ] 7.1 - Profile Server Performance
- [ ] Identify bottlenecks
- [ ] Optimize tool execution
- [ ] Cache frequently accessed data
- **Priority:** MEDIUM
- **Effort:** 2-3 hours

### [ ] 7.2 - Optimize Plugin Performance
- [ ] Profile memory usage
- [ ] Reduce startup time
- [ ] Optimize message handling
- **Priority:** MEDIUM
- **Effort:** 2-3 hours

---

## Phase 8: Release Preparation

### [ ] 8.1 - Version 1.0 Release
- [ ] Final testing
- [ ] Create changelog
- [ ] Create release notes
- [ ] Tag version 1.0
- **Priority:** HIGH
- **Effort:** 2-3 hours

### [ ] 8.2 - Create Example Projects
- [ ] Simple 2D game example
- [ ] Simple 3D game example
- [ ] Advanced workflow example
- **Priority:** MEDIUM
- **Effort:** 3-4 hours

---

## Phase 9: Tech debt (whole-repo review, 2026-09-02)

First review of the repository as a whole rather than of a feature: reliability, portability,
security, and the token cost every future session pays. Scope was deliberately shallow per tool —
6.6 already went through the tool bodies — and instead followed the import graph, duplicate
helpers, and a handful of live measurements.

**Measured, not inferred** (the rest is source reading): the bridge's bind address, the
`tools/list` payload, the pretty-print overhead, the import-time socket, and the divergence
between the 13 copies of `_resolve_node`.

### [x] 9.4 - Reliability — closed 2026-09-03 (9.4.1-9.4.5)

- [x] 9.4.3 - **Make the connection lazy. Done 2026-09-03.** `godotConnection` was constructed at
  import time (godot-connection.ts:29) and every file in server/src/tools/ imports it, so
  *importing a tool module opened the machine-wide port* — hit while preparing this review:
  merely enumerating the schemas raced a live server on 6505. It blocked 6.1.3 (unit tests of
  server modules). **Fixed:** the module-level `new GodotConnection()` is gone. `openBridge()`
  binds, and main() calls it explicitly; the 163 call sites went from
  `godotConnection.callTool(x)` to a `callTool(x)` free function that resolves the bridge at
  call time. **`getBridge()` throws rather than lazily binding** — a handler reaching it with no
  bridge means main() never ran, which is a wiring bug, and quietly opening a port to paper over
  it is exactly the behaviour being removed. `setBridge()` is the seam for a test, typed against
  a new `GodotBridge` interface (isConnected / godotVersion / pluginVersion / callTool / close)
  rather than the class, so a stub needs no socket. The constructor also takes `{port, host}`
  now, defaulting to the env vars read at construction instead of at import — 6.5.5 needs to
  construct the transport explicitly anyway.
- **Verified both directions.** A check that imports `dist/tools/project.js` and probes the port:
  on HEAD it printed `[Godot] WebSocket server listening on ws://127.0.0.1:6531` from the import
  alone and the port stayed bound (exit 1); after the fix the port is free after both the import
  and a handler call, and the handler fails with the wiring error instead. Startup is unchanged —
  the built server still binds before the MCP handshake (the plugin dials in on a backoff and
  cannot wait for a first tool call) and still frees the port on stdin EOF, i.e. 6.5.1 intact.
  Full e2e after the change: **218 passed / 0 failed, 163/163 tools** on 4.4.1 and 4.7.2.
- [x] 9.4.4 - **Bound the enumerating responses. Done 2026-09-03.** `max_results` with a default of
  500 plus `truncated: true` and a `note` naming how to narrow, on `get_scene_tree`,
  `list_project_files`, `search_in_scripts` — and on **`search_files`**, which the task did not
  name but is the same shape and the same exposure.
  - **Named `max_results`, not `limit`:** the batch and analysis tools already took `max_results`
    with `truncated`, so `limit` would have been a second name for the established convention.
    Their three inline `int(args.get("max_results", 500))` copies now call the shared
    `_max_results()` on the 9.3 base class, so there is no fifth divergent copy to drift.
  - **The cap stops the walk, not just the output** — that is where the cost is. Every collector
    takes it and returns early rather than filtering a finished list.
  - **The off-by-one is handled deliberately and tested:** the list tools collect one *past* the
    cap so "exactly `max_results` files exist" and "there are more" stay distinguishable — comparing
    `size()` to the cap reports truncation for a listing that was complete (P-03c).
    `get_scene_tree` cannot use that trick, so its walk sets an explicit `dropped` flag.
  - **`get_scene_tree` needed a node budget, not a row cap:** `max_depth` cannot bound a wide tree —
    one flat node with 20 000 children is a single level deep. Each shortened node is marked
    `truncated_children: true`, because an agent reading a subtree needs to know *that* list is
    short, not merely that something somewhere was dropped.
  - Negative means no cap, matching how `max_depth` already reads; a malformed value falls back to
    the default rather than to zero, so a bad argument cannot turn a listing into an empty one; and
    `null` is caught before `int()` for the reason 6.1.3 found in `_as_bool`.
- **Measured against HEAD on the *test* project**, which is far smaller than any real one:
  `search_in_scripts` for `func` returned **400 matches** (each a dict of file/line/text),
  `list_project_files` **70** files, `search_files` for `.gd` **66**. Those were the unbounded
  replies, and the ones that 9.4.2 showed vanish entirely past the socket buffer.
- **Verified:** e2e **230 passed / 0 failed, 163/163 tools** on 4.4.1 and 4.7.2 (was 223), 78
  GDScript unit checks, 514 server ones. The seven new e2e tests were confirmed to fail against
  HEAD — except P-03c, which asserts the *absence* of truncation and correctly passes both ways.
- [x] 9.4.5 - **Both minor items. Done 2026-09-03.**
  - **`.gitignore`:** the blanket `*.js` is gone, with its `!tests/**/*.js` exception pointing at
    the directory 9.2 deleted. It was entirely redundant — `tsc` emits only into `server/dist`
    (`outDir` in tsconfig.json) and `dist/` was already ignored one line above — while silently
    swallowing any helper `.js` added anywhere in the repo. Purely preventive: `git status` after
    the change shows nothing newly trackable.
  - **The pending reconnect (plugin.gd) turned out to be more than harmless.** The note said the
    `is_initialized` guard made it a non-event, and for *correctness* it does. But `await` on a
    SceneTreeTimer holds a reference to the awaiting object until the timer fires, so a plugin
    disabled mid-backoff stayed alive for up to `max_reconnect_delay` — a full minute at the top
    of the curve. **Confirmed, not inferred:** a control run with the fix removed prints
    `WARNING: ObjectDB instances leaked at exit`. `_shutdown_plugin` now zeroes the timer's
    `time_left`, so it fires on the next frame and the coroutine resumes, sees the plugin is down,
    and releases it.
  - `_shutdown_plugin` also clears `is_initialized` **first**, before anything that could emit.
    Closing the socket signals a disconnect and a disconnect schedules a reconnect; today that
    emission is deferred to the client's `_process`, which no longer runs, but a shutdown relying
    on that is one refactor away from re-arming the timer it just cancelled.
- **The e2e suite cannot cover this**: its teardown kills the editor with `taskkill`, so
  `_exit_tree` never runs there — the last launch section of both engine logs contains zero
  "Plugin shutdown" lines. The mechanism is covered in the GDScript unit harness instead, and
  verified both ways: with the cancellation removed, the awaiting coroutine stays suspended and
  the engine reports the leak.
- **This sharpened the unit runner too.** It only treated `SCRIPT ERROR` as a defect, so it
  swallowed the plain `WARNING: ObjectDB instances leaked…` and printed nothing but that message's
  orphaned `at: cleanup (core/object/object.cpp:2378)` location line. It now fails on any engine
  `ERROR:` **or** `WARNING:` — a clean run emits neither, so the wider match costs nothing and
  catches the whole class.
- **Verified:** e2e **230 passed / 0 failed, 163/163 tools** on 4.4.1 and 4.7.2, 80 GDScript unit
  checks (was 78), 514 server ones, parse gate clean over all 32 scripts.
- **Priority:** DONE — all five items are closed. The closed writeups for 9.4.1/9.4.2 are in the changelog.

### [ ] 9.5 - Bridge authentication — **precondition for 6.5.3, decide inside 6.5.8**
The bridge authenticates nobody: whoever opens the socket is treated as the plugin, and
godot-connection.ts:50-53 evicts the previous connection ("last writer wins").

Today's blast radius is bounded by direction — a connector *receives* `tool_call`s, so it can
return **fabricated results**, i.e. lie to the agent about the project's state, and steal the
session from the real editor. Unpleasant (the agent acts on forged data) but not RCE.

**After 6.5.3 it becomes RCE**: the plugin listens, and `execute_script` runs arbitrary GDScript
in the editor. Note that WebSocket is exempt from same-origin/CORS, so **any web page open in the
developer's browser can reach `ws://localhost:<port>`** — binding to loopback (9.1.2) does not
cover this.

- [ ] 9.5.1 - Shared secret checked at handshake, stored beside the port file from 6.5.6.
- [ ] 9.5.2 - Reject connections that carry an `Origin` header — the real plugin never sends one,
  a browser always does.
- [ ] 9.5.3 - Lower priority: unify the `res://` prefix check on the write paths. It appears 10
  times across the 6 files that write to disk (scene/script/resource/shader/theme/batch tools),
  i.e. inconsistently. One `_safe_write_path()` on the 9.3 base class. Not a containment boundary —
  `execute_script` is arbitrary by design; that is what 9.5.1 protects.
- **Sequencing:** decide before 6.5.3-6.5.7 ships, not after.

### [x] 9.6 - Platform layer for e2e — closed 2026-09-03
The suite is Windows-only by construction, not merely untested elsewhere: provision.mjs downloads
`Godot_v{ver}-stable_win64` and unpacks via `powershell.exe Expand-Archive`, godot-process.mjs:38
kills the editor with `taskkill /T /F`, and everything keys off `*_console.exe`. So CI on GitHub
Actions is impossible and no outside contributor can run it, while the README promises
cross-platform support.
- [x] 9.6.1 - **Platform layer. Done 2026-09-03.** `e2e/lib/platform/{index,win32,linux,darwin}.mjs`;
  each module answers the same five questions — archive name, binary location, where the `_sc_`
  marker goes, how to unpack, how to kill the editor with everything it spawned. `provision.mjs`
  and `godot-process.mjs` became the flow around it, and `consoleExe` was renamed `binary` at its
  four call sites (the console variant is a Windows-only quirk, not a concept).
  - **Details that are not interchangeable:** Windows needs `_console.exe` because the plain .exe
    detaches from the console and the harness would capture nothing; macOS ships an .app bundle,
    so both the binary and `_sc_` live at `Godot.app/Contents/MacOS/` — writing the marker beside
    the bundle would silently leave self-contained mode off and let the run read and write the
    developer's real editor settings. Extraction is `Expand-Archive` / `unzip` / `ditto` (the last
    preserves the bundle's signature, which an unsigned Godot.app would fail Gatekeeper without).
    Killing is `taskkill /T` on Windows and `process.kill(-pid)` on POSIX, which is why the two
    POSIX modules spawn the editor `detached` — without its own process group there is nothing to
    signal, and a game started by `play_scene` would survive teardown.
  - **The cache directory name is unchanged on Windows**, so existing checkouts do not re-download.
  - **13 unit tests** in `server/tests/e2e-platform.test.ts` (the repo's only JS runner). The
    load-bearing one asserts all three modules implement the same interface: the harness runs on
    one host at a time, so two modules are always untested by simply running the suite.
  - **All seven archive URLs verified live** by HTTP HEAD against the GitHub release assets —
    win64/linux.x86_64/linux.arm64 on 4.4.1 and macos.universal plus the 4.7.2 variants. A name
    typo is otherwise a 404 after the download has begun.
- [x] 9.6.2 - **CI actually runs it now** (.github/workflows/ci.yml). Three jobs matching the test
  layers: `check` (no Godot, ubuntu, node 18/20), `godot-fast` (parse gate + GDScript unit tests on
  **ubuntu, windows and macos**), `e2e` (headless suite on ubuntu and windows). macOS is in the
  fast job rather than e2e deliberately — it is the cheapest run that still downloads, unpacks and
  executes a Godot binary, which is what keeps the darwin module from being dead code. Also fixed
  along the way: the workflow still used `npm install` with a comment claiming package-lock.json
  was gitignored, which 9.1.3 changed; it is `npm ci` now.
- **Honest status: Windows is verified here, Linux and macOS are implemented and unexercised.**
  I cannot run them on this machine; the first CI run is their real test. What *is* verified for
  them: the release URLs resolve, and the interface/shape tests pass.
- **Priority:** DONE

### [x] 9.6b - Two product bugs the first headless run exposed (2026-09-03)
CI runs the suite `--headless`, which had never been tried. It came back 187 passed / **1 failed**,
and the failure was not the harness.

- [x] 9.6b.1 - **`EditorFileSystem.scan()` is asynchronous, so tools read a stale index.** Every
  write path called `get_resource_filesystem().scan()`, which *queues* a rescan and returns
  immediately — the file is still missing from the index when the next tool call arrives. Anything
  reading that index answers zero results with `success: true`: **the whole batch and analysis
  category**. So "create a scene, then refactor across scenes" silently skipped the scene just
  created. Windowed runs hid it because the idle scan usually won the race.
  **Fixed:** `_notify_file_changed()` on the 9.3 base class calls `update_file()` — which registers
  the one path synchronously — and then scans for whatever else moved. Applied to `create_scene`,
  `save_scene`, `delete_scene` (update_file on a vanished path drops it, which is what delete
  wants), `create_script`, `attach_script`'s created file, and `take_screenshot`. Caught by BR-08b,
  the `refactor_signals` write-path test added the same day for 6.1.2.
- [x] 9.6b.2 - **`get_error_log` failed hard on a log it could not open.** It picked the newest
  `*.log` and errored out if `FileAccess.open` returned null — and the newest is exactly the one at
  risk, because the documented flow is `play_scene` → `get_error_log` (6.6.4), so the tool runs
  moments after the game exited and on Windows the file the departing process was writing can still
  refuse to open. Reproduced as an intermittent failure of E-03d across back-to-back runs; a known
  flake would have undermined the CI this task exists to enable. **Fixed:** the candidates are now
  ranked newest-first and tried in turn; only if none open does it error, naming the newest, the
  open error and how many it tried.
- **Both are products of running the suite a way it had never been run.** Neither is
  platform-specific, and neither would have surfaced from the Windows windowed runs alone.

### [ ] 9.7 - Token budget
- [ ] 9.7.1 - **`tools/list` costs ~29k tokens in every session.** Measured against the built
  `dist`: 163 tools, **104 448 characters**, loaded into context before the user asks anything.
  Median tool is 528 chars; the heaviest are `add_collision_shape` (2709),
  `set_particle_material` (2655), `add_rigid_body` (2165), `add_mesh` (2130), `add_camera` (1827).
  This is the substance of Phase 4 — but the saving comes from the schemas, not from counting to
  76: (a) compact the 10-15 heaviest descriptions, where long lists of allowed values duplicate
  the `enum`; (b) make lite/full a `GODOT_MCP_PROFILE` filter in `registerAllTools` rather than a
  separate build; (c) fold rarely used categories (particles, navigation, theme, export,
  profiling) behind one dispatcher tool with an `action` field, removing ~40 top-level
  definitions. Re-run e2e afterwards — the 163/163 coverage diff proves nothing was lost.
- [x] 9.7.2 - **Split this file. Done 2026-09-03.** progress.md was 1181 lines / 96 425 characters
  and was read whole at the start of nearly every session, of which ~90 % was closed Phases 1-3.
  **Done:** open work and current status stay here (**19 KB**), the history moved verbatim to
  [docs/changelog.md](docs/changelog.md) — **~77 KB off every session**, well past the ~20k
  estimated. The split was done by line-range slicing rather than retyping, and checked by a
  script asserting that every non-blank line of the pre-split file still appears in one of the
  two: the only lines not carried over are the rewritten header and the **stale
  "Summary Statistics" block**, which is preserved in the changelog with a note on why it was not
  kept — it claimed "26/26 type parser tests PASSED" for a module 9.2 deleted, and linked a
  BUILD_REPORT.md that exists in no commit. Live status is now stated as the e2e suite reports it.
  Closed sections keep their full rationale in the changelog; what still *binds* open work (the
  6.5.2 transport decision, "Not worth changing") stayed here.
- **Priority:** MEDIUM — 9.7.1 is what is left.

*(9.1 quick wins, 9.2 dead-code deletion, 9.3 shared tool base, 9.4.1/9.4.2 and 9.8 editor
error spam are closed — see the changelog.)*

### Not worth changing (recorded so it is not re-litigated)
- **Thin stateless server + all logic in GDScript** — confirmed by the 6.5 analysis; it is what
  makes the transport inversion cheap. Keep.
- **`execute_script` as arbitrary execution** — a feature, not a hole: 6.6 showed it carries every
  scenario the typed tools miss. Close the channel (9.5), do not narrow the tool.
- **The `{"success": true, ...}` response shape** — consistent across 102 sites, with no return
  lacking `success`/`error`. 6.6's problem was that `success` sometimes lies, which effect
  assertions (6.1.1) fix; the shape itself is fine.
- **JSON e2e blocks** — the declarative format has paid off (23 blocks, 216 tests). Do not port to code.

---

## Notes

- 📝 Update this file after completing each task
- Add new subtasks as they are discovered
- Adjust priorities based on feedback
- Track blockers and dependencies
- Document any architectural decisions
