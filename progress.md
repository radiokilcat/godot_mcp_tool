# progress.md — Godot MCP Tool, open work

**Project start:** 2026-06-29
**History:** closed phases, their rationale, and the dated log of what shipped live in
[docs/changelog.md](docs/changelog.md). This file carries **open work only** — it is read at
the start of nearly every session, so it stays short on purpose (task 9.7.2).

## Where the project stands

- **163 tools across 23 categories, all implemented** (Phases 1-3, closed — see the changelog).
- **Six test layers, fastest first** — run them in this order, each is a superset of the
  previous one's cost:

  | | Command | Covers | Time |
  |---|---|---|---|
  | Unit (server) | `npm test` in `server/` | version-utils, timeout policy, bridge seam, 163 tool schemas, e2e platform layer, generated API docs | ~1 s |
  | Unit (plugin) | `node e2e/unit.mjs` | vector/colour parsing, `_as_bool`, `_max_results`, `_value_to_json` | ~2 s |
  | Parse gate | `node e2e/check-syntax.mjs` | every plugin script compiles, named file and line | ~6 s |
  | E2E | `node e2e/run.mjs --godot 4.4.1` | all 163 tools against a live editor, plus on-disk effects | ~4 min |
  | Multi-session | `node e2e/multi-session.mjs` | two sessions on one editor, the call queue, token enforcement | ~40 s |
  | Reconnect | `node e2e/reconnect.mjs` | a session surviving an editor restart onto a new port | ~60 s |

  Run them all before calling a change done; the first three cost about 10 seconds together.

- **E2E: 249 passed / 0 failed, 163/163 tools exercised**, green on Godot **4.4.1** and **4.7.2**;
  549 server unit tests and 94 GDScript ones alongside. `e2e/blocks/*.json` is the executable
  spec, not docs/mcp_test_plan.md — and since 5.1 it is also where the API reference's examples
  come from, so a stale example fails the suite.
- **CI runs every layer and is green** (.github/workflows/ci.yml): the fast three on Linux, Windows
  and macOS, the headless suite plus the multi-session and reconnect checks on Linux and Windows.
  Linux went green with 9.6.4; Windows is the only host also verified locally.
- **The editor hosts the bridge; MCP sessions dial in** (6.5). It picks its own port and publishes
  it with a per-launch token to `~/.godot-mcp/instances/`. Several sessions can drive one editor,
  and each open project listens separately.
- **The suite now checks effects, not just responses** (6.1.1/6.1.2): `verify` re-reads through a
  second tool call, `expectFiles` asserts what landed on disk. That is what a tool answering
  `success: true` for work it did not do cannot survive — it caught two such bugs on its first run.

---

## Phase 4: Lite Mode Implementation

### [x] 4.1 - Lite Mode — delivered by 9.7.1 (2026-09-05)
- [x] Conditional tool loading — `GODOT_MCP_PROFILE=core` and `GODOT_MCP_CATEGORIES`, filtering in
  `registerAllTools` rather than as a separate build.
- [x] Documented — README "Trimming the tool list".
- [x] ~~Select 76 core tools from full set~~ — **selection is by category, and the count is not the
  target.** A hand-listed 76 rots the moment a tool is added, and tool count barely tracks cost:
  `runtime` is 19 tools in 5.8k characters, `scene-3d` is 6 tools in 8.4k. `core` is 115 tools and
  **40% cheaper** than the full set, which is the number that actually mattered.
- **Effect:** ~29.2k → ~17.4k tokens per session for a client that opts in.

### [ ] 4.2 - Test Lite Mode with Cursor/Windsurf
- [ ] Test with Cursor client
- [ ] Test with Windsurf client
- [ ] Verify performance
- **Priority:** MEDIUM — the mechanism is shipped and unit-tested; what is left is confirming those
  two clients behave with a reduced set, which needs the clients themselves.
- **Effort:** 2-3 hours

---

## Phase 5: Documentation & Configuration

### [x] 5.1 - API documentation — done 2026-09-06
- [x] All 163 tools documented — `docs/api/`, an index plus one page per category.
- [x] Examples for every tool (not just every category) — 163/163.
- [x] Generated, not written: `npm run docs` in server/ renders it from the tool definitions.
- **Generated because a hand-written page for 163 tools is stale the day after it is written**,
  and wrong documentation is worse than none — an agent that reads a parameter which no longer
  exists spends its turn on a call that cannot work. `server/src/docs/api-reference.ts` is a pure
  renderer over the same objects the server registers; `generate.ts` is the thin CLI around it.
- **The examples are the e2e blocks' own arguments**, which is the half that makes this hold up.
  Invented examples are a second thing to keep true. These are executed against a live editor on
  every CI run, so an example that stops working fails the suite before it can mislead anyone.
  Coverage is 163/163 because the suite already exercises every tool, and 162 of them cite a
  numbered test rather than an unasserted setup step.
- **`tests/api-docs.test.ts` is what stops the drift** (5 checks, in `npm test`): the checked-in
  files must equal what the renderer produces, every category needs a page, every tool an example,
  every declared parameter a row. **Verified to fail**: editing one description in the generated
  `node.md` fails with "docs/api/node.md is out of date" and the command that fixes it.
- Linked from the README's category table; 240 relative links and anchors across the docs verified
  to resolve.

### [x] 5.3 - Installation guide — done 2026-09-06
- [x] Step-by-step installation — `docs/installation.md`, with the per-OS copy commands, the
  Output-panel line that means the plugin actually started, and where each client's config lives.
- [x] Troubleshooting — symptom → what it means → fix, including the failures this project has
  actually hit: no listening line, a missing discovery entry, several editors open, a pinned
  `GODOT_MCP_PORT` surviving an editor restart.
- [x] Configuration — all six environment variables in one table, each with which side reads it.
  `GODOT_MCP_PRETTY` was undocumented anywhere before this.
- **It deepens the README rather than repeating it**: the README keeps the three-step start and
  links out. Every number in it was re-derived from the registry rather than copied from the
  README — 163 tools, 115 under `core`, 14 categories kept and the 9 dropped named explicitly.
- **Cursor and Windsurf are described as unverified, not supported**, because 4.2 is still open and
  neither has been run against a live editor here.

### [ ] 5.2 - Create Permission Presets
- [ ] Define Claude Code auto-approval preset
- [ ] Create Cursor preset
- [ ] Create Windsurf preset
- [ ] Create custom preset template
- **Priority:** MEDIUM
- **Effort:** 1-2 hours
- **Two of the four items are blocked by the same thing as 4.2** (noted while writing 5.3): a
  preset is a permission format, and Cursor's and Windsurf's are not Claude Code's. Writing them
  from memory is the failure mode 5.1 exists to avoid — documentation that looks authoritative and
  is wrong. The Claude Code preset and the generic template can be written now; the other two need
  the clients. `.claude/settings.json` in this repo is already a working example of the first.

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

### [x] 6.2b - Untested paths left over from 6.2 — closed 2026-09-06
- [x] 6.2b.1 - **UndoRedo. Done 2026-09-06 — `e2e/blocks/24-undo.json`, 15 tests, and it found
  three product bugs.** `grep -ri undo e2e/blocks/` returned nothing while "all mutations support
  Ctrl+Z" sat on the README's front page. It does not: **every multi-step undo in the plugin was
  broken**, and no response-level assertion could have said so.
  - **Driven through `execute_script`, because there is no other way in.**
    `EditorUndoRedoManager` — what `EditorPlugin.get_undo_redo()` hands the tools — **exposes no
    `undo()` or `redo()` to scripting at all** (checked with `ClassDB.class_get_method_list`, not
    assumed). The only route is `get_history_undo_redo(get_object_history_id(node))`, which returns
    the plain `UndoRedo` that does. The block asserts the *action name* it undid as well, since
    that is what makes the change a Ctrl+Z away in the editor's own menu rather than merely
    reversible by hand.
- [x] 6.2b.1a - **Undo operations run in the order they are registered, NOT reversed.** Two sites
  said "LIFO undo order" in a comment and registered accordingly. Probed directly: three undo ops
  registered first/second/third run first, second, third.
  - `delete_node`: owner and `move_child` ran while the node was still parentless, failed, and
    `add_child` then appended it **last and unowned** — listed by `get_scene_tree`, absent from the
    saved `.tscn`. That is the 6.1.4 shape exactly: the tool's answer and the tree both agree, and
    the file disagrees.
  - `move_node` was worse than a wrong index: `add_child` refuses a node that still has a parent,
    and the `remove_child` that followed detached it, so **undoing a move left the node in no scene
    at all** — confirmed by reverting the fix, which empties Keeper out of the saved file entirely.
  - Same defect verbatim in `animation_tree_tools._delete_animation_tree_node`, which is a copy of
    the old `_delete_node`. **Covered by test since 2026-09-06 (AT-09..AT-12), not by inspection** —
    and writing that coverage found the gap underneath it: every existing AT test passes a
    `state_name`, so the tool's *other* branch, the one that removes the AnimationTree node from
    the scene, **had never once executed**. Exactly the hole `refactor_signals` turned out to have
    in 6.1.4. AT-09 adds a third child on purpose: with AT last, restoring it at the wrong index
    and appending it are the same position, and the assertion would prove nothing. Both symptoms
    reproduce on AT-11/AT-12 when the old registration is put back.
- [x] 6.2b.1b - **`delete_node` freed the node it had just restored.** It registered
  `add_do_reference` on the deleted node. A reference is erased together with the branch it is
  registered on, and for a deletion the node lives on the *undo* branch; registered on the do
  branch, the first edit after an undo discards the redo tail and frees a node that is back in the
  scene. Caught by UR-10 as `Nonexistent function 'get_path' in base 'previously freed'`.
- [x] 6.2b.1c - **Five creation sites registered the new node on _both_ branches**, which frees it
  while it is alive in the scene — `_add_node`, `_duplicate_node`, `_add_to_scene` on the 9.3 base
  class (13 `add_*` tools across audio, physics, particles, navigation and scene-3d),
  `create_animation_tree`, and `set_environment`'s WorldEnvironment.
  - **Isolated against the engine rather than argued**: with both references `clear_history()`
    frees the node and the parent loses the child; with the do reference alone it survives. The
    same happens when `UndoRedo` trims the oldest action off the tail. The editor discards a
    scene's history when the tab closes, so this is ordinary use, not a corner.
  - **The e2e damage is wider than one node and completely silent.** With the registration
    restored on `add_node`, UR-14/UR-15 fail and the saved scene comes back holding *only its
    root* — every child gone, and **not one `ERROR` line in the editor log**. The precise chain
    inside the block is not claimed; the probe is the mechanism, the block is the guard.
- **Each fix was verified to fail without it**, separately: the two orderings by reverting each in
  turn, the reference bugs by restoring each registration.
- **Engine facts worth keeping:** undo ops run in registration order; `EditorUndoRedoManager` has
  no scriptable `undo()`; UndoRedo references are per-branch, and registering an object on both
  branches is not belt-and-braces — it is a free of a live object.
- **Verified:** e2e **249 passed / 0 failed, 163/163 tools** on 4.4.1 and 4.7.2 (was 230), 544
  server unit tests, 94 GDScript, parse gate clean, multi-session 11/11, reconnect 9/9.
- [x] 6.2b.2 - **Reconnect. Done 2026-09-05 — `node e2e/reconnect.mjs`, 9/9.** The task predated
  6.5, which moved the retry loop to the other side of the wire and made this sharper rather than
  softer: the restarted editor comes back on **a different port with a different token**, so
  recovery depends on the client *rediscovering* rather than caching its target — and that loop
  was two days old with no coverage at all. Restarting the editor is an ordinary part of working
  in Godot and the failure mode is silent: tools simply stop working.
  - The test runs the server in **discovery mode** (cwd, no `GODOT_MCP_PORT`), because pinning the
    port — as the main suite does — would make it vacuous: a pinned client can never recover, and
    pinning the *new* port after the fact would test nothing.
  - Checks: the session works, a call while the editor is down fails with a diagnosable message
    rather than hanging, the restarted editor is a different process with a fresh token, and **the
    same server process recovers without being restarted**.
  - **Verified to fail without the behaviour it claims:** caching the resolved target instead of
    rediscovering leaves the session on the dead port permanently — `ECONNREFUSED 127.0.0.1:51827`.
  - **Found a defect in the harness, not the product:** `waitForInstance` returned the *stale*
    entry after a restart. An editor killed outright never runs `_exit_tree`, so it never withdraws
    itself, and the helper matched a dead pid. It now skips dead pids — as the server already did
    via `isAlive` — and takes `notPid` to wait for a genuinely different editor.
- **Priority:** DONE — both items closed. The README's front-page claims are now each covered by
  something that fails when the claim stops being true.

### [x] 6.5 - Bridge port lifecycle & the multi-session story — closed 2026-09-03
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

**Implementation — all of it landed 2026-09-03, together with 9.5.**
- [x] 6.5.3 - **Godot-side listener**: `addons/godot_mcp/websocket_server.gd`, `TCPServer` +
  `WebSocketPeer.accept_stream()` polling a peer pool in `_process`. Carries the 9.4.2 buffer
  sizes per peer, drops a connection that opens a socket and never finishes the handshake, and
  checks the token the moment a peer reaches OPEN.
- [x] 6.5.4 - **plugin.gd for N peers**: sends are addressed to a peer, the whole reconnect/backoff
  block is gone, and so is the heartbeat — liveness is now the dialling side's problem, and the
  plugin only answers `ping` with `pong`. `websocket_client.gd` and `heartbeat.gd` are deleted.
- [x] 6.5.5 - **Node side becomes a client**: godot-connection.ts is a reconnecting WS client,
  which is the logic deleted from plugin.gd, moved to the side that should own it. It
  **rediscovers on every attempt** rather than caching the first answer — an editor restarted
  mid-session comes back on a different port with a different token, and a cached target would
  mean a session never recovers from something that simple.
- [x] 6.5.6 - **Discovery**: `~/.godot-mcp/instances/<project hash>.json`, holding port, token,
  project path and pid. **The plan's `res://.godot/` could not work**: nothing tells the server
  where the Godot project is — `.mcp.json` carries an absolute path to the *server* and the
  client's working directory is arbitrary — so a project-local file is findable only by someone
  who already knows the answer. Machine-wide also gives the multi-project story for free.
  `GODOT_MCP_PORT`/`GODOT_MCP_TOKEN` still override, which e2e depends on (6.4.8).
- [x] 6.5.7 - **Queue instead of reject**: `_tool_busy` became a FIFO. `_running` guards
  re-entrancy rather than threads — a tool body awaits, which returns to the main loop, which can
  deliver the next message and re-enter the pump mid-flight. A client that disconnects has its
  queued calls dropped rather than spending the editor's single thread on a result nobody will
  read. The client's timeout gained 30 s of queue slack on top of the 9.4.1 budget.
- [x] 6.5.8 - **Multi-session semantics**: every tool call logs `client N → tool`. Editor state is
  global — one current scene, one selection, one UndoRedo stack — so the question about any change
  is *which* session made it; without attribution the failure mode is a rare, timing-dependent
  "something undid my edit" with nothing in the Output panel to trace. An advisory lease was
  considered and not taken: it adds a protocol and a lock to something no evidence says is a
  problem yet, and the log is what would tell us whether it is.
- [x] 6.5.9 - **e2e harness**: the order flipped. The editor launches first, `waitForInstance()`
  polls the registry for an entry whose `project_path` is the generated project — **matched on the
  path, not "the newest entry", because a developer's own editor may be running and driving that
  would edit their real scenes** — and only then is the MCP server started, with the port and token
  passed explicitly.
- **`e2e/multi-session.mjs` is new and is the point of the whole task.** The main suite drives one
  client and would pass just as well against the old direction. This checks what actually changed:
  the editor picks its own port, two sessions attach to one editor and both work, concurrent calls
  queue instead of one being told "another tool call is already in progress", one session leaving
  does not disturb the other, and the token is enforced in both directions. **11/11.**
- **Verified:** e2e **230 passed / 0 failed, 163/163 tools** on 4.4.1 and 4.7.2, **188 passed /
  42 skipped** headless, 535 server unit tests, 80 GDScript, parse gate clean.

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

### [x] 9.5 - Bridge authentication — closed 2026-09-03 with 6.5 (9.5.3 remains, see below)
The bridge authenticates nobody: whoever opens the socket is treated as the plugin, and
godot-connection.ts:50-53 evicts the previous connection ("last writer wins").

Today's blast radius is bounded by direction — a connector *receives* `tool_call`s, so it can
return **fabricated results**, i.e. lie to the agent about the project's state, and steal the
session from the real editor. Unpleasant (the agent acts on forged data) but not RCE.

**After 6.5.3 it becomes RCE**: the plugin listens, and `execute_script` runs arbitrary GDScript
in the editor. Note that WebSocket is exempt from same-origin/CORS, so **any web page open in the
developer's browser can reach `ws://localhost:<port>`** — binding to loopback (9.1.2) does not
cover this.

**Engine constraints, probed on 4.4.1 before designing anything (2026-09-03).** Both answers
came from a live `TCPServer` + `WebSocketPeer.accept_stream()` connection, not from the docs:

- **`get_requested_url()` works on the accepting side** and returns the full URL the client asked
  for, path and query included (`ws://127.0.0.1:58591/mcp/tok3n?q=1`). So the URL is a usable
  channel for the shared secret.
- **`get_handshake_headers()` returns `[]` on the accepting side.** It is the property of headers a
  peer *sends*, not the request it received — so **a Godot listener cannot see `Origin` at all**,
  and there is no peek on `StreamPeerTCP` to read the request before `accept_stream` consumes it.

- [x] 9.5.1 - **Shared secret. Done 2026-09-03.** 256 bits from `Crypto.generate_random_bytes`,
  fresh per editor launch, published in the discovery file (0600 where the OS has a notion of it —
  GDScript has no chmod, so that is a `chmod` subprocess, and a no-op on Windows where the profile
  is the boundary). It travels in the **URL path**, because the probe above proved headers are
  unreachable; the plugin compares it the moment the peer reaches OPEN, in constant time, and on a
  mismatch closes with application code **4001 and a reason**. That last part is deliberate: a
  browser learns nothing it did not already know, while a *real* client that read the wrong
  discovery file gets something diagnosable instead of a silent drop, and the Node side turns 4001
  into a message naming the file it took the token from.
- **Verified end to end**, not just at the unit level: `e2e/multi-session.mjs` connects a raw
  WebSocket with a wrong token and asserts close code 4001, then connects with the right one and
  asserts it opens.
- [x] 9.5.2 - **Not implementable as written, and 9.5.1 subsumes it (2026-09-03).** The Origin check
  was defence in depth against a web page reaching `ws://localhost:<port>`, since WebSocket ignores
  same-origin. The probe above shows the header never reaches the listener. It costs nothing:
  a page cannot read the token file off disk, so the secret already closes that door — the Origin
  check would only have rejected the same connection one step earlier. Recorded rather than
  silently dropped, so it is not re-proposed.
- [ ] 9.5.3 - Lower priority: unify the `res://` prefix check on the write paths. It appears 10
  times across the 6 files that write to disk (scene/script/resource/shader/theme/batch tools),
  i.e. inconsistently. One `_safe_write_path()` on the 9.3 base class. Not a containment boundary —
  `execute_script` is arbitrary by design; that is what 9.5.1 protects.
- **Sequencing held:** 9.5.1 was designed and shipped in the same change as 6.5.3-6.5.9, so the handshake was never built twice.

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
- [x] 9.6.3 - **The first CI run found the thing only a clean checkout can (2026-09-05).**
  `check-syntax.mjs` and `unit.mjs` failed on **all three** platforms with
  `ENOENT … .e2e_work/logs/syntax-check.log`. `.e2e_work` is gitignored in full, so on a fresh
  checkout the `logs/` subdirectory does not exist — and only `run.mjs` happened to create it.
  Every developer machine has it left over from an earlier run, which is exactly why it passed
  locally and had done for months. `multi-session.mjs` carried the same latent bug, masked because
  CI runs it after `run.mjs`.
  **Fixed where the file is written** — `preImport` and `launchEditor` create the log's directory
  themselves — rather than in each caller, since depending on call order is what let the callers
  diverge in the first place. Verified by deleting `.e2e_work/logs` and running all three.
  **This is the whole argument for 9.6 in one bug:** a suite that only ever runs on machines with
  history cannot tell you what a stranger's machine does.
### [x] 9.6.4 - `GodotMCPScriptCheck` returned nothing on Linux — closed 2026-09-06
E2E on ubuntu was **185 passed / 3 failed / 42 skipped**, and all three failures were one defect:
SC-05 (`validate_syntax`), E-08g and E-08h (`execute_script`) each fell back to the pre-6.6.5
message — "code 43", no line, no reason — because `check_source` produced an empty array. Nothing
else was affected: the rest of `execute_script`, the transport, and every other tool passed, and
the same suite was green on windows-latest, so it was the platform and not the tool.

**The cause was the cache directory — the thing this entry had filed under "not obviously it".**
`_cache_file()` scratches in `OS.get_cache_dir()`, which on Linux is `$XDG_CACHE_HOME` or
`~/.cache` and **the engine does not create it**. `FileAccess` will not create intermediate
directories, so on a fresh runner the probe write returned null, `check_source` returned `[]`, and
the tool answered with its fallback. Windows never hit it because its cache dir always exists.
`_cache_file` now creates the directory and falls back to `user://`, which always does.

**The recorded lead was wrong.** It was the absolute path vs `res://` — the fourth plausible
explanation for a CI failure that week not to survive contact, which is exactly why the entry said
it would not be acted on until a run said so. Worth keeping as a pattern: on an unreproducible
platform the cheap move is to ship the instrumentation and let the run answer, not to pick the most
convincing story.

**And the diagnostics never got to speak.** The fix rode in the same commit (6a05beb) as the
explanation for its absence, so it removed the failure before its own message could ever print.
Confirmed by **CI going green on b0aee56** — the commit that still records this as open: the only
behavioural change between the failing run and that one is the cache-dir creation; everything else
in it is message text.

**The instrumentation stays, on its own merit.** A tool that says "code 43" about its own failure
is the same complaint 6.6.5 existed to fix. `check_source`/`check_path` now take a status
dictionary and record *why* they had nothing — the open error and path if the probe could not be
written, or the subprocess's exit code and the tail of its output — and `describe()` appends it to
the fallback. The next platform that breaks this way explains itself in one run.

- **Status: Windows and Linux are exercised by CI on every push; macOS runs the fast three
  layers** (parse gate plus the GDScript unit harness), which is the cheapest run that still
  downloads, unpacks and executes a Godot binary and keeps the darwin platform module from being
  dead code. Windows is the only host also verified locally.
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

### [x] 9.7 - Token budget — closed 2026-09-05
- [x] 9.7.1 - **Done 2026-09-05. 105 064 → 99 677 chars for everyone (-5.1%), and 62 779
  (-40.2%, ~17.4k tokens) for a client that opts into `GODOT_MCP_PROFILE=core`.**

  **The payload is not shaped the way this task assumed, and measuring first changed the plan.**
  Broken down: parameter descriptions 30%, tool descriptions 22%, **JSON structure 37%**,
  identifiers 10%, enum values 1%. So prose is 52% and the structural overhead of 481 parameters
  (`{"type":"string","description":…}` around every one) is another 37% that no amount of editing
  reaches. **To cut this materially you have to not send tools, not write shorter sentences.**

  - **(a) compacting descriptions that duplicate their `enum` — mostly a non-issue.** Of 12
    candidates, nine explain what each *value means* ("'2d' — attenuates with distance in 2D"),
    which the enum does not carry and an agent needs. Only two were pure restatement; both
    trimmed, 62 characters. Recorded because the assumption looked much bigger than it was.
  - **The real duplication was in schemas, not prose.** 33 parameters spelled out an `anyOf` of
    three branches — 10 134 chars, a tenth of the payload — copied across four files.
    `server/src/tools/schemas.ts` now holds one compact form each. A JSON Schema `type` may be a
    list, and the array keywords still apply when the value *is* an array, so `[1, 2]` is still
    rejected for a Vector3 — which matters, because the plugin would coerce it to the default and
    report success, exactly the 6.6.14 bug class. **−5 325 chars, no information lost.**
  - **(b) `GODOT_MCP_PROFILE` shipped**, plus `GODOT_MCP_CATEGORIES` for an explicit list.
    Selection is **by category, not by naming 76 tools**: a hand-listed subset rots as soon as a
    tool is added, and tool count is a poor proxy for cost anyway — `runtime` is 19 tools in 5.8k
    chars while `scene-3d` is 6 tools in 8.4k. A list that is all typos falls back to everything,
    because registering nothing reads as a broken build rather than a bad env var.
  - **(c) the dispatcher tool: deliberately not done.** Folding the five "rarely used" categories
    saves 18.5% — less than `core` already gives, and it buys that by making 22 tools worse. A
    dispatcher is only small if it *omits* its actions' schemas, and then the model has to guess
    arguments or make a discovery round trip first; if it documents them the characters come
    straight back. It would also mean rewriting those tools and their e2e blocks. The profile
    filter gets the same saving for anyone who wants it and costs those who do not nothing.
- **Verified:** e2e **230 passed / 0 failed, 163/163 tools exercised** on 4.4.1 and 4.7.2 — the
  coverage diff is what proves the schema rewrite dropped nothing — plus 544 server unit tests
  (9 new on profile selection, including that `core` stays a strict subset and keeps the tools a
  session reaches for first) and the multi-session check at 11/11.
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
- **Priority:** DONE — both items closed.

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
