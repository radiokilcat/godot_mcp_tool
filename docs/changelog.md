# Changelog — closed work

The history half of [progress.md](../progress.md), split out on 2026-09-03 (task 9.7.2).
Everything here is **done and verified**; open work stays in progress.md, which is what a
session needs to read. Sections are copied verbatim from progress.md, so the rationale,
the measurements and the engine facts recorded alongside each fix are unchanged.

Read this when you need *why* something is the way it is — the reasoning behind a closed
decision, what a fix actually changed, or which engine behaviour forced a workaround.

---

## Dated log — what shipped, newest first

**Last Updated:** 2026-09-03 (**9.4.3 and 9.7.2 done.** The bridge is no longer opened by an
import: `new GodotConnection()` at module scope is replaced by an explicit `openBridge()` in
main(), and the 163 call sites now go through a `callTool()` free function. `getBridge()`
deliberately *throws* instead of lazily binding — quietly opening a machine-wide port to cover a
wiring bug is the behaviour being removed — and `setBridge()` plus a narrow `GodotBridge`
interface give 6.1.3 a socket-free seam. Verified against HEAD both ways: importing
`dist/tools/project.js` used to bind the port from the import alone, now it does not, while the
built server still binds at startup and frees the port on EOF. And progress.md went **96 KB →
19 KB**, with the history moved verbatim into this file and a script asserting no line was lost.
**218 passed / 0 failed, 163/163 tools** on 4.4.1 and 4.7.2. Next: 6.1.1 effect assertions —
now unblocked on both sides, by 9.3 and by 9.4.3.)

**Previously:** 2026-09-02 (**9.3 done — the 23 tool classes now share one base**, `GodotMCPToolBase`. Net **−714 lines**, and `_resolve_node` is one implementation instead of 6 across 13 files. Two of the disagreements between the old copies turned out to be bugs: `_as_bool` answered `false` for a numeric `1` in 8 of 9 files, and `_parse_color` in two files pushed an engine error for the project's own `"Color(1, 0, 0)"` shorthand. The 4.0-incompatible `make_dir_recursive_absolute` that 3.17b fixed in one of three places is gone from the other two. 218/218 on 4.7.2 and 4.4.1 after every stage. Next: 6.1.1 effect assertions, or 9.5+6.5.3 (auth + transport inversion) as one piece.)

**Previously:** 2026-09-02 (**9.4.1 and 9.4.2 done — the two remaining defects a live user could hit.** Timeouts are now derived per call from the tool's own `timeout`/`duration` argument (plus a table for the inherently slow ones), so `listen_to_signal` at 30 s and `execute_script` at 60 s can finally return; and the WebSocket buffers are 4 MB instead of Godot's 64 KB default, with an explicit "result could not be sent, narrow the request" reply if a payload still will not fit. Both carry regression tests (E-11, E-12) that were **verified to fail without the fix**. **218 passed / 0 failed, 163/163 tools** on 4.7.2 and 4.4.1. Next: 9.3 (shared tool base class) before 6.1.1.)

**Previously:** 2026-09-02 (**9.2 done — ~1530 lines of dead code deleted**, 8 files plus the one unit test, which covered a module nothing imported. Verified before and after: repo-wide search over every tracked file type, `class_name` cross-check against actually declared names (which caught a false negative in the review — undo_redo_manager.gd declares `GodotMCPUndoRedo`), config/preload checks, then a clean rebuild, `check-syntax --all` over all 31 remaining scripts, and **216/216, 163/163 tools on both 4.7.2 and 4.4.1**. Next: 9.4.1/9.4.2, then 9.3 before 6.1.1.)

**Previously:** 2026-09-02 (**9.8 done — the editor's error spam during tool calls is mostly gone**, 33 lines per run → 18 on 4.4.1 / 14 on 4.7.2, and what remains is the suite deliberately feeding the parser broken code. Two were real product bugs users would also hit: `execute_script` ran its body inside the deferred-call flush, so anything touching the filesystem spammed progress-dialog errors; and `create_animation` used `get_animation_library()` as an existence check, which the engine logs as a failure. 216/216 on both engines. One lesson recorded in 9.8: a zero-length SceneTreeTimer is *not* a safe substitute for `call_deferred` — a body that pumps the main loop re-fires the still-pending timer and takes the editor down with a stack overflow.)

**Previously:** 2026-09-02 (**9.1 quick wins done** — compact tool responses, loopback-only bridge, committed lockfile, docs reconciled with the built registry, `.gitattributes`, `.mcp.json.example` (which also closes 5.4.1). Full e2e re-run on both engines after the changes: **216 passed / 0 failed, 163/163 tools** on 4.4.1 and 4.7.2. Next: 9.2 (delete the dead code), then 9.3 before 6.1.1.)

**Previously:** 2026-09-02 (**whole-repo tech-debt review → new Phase 9**, 9.1-9.7 above.) Headlines: the bridge listens on every interface and authenticates nobody (a hard precondition for 6.5.3, not a standalone nicety); tool responses are pretty-printed at +233 % characters; `tools/list` costs ~29k tokens per session; ~1530 lines are dead, including the one module the project's only unit test covers; `_resolve_node` exists in 6 different implementations across 13 files. Suggested order: the 9.1 quick wins (~1 h), then 9.2, then 9.3 **before** 6.1.1, with 9.5 decided before 6.5.3 ships.)

**Previously:** 2026-09-02 (**6.5.1 done — the orphaned bridge process is gone.** The server now shuts down when the client closes the pipe (stdin EOF / stdout EPIPE), on the usual signals, and on any other exit path; `close()` terminates the editor socket before closing the server, without which the port stayed bound regardless. Verified end-to-end: exit 0 and port free ~13 ms after EOF, with a connected editor. Next: 6.1.1 effect assertions, then 6.5.3-6.5.9 transport inversion, 6.2b undo/reconnect, Phases 4-5 packaging.)

**Previously:** 2026-09-01 (**the 6.6 field report is fully closed — 6.6.1 through 6.6.15.** Last in: `add_camera` takes an orthographic `size`, `add_mesh` shapes its primitive and takes a material, an unknown `mesh_type` is an error rather than a silent box (6.6.11/6.6.12); `node e2e/check-syntax.mjs` is a 6-second parse gate that names file and line (6.6.15); E2E number comparison is float32-tolerant. **216 passed / 0 failed, coverage 163/163** on 4.7.2 and 4.4.1. Next: 6.5 transport inversion, 6.1.1 effect assertions, 6.2b undo/reconnect, and Phases 4-5 packaging.)

**Previously:** 2026-09-01 (**all five field-report blockers cleared.** 6.6.5: a `--check-only` subprocess turns "code 43. Check syntax." into "line 2: Identifier \"this\" not declared in the current scope." for both `execute_script` and `validate_syntax`, ~180 ms warm and only when a compile has already failed. E2E **212 passed / 0 failed, coverage 163/163** on 4.7.2 and 4.4.1. Next: 6.6.11/6.6.12 (papercuts), 6.6.15 (syntax gate), then 6.5 (transport inversion) and 6.1.1 effect assertions.)

**Previously:** 2026-09-01 (field-report blockers cleared except 6.6.5: `execute_script` returns `output`/`errors`/`result` and finishes coroutines under a `timeout` watchdog (6.6.1/6.6.2); `take_screenshot` renders through a scene camera (6.6.3); `get_error_log` reads the log Godot actually writes — the editor writes none, game runs do (6.6.4); string vectors are no longer dropped by the 3D/physics/particle/navigation tools (6.6.14, found by the camera test). New: 6.6.15 proposes a 10-second syntax gate. Full E2E green on both engines: **210 passed / 0 failed, coverage 163/163**, verified on 4.7.2 and 4.4.1. Next: 6.6.5 (compile diagnostics — `--check-only` in a subprocess is a proven route), then 6.5.)

**Previously:** 2026-08-31 (6.5 expanded into a decided plan: transport inversion — the Godot plugin hosts the WebSocket server, MCP processes become clients — deferred until after the 6.6 blockers. 6.6 cheap batch landed: 6.6.6/6.6.7/6.6.8/6.6.9/6.6.10/6.6.13 fixed, new save_scene tool. Full E2E green on 4.7.2: **196 passed / 0 failed, coverage 163/163 tools**. 6.1 rescoped to effect-level assertions; 6.2/6.3 closed as absorbed by 6.4 with undo/reconnect split out as 6.2b; 5.4 downgraded. Remaining from the field report: 6.6.1-6.6.5, 6.6.11, 6.6.12.)

---

# Closed phases

## Phase 1: Project Foundation & Architecture

### [x] 1.1 - Initialize Project Structure
- [x] Create directory structure: `addons/`, `server/`, `docs/`, `tests/`
- [x] Set up `.gitignore`, `README.md`
- [x] Create LICENSE file
- **Priority:** HIGH
- **Effort:** 1-2 hours
- **Completed:** 2026-06-29

### [x] 1.2 - Set Up Node.js Server Foundation
- [x] Initialize `package.json` with MCP dependencies
- [x] Create TypeScript configuration (`tsconfig.json`)
- [x] Set up build scripts and tool registry
- [x] Create basic server entry point with MCP protocol handler
- **Priority:** HIGH
- **Effort:** 2-3 hours
- **Completed:** 2026-06-29

### [x] 1.3 - Set Up Godot Plugin Foundation
- [x] Create `plugin.cfg` for Godot addon
- [x] Create main plugin class (GDScript)
- [x] Set up WebSocket connection handler
- [x] Implement heartbeat/ping-pong system with 10s interval
- [x] Create tool registry for managing tools
- **Priority:** HIGH
- **Effort:** 2-3 hours
- **Completed:** 2026-06-29

### [x] 1.4 - Set Up MCP Protocol Communication
- [x] Implement MCP message serialization/deserialization (GDScript & TypeScript)
- [x] Create request/response handler with pending request tracking
- [x] Implement error handling with suggestions and standard error codes
- [x] Add auto-reconnect with exponential backoff (1s to 60s max)
- **Priority:** HIGH
- **Effort:** 3-4 hours
- **Completed:** 2026-06-29

---

## Phase 2: Core Tool Framework

### [x] 2.1 - Create Tool Definition Schema
- [x] Design JSON schema for tool definitions (with parameters, I/O, metadata)
- [x] Create validator for tool format with error reporting
- [x] Document tool metadata structure with categories
- [x] Create tool template generator
- **Priority:** HIGH
- **Effort:** 1-2 hours
- **Completed:** 2026-06-29

### [x] 2.2 - Implement Type Parsing System
- [x] Create smart type parser for Godot types
- [x] Add support for Vector2, Vector3, Vector4, Color, Rect2, Quaternion
- [x] Handle string literals, hex colors (#RRGGBB, #RRGGBBAA)
- [x] Create comprehensive unit tests for type parsing (15+ test cases)
- [x] Add round-trip conversion (parse → convert back)
- **Priority:** HIGH
- **Effort:** 2-3 hours
- **Completed:** 2026-06-29

### [x] 2.3 - Implement UndoRedo Integration
- [x] Create undo/redo wrapper for all mutations
- [x] Implement transaction batching (nested transactions)
- [x] Add automatic undo labels with action descriptions
- [x] Implement methods for: set_property, create_node, delete_node, move_node, rename_node, attach_script, connect_signal, add_to_group
- **Priority:** HIGH
- **Effort:** 2-3 hours
- **Completed:** 2026-06-29

---

## Phase 3: Tool Implementation (163 tools across 23 categories)

### [x] 3.1 - Project Tools (7 tools)
- [x] get_project_info
- [x] list_project_files
- [x] search_files
- [x] get_project_settings
- [x] set_project_setting
- [x] convert_uid
- [x] get_project_metadata
- **Priority:** HIGH
- **Effort:** 2-3 hours
- **Completed:** 2026-06-29

### [x] 3.2 - Scene Tools (10 tools)
- [x] get_scene_tree
- [x] create_scene
- [x] save_scene (added 2026-08-31, see 6.6.9)
- [x] open_scene
- [x] delete_scene
- [x] play_scene
- [x] stop_scene
- [x] instantiate_scene
- [x] get_scene_info
- [x] list_open_scenes
- **Priority:** HIGH
- **Effort:** 3-4 hours
- **Completed:** 2026-06-29

### [x] 3.3 - Node Tools (14 tools)
- [x] add_node
- [x] delete_node
- [x] duplicate_node
- [x] move_node
- [x] rename_node
- [x] get_node_properties
- [x] set_node_property
- [x] get_node_signals
- [x] connect_signal
- [x] add_to_group
- [x] remove_from_group
- [x] get_node_groups
- [x] get_node_parent
- [x] get_node_children
- **Priority:** HIGH
- **Effort:** 4-5 hours
- **Completed:** 2026-06-29

### [x] 3.4 - Script Tools (8 tools)
- [x] read_script
- [x] create_script
- [x] edit_script
- [x] attach_script
- [x] validate_syntax
- [x] search_in_scripts
- [x] get_script_info
- [x] reload_scripts
- **Priority:** HIGH
- **Effort:** 3-4 hours
- **Completed:** 2026-06-29

### [x] 3.5 - Editor Tools (9 tools)
- [x] take_screenshot
- [x] get_error_log
- [x] execute_script
- [x] reload_scripts (implemented in 3.4)
- [x] open_editor_settings
- [x] get_editor_version
- [x] get_editor_state
- [x] select_node_in_editor
- [x] focus_editor
- **Priority:** MEDIUM
- **Effort:** 3-4 hours
- **Completed:** 2026-06-29

### [x] 3.6 - Input Tools (7 tools)
- [x] simulate_key_press
- [x] simulate_mouse_click
- [x] simulate_mouse_move
- [x] trigger_input_action
- [x] record_input_sequence
- [x] replay_input_sequence
- [x] configure_input_mapping
- **Priority:** MEDIUM
- **Effort:** 3-4 hours
- **Completed:** 2026-06-29

### [x] 3.7 - Runtime Tools (19 tools)
- [x] get_game_state
- [x] list_loaded_resources
- [x] inspect_node_at_runtime
- [x] get_performance_metrics
- [x] record_gameplay
- [x] replay_gameplay
- [x] navigate_to_node
- [x] click_ui_element
- [x] get_node_tree_runtime
- [x] pause_game
- [x] resume_game
- [x] set_game_speed
- [x] list_autoloads
- [x] call_function
- [x] get_variable_value
- [x] set_variable_value
- [x] get_signal_connections
- [x] emit_signal
- [x] listen_to_signal
- **Priority:** MEDIUM
- **Effort:** 5-6 hours
- **Completed:** 2026-06-30

### [x] 3.7b - Runtime Tools bug fixes (code review)
- [x] emit_signal: callv вместо прямого вызова (Array не распаковывался)
- [x] speed_scale в replay_gameplay: деление вместо умножения
- [x] gui_input в click_ui_element: добавлено событие release
- [x] memory_dynamic: исправлен enum (MEMORY_DYNAMIC вместо MEMORY_MESSAGE_BUFFER_MAX)
- [x] _value_to_json: добавлены Vector2i, Vector3i, Rect2i, Quaternion, Basis, Transform2D, Transform3D
- [x] pause_game/resume_game: Engine.time_scale вместо editor SceneTree.paused
- [x] get_game_state.is_paused: Engine.time_scale == 0.0 вместо editor tree
- [x] listen_to_signal: clamp на timeout (макс. 30 сек)
- **Completed:** 2026-06-30

### [x] 3.8 - Animation Tools (6 tools)
- [x] create_animation
- [x] add_animation_track
- [x] add_keyframe
- [x] set_easing
- [x] get_animation_info
- [x] delete_animation
- **Priority:** MEDIUM
- **Effort:** 2-3 hours
- **Completed:** 2026-06-30

### [x] 3.9 - AnimationTree Tools (8 tools)
- [x] create_animation_tree
- [x] create_state_machine
- [x] add_transition
- [x] add_blend_tree
- [x] set_active_state
- [x] get_state_machine_info
- [x] edit_blend_space
- [x] delete_animation_tree_node
- **Priority:** MEDIUM
- **Effort:** 3-4 hours
- **Completed:** 2026-06-30

### [x] 3.9b - AnimationTree Tools bug fixes (code review)
- [x] get_state_machine_info: sm.get_transition(from,to) → sm.get_transition(i) (StringName≠int overload)
- [x] edit_blend_space BlendSpace1D remove_point: undo add_blend_point now passes idx for correct position restore
- [x] edit_blend_space BlendSpace2D remove_point: same fix — idx passed as at_index to undo
- [x] create_state_machine: guard against reserved "Start"/"End" state names (silent ERR_FAIL_COND in C++)
- [x] set_active_state: handles both active+state_name in one call; no longer early-returns ignoring state_name
- [x] edit_blend_space TS schema: action removed from required[] (aligns with GDScript default "list_points")
- **Completed:** 2026-06-30

### [x] 3.10 - 3D Scene Tools (6 tools)
- [x] add_mesh
- [x] add_camera
- [x] add_light
- [x] set_environment
- [x] add_gridmap
- [x] get_3d_scene_info
- **Priority:** MEDIUM
- **Effort:** 2-3 hours
- **Completed:** 2026-06-30

### [x] 3.10b - 3D Scene Tools bug fixes (code review)
- [x] _collect_3d_nodes: depth now counts Node3D levels only; non-3D wrapper nodes are transparent (don't consume depth budget)
- [x] set_environment created_new path: we.environment moved inside UndoRedo as add_do_property instead of eager assignment outside the action
- **Completed:** 2026-06-30

### [x] 3.11 - Physics Tools (6 tools)
- [x] add_rigid_body
- [x] add_collision_shape
- [x] set_collision_layer
- [x] set_collision_mask
- [x] add_raycast
- [x] get_physics_info
- **Priority:** MEDIUM
- **Effort:** 2-3 hours
- **Completed:** 2026-06-30

### [x] 3.11b - Physics Tools bug fixes (code review)
- [x] add_rigid_body 2D rotation: float(dict) → extract z key when dict is passed, silent 0 was lost
- [x] add_collision_shape: explicit error for cross-dimension shape_type (sphere+2d, rectangle+3d etc.)
- [x] get_physics_info RigidBody2D: angular_velocity wrapped as {z: value} to match 3D {x,y,z} dict shape
- [x] get_physics_info RayCast: force_raycast_update() called before is_colliding() so value is valid in editor
- [x] layersSchema (physics.ts): added anyOf[integer, array] so MCP clients receive typed schema
- **Completed:** 2026-06-30

### [x] 3.12 - Particle Tools (5 tools)
- [x] create_particle_system
- [x] set_particle_material
- [x] set_particle_gradient
- [x] load_particle_preset
- [x] get_particle_info
- **Priority:** LOW
- **Effort:** 2-3 hours
- **Completed:** 2026-06-30

### [x] 3.12b - Particle Tools bug fixes (code review)
- [x] set_particle_gradient: `while gradient.get_point_count() > 0` infinite loop — Gradient enforces min 1 point so remove_point is no-op at count=1; replaced with PackedFloat32Array/PackedColorArray bulk assignment
- [x] get_particle_info: `pm.color_initial_ramp` direct access crashes on Godot 4.0 (property added in 4.1); replaced with safe `pm.get("color_initial_ramp")` which returns null instead of crashing
- [x] set_particle_gradient: invalid `gradient_type` silently coerced to "color_ramp"; now returns explicit error consistent with other tools
- **Completed:** 2026-06-30

### [x] 3.13 - Navigation Tools (6 tools)
- [x] add_navigation_region
- [x] add_navigation_agent
- [x] bake_navigation
- [x] set_navigation_layer
- [x] get_navigation_path
- [x] get_navigation_info
- **Priority:** LOW
- **Effort:** 2-3 hours
- **Completed:** 2026-06-30

### [x] 3.13b - Navigation Tools bug fixes (code review)
- [x] set_navigation_layer: _is_navigation_node included NavigationObstacle3D/2D which lack navigation_layers in Godot 4.0; removed Obstacles from the helper — they gained navigation_layers only in 4.1
- **Completed:** 2026-06-30

### [x] 3.14 - Audio Tools (6 tools)
- [x] add_audio_player
- [x] load_audio_file
- [x] play_audio
- [x] stop_audio
- [x] configure_bus
- [x] add_audio_effect
- **Priority:** LOW
- **Effort:** 2-3 hours
- **Completed:** 2026-06-30

### [x] 3.14b - Audio Tools bug fixes (code review)
- [x] configure_bus: validate that send target bus exists (nonexistent send silently routes bus to nothing)
- [x] configure_bus: guard against setting send on Master bus (bus_idx==0) — Godot ignores it but tool returned success
- [x] load_audio_file: changed `load()` to `ResourceLoader.load()` for consistency with all other tool files
- [x] configure_bus schema: added note to description that at least one property (volume_db/mute/solo/send) must be provided
- **Completed:** 2026-06-30

### [x] 3.15 - TileMap Tools (6 tools)
- [x] set_tile_cell
- [x] fill_tiles
- [x] query_tile_cell
- [x] get_tileset_info
- [x] erase_tile_cell
- [x] get_tilemap_info
- **Priority:** MEDIUM
- **Effort:** 2-3 hours
- **Completed:** 2026-06-30

### [x] 3.15b - TileMap Tools bug fixes (code review)
- [x] set_tile_cell/fill_tiles: validate source_id exists in TileSet (invalid ID silently no-ops in Godot 4)
- [x] get_tileset_info: guard get_atlas_grid_size() with has_method for Godot 4.0 compatibility; fall back to texture/texture_region_size
- [x] erase_tile_cell: early-return when cell is already empty to avoid spurious no-op undo entry
- [x] get_tilemap_info: add has_tiles boolean (Rect2i(0,0,0,0) is ambiguous for empty tilemaps)
- [x] get_tileset_info: replace ts.get('tile_shape') double-call with direct ts.tile_shape property
- **Completed:** 2026-06-30

### [x] 3.16 - Theme/UI Tools (6 tools)
- [x] create_theme
- [x] set_theme_color
- [x] set_theme_font
- [x] set_theme_constant
- [x] set_stylebox
- [x] get_theme_info
- **Priority:** LOW
- **Effort:** 2-3 hours
- **Completed:** 2026-07-01

### [x] 3.16b - Theme/UI Tools bug fixes (code review)
- [x] _load_theme: use CACHE_MODE_IGNORE so modifications after _create_theme always read fresh from disk (CACHE_MODE_REUSE returned stale object)
- [x] _parse_color: use Color.html_is_valid/Color.html to handle bare hex 'ff0000' and '#rrggbb' uniformly (previously fell back to WHITE for any non-'Color(' string)
- [x] create_theme: guard existing file with overwrite: bool parameter — returns error if file exists and overwrite is not true (was silently overwriting)
- [x] create_theme: return error when default_font path is specified but font file does not exist (was silently ignored)
- [x] set_stylebox: use _as_bool() for draw_center, anti_aliased, vertical — bool("false") in GDScript returns true for any non-empty string
- **Completed:** 2026-07-01

### [x] 3.17 - Shader Tools (6 tools)
- [x] create_shader
- [x] edit_shader
- [x] assign_material
- [x] set_shader_param
- [x] get_shader_info
- [x] validate_shader
- **Priority:** MEDIUM
- **Effort:** 2-3 hours
- **Completed:** 2026-07-01

### [x] 3.17b - Shader Tools bug fixes (code review)
- [x] _validate_shader: track /* */ block comment state across lines — multi-line block comments before shader_type caused early break and false "missing shader_type" error
- [x] _validate_shader: strip inline // comment before parsing shader_type line — "shader_type spatial; // note" produced "spatial;" (with semicolon) as declared_type, failing type check
- [x] _parse_param_value: add size-1 Array → float conversion; add explicit return inside Array branch for size 5+ (was falling through to return raw Array, passed to set_shader_parameter as wrong type)
- [x] _set_shader_param: guard empty param_name after str() conversion — set_shader_parameter("", ...) is a silent no-op in Godot 4, tool returned success:true
- [x] _set_shader_param: guard null param_value — set_shader_parameter(name, null) clears the uniform rather than setting it, now returns error
- [x] _write_file: replace DirAccess.make_dir_recursive_absolute (Godot 4.1+) with instance-based make_dir_recursive for Godot 4.0 compatibility
- [x] _assign_material material_path branch: add CACHE_MODE_IGNORE so freshly-saved material is never returned as stale cached object
- **Completed:** 2026-07-01

### [x] 3.18 - Resource Tools (6 tools)
- [x] read_resource
- [x] edit_resource
- [x] create_resource
- [x] save_resource
- [x] get_project_autoloads (renamed from list_autoloads to avoid collision with runtime_tools)
- [x] set_autoload
- **Priority:** MEDIUM
- **Effort:** 2-3 hours
- **Completed:** 2026-07-01

### [x] 3.18b - Resource Tools bug fixes (code review)
- [x] _set_autoload: add ProjectSettings.save() after add/remove_autoload_singleton — without it, autoload changes were lost on editor exit
- [x] _parse_prop_value: add TYPE_QUATERNION, TYPE_RECT2I, TYPE_BASIS, TYPE_TRANSFORM3D, TYPE_TRANSFORM2D branches + _parse_v2/v3/basis helpers — these types were serialized by _value_to_json but silently failed on round-trip (raw dict → resource.set() no-op)
- [x] _value_to_json: handle PackedByteArray — was falling through to str(val), producing multi-MB strings for audio/image assets; now returns up to 64 bytes as array or a {type, size, preview_hex} summary
- [x] _edit_resource: guard against saving when all properties were skipped — was writing unchanged file, touching mtime, and returning misleading success:true
- [x] _set_autoload: validate action string — 'delete', 'update', typos now return error instead of silently acting as 'add'
- [x] _edit_resource: add res:// prefix validation — OS-absolute paths were silently attempted
- [x] runtime_tools.gd _list_autoloads: fix enabled=not path.begins_with('*') (inverted Godot convention) → renamed field to is_singleton with correct polarity
- **Completed:** 2026-07-01

### [x] 3.19 - Batch/Refactor Tools (8 tools)
- [x] find_by_node_type
- [x] find_by_script
- [x] find_by_group
- [x] bulk_rename
- [x] cross_scene_update
- [x] find_dependencies
- [x] orphaned_resources
- [x] refactor_signals
- **Priority:** LOW
- **Effort:** 3-4 hours
- **Completed:** 2026-07-01

### [x] 3.19b - Batch/Refactor Tools bug fixes (code review)
- [x] bulk_rename all_scenes: check ResourceSaver.save() return value — save failures were silently swallowed and reported as success
- [x] bulk_rename current_scene: call ur.commit_action(false) when renamed array is empty to discard the action rather than pushing a spurious blank entry onto the undo stack
- [x] bulk_rename all_scenes: add SceneState pre-scan before ps.instantiate() to skip scenes with no matching node names — mirrors the optimization already present in cross_scene_update, avoids unnecessary memory allocation for non-matching scenes
- **Completed:** 2026-07-01

### [x] 3.20 - Analysis Tools (4 tools)
- [x] analyze_scene_complexity
- [x] trace_signal_flow
- [x] find_unused_resources
- [x] get_code_metrics
- **Priority:** LOW
- **Effort:** 2-3 hours
- **Completed:** 2026-07-01

### [x] 3.20b - Analysis Tools bug fixes (code review)
- [x] find_unused_resources: handle uid:// dependency strings returned by ResourceLoader.get_dependencies() in Godot 4.3+ (scenes omit path= in ext_resource); resolve via ResourceUID to res:// path before lookup — without this every asset was falsely reported as unused
- [x] get_code_metrics single-file failure: return {error: "Failed to read <path>: <reason>"} instead of raw {script, error} dict (the raw shape leaked internal structure and lost path info when the MCP layer forwarded only the "error" value)
- [x] get_code_metrics multi-file: count now reflects successfully analyzed scripts only, excluding failed-read entries — previously count==results.size() included failures, making totals/count inconsistent for callers computing per-file averages
- **Completed:** 2026-07-01

### [x] 3.21 - Testing/QA Tools (6 tools)
- [x] run_automated_tests
- [x] assert_node_state
- [x] compare_screenshots
- [x] record_test
- [x] replay_test
- [x] get_test_report
- **Priority:** LOW
- **Effort:** 3-4 hours
- **Completed:** 2026-07-01

### [x] 3.21b - Testing/QA Tools bug fixes (code review)
- [x] replay_test: InputEventAction now fires press + release (was press-only, leaving action stuck in pressed state)
- [x] run_automated_tests: test methods called with await so async test_ functions don't silently pass as GDScriptFunctionState
- [x] replay_test: replaced get_editor_viewport_2d() (Godot 4.1+ only) with Input.parse_input_event() for Godot 4.0 compatibility
- [x] run_automated_tests: free() guard changed from has_method("free") to not instance is RefCounted — free() on RefCounted prints runtime error
- [x] assert_node_state: int vs float now uses tolerant float comparison (str(1) != str(1.0) caused false failures on int properties)
- [x] _collect_test_files: base_path normalized to end with "/" preventing "tests" from matching "tests_helper/" sibling directory
- **Completed:** 2026-07-01

### [x] 3.22 - Profiling Tools (2 tools)
- [x] get_performance_monitors
- [x] get_memory_usage
- **Priority:** LOW
- **Effort:** 1-2 hours
- **Completed:** 2026-07-01

### [x] 3.22b - Profiling Tools bug fixes (code review)
- [x] TIME_NAVIGATION_PROCESS + NAVIGATION_* constants: guarded with Engine.get_version_info minor>=1 check for Godot 4.0 compatibility
- [x] clampi(): replaced with int(clamp()) for Godot 4.0 compatibility
- [x] ResourceLoader.list_cached_resources(): guarded with has_method() check for Godot 4.1+; fallback returns informative note
- [x] Dict self-reference bug: captured full_count before assignment to cached_resources dict so note field resolves correctly
- [x] Double list_cached_resources() call eliminated: single call, stored in local, sliced in-place
- [x] MEMORY_MESSAGE_BUFFER_MAX key renamed to message_buffer_max_bytes to clarify it is a queue ceiling, not current usage
- **Completed:** 2026-07-01

### [x] 3.23 - Export Tools (3 tools)
- [x] list_export_presets
- [x] export_project
- [x] get_template_info
- **Priority:** LOW
- **Effort:** 1-2 hours
- **Completed:** 2026-07-01

### [x] 3.23b - Export Tools bug fixes (code review)
- [x] OS.execute stderr coercion: removed separate stderr Array; use single output Array + read_stderr=true; output included in both success and failure responses (was always "(no stderr)")
- [x] Template path: use version_string (e.g. "4.2.2.stable") directly instead of "%d.%d.%d" numeric format — templates_installed was always false for correct installations
- [x] DirAccess.make_dir_recursive_absolute (Godot 4.1+): replaced with instance-based DirAccess.open("user://").make_dir_recursive() for Godot 4.0 compatibility
- [x] exit_code == -1: now returns distinct "subprocess not launched" error distinguishing from export failure
- [x] Dead variables preset_index/preset_platform removed; redundant export_result intermediate variable inlined
- **Completed:** 2026-07-01

### [x] 3.24 - Godot 4.4.1 Compatibility Fixes
- [x] undo_redo_manager.gd: extend RefCounted instead of Node (eliminates add_to_group/remove_from_group Node signature conflicts); replace non-existent EditorUndoRedo type with EditorUndoRedoManager
- [x] node_tools.gd, animation_tree_tools.gd: explicit type annotations (Node/int/StringName) where := inference fails on Variant-returning methods in Godot 4.4
- [x] scene_tools.gd: fix ternary type-inference on get_script() result
- [x] runtime_tools.gd: remove Performance.MEMORY_DYNAMIC (removed in 4.4)
- [x] shader_tools.gd: replace RenderingServer.shader_get_param_list() (removed) with Shader.get_shader_uniform_list()
- [x] theme_tools.gd: explicit String/PackedStringArray annotations in _parse_color()
- [x] analysis_tools.gd: explicit Dictionary annotation for array element access
- [x] profiling_tools.gd: ResourceLoader.call("list_cached_resources") to bypass Godot 4.4 parse-time static method validation
- [x] Verified: plugin loads clean in Godot 4.4.1 — "Registered 162 tools", zero parse errors
- **Completed:** 2026-07-02

### [x] 3.25 - Critical Bug Fixes (found during live MCP testing)
- [x] **callable_tool.gd null instance**: all tool handlers (`GodotMCPProjectTools` etc.) extend `RefCounted` and were created as temporaries in `_register_tools()` — GC freed them immediately after `register()` returned. Fix: store all 23 tool instances as member variables in `plugin.gd` (`_tool_project`, `_tool_scene`, …, `_tool_export`).
- [x] **heartbeat._send_ping() was empty (pass)**: ping was never sent over WebSocket → timeout fired every ~15s → constant disconnect/reconnect loop. Fix: added `send_fn: Callable` to `heartbeat.gd`; wired in `plugin.gd` via `heartbeat.send_fn = func(): _send_message({"type": "ping"})`.
- **Completed:** 2026-07-02

### [x] 3.27 - Plugin bugs found by the E2E suite (2026-07-08)
- [x] **get_state_machine_info returned `{}`**: called `AnimationNodeStateMachine.get_node_list()`, which does not exist in Godot 4.x — the runtime error aborted the typed `-> Dictionary` function, silently returning an empty dict. Fix: enumerate states via the SM's dynamic `states/<name>/node` properties.
- [x] **reload_scripts silently failed**: called `ScriptEditor.reload_scripts()`, not exposed to scripting in Godot 4.0-4.4 — same silent-`{}` abort pattern, and the tool still reported success. Fix: reload each open script from disk (`source_code` + `reload(true)`) and `scan_sources()`; response now includes the reloaded list.
- **Lesson:** a runtime error in a GDScript function typed `-> Dictionary` returns `{}` instead of propagating — e2e asserts must check a concrete field (e.g. `success == true`), never just "call did not error".
- **Completed:** 2026-07-08

### [x] 3.28 - Server survives a failed WebSocket bind (2026-08-31)
- [x] **A busy port killed the whole process**: `WebSocketServer` was constructed with no `error` handler, so `EADDRINUSE` surfaced as an unhandled `'error'` event and terminated the server before the MCP handshake — the client could only report `CONNECTION_CLOSED` with no cause. Fix: handle `wss.on("error")`, record the reason, stay up.
- [x] **`callTool` reported the wrong cause**: after a failed bind every tool fell through to the generic "Godot editor is not connected — make sure the plugin is enabled" hint, sending the user after a problem that was not theirs. Now the bind error is checked first and returned verbatim (names the port and the `GODOT_MCP_PORT` escape hatch).
- [x] **"listening" was logged before the bind resolved**: `listen()` is async, so the constructor announced success it could not yet know — moved into the `listening` event.
- **Context:** every MCP client session spawns its own server process, but the bridge port is a machine-wide singleton — a second session (or a leftover orphan from a closed one) always collides. This makes the collision diagnosable; it does not resolve it (see 6.5).
- **Completed:** 2026-08-31

### [x] 3.26 - Godot API Versioning Infrastructure
- [x] `addons/godot_mcp/version_utils.gd`: shared `GodotMCPVersionUtils` helper — `at_least()`/`before()` for version-number branching, plus `has_class()`/`has_constant()`/`get_constant()` for String-based ClassDB lookups (needed because GDScript resolves class/constant identifiers at *parse time*, so a runtime `if` guard cannot protect a direct reference to a symbol missing on the running engine — e.g. `TileMapLayer` on 4.0-4.2, `Performance.MEMORY_DYNAMIC` on 4.4+)
- [x] `tilemap_tools.gd`: all 6 tools now also accept `TileMapLayer` nodes (Godot 4.3+) alongside `TileMap`, dispatched dynamically (no static cast) since the two classes have different cell-method signatures (TileMapLayer has no `layer` argument)
- [x] `profiling_tools.gd`, `runtime_tools.gd`: restored the `MEMORY_DYNAMIC` monitor (dropped in the 4.4 compat pass, 3.24) for Godot 4.0-4.3 via dynamic constant lookup, and switched the existing inline "godot_minor >= 1" navigation-monitor guard to `GodotMCPVersionUtils.at_least()`
- [x] `server/src/utils/version-utils.ts`: parses Godot version strings (e.g. "4.4.1.stable") and compares against optional `minGodotVersion`/`maxGodotVersion` on a `ToolDefinition`
- [x] `server/src/godot-connection.ts`: now retains `godot_version`/`plugin_version` from the plugin's handshake (previously logged and discarded) via `godotVersion`/`pluginVersion` getters, cleared on disconnect
- [x] `server/src/index.ts`: `call_tool` checks a tool's version range against the connected editor before dispatch, returning a clear error instead of a confusing in-Godot failure
- **Note:** TileMapLayer dual-support is unverified against a live Godot 4.3+/4.4 editor (no editor available in this environment) — spot-check `set_tile_cell`/`get_tilemap_info` on a `TileMapLayer` node before relying on it.
- **Completed:** 2026-07-03

### [x] 6.1b - Live MCP Integration Test (18 basic tools)
- [x] get_project_info ✅ — Godot 4.4.1, project "test_mcp"
- [x] get_editor_version ✅ — 4.4.1-stable (official)
- [x] get_editor_state ✅ — has_open_scene: false before scene created
- [x] get_project_settings ✅ — gravity, viewport defaults returned
- [x] list_project_files ✅ — 68 files incl. plugin addons/
- [x] get_scene_tree ✅* — expected error with no scene; correct after open
- [x] list_open_scenes ✅ — empty initially, expected
- [x] create_scene ✅ — res://test_basic.tscn created
- [x] open_scene ✅ — scene opened in editor
- [x] add_node ✅ — Label "TestLabel" added to root
- [x] set_node_property ✅ — text "" → "Hello MCP!"
- [x] get_node_properties ✅ — all Label props returned, text confirmed
- [x] get_scene_tree (repeat) ✅ — TestScene → TestLabel visible
- [x] create_script ✅ — res://test_script.gd created
- [x] read_script ✅ — content matches written source
- [x] validate_syntax ✅ — valid: true
- [x] get_error_log ✅ — empty log, no errors
- [x] take_screenshot ✅ — 1920×1080, saved to res://screenshot.png
- **Result:** 18/18 PASSED
- **Completed:** 2026-07-02

---

## Closed in Phase 5

---

### [x] 5.4 - Create .mcp.json Template — closed by 9.1.6 (2026-09-02)
- [x] Create example config file — working [.mcp.json](.mcp.json) in the repo root
- [x] Document all options — README "Point your MCP client at it" covers the absolute-path requirement and `GODOT_MCP_PORT`
- [x] 5.4.1 - Ship it as a copyable template rather than a live config, and document the two traps found in the field: the file must be named exactly `.mcp.json` and must sit in the directory the client is launched from (a config named otherwise, or one level down in the Godot project subfolder, is silently ignored) — **done as 9.1.6**: `.mcp.json.example` committed with both traps in the header, the live `.mcp.json` untracked and gitignored
- **Completed:** 2026-09-02

---

## Closed in Phase 6

---

### [x] 6.2 - Integration Testing — mostly absorbed by 6.4
- [x] Test WebSocket communication — full MCP stack over the bridge, 191 tests
- [x] Test plugin-server interaction — every one of 162 registered tools is called for real
- **Remaining, moved to 6.2b below:** undo/redo and auto-reconnect are genuinely untested
- **Priority:** HIGH

---

### [x] 6.3 - 2D & 3D Workflow Testing — covered by 6.4
- [x] 2D and 3D fixtures both live in the generated test project; 2D node types appear across blocks 02-09 and the 3D/physics/navigation blocks cover the 3D path
- [x] All 162 registered tools are called in both contexts where applicable (coverage diff vs tools/list is part of the report)
- **Priority:** HIGH

---

### [x] 6.4 - Autonomous E2E Test Infrastructure (design: docs/e2e_test_infrastructure.md)
- [x] Design document: pipeline (provision → generate → launch → execute → teardown), workspace layout, assertion DSL, report format, risk register — see docs/e2e_test_infrastructure.md (2026-07-08)
- [x] 6.4.0 - Port isolation: `GODOT_MCP_PORT` env override in server (godot-connection.ts) and plugin (plugin.gd); runner defaults to 6510 so a live setup on 6505 is untouched
- [x] 6.4.1 - Provisioning: download/cache Godot 4.x win64 from godot-builds releases (fallback: main repo), `_sc_` self-contained mode, `--godot` version matrix, `--purge-cache`
- [x] 6.4.2 - Test project generation: project.godot template with version-matched features tag, addon copy, fixtures, `--import` pre-pass
- [x] 6.4.3 - Process management: spawn console exe with log capture, readiness gate (poll get_editor_version), taskkill /T + wait-for-exit teardown, cleanup with file-lock retries
- [x] 6.4.4 - Executor: MCP stdio client (full production stack via SDK), sequential block runner, $VAR store, disconnect recovery with single retry, per-test timeout (`--bridge-only` mode deferred)
- [x] 6.4.5 - Assertion DSL evaluator (eq/neq/notNull/isNull/notEmpty/contains/gte/lte/matches/allElementsMatch/jsonContains, expectError/errorContains, dot-path fields with literal-key priority)
- [x] 6.4.6 - Port 23 blocks from docs/mcp_test_plan.md to e2e/blocks/*.json — all 23 blocks ported (190 tests), args adapted to the actual tool schemas (dumped from server/dist) rather than the stale plan
- [x] 6.4.7 - Reporting: JSON + Markdown, per-block tables, failure details, tool coverage diff vs tools/list, CI exit codes (0/1/2)
- [x] Live verification: full pipeline from clean machine state — download 4.4.1 (66 MB), pre-import, editor boot, handshake, block 1 = 9 passed / 0 failed, workspace cleaned
- [x] **FULL SUITE GREEN (2026-07-08): 191 passed / 0 failed / 0 skipped, coverage 162/162 registered tools, 46s wall time on cached distribution.** Two real plugin bugs found and fixed along the way (see 3.27); 14 initial failures triaged — 12 were stale-plan/arg mismatches fixed in blocks, 2 were the plugin bugs.
- **Note:** mcp_test_plan.md is stale vs the implemented API in at least two places found while porting block 1: `set_project_setting` takes `setting_path` (not `setting`); `get_editor_version` returns Godot's version dict (`string`/`build`/`major`…), not `version`/`is_official`. e2e/blocks/*.json are the executable source of truth.
- [x] 6.4.8 - **Pre-import pass ignored `--port` (2026-08-31)**: `preImport()` called `spawnSync` with no `env`, so it inherited a `process.env` without `GODOT_MCP_PORT` — the plugin loads during the import pass too, so it attached to the default 6505 and connected to whatever live server owned it. Since the server replaces its existing client on a new connection, an e2e run could knock a developer's editor off its own server mid-session — exactly what `--port` exists to prevent. Fix: thread `port` through to `preImport` (e2e/lib/project.mjs, e2e/run.mjs). Verified: the pre-import pass now logs 6510, and 6505 appears nowhere in the run.
- [x] **GODOT 4.7.2 VERIFIED (2026-08-31): 191 passed / 0 failed / 0 skipped, 162/162 tools, 60s.** No code changes were needed for 4.7 — all 34 plugin classes register with zero parse errors and the handshake reports `4.7.2-stable (official)`. The version range in the README (verified on 4.4.1) understates actual coverage.
- **Priority:** HIGH
- **Completed:** 2026-07-08 (run: `node e2e/run.mjs --godot 4.4.1`; CI exit codes 0/1/2; version matrix via `--godot 4.2.2,4.4.1` ready). Verified live on 4.4.1 (2026-07-08) and 4.7.2 (2026-08-31).

---

### [ ] 6.6 - Field report: 3D blockout session in a real project (dragon_hoard, 2026-08-31)
First sustained use of the toolset on real work rather than E2E fixtures. Node-graph
construction (`add_node`, `add_mesh`, `set_node_property`, `create_scene`) held up and
produced exactly the intended scene. **Everything on the feedback path — script output,
errors, and seeing the frame as the player sees it — had to be routed around through
files on disk.** Nearly all of the session's real work ended up inside `execute_script`
plus PowerShell file reads instead of the specialized tools. All items below are
confirmed against the source.

**Blocking — required workarounds**
- [x] 6.6.1 - **`execute_script` drops coroutines.** `instance._run()` (editor_tools.gd:148) discards the return value, so a `_run()` containing `await` yields a `GDScriptFunctionState` that is never resumed — the whole tail of the script (saving a PNG, `queue_free`) silently never runs. `await RenderingServer.frame_post_draw` is the common case. Worse, editor_tools.gd:150 reports `success: true` regardless, and an orphaned `SubViewport` is left parented in the editor. Fix: detect `GDScriptFunctionState`, keep the instance alive, and `await` completion (callable_tool.gd already supports async tools). **Fixed 2026-09-01:** the body is started through an injected `_mcp_main()` via `call_deferred` and the tool polls for completion, so the engine resumes the coroutine and the whole script runs before the response is sent. A `timeout` arg (default 10s, max 60) bounds the wait: a script awaiting something that never fires now returns its partial output with `partial: true` instead of wedging the bridge — `_tool_busy` (plugin.gd:255) serves one call at a time, so a permanent await used to require an editor restart. E2E E-08d, E-08e, E-08f.
- [x] 6.6.2 - **`execute_script` returns no output.** `print()` goes to Godot's Output panel; the tool returns only "Check Godot Output panel" (editor_tools.gd:146-150 — the comment concedes capture is "not available"). The only way to get data out of the editor is writing to `user://` and reading it off disk. Fix: expose a collector (e.g. an injected `mcp_print()`/return-value convention) so `_run()` can hand structured data back. **Fixed 2026-09-01:** every executed script gets an injected collector — `mcp_print(...)`/`mcp_printerr(...)` (same signature as `print`, still echoing to the Output panel) come back as `output`/`errors`, capped at 500 lines, and whatever the body returns comes back as `result`, JSON-converted recursively (containers, the vector/transform family, Nodes as scene-relative paths). A script that only uses plain `print(` gets a note saying where its output went. If the injection collides with a name the script declares, it is compiled and run as written with `output_capture: false`. E2E E-08, E-08b, E-08c.
- **Two engine facts found while fixing these (probed on 4.4.1/4.7.2, both now green):** `print()` cannot be intercepted — GDScript resolves it to the built-in utility function at parse time, so a same-named method in the script is never called, which is why the collector needs its own name. And the body cannot run as `_run()`: `EditorScript._run()` is a `void` virtual, so from Godot 4.7 returning a value from it is the parse error "A void function cannot return a value" (4.4 accepted it). The caller's `func _run(` is therefore renamed to `func _mcp_body(` before compiling — callers still write `_run()` and can return from it on every supported engine.
- [x] 6.6.3 - **No way to see what the player sees.** `take_screenshot` offers `editor`, `2d`, `3d` — all editor viewports via `EditorInterface.get_editor_viewport_*` (editor_tools.gd:46-56). Neither the running game window nor a render through the game camera is reachable. For an orthographic camera this is fatal: `size` cannot be tuned blind. Drove the entire offscreen `SubViewport` + `own_world_3d` pipeline. Fix: a `viewport: "game"` mode, or a first-class "render through camera N" tool. **Fixed 2026-09-01:** `viewport: "camera"` renders the open scene through one of its own cameras — an offscreen `SubViewport` sharing the scene's `World3D`/`World2D`, with a stand-in camera cloned from the target through its property list (version-proof) and defaults sized to the project's viewport, so framing and an orthographic `size` read as they will in game. Accepts `camera_path`, `width`, `height`, `transparent_bg`; auto-picks the scene's current/enabled camera; returns the projection and its relevant field (`size` for orthographic, `fov` otherwise). The wait is on `process_frame`, not `RenderingServer.frame_post_draw`, so it cannot hang the bridge if the editor is not drawing — and it is much faster: an unfocused editor takes ~0.75 s per drawn frame. E2E 3D-07, 3D-07b (asserts the PNG is not a flat colour), 3D-08, E-04b/c/d.
- **Still not possible:** capturing the *running game's* window — it is a separate OS process, and reaching it needs the debugger channel plus a runtime autoload, not an editor-side call.
- [x] 6.6.4 - **`get_error_log` does not work out of the box.** editor_tools.gd:79 reads `<editor data dir>/logs/godot.log`, which the editor does not write unless file logging is on — so the tool answers "Log file not found. Run project with --verbose". There is no way to confirm a scene starts clean; `get_game_state` (scene/fps/is_playing) was the fallback. Fix: read the engine's actual log setting, or capture errors in-process. **Fixed 2026-09-01:** it was looking in the wrong place. Verified on this machine: the editor process writes **no** log file at all (`--editor --quit` creates nothing, and `%APPDATA%\Godot\logs` does not exist), while every *game* run writes `user://logs/godot.log` with rotation — including the field-report project itself, whose logs from 2026-08-31 were there the whole time. The tool now reads the newest `*.log` across the configured `debug/file_logging/log_path`, the project's user dir and the editor data dir, reports `log_path`/`modified_time`/`file_logging_enabled`, takes an explicit `log_path` override, and keeps the indented location/backtrace lines attached to a filtered error instead of returning a message that names no file. When nothing is found it says so, with the paths searched. So "does this scene start clean?" is answered by `play_scene` → `get_error_log`. E2E E-03, E-03b/c/d.

**Smaller, but cost time**
- [x] 6.6.5 - **Compile errors carry no diagnostics.** `Script compilation failed (code 43). Check syntax.` — no line, no message (editor_tools.gd:140). `validate_syntax` has the same hole (script_tools.gd:234). A typo has to be found by eye. `GDScript.reload()` genuinely does not surface the parse message, so the fix means capturing stderr or the editor log around the probe. **Fixed 2026-09-01:** `addons/godot_mcp/script_check.gd` re-runs the editor's own binary with `--check-only --script` and parses the parse/compile errors off its output, so `execute_script` and `validate_syntax` now answer `line 2: Identifier "this" not declared in the current scope.` instead of a number, plus a `diagnostics` array. Only pays on the path that already failed: ~180 ms warm, ~1.2 s cold. Line numbers are mapped back through the wrapper's header offset, so they point at the code the caller wrote. E2E E-08g, E-08h (both auto-wrap branches), SC-05.
- **Details worth keeping:** the probe file goes in the OS cache dir with an absolute path, not `user://` — the editor and the subprocess do not resolve `user://` to the same place in self-contained mode, and `--script` takes absolute paths. `--log-file` points the subprocess's log away from the project, or every failed compile would rotate `user://logs/godot.log` — which 6.6.4 now reads (default `max_files` is 5, so a handful of typos would evict a real run's log); if the engine predates `--log-file` the run is retried without it. Several diagnostics are folded into the message text because a tool that fails answers over the MCP error channel, which carries no structured payload.
- [x] 6.6.6 - **`create_scene` does not create directories.** scene_tools.gd:71 calls `ResourceSaver.save` straight into the path, so `res://scenes/lair/Lair.tscn` fails with "Can't open" when `lair/` is missing. Fix: `DirAccess.make_dir_recursive_absolute` on the parent first. **Fixed 2026-08-31:** `_ensure_dir_for()` in scene_tools.gd creates the tree before saving; used by both `create_scene` and `save_scene`. E2E S-11.
- [x] 6.6.7 - **`set_project_setting` writes ints as floats.** project_tools.gd:135 passes the JSON value through untouched, and JSON numbers arrive as `float` — `1920` lands in project.godot as `viewport_width=1920.0`. Fix: coerce to the existing setting's type (or the property-list type) before setting. **Fixed 2026-08-31:** `_coerce_numeric()` converts to the type the setting already holds (numeric types only — coercing a String would turn a typo into 0). Note: int-vs-float is not observable over JSON, so the E2E assertion covers the read-back, not the on-disk literal — see 6.1.1.
- [x] 6.6.8 - **A value equal to the engine default is silently not persisted.** `stretch/aspect = keep` returned `success: true` and never appeared in project.godot, because Godot omits defaults on save. The response echoes the *input* value (project_tools.gd:139) rather than reading back, so "did not apply" and "applied but not written" are indistinguishable. Fix: read the setting back and report the effective value. **Fixed 2026-08-31:** the response now reports the value read back from ProjectSettings, plus `is_engine_default: true` and an explaining note when the value matches `property_get_revert()`. E2E P-07b.
- [x] 6.6.9 - **No scene-save tool.** `add_node` / `set_node_property` mutate the open scene but nothing commits it; the only `ResourceSaver.save` in the scene path is inside `create_scene` (scene_tools.gd:92). Saving meant calling `save_scene()` by hand inside `execute_script`. Fix: add `save_scene` (and likely `save_all_scenes`). **Fixed 2026-08-31:** added `save_scene` (optional `scene_path` acts as save-as, directories created automatically). Uses `EditorInterface.save_scene()`/`save_scene_as()` — what Ctrl+S runs; `save_scene_as` returns void, so the write is confirmed by checking the file landed. E2E S-09d, S-12.

**API inconsistencies**
- [x] 6.6.10 - **`add_node` returns an unusable path.** node_tools.gd:163 returns `str(node.get_path())` — a screen-long `/root/@EditorNode@19513/@Panel@14/...` — while every other tool expects a scene-relative path. `_add_to_scene` in the 3D tools already does it right: `str(root.get_path_to(new_node))` (scene_3d_tools.gd:76). Fix: make node_tools match. **Fixed 2026-08-31:** returns `root.get_path_to(node)`, matching `_add_to_scene`. E2E N-01 asserts the exact relative path and that `@EditorNode` is absent.
- [x] 6.6.11 - **`add_camera` cannot set `size`** — the one parameter that means anything for an orthographic camera. It accepts `fov`/`near`/`far` (scene_3d_tools.gd:180-213) and cheerfully returns `"fov": 75` for an orthographic camera (line 213). Fix: accept `size`, and return the projection-relevant field. **Fixed 2026-09-01:** takes `size`, and the response carries `size` for an orthographic camera and `fov` otherwise. E2E 3D-02b verifies the value on the node itself.
- [x] 6.6.12 - **`add_mesh` gives no access to the mesh resource** — only the node transform (scene_3d_tools.gd:140-176). Primitives are born at engine defaults, so worker capsules came out 2.0 m tall instead of 1.8; dimensions and materials had to be finished in a script anyway. Fix: pass through the `PrimitiveMesh` properties (radius/height/size) and an optional material. **Fixed 2026-09-01:** `mesh_properties` sets any property of the primitive itself, coerced to the property's real type (a JSON number reaching a `Vector3` property would otherwise leave it untouched), with the applied values read back in the response and misspellings listed under `unknown_properties`. `material` takes a res:// path, `material_color` builds a StandardMaterial3D. Also: `mesh_type` now accepts both `capsule` and `CapsuleMesh`, and an unrecognised type is an error instead of silently building a box. E2E 3D-02c/d/e.
- [x] 6.6.14 - **String vectors were silently dropped outside node_tools** (found 2026-09-01 while testing 6.6.3). `_parse_vector2/3` in scene_3d_tools, physics_tools, particle_tools and navigation_tools accepted only a Vector, Dictionary or Array and returned the default for anything else — so `add_camera(position: "Vector3(0, 2, 5)")` put the camera at the origin and reported `success: true`, and the same held for `add_mesh`, `add_light`, `add_gridmap` (`cell_size`), the physics shape sizes and the particle/navigation vectors. The string form is the shorthand CLAUDE.md advertises and `set_node_property` already accepts, so it is the form an agent writes. **Fixed 2026-09-01:** new `addons/godot_mcp/type_utils.gd` (`GodotMCPTypeUtils.to_vector2/to_vector3`) parses all four shapes, the four tool files delegate to it, and the `vector2Schema`/`vector3Schema` in the four matching server files became `anyOf[object, string, array]` so clients see what is accepted (same treatment as `layersSchema` in 3.11b). E2E 3D-02 now verifies the camera's actual position rather than `success: true`.
- [x] 6.6.13 - **`get_node_properties` dumps ~40 properties with no filter** (node_tools.gd:273) — reading one `scale` returns a wall of text. Fix: an optional `names` / prefix filter. **Fixed 2026-08-31:** optional `names` array filters the result; unmatched names come back under `not_found` so a typo is not a silent empty list. E2E N-02b, N-02c.

**Test-suite gap:** the E2E suite is green at 191/191 across 162/162 tools, and caught none of
these. It asserts tool *responses*, and the responses are exactly what is wrong — 6.6.1 and
6.6.8 both report `success: true` for work that did not happen. Effect-level assertions
(read the setting back, verify the file on disk, check the node tree after the call) are what
would have caught them.
- **Priority:** DONE — **the whole 6.6 field report is closed as of 2026-09-01** (6.6.1–6.6.15).
- **Status:** every workaround the field report had to build (script output through `user://` files, the hand-rolled SubViewport render pipeline, `get_game_state` as an error-log substitute, finding typos by eye, finishing primitives in a script) now has a first-class path. E2E: **216 passed / 0 failed, coverage 163/163**, green on 4.7.2 and 4.4.1.
- **One test-infrastructure change came with it:** `looseEq` in e2e/lib/asserts.mjs compared numbers to 1e-9, but Godot stores most numeric properties as 32-bit floats — a height written as 1.8 reads back as 1.79999995231628. Numbers now compare with a relative tolerance of 1e-6, which is what an effect-level assertion (6.1.1) needs to be usable at all.
- [x] 6.6.15 - **Add a fast GDScript syntax gate.** **Done 2026-09-01:** `node e2e/check-syntax.mjs [--godot 4.4.1] [--all]` — 6 s including project generation, exit 0/1/2. Verified both ways: a deliberate typo in audio_tools.gd is reported as `res://addons/godot_mcp/tools/audio_tools.gd:311 — Identifier "this" not declared in the current scope.` with exit 1, and a clean tree exits 0. One `--check-only` load of `plugin.gd` covers the whole dependency graph, so the default is a single ~1.3 s subprocess; `--all` checks each file separately for anything nothing references yet. Original note below. A parse error in any one plugin file makes `plugin.gd` fail to compile, so *every* tool disappears and the only symptom is `Tool not found: <anything>` — a 4-minute E2E run to discover a typo. `godot --headless --path <project> --check-only --script res://addons/godot_mcp/tools/<file>.gd` reports the error with a line number in ~10 s and caught two of my own this session. Worth a script (`e2e/check-syntax.mjs`) over all plugin files, run before the suite. Note it needs an `--import` pass first when a file introduces a new `class_name`, or every reference to it reads as "not declared in the current scope".

---

## Closed in Phase 9

---

### [x] 9.1 - Quick wins — done 2026-09-02
- [x] 9.1.1 - **Stop pretty-printing tool responses.** index.ts:146 was
  `JSON.stringify(result, null, 2)`; the reader is a model, not a human. Measured on a deep scene
  tree (short keys, heavy nesting — the shape agents request most): compact 10 273 chars vs pretty
  34 178, **+233 %**. Flat payloads cost tens of percent instead. **Done:** compact by default,
  `GODOT_MCP_PRETTY=1` restores indentation for reading responses by hand.
- [x] 9.1.2 - **Bind the bridge to `127.0.0.1`.** `new WebSocketServer({ port })`
  (godot-connection.ts:29) bound `::` — verified: `{"address":"::","family":"IPv6"}` — i.e. every
  interface, LAN included. **Done:** binds loopback, now verified as
  `{"address":"127.0.0.1","family":"IPv4"}`, with `GODOT_MCP_HOST` as a deliberate escape hatch
  for a remote editor. **Not a one-line change after all:** the plugin dialled `ws://localhost`,
  which resolves to `::1` first on Windows, so an IPv4-only bind would have left the editor
  knocking on an address nobody listens to. Both ends now say `127.0.0.1` (plugin.gd, and the
  fallback URL in websocket_client.gd), and the plugin reads `GODOT_MCP_HOST` the same way it
  already read `GODOT_MCP_PORT`. The authentication half is 9.5 — this only closes the network.
- [x] 9.1.3 - **Commit `package-lock.json`.** `@modelcontextprotocol/sdk: ^1.0.0` and `ws: ^8.18.0`
  are ranges, so another machine built a different server — and the e2e suite runs the production
  `dist`, which made a green run non-reproducible. **Done:** un-ignored and committed
  (lockfileVersion 3, 368 packages, pinning sdk 1.29.0 and ws 8.21.0 — what the green runs
  actually used). CI should use `npm ci`.
- [x] 9.1.4 - **Reconcile the docs with reality.** **Done:** README now says 216/216 tests and
  163/163 tools (was 191 and 162, and it disagreed with itself on 163 vs 162). The category table
  was also wrong in two rows — counted against the built registry: Scene is 10 (save_scene, 6.6.9),
  Editor is 8 (reload_scripts lives in Script). Sum reconciles to 163. docs/mcp_test_plan.md now
  carries a HISTORICAL banner naming `e2e/blocks/*.json` as the executable spec and listing the
  known drift, so an agent that finds it by search cannot mistake it for current.
- [x] 9.1.5 - **`.gitattributes`** with `* text=auto eol=lf`, explicit `eol=lf` for `.gd/.tscn/.tres/.cfg/.gdshader`,
  and binary markers. **Done.** `git add --renormalize .` produced no changes — the index was
  already LF throughout, so this is purely preventive and cost no churn.
- [x] 9.1.6 - **Ship `.mcp.json` as `.mcp.json.example`** — the committed one hardcoded
  `C:/Users/User/development/...`, breaking a clone and leaking the username. **Done:** untracked
  via `git rm --cached` (the working file stays on disk, so the live setup is untouched) and
  gitignored; the committed template carries the two field traps from 5.4.1 — the file must be
  named exactly `.mcp.json`, and must sit in the directory the client launches from. Closes 5.4.1.
- **Verified:** full e2e on **both** engines after the changes — **216 passed / 0 failed,
  163/163 tools** on 4.4.1 and 4.7.2. That is the real test of 9.1.2: the handshake happens over
  the new IPv4-only bind, and every assertion parses compact JSON.

---

### [x] 9.2 - Delete the dead code — ~1530 lines, 10 % of the codebase (done 2026-09-02)
Phase 1-2 scaffolding the final architecture routed around. Nothing in the import graph reaches
any of it (checked across every `.ts` and `.gd`).

| File | Lines | Referenced by |
|---|---|---|
| server/src/utils/type-parser.ts | 360 | nobody — type parsing happens in the plugin |
| server/src/tools/tool-validator.ts | 295 | nobody |
| server/src/protocol/mcp-protocol.ts | 189 | nobody — the SDK owns the protocol |
| server/src/types/tool-schema.ts | 126 | nobody — `types/index.ts` is the live one |
| addons/godot_mcp/undo_redo_manager.gd | 196 | **nobody** — all 54 call sites use `get_undo_redo()` directly |
| addons/godot_mcp/error_handler.gd | 171 | only protocol_handler.gd |
| addons/godot_mcp/protocol_handler.gd | 118 | nobody — plugin.gd parses JSON inline |
| addons/godot_mcp/message_serializer.gd | 75 | only protocol_handler.gd |

The last three are a closed island referencing only each other.

- [x] 9.2.1 - Delete the eight files. **Done 2026-09-02**, after the verification below.
- [x] 9.2.2 - **The project's only unit test covered dead code**: tests/type-parser.test.ts (26
  tests) imported `server/src/utils/type-parser.ts`, so "26/26 PASSED" in progress.md and
  BUILD_REPORT.md stated nothing about the shipped code. **Deleted with it.** The capability
  check asked for first found nothing to salvage: the TS module inferred a type from the literal
  (`"Vector3(1,2,3)"` → Vector3), while the plugin parses *by the target property's type*, which
  it gets from Godot's introspection — a different model the architecture does not use. If 6.1.3
  unit-tests parsing, it should test the plugin's rules, not resurrect these. `passWithNoTests`
  is set in server/vitest.config.ts so `npm test` does not fail on the now-empty suite; remove
  that line when 6.1.3 lands.
- **Verified before deleting** (the first pass had a false negative worth recording): a repo-wide
  text search over *every tracked file*, not just source — `.gd`, `.ts`, `.cfg`, `.tscn`, `.json`,
  `.md` — found no mention outside progress.md and the island's own files. Then each file's
  **actually declared** `class_name` was cross-checked against its users, which is how it emerged
  that undo_redo_manager.gd declares `GodotMCPUndoRedo`, **not** `GodotMCPUndoRedoManager` as the
  review assumed — the original grep searched a name that does not exist and got the right answer
  by luck. Also checked: no `preload`/`load`/`extends` by path anywhere in the plugin; plugin.cfg
  names only plugin.gd; the e2e project template only enables plugin.cfg; no `export *` barrels on
  the server side. Blind spot of the method, stated so it is not trusted blindly: a file reached
  by path or config rather than by identifier looks unused this way — `plugin.gd` itself reports
  "not used" — which is why the config and preload checks above are part of the evidence.
- **Then verified dynamically:** clean `rm -rf dist` rebuild + eslint pass, `e2e/check-syntax.mjs --all`
  parsing all **31** remaining plugin scripts standalone, and the full suite green on both engines —
  **216 passed / 0 failed, 163/163 tools** on 4.7.2 and 4.4.1.
- **Why it is not merely clutter:** e2e/check-syntax.mjs loads only plugin.gd's dependency graph,
  so the dead GDScript is never even parsed; and `undo_redo_manager.gd` reads as the intended
  UndoRedo path (progress.md 2.3 lists it as implemented), so the next author may start using it
  in parallel with the real practice. Every future grep for `_parse_color`, `serialize` or `error`
  pays for it in tokens.
- **Priority:** HIGH (cheap, and it removes a live trap)

---

### [x] 9.3 - Shared tool base class (done 2026-09-02) — **6.1.1 can now be written against it**
Duplicate helpers across addons/godot_mcp/tools/*.gd:

| Helper | Copies | Note |
|---|---|---|
| `_resolve_node` | 13 | **6 distinct implementations** (hashed normalized bodies) |
| `_as_bool` | 9 | introduced in 3.16b, spread by copy-paste |
| `_scene_root` | 8 | |
| `_parse_vector3` / `_parse_vector2` | 5 / 4 | 6.6.14 fixed exactly this class of bug in four files at once |
| `_add_to_scene` | 5 | |
| `_value_to_json` | 4 | fixed twice independently, in 3.7b and 3.18b |
| `_parse_color` | 4 | |
| `_write_file` / `_read_file` | 2 | 3.17b fixed `make_dir_recursive` in one copy only |

Six `_resolve_node` variants means six behaviours for the same bad path from an agent — this is
the mechanism behind three separate bug-fix rounds already recorded above.

- [x] 9.3.1 - `GodotMCPToolBase (RefCounted)` — **done 2026-09-02**, addons/godot_mcp/tool_base.gd.
  Holds `_plugin` and `_init(plugin = null)` (the default keeps `GodotMCPProjectTools.new()`
  working), `_scene_root()`, `_resolve_node()`, `_resolve_parent()`, `_add_to_scene()`,
  `_as_bool()`, `_value_to_json()`, `_ensure_dir_for()`, and thin `_parse_vector2/3`/`_parse_color`
  over GodotMCPTypeUtils. All 23 tool classes now extend it. **Net −714 lines** (850 deleted).
- **Where the copies disagreed, the union won — and two of the disagreements were bugs:**
  `_as_bool` in 8 of 9 files recognised only the literal string `"true"`, so a client sending `1`
  got `false`; the ninth (scene_3d) handled all three forms and is what the base does now.
  `_parse_color` in particle/scene_3d passed a `"Color(1, 0, 0)"` string straight to
  `Color(String)`, which expects HTML and pushes an engine error — the project's own documented
  shorthand failed in one tool and worked in another, the same shape of defect as 6.6.14. The new
  `GodotMCPTypeUtils.to_color()` takes Color, Dictionary, Array, `"Color(...)"`, `#rrggbb`, bare
  hex and a loose `"1, 0, 0"`. `_ensure_dir_for` folds in the 3.17b fix that had been applied to
  one of three copies: script_tools and scene_tools still called
  `DirAccess.make_dir_recursive_absolute()`, which does not exist before Godot 4.1, while the
  project targets 4.0+.
- [x] 9.3.2 - **Done.** plugin.gd registers from a list of classes in a loop — 69 lines of
  boilerplate became 8, and the `GodotMCPProjectTools.new()` / `.new(self)` inconsistency is gone.
  The list is a local `var`, not a `const`: an Array literal is not a constant expression in
  GDScript. **The syntax gate (6.6.15) caught that in 6 seconds** — `plugin.gd:19 Assigned value
  for constant "TOOL_CLASSES" isn't a constant expression` — instead of a 4-minute E2E run
  reporting "Tool not found" for all 163 tools.
- [x] 9.3.3 - **Done.** 23 Python-style `"""docstrings"""` (standalone string expressions, not
  documentation) became `##` comments in plugin.gd, tool_registry.gd and heartbeat.gd.
  protocol_handler.gd's 8 went with the file itself in 9.2.
- **Deliberately not merged, so the next reader does not re-open it:**
  - `_write_file`/`_read_file` (script_tools vs shader_tools) return different things by design —
    `Error`/`null` versus a message string / `{"error": ...}` — and their 13 call sites branch on
    that. Unifying means rewriting all 13 for no behavioural gain; the part that *was* shared and
    buggy (directory creation) is now `_ensure_dir_for` on the base.
  - `_value_to_json` in resource_tools stays an override: it is a serializer with an inverse
    (`_parse_prop_value` must read its output back), not a display conversion, and it summarises
    PackedByteArray rather than dumping megabytes (3.18b).
  - `_coerce_value` in animation vs node tools share a name but not a job: one coerces by the
    literal's shape, the other by the target property's Variant type.
  - `_get_filesystem` and `_collect_files_by_ext` (analysis vs batch, ~30 lines) are still
    duplicated — small, and untangling them was not worth extending an already large diff.
- **Verified after every stage:** `check-syntax --all` over all 32 scripts, then the full suite —
  **218 passed / 0 failed, 163/163 tools** on 4.7.2 and 4.4.1, and the plugin logs
  `Registered 163 tools from 23 categories`.

---

### [x] 9.4.1 / 9.4.2 — per-call timeouts and WebSocket buffers (done 2026-09-02)

---

- [x] 9.4.1 - **Per-tool timeouts. Done 2026-09-02.** godot-connection.ts:9 applied a flat `TOOL_TIMEOUT_MS = 15_000`
  to all 163 tools, while `listen_to_signal` allows `timeout` up to 30 s
  (runtime_tools.gd:534), `execute_script` up to 60 s (editor_tools.gd:422), and `export_project`
  runs a synchronous `OS.execute` (export_tools.gd:182) that blocks the editor's main thread for
  minutes. A legal `timeout: 20` therefore *always* fails on the server side — and the plugin
  stays `_tool_busy` (plugin.gd:255) for the remainder, so every following call answers "Another
  tool call is already in progress" without naming the cause. **Fixed:** `timeoutForCall()` derives
  the budget from the call itself — any `timeout`/`duration` argument (seconds) plus 10 s of slack
  for scheduling and serialising, clamped to [15 s, 10 min] — with a small table for the tools that
  are slow without saying so in their arguments (`export_project` 10 min, `run_automated_tests`,
  `bake_navigation`, the three `replay_*` 2 min). It lives in the transport rather than on each
  `ToolDefinition` because every one of the 163 handlers reaches the editor through this one call,
  so a per-definition field would have meant touching 23 files to be enforced in one.
  6.5.7 (queue instead of reject) will need to add queue wait to the same budget.
- [x] 9.4.2 - **Configure the WebSocket buffers. Done 2026-09-02.** websocket_client.gd never set
  `inbound_buffer_size` / `outbound_buffer_size` / `max_queued_packets`, so both directions cap at
  Godot's 64 KB default. A larger reply — `get_scene_tree` on a real scene (`max_depth` defaults
  to -1, scene_tools.gd:50), `list_project_files`, `search_in_scripts`, `get_project_settings` —
  makes `send()` fail, the result vanishes into a `push_error`, and the only symptom is the
  server's timeout. Presented as "the tools sometimes silently don't work on big projects".
  **Fixed:** 4 MB in both directions, set before `connect_to_url` (the peer sizes its buffers at
  connect time), `send_message()` now returns the error instead of swallowing it, and a reply that
  still will not fit is answered with a message small enough to get through — it names the byte
  count, the buffer size and what to narrow — rather than leaving the caller to wait out a timeout
  on a result that will never arrive.
- **Both fixes carry a regression test, and both tests were verified to fail without them**
  (e2e/blocks/05-editor.json): **E-11** pushes a 300 KB reply through the bridge — with the old
  64 KB buffer it fails, and usefully so: `Result could not be sent (300138 bytes, socket buffer is
  65535 bytes)`, which also exercises the new fallback path. **E-12** asks `execute_script` for a
  17 s timeout and expects the plugin's own watchdog to answer; forced back to the flat budget it
  fails with `Tool call timed out after 15000ms`, i.e. exactly the bug.
- **Verified:** **218 passed / 0 failed, 163/163 tools** on 4.7.2 and 4.4.1.

---

### [x] 9.8 - Editor error spam during tool calls (asked 2026-09-02, fixed same day)
The Output panel filled with engine errors during every e2e run. Triaged from the captured
editor log — note it is **append-only since July**, so a naive grep mixes in bugs closed back in
3.27; only the last `===== editor launch =====` section describes the current build. 33 error
lines per run on 4.4.1, identical on 4.7.2, i.e. deterministic rather than flaky.

- [x] 9.8.1 - **Progress-dialog cascade (12 of the 33 lines).** `Do not use progress dialog (task)
  while flushing the message queue or using call_deferred!` followed by eight
  `Condition "!tasks.has(p_task)" is true`. Since 6.6.1 the executed body starts through
  `call_deferred`, so it runs *during* the message-queue flush, where the editor refuses to open a
  progress task — and a body that scans the filesystem or reimports needs one. Not a test-only
  problem: any user script calling `EditorInterface.get_resource_filesystem().scan()` hit it.
  **Fixed:** the injected `_mcp_main` awaits one `process_frame` before calling the body, so the
  body runs off the flush. Costs nothing measurable — the watchdog loop already waits a frame.
- **The obvious fix crashed the editor, and the reason is worth keeping.** Starting the body from
  `create_timer(0.0).timeout.connect(...)` instead looked equivalent and took the editor down with
  a 1023-frame stack overflow (`_mcp_main` → `_mcp_body` → `_mcp_main` …, exit 0xC0000374). A
  SceneTreeTimer is removed from the tree's list only *after* its `timeout` returns, and a
  filesystem scan pumps the main loop from inside the callback — so the re-entrant pass finds the
  same timer still pending and fires it again, recursively. **Any callback that may re-enter the
  main loop must be started by something that consumes itself before running**: an `await`
  (resumes exactly once) or `call_deferred` (the message is popped before dispatch), never a
  signal connection that outlives its own emission.
- [x] 9.8.2 - **`create_animation` printed an engine error every time.**
  animation_tools.gd used `get_animation_library("")` as an existence probe, but that is an
  `ERR_FAIL_COND` inside the engine — `Method/function failed. Returning: Ref<AnimationLibrary>()`
  landed in the Output panel of every user adding a first animation. **Fixed:** `has_animation_library()`
  first, here and in `_delete_animation`.
- [x] 9.8.3 - **Screenshot cleanup raced the importer** (4 lines): the blocks deleted a PNG and
  immediately forced a scan, so the editor tried to import a file that was already gone.
  **Fixed** in blocks 05/10/21: remove the `.import` sidecar with the image and call
  `update_file()` before scanning.
- **Result: 33 → 18 lines on 4.4.1 and → 14 on 4.7.2, of which 13-16 are deliberate** — the suite
  feeds the parser broken code on purpose (E-08g/h, `validate_syntax`, `test_broken.gd`), and
  GDScript has no quiet compile: an engine error *is* the evidence the negative test reached its
  branch. One cosmetic line survives (`Can't find file 'res://screenshot_qa.png' during file
  reimport`) — the importer had queued the file before `update_file` could withdraw it.
- **Not a leak, in case it looks like one:** `res://addons/.godot_mcp_syntax_probe_*.gd` in the log
  is a *virtual* `resource_path` on an in-memory GDScript (script_tools.gd:254-258), chosen so the
  parser applies the addons warning opt-out. No such file is ever written.
- **Verified:** 216/216 on both 4.4.1 and 4.7.2 after the changes.

---

## Implementation notes, Phases 1-3

- ✅ Build & test complete (see BUILD_REPORT.md)
- ✅ All Phase 1-2 tasks implemented and validated
- ✅ Phase 3.1 - Project Tools (7 tools) implemented
- ✅ Phase 3.2 - Scene Tools (9 tools) implemented
- ✅ Phase 3.3 - Node Tools (14 tools) implemented (full UndoRedo + smart type coercion)
- ✅ Phase 3.4 - Script Tools (8 tools) implemented
- ✅ Phase 3.5 - Editor Tools (8 tools) implemented
- ✅ Phase 3.6 - Input Tools (7 tools) implemented (async record/replay via inner Node class)
- ✅ Phase 3.7 - Runtime Tools (19 tools) implemented (GameplayRecorder inner class, async listen_to_signal, incoming signal scan)
- ✅ Phase 3.8 - Animation Tools (6 tools) implemented (AnimationPlayer, UndoRedo, track types, keyframes, easing)
- ✅ Phase 3.9 - AnimationTree Tools (8 tools) implemented (StateMachine, BlendTree, BlendSpace1D/2D, UndoRedo)
- ✅ callable_tool.gd updated to support async functions (await)
- ✅ GodotConnection WebSocket bridge (server → Godot, port 6505)
- ✅ GodotMCPCallableTool wrapper (RefCounted, no Node overhead)
- ✅ Phase 3.10 - 3D Scene Tools (6 tools) implemented (MeshInstance3D, Camera3D, Light3D types, WorldEnvironment, GridMap, scene scan)
- ✅ Phase 3.11 - Physics Tools (6 tools) implemented (RigidBody3D/2D, CollisionShape3D/2D, layer/mask bitmask, RayCast3D/2D, physics info)
- ✅ Phase 3.12 - Particle Tools (5 tools) implemented
- ✅ Phase 3.13 - Navigation Tools (6 tools) implemented
- ✅ Phase 3.14 - Audio Tools (6 tools) implemented
- ✅ Phase 3.15 - TileMap Tools (6 tools) implemented
- ✅ Phase 3.16 - Theme/UI Tools (6 tools) implemented (file-based, no UndoRedo; CACHE_MODE_IGNORE, _as_bool, overwrite guard)
- ✅ Phase 3.17 - Shader Tools (6 tools) implemented (create/edit .gdshader, assign ShaderMaterial, set params, inspect, validate)
- ✅ Phase 3.18 - Resource Tools (6 tools) implemented (read/edit/create/save .tres resources, get_project_autoloads, set_autoload via EditorPlugin API; full type round-trip including Transform3D/Basis/Quaternion/Rect2i/Transform2D)
- ✅ Phase 3.19 - Batch/Refactor Tools (8 tools) implemented (SceneState-based find_by_node_type/script/group, bulk_rename with UndoRedo for current scene + all_scenes mode, cross_scene_update, find_dependencies with BFS, orphaned_resources with entry-point seeding, refactor_signals)
- ✅ Phase 3.20 - Analysis Tools (4 tools) implemented (analyze_scene_complexity via SceneState, trace_signal_flow with optional node filter, find_unused_resources with UID→path resolution for Godot 4.3+, get_code_metrics with per-file and aggregate stats)
- ✅ Phase 3.21 - Testing/QA Tools (6 tools) implemented (run_automated_tests with await-safe method dispatch, assert_node_state with int/float tolerance, compare_screenshots, record_test/replay_test with Godot 4.0-safe Input.parse_input_event, get_test_report)
- ✅ Phase 3.22 - Profiling Tools (2 tools) implemented (get_performance_monitors with per-category filter, navigation monitors guarded for Godot 4.1+; get_memory_usage with static/render breakdown + cached resource sample guarded for Godot 4.1+)
- ✅ Phase 3.23 - Export Tools (3 tools) implemented (list_export_presets via ConfigFile, export_project via OS.execute headless with merged output capture, get_template_info with version_string-based path lookup)
- 🎉 ALL 163 TOOLS IMPLEMENTED — Phase 3 complete
- ✅ Godot 4.4.1 compatibility verified: plugin loads with zero parse errors, registers 162 tools
- ✅ Godot 4.7.2 compatibility verified (2026-08-31): full E2E suite green, 191/191, no code changes required
- ✅ Type parser tested with 26 comprehensive tests

---

## The old "Summary Statistics" block, as it stood at the split

Kept for the record and **not carried into progress.md, because most of it was wrong** by
2026-09-03: the task count had stopped being updated around Phase 3; the type parser and its
26 tests were deleted in 9.2 (nothing imported them), so "26/26 PASSED" describes code that no
longer exists; the file counts predate 9.2's deletion of ~1530 lines; and BUILD_REPORT.md is
not in the repository and appears in no commit. The live status now sits at the top of
progress.md and is stated as the e2e suite reports it.

- **Total Planned Tasks:** ~100+
- **Completed Tasks:** 46 ✅ (Phases 1–2 + 3.1–3.23 Project/Scene/Node/Script/Editor/Input/Runtime/Animation/AnimationTree/3DScene/Physics/Particle/Navigation/Audio/TileMap/Theme/Shader/Resource/Batch/Analysis/Testing/Profiling/Export Tools)
- **Current Progress:** 100% (163/163 tools implemented)
- **Estimated Total Effort:** 120-150 hours

### Build & Test Results ✅
- **TypeScript Compilation:** SUCCESS (40 files compiled)
- **Type Parser Tests:** 26/26 PASSED
- **Code Quality:** PASS (ESLint clean)
- **Project Structure:** COMPLETE (40+ files, 9 GDScript + server code)
- **See:** `BUILD_REPORT.md` for details *(de-linked at the split: no such file exists)*

### Priority Distribution
- **HIGH:** ~30 tasks (Phases 1-3)
- **MEDIUM:** ~40 tasks (Phases 4-6)
- **LOW:** ~30 tasks (Phases 7-8)
