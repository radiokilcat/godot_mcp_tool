# MCP Tool Test Plan — Godot MCP v1.0.0

**Purpose:** Step-by-step test plan for AI agents.  
**Format:** tool call → assert → (optional) cleanup.  
**Test project:** `res://` = `C:/Users/User/Documents/test_mcp`  
**Precondition:** Godot 4.4.1 open with the test project, godot_mcp plugin connected.

---

## Conventions

- `ASSERT field == value` — response field must match exactly
- `ASSERT field != null` — field is present and not null
- `ASSERT field contains X` — string/array contains X
- `ASSERT field >= N` — numeric comparison
- `ASSERT error contains X` — expected error (negative test)
- Variables `$VAR` — values saved from previous calls
- Each block starts with **SETUP** and ends with **CLEANUP**

---

## BLOCK 1 — Project Tools (7 tools)

### SETUP
No preconditions. A scene does not need to be open.

### P-01 — get_project_info
```json
{}
```
- ASSERT `project_name` != null
- ASSERT `godot_version` contains "4.4"
- ASSERT `project_path` != null
- Save: `$PROJECT_PATH = project_path`

### P-02 — get_editor_version
```json
{}
```
- ASSERT `version` contains "4.4.1"
- ASSERT `is_official` == true

### P-03 — list_project_files
```json
{ "path": "res://" }
```
- ASSERT `files` != null
- ASSERT `total` >= 1
- ASSERT `files` contains "res://icon.svg"

### P-04 — list_project_files with filter
```json
{ "path": "res://", "filter": ".gd" }
```
- ASSERT all elements of `files` end with ".gd"

### P-05 — search_files
```json
{ "query": "plugin", "type": "name" }
```
- ASSERT `results` != null
- ASSERT `results` contains a path with "plugin"

### P-06 — get_project_settings
```json
{}
```
- ASSERT response contains at least one setting (object is not empty)

### P-07 — set_project_setting + verify
```json
{ "setting": "application/config/description", "value": "MCP Test Project" }
```
- ASSERT `success` == true  
- **Verify:** call `get_project_settings` → ASSERT description == "MCP Test Project"

### P-08 — get_project_metadata
```json
{}
```
- ASSERT `features` != null
- ASSERT `renderer` != null

### P-09 — convert_uid (negative test — non-existent uid)
```json
{ "uid": "uid://invalid_test_uid_xyz" }
```
- ASSERT `error` != null (error expected)

### CLEANUP
```json
{ "setting": "application/config/description", "value": "" }
```
(reset description)

---

## BLOCK 2 — Scene Tools (9 tools)

### SETUP
No scene open.

### S-01 — get_scene_tree (no scene — negative test)
```json
{}
```
- ASSERT `error` contains "No scene"

### S-02 — create_scene
```json
{ "path": "res://test_scene.tscn", "root_type": "Node2D", "root_name": "TestRoot" }
```
- ASSERT `success` == true
- ASSERT `path` == "res://test_scene.tscn"

### S-03 — list_project_files after creation
```json
{ "path": "res://", "filter": ".tscn" }
```
- ASSERT `files` contains "res://test_scene.tscn"

### S-04 — open_scene
```json
{ "path": "res://test_scene.tscn" }
```
- ASSERT `success` == true

### S-05 — get_scene_tree (after opening)
```json
{}
```
- ASSERT `root` != null
- ASSERT `root.name` == "TestRoot"
- ASSERT `root.type` == "Node2D"

### S-06 — get_scene_info
```json
{ "path": "res://test_scene.tscn" }
```
- ASSERT `path` == "res://test_scene.tscn"
- ASSERT `root_type` == "Node2D"

### S-07 — list_open_scenes
```json
{}
```
- ASSERT `scenes` contains "res://test_scene.tscn"

### S-08 — instantiate_scene
Precondition: create a second scene to instantiate.
```json
{ "path": "res://test_prefab.tscn", "root_type": "Sprite2D", "root_name": "Prefab" }
```
- ASSERT `success` == true

Then reopen the main scene:
```json
{ "path": "res://test_scene.tscn" }
```

Instantiate:
```json
{ "scene_path": "res://test_prefab.tscn", "parent_path": ".", "name": "PrefabInstance" }
```
- ASSERT `success` == true  
- **Verify:** `get_scene_tree` → `root.children` contains a node named "PrefabInstance"

### S-09 — play_scene / stop_scene
```json
{ "path": "res://test_scene.tscn" }
```
*(play_scene)*
- ASSERT `success` == true (launched in editor)

```json
{}
```
*(stop_scene)*
- ASSERT `success` == true

### S-09b — remove instance before deleting prefab
⚠️ Must do this first — otherwise Godot shows a modal "cannot save scene" dialog that blocks the editor.

Reopen main scene and delete the instance node:
```json
{ "path": "res://test_scene.tscn" }
```
*(open_scene)*
```json
{ "node_path": "PrefabInstance" }
```
*(delete_node)*
- ASSERT `success` == true

Then save via script to flush the scene to disk:
```json
{ "script": "EditorInterface.save_scene()" }
```
*(execute_script)*
- ASSERT `success` == true

### S-10 — delete_scene
```json
{ "path": "res://test_prefab.tscn" }
```
- ASSERT `success` == true  
- **Verify:** `list_project_files` → `files` does NOT contain "res://test_prefab.tscn"

### CLEANUP
```json
{ "path": "res://test_scene.tscn" }
```
*(delete_scene)*

---

## BLOCK 3 — Node Tools (14 tools)

### SETUP
```json
{ "path": "res://test_nodes.tscn", "root_type": "Node2D", "root_name": "Root" }
```
*(create_scene)*
```json
{ "path": "res://test_nodes.tscn" }
```
*(open_scene)*

### N-01 — add_node
```json
{ "parent_path": ".", "type": "Label", "name": "LabelA" }
```
- ASSERT `success` == true  
- **Verify:** `get_scene_tree` → tree contains "LabelA"

### N-02 — get_node_properties
```json
{ "node_path": "LabelA" }
```
- ASSERT `properties` != null
- ASSERT `properties` contains key "text"

### N-03 — set_node_property + verify
```json
{ "node_path": "LabelA", "property": "text", "value": "Hello" }
```
- ASSERT `success` == true  
- **Verify:** `get_node_properties {"node_path":"LabelA"}` → `properties.text` == "Hello"

### N-04 — rename_node + verify
```json
{ "node_path": "LabelA", "new_name": "LabelRenamed" }
```
- ASSERT `success` == true  
- **Verify:** `get_scene_tree` → does NOT contain "LabelA", contains "LabelRenamed"

### N-05 — duplicate_node
```json
{ "node_path": "LabelRenamed", "new_name": "LabelCopy" }
```
- ASSERT `success` == true  
- **Verify:** `get_scene_tree` → contains both "LabelRenamed" and "LabelCopy"

### N-06 — get_node_children
```json
{ "node_path": "." }
```
- ASSERT `children` != null
- ASSERT `children` contains "LabelRenamed"
- ASSERT `children` contains "LabelCopy"

### N-07 — get_node_parent
```json
{ "node_path": "LabelRenamed" }
```
- ASSERT `parent_path` == "." or "Root"

### N-08 — add_to_group + verify
```json
{ "node_path": "LabelRenamed", "group": "test_group" }
```
- ASSERT `success` == true  
- **Verify:** `get_node_groups {"node_path":"LabelRenamed"}` → `groups` contains "test_group"

### N-09 — get_node_groups
```json
{ "node_path": "LabelRenamed" }
```
- ASSERT `groups` contains "test_group"

### N-10 — remove_from_group + verify
```json
{ "node_path": "LabelRenamed", "group": "test_group" }
```
- ASSERT `success` == true  
- **Verify:** `get_node_groups` → `groups` does NOT contain "test_group"

### N-11 — get_node_signals
```json
{ "node_path": "LabelRenamed" }
```
- ASSERT `signals` != null (Label inherits signals from base class)

### N-12 — add_node (Button for signal test)
```json
{ "parent_path": ".", "type": "Button", "name": "TestBtn" }
```
- ASSERT `success` == true

### N-13 — connect_signal + verify
```json
{
  "source_path": "TestBtn",
  "signal_name": "pressed",
  "target_path": ".",
  "method_name": "_on_btn_pressed"
}
```
- ASSERT `success` == true  
- **Verify:** `get_node_signals {"node_path":"TestBtn"}` → signal "pressed" has connections with target "."

### N-14 — move_node + verify
```json
{ "node_path": "LabelCopy", "new_parent_path": "TestBtn" }
```
- ASSERT `success` == true  
- **Verify:** `get_node_parent {"node_path":"TestBtn/LabelCopy"}` → parent contains "TestBtn"

### N-15 — delete_node + verify
```json
{ "node_path": "TestBtn/LabelCopy" }
```
- ASSERT `success` == true  
- **Verify:** `get_scene_tree` → does NOT contain "LabelCopy"

### CLEANUP
*(delete_scene)*
```json
{ "path": "res://test_nodes.tscn" }
```

---

## BLOCK 4 — Script Tools (8 tools)

### SETUP
Create and open scene `res://test_scripts.tscn` with Node2D root.

### SC-01 — create_script
```json
{
  "path": "res://test_tool.gd",
  "content": "extends Node\n\nvar value: int = 0\n\nfunc increment() -> void:\n\tvalue += 1\n\nfunc get_value() -> int:\n\treturn value\n"
}
```
- ASSERT `success` == true

### SC-02 — read_script + verify
```json
{ "path": "res://test_tool.gd" }
```
- ASSERT `content` contains "func increment"
- ASSERT `content` contains "extends Node"

### SC-03 — validate_syntax (valid)
```json
{ "path": "res://test_tool.gd" }
```
- ASSERT `valid` == true
- ASSERT `errors` == [] or null

### SC-04 — create_script with syntax error
```json
{
  "path": "res://test_broken.gd",
  "content": "extends Node\n\nfunc broken(\n\tpass\n"
}
```
- ASSERT `success` == true (file is created)

### SC-05 — validate_syntax (invalid)
```json
{ "path": "res://test_broken.gd" }
```
- ASSERT `valid` == false
- ASSERT `errors` != null and non-empty

### SC-06 — edit_script + verify
```json
{
  "path": "res://test_tool.gd",
  "content": "extends Node\n\nvar value: int = 0\n\nfunc increment(step: int = 1) -> void:\n\tvalue += step\n\nfunc get_value() -> int:\n\treturn value\n\nfunc reset() -> void:\n\tvalue = 0\n"
}
```
- ASSERT `success` == true  
- **Verify:** `read_script` → content contains "func reset"

### SC-07 — get_script_info
```json
{ "path": "res://test_tool.gd" }
```
- ASSERT `path` == "res://test_tool.gd"
- ASSERT `base_class` == "Node"
- ASSERT `methods` contains "increment"
- ASSERT `methods` contains "get_value"

### SC-08 — attach_script + verify
```json
{ "node_path": ".", "script_path": "res://test_tool.gd" }
```
- ASSERT `success` == true  
- **Verify:** `get_node_properties {"node_path":"."}` → properties contains "script"

### SC-09 — search_in_scripts
```json
{ "query": "increment", "path": "res://" }
```
- ASSERT `results` != null
- ASSERT `results` contains "res://test_tool.gd"

### SC-10 — reload_scripts
```json
{}
```
- ASSERT `success` == true

### CLEANUP
- delete res://test_tool.gd
- delete res://test_broken.gd
- delete res://test_scripts.tscn

---

## BLOCK 5 — Editor Tools (9 tools)

### E-01 — get_editor_state
```json
{}
```
- ASSERT `has_open_scene` is a boolean (true or false)
- ASSERT `godot_version` != null

### E-02 — get_editor_state (with scene open)
Open any scene, then:
```json
{}
```
- ASSERT `has_open_scene` == true
- ASSERT `current_scene` != null

### E-03 — get_error_log
```json
{}
```
- ASSERT response does not contain its own error (may be empty)

### E-04 — take_screenshot
```json
{}
```
- ASSERT `success` == true
- ASSERT `path` != null (path to saved file)
- ASSERT `width` >= 800
- ASSERT `height` >= 600  
- **Verify:** `list_project_files` → screenshot file is present

### E-05 — select_node_in_editor
Precondition: scene open with node "Root".
```json
{ "node_path": "." }
```
- ASSERT `success` == true

### E-06 — get_editor_state (verify selected node)
```json
{}
```
- ASSERT `selected_node` != null

### E-07 — focus_editor
```json
{}
```
- ASSERT `success` == true

### E-08 — execute_script
```json
{ "script": "return 2 + 2" }
```
- ASSERT `result` == 4

### E-09 — execute_script (side-effect)
```json
{ "script": "EditorInterface.get_editor_main_screen().show()" }
```
- ASSERT `success` == true (no error)

### E-10 — open_editor_settings
```json
{}
```
- ASSERT `success` == true

---

## BLOCK 6 — Input Tools (7 tools)

### SETUP
Open a scene, launch the game (`play_scene`) so input is processed.

### I-01 — simulate_key_press
```json
{ "key": "KEY_A", "pressed": true }
```
- ASSERT `success` == true

### I-02 — simulate_key_press (release)
```json
{ "key": "KEY_A", "pressed": false }
```
- ASSERT `success` == true

### I-03 — simulate_mouse_move
```json
{ "x": 400, "y": 300 }
```
- ASSERT `success` == true

### I-04 — simulate_mouse_click
```json
{ "button": 1, "x": 400, "y": 300, "pressed": true }
```
- ASSERT `success` == true

### I-05 — trigger_input_action
```json
{ "action": "ui_accept", "pressed": true }
```
- ASSERT `success` == true

### I-06 — record_input_sequence
```json
{ "duration": 2.0 }
```
- ASSERT `success` == true
- Save: `$SEQUENCE_ID = id`

### I-07 — replay_input_sequence
```json
{ "id": "$SEQUENCE_ID" }
```
- ASSERT `success` == true

### I-08 — configure_input_mapping (add action)
```json
{
  "action": "test_action_mcp",
  "keys": ["KEY_F12"]
}
```
- ASSERT `success` == true

### I-09 — configure_input_mapping (remove action)
```json
{
  "action": "test_action_mcp",
  "remove": true
}
```
- ASSERT `success` == true

### CLEANUP
`stop_scene`

---

## BLOCK 7 — Runtime Tools (19 tools)

### SETUP
Launch game: `play_scene { "path": "res://test_scene.tscn" }`

### R-01 — get_game_state
```json
{}
```
- ASSERT `is_running` == true
- ASSERT `is_paused` == false
- ASSERT `fps` >= 0

### R-02 — pause_game
```json
{}
```
- ASSERT `success` == true  
- **Verify:** `get_game_state` → `is_paused` == true

### R-03 — resume_game
```json
{}
```
- ASSERT `success` == true  
- **Verify:** `get_game_state` → `is_paused` == false

### R-04 — set_game_speed
```json
{ "speed": 0.5 }
```
- ASSERT `success` == true  
- **Verify:** `get_game_state` → `speed_scale` == 0.5

Restore speed:
```json
{ "speed": 1.0 }
```

### R-05 — get_node_tree_runtime
```json
{}
```
- ASSERT `root` != null

### R-06 — inspect_node_at_runtime
```json
{ "node_path": "/root" }
```
- ASSERT `name` == "root" or != null
- ASSERT `type` != null

### R-07 — get_performance_metrics
```json
{}
```
- ASSERT `fps` >= 0
- ASSERT `memory_static` >= 0

### R-08 — list_loaded_resources
```json
{}
```
- ASSERT `resources` != null

### R-09 — list_autoloads
```json
{}
```
- ASSERT `autoloads` != null (list may be empty)

### R-10 — get_variable_value
```json
{ "node_path": "/root", "variable": "name" }
```
- ASSERT `value` != null

### R-11 — call_function
```json
{ "node_path": "/root", "function": "get_name", "args": [] }
```
- ASSERT `result` != null

### R-12 — emit_signal
```json
{
  "node_path": "/root",
  "signal_name": "child_entered_tree",
  "args": []
}
```
- ASSERT `success` == true OR `error` contains "signal" (if node does not have that signal)

### R-13 — listen_to_signal
```json
{
  "node_path": "/root",
  "signal_name": "child_entered_tree",
  "timeout": 3.0
}
```
- ASSERT does not crash with error (timeout result is acceptable)

### R-14 — navigate_to_node
```json
{ "node_path": "/root" }
```
- ASSERT `success` == true

### R-15 — click_ui_element (if UI node exists)
```json
{ "node_path": "/root/TestBtn" }
```
- ASSERT `success` == true OR `error` contains "not found" (if node does not exist at runtime)

### R-16 — get_signal_connections
```json
{ "node_path": "/root" }
```
- ASSERT `connections` != null

### R-17 — record_gameplay
```json
{ "duration": 2.0 }
```
- ASSERT `success` == true
- Save: `$GAMEPLAY_ID = id`

### R-18 — replay_gameplay
```json
{ "id": "$GAMEPLAY_ID" }
```
- ASSERT `success` == true

### R-19 — set_variable_value
```json
{ "node_path": "/root", "variable": "_mcp_test_var", "value": 42 }
```
- ASSERT `success` == true OR `error` != null (expected error if variable does not exist)

### CLEANUP
`stop_scene`

---

## BLOCK 8 — Animation Tools (6 tools)

### SETUP
Create and open `res://test_anim.tscn` with Node2D root, add an AnimationPlayer node named "AnimPlayer".

### AN-01 — create_animation
```json
{
  "player_path": "AnimPlayer",
  "animation_name": "test_anim",
  "length": 1.0,
  "loop": false
}
```
- ASSERT `success` == true

### AN-02 — get_animation_info
```json
{ "player_path": "AnimPlayer", "animation_name": "test_anim" }
```
- ASSERT `name` == "test_anim"
- ASSERT `length` == 1.0
- ASSERT `tracks` != null

### AN-03 — add_animation_track
```json
{
  "player_path": "AnimPlayer",
  "animation_name": "test_anim",
  "track_type": "value",
  "node_path": ".",
  "property": "position"
}
```
- ASSERT `success` == true
- Save: `$TRACK_IDX = track_index`

### AN-04 — add_keyframe
```json
{
  "player_path": "AnimPlayer",
  "animation_name": "test_anim",
  "track_index": "$TRACK_IDX",
  "time": 0.0,
  "value": "Vector2(0, 0)"
}
```
- ASSERT `success` == true

```json
{
  "player_path": "AnimPlayer",
  "animation_name": "test_anim",
  "track_index": "$TRACK_IDX",
  "time": 1.0,
  "value": "Vector2(100, 0)"
}
```
- ASSERT `success` == true

### AN-05 — set_easing
```json
{
  "player_path": "AnimPlayer",
  "animation_name": "test_anim",
  "track_index": "$TRACK_IDX",
  "key_index": 0,
  "ease_type": "ease_in_out"
}
```
- ASSERT `success` == true

### AN-06 — get_animation_info (verify keyframes)
```json
{ "player_path": "AnimPlayer", "animation_name": "test_anim" }
```
- ASSERT `tracks[0].key_count` >= 2

### AN-07 — delete_animation
```json
{ "player_path": "AnimPlayer", "animation_name": "test_anim" }
```
- ASSERT `success` == true  
- **Verify:** `get_animation_info` → `error` != null (animation deleted)

### CLEANUP
delete `res://test_anim.tscn`

---

## BLOCK 9 — AnimationTree Tools (8 tools)

### SETUP
Create `res://test_animtree.tscn`, add AnimationPlayer ("AP") and AnimationTree ("AT").

### AT-01 — create_animation_tree
```json
{
  "node_path": "AT",
  "animation_player_path": "../AP"
}
```
- ASSERT `success` == true

### AT-02 — create_state_machine
```json
{ "tree_path": "AT", "sm_name": "StateMachine" }
```
- ASSERT `success` == true

### AT-03 — get_state_machine_info
```json
{ "tree_path": "AT" }
```
- ASSERT `states` != null
- ASSERT `states` contains "Start" and "End" (or at least one state)

### AT-04 — add_transition
Precondition: add state "Idle":
```json
{
  "tree_path": "AT",
  "state_name": "Idle"
}
```
```json
{
  "tree_path": "AT",
  "from_state": "Start",
  "to_state": "Idle",
  "condition": ""
}
```
- ASSERT `success` == true

### AT-05 — set_active_state
```json
{ "tree_path": "AT", "active": true }
```
- ASSERT `success` == true

### AT-06 — add_blend_tree
```json
{ "tree_path": "AT", "blend_type": "BlendSpace1D" }
```
- ASSERT `success` == true OR a valid error if root is already set

### AT-07 — edit_blend_space
```json
{
  "tree_path": "AT",
  "action": "list_points"
}
```
- ASSERT `success` == true
- ASSERT `points` != null

### AT-08 — delete_animation_tree_node
```json
{ "tree_path": "AT", "state_name": "Idle" }
```
- ASSERT `success` == true  
- **Verify:** `get_state_machine_info` → states does NOT contain "Idle"

### CLEANUP
delete `res://test_animtree.tscn`

---

## BLOCK 10 — 3D Scene Tools (6 tools)

### SETUP
Create and open `res://test_3d.tscn` with Node3D root.

### 3D-01 — add_mesh
```json
{
  "parent_path": ".",
  "mesh_type": "BoxMesh",
  "name": "TestBox",
  "size": "Vector3(1, 1, 1)"
}
```
- ASSERT `success` == true  
- **Verify:** `get_scene_tree` → contains "TestBox"

### 3D-02 — add_camera
```json
{
  "parent_path": ".",
  "name": "TestCam",
  "position": "Vector3(0, 2, 5)"
}
```
- ASSERT `success` == true

### 3D-03 — add_light
```json
{
  "parent_path": ".",
  "light_type": "DirectionalLight3D",
  "name": "TestLight"
}
```
- ASSERT `success` == true

### 3D-04 — set_environment
```json
{
  "sky_type": "Sky",
  "ambient_light": "Color(0.2, 0.2, 0.2)"
}
```
- ASSERT `success` == true

### 3D-05 — get_3d_scene_info
```json
{}
```
- ASSERT `mesh_count` >= 1
- ASSERT `light_count` >= 1
- ASSERT `camera_count` >= 1

### 3D-06 — add_gridmap
```json
{
  "parent_path": ".",
  "name": "TestGrid",
  "cell_size": "Vector3(1, 1, 1)"
}
```
- ASSERT `success` == true

### CLEANUP
delete `res://test_3d.tscn`

---

## BLOCK 11 — Physics Tools (6 tools)

### SETUP
Create `res://test_physics.tscn` with Node2D root.

### PH-01 — add_rigid_body (2D)
```json
{
  "parent_path": ".",
  "name": "Body2D",
  "dimension": "2d",
  "position": "Vector2(100, 100)"
}
```
- ASSERT `success` == true

### PH-02 — add_collision_shape (2D)
```json
{
  "parent_path": "Body2D",
  "shape_type": "circle",
  "name": "Shape2D",
  "dimension": "2d",
  "radius": 32.0
}
```
- ASSERT `success` == true

### PH-03 — set_collision_layer
```json
{
  "node_path": "Body2D",
  "layers": [1, 2]
}
```
- ASSERT `success` == true

### PH-04 — set_collision_mask
```json
{
  "node_path": "Body2D",
  "layers": [1]
}
```
- ASSERT `success` == true

### PH-05 — add_raycast (2D)
```json
{
  "parent_path": ".",
  "name": "Ray2D",
  "dimension": "2d",
  "target": "Vector2(0, 100)"
}
```
- ASSERT `success` == true

### PH-06 — get_physics_info
```json
{ "node_path": "Body2D" }
```
- ASSERT `type` contains "RigidBody"
- ASSERT `collision_layer` != null

### CLEANUP
delete `res://test_physics.tscn`

---

## BLOCK 12 — Particle Tools (5 tools)

### SETUP
Create `res://test_particles.tscn` with Node2D root.

### PT-01 — create_particle_system
```json
{
  "parent_path": ".",
  "name": "Particles",
  "dimension": "2d",
  "amount": 50
}
```
- ASSERT `success` == true

### PT-02 — get_particle_info
```json
{ "node_path": "Particles" }
```
- ASSERT `amount` == 50
- ASSERT `emitting` != null

### PT-03 — set_particle_material
```json
{
  "node_path": "Particles",
  "material_type": "ParticleProcessMaterial"
}
```
- ASSERT `success` == true

### PT-04 — set_particle_gradient
```json
{
  "node_path": "Particles",
  "gradient_type": "color_ramp",
  "colors": ["#ff0000", "#0000ff"],
  "offsets": [0.0, 1.0]
}
```
- ASSERT `success` == true

### PT-05 — load_particle_preset
```json
{
  "node_path": "Particles",
  "preset": "fire"
}
```
- ASSERT `success` == true

### CLEANUP
delete `res://test_particles.tscn`

---

## BLOCK 13 — Navigation Tools (6 tools)

### SETUP
Create `res://test_nav.tscn` with Node2D root.

### NAV-01 — add_navigation_region (2D)
```json
{
  "parent_path": ".",
  "name": "NavRegion",
  "dimension": "2d"
}
```
- ASSERT `success` == true

### NAV-02 — add_navigation_agent (2D)
```json
{
  "parent_path": ".",
  "name": "NavAgent",
  "dimension": "2d"
}
```
- ASSERT `success` == true

### NAV-03 — set_navigation_layer
```json
{
  "node_path": "NavRegion",
  "layers": [1]
}
```
- ASSERT `success` == true

### NAV-04 — get_navigation_info
```json
{}
```
- ASSERT `regions` != null

### NAV-05 — get_navigation_path
```json
{
  "from": "Vector2(0, 0)",
  "to": "Vector2(100, 100)",
  "dimension": "2d"
}
```
- ASSERT `path` != null (may be empty if no baked mesh)

### NAV-06 — bake_navigation
```json
{ "region_path": "NavRegion" }
```
- ASSERT `success` == true OR `error` contains "mesh" (no NavigationMesh — expected)

### CLEANUP
delete `res://test_nav.tscn`

---

## BLOCK 14 — Audio Tools (6 tools)

### SETUP
Create `res://test_audio.tscn` with Node root.

### AU-01 — add_audio_player
```json
{
  "parent_path": ".",
  "name": "Player",
  "stream_type": "2d"
}
```
- ASSERT `success` == true

### AU-02 — configure_bus
```json
{
  "bus_name": "Master",
  "volume_db": -6.0
}
```
- ASSERT `success` == true

### AU-03 — add_audio_effect
```json
{
  "bus_name": "Master",
  "effect_type": "AudioEffectReverb",
  "effect_name": "TestReverb"
}
```
- ASSERT `success` == true

### AU-04 — configure_bus (reset volume)
```json
{ "bus_name": "Master", "volume_db": 0.0 }
```
- ASSERT `success` == true

### AU-05 — load_audio_file (negative — non-existent file)
```json
{
  "node_path": "Player",
  "file_path": "res://nonexistent.ogg"
}
```
- ASSERT `error` != null

### AU-06 — play_audio / stop_audio (no file — expected error)
```json
{ "node_path": "Player" }
```
*(play_audio)*
- ASSERT `success` == true OR `error` contains "stream" (no stream loaded)

### CLEANUP
delete `res://test_audio.tscn`

---

## BLOCK 15 — TileMap Tools (6 tools)

### SETUP
Create `res://test_tilemap.tscn` with Node2D root, add a TileMapLayer node named "TileMap" (Godot 4.4+).

### TM-01 — get_tilemap_info
```json
{ "node_path": "TileMap" }
```
- ASSERT `has_tiles` != null
- ASSERT `cell_size` != null

### TM-02 — get_tileset_info (no TileSet — expected error)
```json
{ "node_path": "TileMap" }
```
- ASSERT `error` != null OR `sources` == [] (no TileSet)

### TM-03 — set_tile_cell (no TileSet — expected error)
```json
{
  "node_path": "TileMap",
  "x": 0, "y": 0,
  "source_id": 0,
  "atlas_x": 0, "atlas_y": 0
}
```
- ASSERT `error` contains "source" OR `error` contains "TileSet"

### TM-04 — query_tile_cell (empty cell)
```json
{ "node_path": "TileMap", "x": 0, "y": 0 }
```
- ASSERT `is_empty` == true OR response contains cell data

### TM-05 — erase_tile_cell (empty — no-op)
```json
{ "node_path": "TileMap", "x": 0, "y": 0 }
```
- ASSERT `success` == true (erasing empty cell is valid)

### TM-06 — fill_tiles (no TileSet — expected error)
```json
{
  "node_path": "TileMap",
  "from_x": 0, "from_y": 0,
  "to_x": 2, "to_y": 2,
  "source_id": 0
}
```
- ASSERT `error` != null

### CLEANUP
delete `res://test_tilemap.tscn`

---

## BLOCK 16 — Theme/UI Tools (6 tools)

### TH-01 — create_theme
```json
{
  "path": "res://test.theme",
  "overwrite": true
}
```
- ASSERT `success` == true

### TH-02 — create_theme (again without overwrite — expected error)
```json
{ "path": "res://test.theme" }
```
- ASSERT `error` contains "exists" OR "overwrite"

### TH-03 — set_theme_color
```json
{
  "theme_path": "res://test.theme",
  "type": "Button",
  "name": "font_color",
  "color": "#ff0000"
}
```
- ASSERT `success` == true

### TH-04 — set_theme_constant
```json
{
  "theme_path": "res://test.theme",
  "type": "Button",
  "name": "outline_size",
  "value": 2
}
```
- ASSERT `success` == true

### TH-05 — set_stylebox
```json
{
  "theme_path": "res://test.theme",
  "type": "Button",
  "name": "normal",
  "stylebox_type": "StyleBoxFlat",
  "bg_color": "#334455"
}
```
- ASSERT `success` == true

### TH-06 — get_theme_info
```json
{ "theme_path": "res://test.theme" }
```
- ASSERT `types` contains "Button"

### CLEANUP
(the .theme file remains as a test resource; delete manually if needed)

---

## BLOCK 17 — Shader Tools (6 tools)

### SH-01 — create_shader
```json
{
  "path": "res://test_shader.gdshader",
  "shader_type": "spatial",
  "template": "unshaded"
}
```
- ASSERT `success` == true

### SH-02 — get_shader_info
```json
{ "path": "res://test_shader.gdshader" }
```
- ASSERT `shader_type` == "spatial"
- ASSERT `uniforms` != null

### SH-03 — validate_shader (valid)
```json
{ "path": "res://test_shader.gdshader" }
```
- ASSERT `valid` == true

### SH-04 — edit_shader
```json
{
  "path": "res://test_shader.gdshader",
  "content": "shader_type spatial;\n\nuniform vec4 albedo : source_color = vec4(1.0);\n\nvoid fragment() {\n\tALBEDO = albedo.rgb;\n}\n"
}
```
- ASSERT `success` == true

### SH-05 — validate_shader (after editing)
```json
{ "path": "res://test_shader.gdshader" }
```
- ASSERT `valid` == true
- ASSERT `uniforms` contains "albedo"

### SH-06 — assign_material
Precondition: create a scene with MeshInstance3D.
```json
{
  "node_path": "TestBox",
  "shader_path": "res://test_shader.gdshader"
}
```
- ASSERT `success` == true

### SH-07 — set_shader_param
```json
{
  "node_path": "TestBox",
  "param_name": "albedo",
  "value": "Color(0, 1, 0, 1)"
}
```
- ASSERT `success` == true

### CLEANUP
delete `res://test_shader.gdshader`

---

## BLOCK 18 — Resource Tools (6 tools)

### RS-01 — create_resource
```json
{
  "path": "res://test_res.tres",
  "type": "Resource",
  "properties": {}
}
```
- ASSERT `success` == true

### RS-02 — read_resource
```json
{ "path": "res://test_res.tres" }
```
- ASSERT `type` != null
- ASSERT `properties` != null

### RS-03 — edit_resource
```json
{
  "path": "res://test_res.tres",
  "properties": { "resource_name": "MCPTestResource" }
}
```
- ASSERT `success` == true  
- **Verify:** `read_resource` → `properties.resource_name` == "MCPTestResource"

### RS-04 — save_resource
```json
{ "path": "res://test_res.tres" }
```
- ASSERT `success` == true

### RS-05 — get_project_autoloads
```json
{}
```
- ASSERT `autoloads` != null (list may be empty)

### RS-06 — set_autoload (add)
```json
{
  "action": "add",
  "name": "MCPTestAutoload",
  "path": "res://test_tool.gd"
}
```
- ASSERT `success` == true  
- **Verify:** `get_project_autoloads` → contains "MCPTestAutoload"

### RS-07 — set_autoload (remove)
```json
{
  "action": "remove",
  "name": "MCPTestAutoload"
}
```
- ASSERT `success` == true  
- **Verify:** `get_project_autoloads` → does NOT contain "MCPTestAutoload"

### RS-08 — set_autoload (invalid action — expected error)
```json
{
  "action": "update",
  "name": "MCPTestAutoload"
}
```
- ASSERT `error` != null

### CLEANUP
delete `res://test_res.tres`

---

## BLOCK 19 — Batch/Refactor Tools (8 tools)

### SETUP
Create 2–3 scenes with Label nodes.

### BR-01 — find_by_node_type
```json
{ "node_type": "Label" }
```
- ASSERT `results` != null

### BR-02 — find_by_group
```json
{ "group": "test_group" }
```
- ASSERT `results` != null (may be empty if no nodes in that group)

### BR-03 — find_by_script
```json
{ "script_path": "res://test_tool.gd" }
```
- ASSERT `results` != null

### BR-04 — find_dependencies
```json
{ "path": "res://test_scene.tscn" }
```
- ASSERT `dependencies` != null

### BR-05 — orphaned_resources
```json
{}
```
- ASSERT `orphaned` != null (list may be empty)

### BR-06 — bulk_rename (current scene)
Precondition: scene open with a node named "LabelA".
```json
{
  "find": "Label",
  "replace": "Text",
  "scope": "current_scene"
}
```
- ASSERT `renamed` >= 0

### BR-07 — cross_scene_update
```json
{
  "find_property": "text",
  "find_value": "Hello",
  "new_value": "Hi MCP"
}
```
- ASSERT `updated_scenes` >= 0

### BR-08 — refactor_signals
```json
{
  "old_method": "_on_btn_pressed",
  "new_method": "_on_button_pressed"
}
```
- ASSERT `updated` >= 0

---

## BLOCK 20 — Analysis Tools (4 tools)

### AL-01 — analyze_scene_complexity
```json
{ "path": "res://test_scene.tscn" }
```
- ASSERT `node_count` >= 1
- ASSERT `depth` >= 0

### AL-02 — trace_signal_flow
```json
{ "path": "res://test_scene.tscn" }
```
- ASSERT `connections` != null

### AL-03 — find_unused_resources
```json
{}
```
- ASSERT `unused` != null

### AL-04 — get_code_metrics
```json
{ "path": "res://test_tool.gd" }
```
- ASSERT `line_count` >= 1
- ASSERT `function_count` >= 2

---

## BLOCK 21 — Testing/QA Tools (6 tools)

### SETUP
Create `res://tests/test_basic.gd` with methods `test_addition` and `test_string`.

### QA-01 — run_automated_tests
```json
{ "path": "res://tests/" }
```
- ASSERT `total` >= 1
- ASSERT `passed` >= 0
- ASSERT `failed` >= 0

### QA-02 — get_test_report
```json
{}
```
- ASSERT `last_run` != null

### QA-03 — assert_node_state (open scene)
```json
{
  "node_path": ".",
  "property": "visible",
  "expected_value": true
}
```
- ASSERT `passed` == true

### QA-04 — assert_node_state (negative)
```json
{
  "node_path": ".",
  "property": "position",
  "expected_value": "Vector2(9999, 9999)"
}
```
- ASSERT `passed` == false

### QA-05 — record_test
```json
{ "test_name": "mcp_test_record", "duration": 2.0 }
```
- ASSERT `success` == true

### QA-06 — replay_test
```json
{ "test_name": "mcp_test_record" }
```
- ASSERT `success` == true

### QA-07 — compare_screenshots
Take two screenshots and compare:
```json
{ "path_a": "res://screenshot_a.png", "path_b": "res://screenshot_a.png" }
```
- ASSERT `similarity` == 1.0 (identical files)

---

## BLOCK 22 — Profiling Tools (2 tools)

### PR-01 — get_performance_monitors
```json
{}
```
- ASSERT `fps` >= 0
- ASSERT `memory` != null

### PR-02 — get_performance_monitors with filter
```json
{ "category": "memory" }
```
- ASSERT all returned keys relate to memory

### PR-03 — get_memory_usage
```json
{}
```
- ASSERT `static_bytes` >= 0
- ASSERT `dynamic_bytes` >= 0

---

## BLOCK 23 — Export Tools (3 tools)

### EX-01 — list_export_presets
```json
{}
```
- ASSERT `presets` != null (may be empty if no presets configured)

### EX-02 — get_template_info
```json
{}
```
- ASSERT `version` != null
- ASSERT `templates_installed` is a boolean

### EX-03 — export_project (negative — no matching preset)
```json
{
  "preset_name": "NonExistentPreset",
  "output_path": "C:/tmp/test_export/"
}
```
- ASSERT `error` contains "preset" OR "not found"

---

## Coverage Summary

| Block | Tools | Tests | Negative tests |
|-------|-------|-------|----------------|
| 1. Project | 7 | 9 | 1 |
| 2. Scene | 9 | 10 | 1 |
| 3. Node | 14 | 15 | 0 |
| 4. Script | 8 | 10 | 1 |
| 5. Editor | 9 | 10 | 0 |
| 6. Input | 7 | 9 | 0 |
| 7. Runtime | 19 | 19 | 2 |
| 8. Animation | 6 | 7 | 1 |
| 9. AnimationTree | 8 | 8 | 1 |
| 10. 3D Scene | 6 | 6 | 0 |
| 11. Physics | 6 | 6 | 0 |
| 12. Particles | 5 | 5 | 0 |
| 13. Navigation | 6 | 6 | 1 |
| 14. Audio | 6 | 6 | 2 |
| 15. TileMap | 6 | 6 | 4 |
| 16. Theme/UI | 6 | 6 | 1 |
| 17. Shader | 6 | 7 | 0 |
| 18. Resource | 6 | 8 | 1 |
| 19. Batch/Refactor | 8 | 8 | 0 |
| 20. Analysis | 4 | 4 | 0 |
| 21. Testing/QA | 6 | 7 | 1 |
| 22. Profiling | 2 | 3 | 0 |
| 23. Export | 3 | 3 | 1 |
| **TOTAL** | **163** | **188** | **17** |

---

## Agent Instructions

1. **Execute blocks sequentially** — some blocks depend on state from previous ones (open scene, created files).
2. **After every set/create — run the verify call** to confirm the change took effect.
3. **Negative tests** expect an error — absence of an `error` field when one is expected = ❌.
4. **CLEANUP is mandatory** — do not leave test files in the project.
5. **On block failure** — record the exact `error` text and continue with the next test.
6. **Block summary** — table: `tool | status | note`.
7. **Full run summary** — aggregate table: `block | passed | failed | skipped`.
