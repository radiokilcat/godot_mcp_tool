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

### [ ] 5.4 - Create .mcp.json Template — mostly done already
- [x] Create example config file — working [.mcp.json](.mcp.json) in the repo root
- [x] Document all options — README "Point your MCP client at it" covers the absolute-path requirement and `GODOT_MCP_PORT`
- [ ] 5.4.1 - Ship it as a copyable template rather than a live config, and document the two traps found in the field: the file must be named exactly `.mcp.json` and must sit in the directory the client is launched from (a config named otherwise, or one level down in the Godot project subfolder, is silently ignored)
- **Priority:** LOW (downgraded — the substance exists, only packaging is left)
- **Effort:** ~1 hour

---

## Phase 6: Testing & Quality Assurance

### [ ] 6.1 - Effect-level assertions (rescoped 2026-08-31, was "Unit Testing")
Original scope was per-category unit tests plus 80% coverage. 6.4 made that largely moot for
tool bodies — they are exercised end-to-end against a live editor. What 6.4 does **not** do is
check that a call changed anything: it asserts the tool's *response*, and 6.6 showed the
response is exactly what lies (6.6.1 and 6.6.8 both return `success: true` for work that never
happened). That is the gap worth closing.
- [x] Write tests for type parser — tests/type-parser.test.ts, 26 tests
- [ ] 6.1.1 - Add an effect-assertion vocabulary to the E2E DSL: read the setting back, stat the file on disk, re-read the node tree after a mutation
- [ ] 6.1.2 - Apply it to the tools that can silently no-op: `set_project_setting`, `execute_script`, `create_scene`, `save_scene`, the `add_*` family
- [ ] 6.1.3 - Unit-test the pure server-side modules that have no editor dependency (type coercion, tool-validator, message framing) — currently 1 test file for 31 modules
- **Priority:** HIGH
- **Effort:** 4-6 hours
- **Depends on:** 6.6 fixes landing first, so the assertions encode the corrected behaviour

### [x] 6.2 - Integration Testing — mostly absorbed by 6.4
- [x] Test WebSocket communication — full MCP stack over the bridge, 191 tests
- [x] Test plugin-server interaction — every one of 162 registered tools is called for real
- **Remaining, moved to 6.2b below:** undo/redo and auto-reconnect are genuinely untested
- **Priority:** HIGH

### [ ] 6.2b - Untested paths left over from 6.2 (2026-08-31)
- [ ] 6.2b.1 - **UndoRedo is asserted nowhere.** `grep -ri undo e2e/blocks/` returns nothing, yet "all mutations support Ctrl+Z" is a headline feature. Needs a block that mutates, undoes via the editor's UndoRedo, and re-reads the tree.
- [ ] 6.2b.2 - **Auto-reconnect is not exercised.** The only retry in the suite is client-side in e2e/lib/executor.mjs; the plugin's exponential backoff (1s→60s) has never been tested. Needs a block that kills the bridge mid-run and asserts the plugin comes back.
- **Priority:** MEDIUM

### [x] 6.3 - 2D & 3D Workflow Testing — covered by 6.4
- [x] 2D and 3D fixtures both live in the generated test project; 2D node types appear across blocks 02-09 and the 3D/physics/navigation blocks cover the 3D path
- [x] All 162 registered tools are called in both contexts where applicable (coverage diff vs tools/list is part of the report)
- **Priority:** HIGH

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

### [ ] 6.5 - Bridge port lifecycle & the multi-session story (discovered 2026-08-31; planned 2026-08-31)
- [ ] 6.5.1 - **Graceful shutdown**: `GodotConnection.close()` exists but is wired to no signal, so a closing client leaves an orphaned node process holding 6505 — which then blocks every later session until it is killed by hand. Hook `SIGTERM`/`SIGINT`/`exit`.
- [x] 6.5.2 - **Decide the multi-session story.** Original options were (a) auto-picked port + discovery file, (b) a long-lived broker owning 6505 with thin per-session stdio shims. **Decided 2026-08-31: neither — invert the transport instead (6.5.3-6.5.7).** Analysis below.

**Diagnosis (source-confirmed 2026-08-31)**

The transport direction is inverted relative to the lifetimes involved: the *Node server*
listens (godot-connection.ts:28, bound in the singleton's constructor at import time —
index.ts:39) and the *Godot plugin* dials in (websocket_client.gd:62). The machine-wide
resource is therefore owned by the most ephemeral process in the chain. Three consequences:

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
- **Priority:** MEDIUM — **deferred**, scheduled after the 6.6 blockers (6.6.1-6.6.5). 6.5.1 is independent and cheap; it can land at any time and reduces the pain until the rest ships.
- **Effort:** ~1 day for 6.5.3-6.5.7, plus 6.5.9 on top.

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
- [ ] 6.6.5 - **Compile errors carry no diagnostics.** `Script compilation failed (code 43). Check syntax.` — no line, no message (editor_tools.gd:140). `validate_syntax` has the same hole (script_tools.gd:234). A typo has to be found by eye. `GDScript.reload()` genuinely does not surface the parse message, so the fix means capturing stderr or the editor log around the probe.
- [x] 6.6.6 - **`create_scene` does not create directories.** scene_tools.gd:71 calls `ResourceSaver.save` straight into the path, so `res://scenes/lair/Lair.tscn` fails with "Can't open" when `lair/` is missing. Fix: `DirAccess.make_dir_recursive_absolute` on the parent first. **Fixed 2026-08-31:** `_ensure_dir_for()` in scene_tools.gd creates the tree before saving; used by both `create_scene` and `save_scene`. E2E S-11.
- [x] 6.6.7 - **`set_project_setting` writes ints as floats.** project_tools.gd:135 passes the JSON value through untouched, and JSON numbers arrive as `float` — `1920` lands in project.godot as `viewport_width=1920.0`. Fix: coerce to the existing setting's type (or the property-list type) before setting. **Fixed 2026-08-31:** `_coerce_numeric()` converts to the type the setting already holds (numeric types only — coercing a String would turn a typo into 0). Note: int-vs-float is not observable over JSON, so the E2E assertion covers the read-back, not the on-disk literal — see 6.1.1.
- [x] 6.6.8 - **A value equal to the engine default is silently not persisted.** `stretch/aspect = keep` returned `success: true` and never appeared in project.godot, because Godot omits defaults on save. The response echoes the *input* value (project_tools.gd:139) rather than reading back, so "did not apply" and "applied but not written" are indistinguishable. Fix: read the setting back and report the effective value. **Fixed 2026-08-31:** the response now reports the value read back from ProjectSettings, plus `is_engine_default: true` and an explaining note when the value matches `property_get_revert()`. E2E P-07b.
- [x] 6.6.9 - **No scene-save tool.** `add_node` / `set_node_property` mutate the open scene but nothing commits it; the only `ResourceSaver.save` in the scene path is inside `create_scene` (scene_tools.gd:92). Saving meant calling `save_scene()` by hand inside `execute_script`. Fix: add `save_scene` (and likely `save_all_scenes`). **Fixed 2026-08-31:** added `save_scene` (optional `scene_path` acts as save-as, directories created automatically). Uses `EditorInterface.save_scene()`/`save_scene_as()` — what Ctrl+S runs; `save_scene_as` returns void, so the write is confirmed by checking the file landed. E2E S-09d, S-12.

**API inconsistencies**
- [x] 6.6.10 - **`add_node` returns an unusable path.** node_tools.gd:163 returns `str(node.get_path())` — a screen-long `/root/@EditorNode@19513/@Panel@14/...` — while every other tool expects a scene-relative path. `_add_to_scene` in the 3D tools already does it right: `str(root.get_path_to(new_node))` (scene_3d_tools.gd:76). Fix: make node_tools match. **Fixed 2026-08-31:** returns `root.get_path_to(node)`, matching `_add_to_scene`. E2E N-01 asserts the exact relative path and that `@EditorNode` is absent.
- [ ] 6.6.11 - **`add_camera` cannot set `size`** — the one parameter that means anything for an orthographic camera. It accepts `fov`/`near`/`far` (scene_3d_tools.gd:180-213) and cheerfully returns `"fov": 75` for an orthographic camera (line 213). Fix: accept `size`, and return the projection-relevant field.
- [ ] 6.6.12 - **`add_mesh` gives no access to the mesh resource** — only the node transform (scene_3d_tools.gd:140-176). Primitives are born at engine defaults, so worker capsules came out 2.0 m tall instead of 1.8; dimensions and materials had to be finished in a script anyway. Fix: pass through the `PrimitiveMesh` properties (radius/height/size) and an optional material.
- [x] 6.6.14 - **String vectors were silently dropped outside node_tools** (found 2026-09-01 while testing 6.6.3). `_parse_vector2/3` in scene_3d_tools, physics_tools, particle_tools and navigation_tools accepted only a Vector, Dictionary or Array and returned the default for anything else — so `add_camera(position: "Vector3(0, 2, 5)")` put the camera at the origin and reported `success: true`, and the same held for `add_mesh`, `add_light`, `add_gridmap` (`cell_size`), the physics shape sizes and the particle/navigation vectors. The string form is the shorthand CLAUDE.md advertises and `set_node_property` already accepts, so it is the form an agent writes. **Fixed 2026-09-01:** new `addons/godot_mcp/type_utils.gd` (`GodotMCPTypeUtils.to_vector2/to_vector3`) parses all four shapes, the four tool files delegate to it, and the `vector2Schema`/`vector3Schema` in the four matching server files became `anyOf[object, string, array]` so clients see what is accepted (same treatment as `layersSchema` in 3.11b). E2E 3D-02 now verifies the camera's actual position rather than `success: true`.
- [x] 6.6.13 - **`get_node_properties` dumps ~40 properties with no filter** (node_tools.gd:273) — reading one `scale` returns a wall of text. Fix: an optional `names` / prefix filter. **Fixed 2026-08-31:** optional `names` array filters the result; unmatched names come back under `not_found` so a typo is not a silent empty list. E2E N-02b, N-02c.

**Test-suite gap:** the E2E suite is green at 191/191 across 162/162 tools, and caught none of
these. It asserts tool *responses*, and the responses are exactly what is wrong — 6.6.1 and
6.6.8 both report `success: true` for work that did not happen. Effect-level assertions
(read the setting back, verify the file on disk, check the node tree after the call) are what
would have caught them.
- **Priority:** HIGH (6.6.5 is the last of the blockers; the rest are papercuts)
- **Status:** 6.6.1/6.6.2/6.6.3/6.6.4 + 6.6.14 landed 2026-09-01 — every workaround the field report had to build (script output through `user://` files, the hand-rolled SubViewport render pipeline, `get_game_state` as an error-log substitute) now has a first-class path. E2E: **210 passed / 0 failed, coverage 163/163**, green on 4.7.2 and 4.4.1.
- [ ] 6.6.15 - **Add a fast GDScript syntax gate.** A parse error in any one plugin file makes `plugin.gd` fail to compile, so *every* tool disappears and the only symptom is `Tool not found: <anything>` — a 4-minute E2E run to discover a typo. `godot --headless --path <project> --check-only --script res://addons/godot_mcp/tools/<file>.gd` reports the error with a line number in ~10 s and caught two of my own this session. Worth a script (`e2e/check-syntax.mjs`) over all plugin files, run before the suite. Note it needs an `--import` pass first when a file introduces a new `class_name`, or every reference to it reads as "not declared in the current scope".

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

**Last Updated:** 2026-09-01 (field-report blockers cleared except 6.6.5: `execute_script` returns `output`/`errors`/`result` and finishes coroutines under a `timeout` watchdog (6.6.1/6.6.2); `take_screenshot` renders through a scene camera (6.6.3); `get_error_log` reads the log Godot actually writes — the editor writes none, game runs do (6.6.4); string vectors are no longer dropped by the 3D/physics/particle/navigation tools (6.6.14, found by the camera test). New: 6.6.15 proposes a 10-second syntax gate. Full E2E green on both engines: **210 passed / 0 failed, coverage 163/163**, verified on 4.7.2 and 4.4.1. Next: 6.6.5 (compile diagnostics — `--check-only` in a subprocess is a proven route), then 6.5.)

**Previously:** 2026-08-31 (6.5 expanded into a decided plan: transport inversion — the Godot plugin hosts the WebSocket server, MCP processes become clients — deferred until after the 6.6 blockers. 6.6 cheap batch landed: 6.6.6/6.6.7/6.6.8/6.6.9/6.6.10/6.6.13 fixed, new save_scene tool. Full E2E green on 4.7.2: **196 passed / 0 failed, coverage 163/163 tools**. 6.1 rescoped to effect-level assertions; 6.2/6.3 closed as absorbed by 6.4 with undo/reconnect split out as 6.2b; 5.4 downgraded. Remaining from the field report: 6.6.1-6.6.5, 6.6.11, 6.6.12.)
