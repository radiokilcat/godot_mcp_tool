# progress.md - Godot MCP Tool Project Tasks

**Project Start Date:** 2026-06-29  
**Status:** 🎯 Foundation Built & Tested ✅

---

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

### [x] 3.2 - Scene Tools (9 tools)
- [x] get_scene_tree
- [x] create_scene
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

### [ ] 5.4 - Create .mcp.json Template
- [ ] Create example config file
- [ ] Document all options
- [ ] Add comments and explanations
- **Priority:** HIGH
- **Effort:** 1-2 hours

---

## Phase 6: Testing & Quality Assurance

### [ ] 6.1 - Unit Testing
- [ ] Write tests for type parser
- [ ] Write tests for MCP protocol
- [ ] Write tests for each tool category
- [ ] Achieve 80%+ coverage
- **Priority:** HIGH
- **Effort:** 6-8 hours

### [ ] 6.2 - Integration Testing
- [ ] Test WebSocket communication
- [ ] Test plugin-server interaction
- [ ] Test undo/redo functionality
- [ ] Test auto-reconnect
- **Priority:** HIGH
- **Effort:** 4-5 hours

### [ ] 6.3 - 2D & 3D Workflow Testing
- [ ] Create 2D test project
- [ ] Create 3D test project
- [ ] Test all tools in both contexts
- **Priority:** HIGH
- **Effort:** 3-4 hours

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

### [ ] 6.5 - Bridge port lifecycle (discovered 2026-08-31)
- [ ] 6.5.1 - **Graceful shutdown**: `GodotConnection.close()` exists but is wired to no signal, so a closing client leaves an orphaned node process holding 6505 — which then blocks every later session until it is killed by hand. Hook `SIGTERM`/`SIGINT`/`exit`.
- [ ] 6.5.2 - **Decide the multi-session story**: each MCP client session spawns its own server process, but the bridge port is machine-wide, so two concurrent sessions cannot both reach the editor. Options: (a) auto-pick a free port plus a discovery file the plugin reads, (b) split into one long-lived broker owning 6505 and thin per-session stdio servers that attach to it. 3.28 only makes the collision legible — it does not fix it.
- **Priority:** MEDIUM

### [ ] 6.6 - Field report: 3D blockout session in a real project (dragon_hoard, 2026-08-31)
First sustained use of the toolset on real work rather than E2E fixtures. Node-graph
construction (`add_node`, `add_mesh`, `set_node_property`, `create_scene`) held up and
produced exactly the intended scene. **Everything on the feedback path — script output,
errors, and seeing the frame as the player sees it — had to be routed around through
files on disk.** Nearly all of the session's real work ended up inside `execute_script`
plus PowerShell file reads instead of the specialized tools. All items below are
confirmed against the source.

**Blocking — required workarounds**
- [ ] 6.6.1 - **`execute_script` drops coroutines.** `instance._run()` (editor_tools.gd:148) discards the return value, so a `_run()` containing `await` yields a `GDScriptFunctionState` that is never resumed — the whole tail of the script (saving a PNG, `queue_free`) silently never runs. `await RenderingServer.frame_post_draw` is the common case. Worse, editor_tools.gd:150 reports `success: true` regardless, and an orphaned `SubViewport` is left parented in the editor. Fix: detect `GDScriptFunctionState`, keep the instance alive, and `await` completion (callable_tool.gd already supports async tools).
- [ ] 6.6.2 - **`execute_script` returns no output.** `print()` goes to Godot's Output panel; the tool returns only "Check Godot Output panel" (editor_tools.gd:146-150 — the comment concedes capture is "not available"). The only way to get data out of the editor is writing to `user://` and reading it off disk. Fix: expose a collector (e.g. an injected `mcp_print()`/return-value convention) so `_run()` can hand structured data back.
- [ ] 6.6.3 - **No way to see what the player sees.** `take_screenshot` offers `editor`, `2d`, `3d` — all editor viewports via `EditorInterface.get_editor_viewport_*` (editor_tools.gd:46-56). Neither the running game window nor a render through the game camera is reachable. For an orthographic camera this is fatal: `size` cannot be tuned blind. Drove the entire offscreen `SubViewport` + `own_world_3d` pipeline. Fix: a `viewport: "game"` mode, or a first-class "render through camera N" tool.
- [ ] 6.6.4 - **`get_error_log` does not work out of the box.** editor_tools.gd:79 reads `<editor data dir>/logs/godot.log`, which the editor does not write unless file logging is on — so the tool answers "Log file not found. Run project with --verbose". There is no way to confirm a scene starts clean; `get_game_state` (scene/fps/is_playing) was the fallback. Fix: read the engine's actual log setting, or capture errors in-process.

**Smaller, but cost time**
- [ ] 6.6.5 - **Compile errors carry no diagnostics.** `Script compilation failed (code 43). Check syntax.` — no line, no message (editor_tools.gd:140). `validate_syntax` has the same hole (script_tools.gd:234). A typo has to be found by eye. `GDScript.reload()` genuinely does not surface the parse message, so the fix means capturing stderr or the editor log around the probe.
- [ ] 6.6.6 - **`create_scene` does not create directories.** scene_tools.gd:71 calls `ResourceSaver.save` straight into the path, so `res://scenes/lair/Lair.tscn` fails with "Can't open" when `lair/` is missing. Fix: `DirAccess.make_dir_recursive_absolute` on the parent first.
- [ ] 6.6.7 - **`set_project_setting` writes ints as floats.** project_tools.gd:135 passes the JSON value through untouched, and JSON numbers arrive as `float` — `1920` lands in project.godot as `viewport_width=1920.0`. Fix: coerce to the existing setting's type (or the property-list type) before setting.
- [ ] 6.6.8 - **A value equal to the engine default is silently not persisted.** `stretch/aspect = keep` returned `success: true` and never appeared in project.godot, because Godot omits defaults on save. The response echoes the *input* value (project_tools.gd:139) rather than reading back, so "did not apply" and "applied but not written" are indistinguishable. Fix: read the setting back and report the effective value.
- [ ] 6.6.9 - **No scene-save tool.** `add_node` / `set_node_property` mutate the open scene but nothing commits it; the only `ResourceSaver.save` in the scene path is inside `create_scene` (scene_tools.gd:92). Saving meant calling `save_scene()` by hand inside `execute_script`. Fix: add `save_scene` (and likely `save_all_scenes`).

**API inconsistencies**
- [ ] 6.6.10 - **`add_node` returns an unusable path.** node_tools.gd:163 returns `str(node.get_path())` — a screen-long `/root/@EditorNode@19513/@Panel@14/...` — while every other tool expects a scene-relative path. `_add_to_scene` in the 3D tools already does it right: `str(root.get_path_to(new_node))` (scene_3d_tools.gd:76). Fix: make node_tools match.
- [ ] 6.6.11 - **`add_camera` cannot set `size`** — the one parameter that means anything for an orthographic camera. It accepts `fov`/`near`/`far` (scene_3d_tools.gd:180-213) and cheerfully returns `"fov": 75` for an orthographic camera (line 213). Fix: accept `size`, and return the projection-relevant field.
- [ ] 6.6.12 - **`add_mesh` gives no access to the mesh resource** — only the node transform (scene_3d_tools.gd:140-176). Primitives are born at engine defaults, so worker capsules came out 2.0 m tall instead of 1.8; dimensions and materials had to be finished in a script anyway. Fix: pass through the `PrimitiveMesh` properties (radius/height/size) and an optional material.
- [ ] 6.6.13 - **`get_node_properties` dumps ~40 properties with no filter** (node_tools.gd:273) — reading one `scale` returns a wall of text. Fix: an optional `names` / prefix filter.

**Test-suite gap:** the E2E suite is green at 191/191 across 162/162 tools, and caught none of
these. It asserts tool *responses*, and the responses are exactly what is wrong — 6.6.1 and
6.6.8 both report `success: true` for work that did not happen. Effect-level assertions
(read the setting back, verify the file on disk, check the node tree after the call) are what
would have caught them.
- **Priority:** HIGH (6.6.1–6.6.4 block real 3D work; the rest are papercuts)

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

## Summary Statistics

- **Total Planned Tasks:** ~100+
- **Completed Tasks:** 46 ✅ (Phases 1–2 + 3.1–3.23 Project/Scene/Node/Script/Editor/Input/Runtime/Animation/AnimationTree/3DScene/Physics/Particle/Navigation/Audio/TileMap/Theme/Shader/Resource/Batch/Analysis/Testing/Profiling/Export Tools)
- **Current Progress:** 100% (163/163 tools implemented)
- **Estimated Total Effort:** 120-150 hours

### Build & Test Results ✅
- **TypeScript Compilation:** SUCCESS (40 files compiled)
- **Type Parser Tests:** 26/26 PASSED
- **Code Quality:** PASS (ESLint clean)
- **Project Structure:** COMPLETE (40+ files, 9 GDScript + server code)
- **See:** [BUILD_REPORT.md](BUILD_REPORT.md) for details

### Priority Distribution
- **HIGH:** ~30 tasks (Phases 1-3)
- **MEDIUM:** ~40 tasks (Phases 4-6)
- **LOW:** ~30 tasks (Phases 7-8)

---

## Notes

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
- 📝 Update this file after completing each task
- Add new subtasks as they are discovered
- Adjust priorities based on feedback
- Track blockers and dependencies
- Document any architectural decisions

**Last Updated:** 2026-08-31 (Godot 4.7.2 verified green: 191/191 tests, 162/162 tools, no code changes needed; e2e pre-import port isolation fixed (6.4.8); server now survives a failed bind (3.28); bridge port lifecycle opened as 6.5; field report from first real-project session opened as 6.6 — 13 findings, feedback path is the weak spot)
