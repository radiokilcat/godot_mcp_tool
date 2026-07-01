@tool
extends RefCounted

class_name GodotMCPRuntimeTools

## Implements all 19 runtime tools.
## Tools that need the game running are marked with a guard check.

var _plugin: EditorPlugin
var _prev_time_scale: float = 1.0

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("get_game_state",         GodotMCPCallableTool.new(_get_game_state))
	registry.register_tool("list_loaded_resources",  GodotMCPCallableTool.new(_list_loaded_resources))
	registry.register_tool("inspect_node_at_runtime",GodotMCPCallableTool.new(_inspect_node_at_runtime))
	registry.register_tool("get_performance_metrics",GodotMCPCallableTool.new(_get_performance_metrics))
	registry.register_tool("record_gameplay",        GodotMCPCallableTool.new(_record_gameplay))
	registry.register_tool("replay_gameplay",        GodotMCPCallableTool.new(_replay_gameplay))
	registry.register_tool("navigate_to_node",       GodotMCPCallableTool.new(_navigate_to_node))
	registry.register_tool("click_ui_element",       GodotMCPCallableTool.new(_click_ui_element))
	registry.register_tool("get_node_tree_runtime",  GodotMCPCallableTool.new(_get_node_tree_runtime))
	registry.register_tool("pause_game",             GodotMCPCallableTool.new(_pause_game))
	registry.register_tool("resume_game",            GodotMCPCallableTool.new(_resume_game))
	registry.register_tool("set_game_speed",         GodotMCPCallableTool.new(_set_game_speed))
	registry.register_tool("list_autoloads",         GodotMCPCallableTool.new(_list_autoloads))
	registry.register_tool("call_function",          GodotMCPCallableTool.new(_call_function))
	registry.register_tool("get_variable_value",     GodotMCPCallableTool.new(_get_variable_value))
	registry.register_tool("set_variable_value",     GodotMCPCallableTool.new(_set_variable_value))
	registry.register_tool("get_signal_connections", GodotMCPCallableTool.new(_get_signal_connections))
	registry.register_tool("emit_signal",            GodotMCPCallableTool.new(_emit_signal_tool))
	registry.register_tool("listen_to_signal",       GodotMCPCallableTool.new(_listen_to_signal))

# ---------------------------------------------------------------------------
# Inner class: records input events with optional perf snapshots
# ---------------------------------------------------------------------------

class GameplayRecorder extends Node:
	var events: Array = []
	var snapshots: Array = []
	var _start_ms: float = 0.0
	var include_snapshots: bool = false
	var _snap_timer: float = 0.0
	const SNAP_INTERVAL := 1.0

	func _ready() -> void:
		_start_ms = Time.get_ticks_msec()
		set_process_input(true)
		set_process(include_snapshots)

	func _process(delta: float) -> void:
		_snap_timer += delta
		if _snap_timer >= SNAP_INTERVAL:
			_snap_timer = 0.0
			snapshots.append({
				"t": (Time.get_ticks_msec() - _start_ms) / 1000.0,
				"fps": Performance.get_monitor(Performance.TIME_FPS),
				"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				"mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1_048_576.0,
			})

	func _input(event: InputEvent) -> void:
		var ts: float = (Time.get_ticks_msec() - _start_ms) / 1000.0
		if event is InputEventKey:
			events.append({
				"type": "key",
				"timestamp": ts,
				"key": OS.get_keycode_string(event.keycode),
				"pressed": event.pressed,
				"shift": event.shift_pressed,
				"ctrl": event.ctrl_pressed,
				"alt": event.alt_pressed,
			})
		elif event is InputEventMouseButton:
			events.append({
				"type": "mouse_button",
				"timestamp": ts,
				"button": _btn(event.button_index),
				"pressed": event.pressed,
				"x": event.position.x,
				"y": event.position.y,
			})

	static func _btn(idx: int) -> String:
		match idx:
			MOUSE_BUTTON_LEFT:   return "left"
			MOUSE_BUTTON_RIGHT:  return "right"
			MOUSE_BUTTON_MIDDLE: return "middle"
		return "button%d" % idx

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _resolve_node(node_path: String) -> Variant:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return null
	if node_path == "." or node_path == root.name:
		return root
	return root.get_node_or_null(node_path)

func _node_runtime_dict(node: Node, depth: int, max_depth: int) -> Dictionary:
	var d := {
		"name": node.name,
		"type": node.get_class(),
		"path": str(node.get_path()) if node.is_inside_tree() else node.name,
		"visible": node.get("visible") if node.has_method("get") else true,
		"groups": node.get_groups(),
		"script": node.get_script().resource_path if node.get_script() else "",
		"children": [],
	}
	if depth < max_depth:
		for child in node.get_children():
			d["children"].append(_node_runtime_dict(child, depth + 1, max_depth))
	return d

func _value_to_json(v: Variant) -> Variant:
	if v is Vector2:     return {"x": v.x, "y": v.y}
	if v is Vector2i:    return {"x": v.x, "y": v.y}
	if v is Vector3:     return {"x": v.x, "y": v.y, "z": v.z}
	if v is Vector3i:    return {"x": v.x, "y": v.y, "z": v.z}
	if v is Color:       return {"r": v.r, "g": v.g, "b": v.b, "a": v.a}
	if v is Rect2:       return {"x": v.position.x, "y": v.position.y, "w": v.size.x, "h": v.size.y}
	if v is Rect2i:      return {"x": v.position.x, "y": v.position.y, "w": v.size.x, "h": v.size.y}
	if v is Quaternion:  return {"x": v.x, "y": v.y, "z": v.z, "w": v.w}
	if v is Basis:       return {"x": _value_to_json(v.x), "y": _value_to_json(v.y), "z": _value_to_json(v.z)}
	if v is Transform2D: return {"origin": _value_to_json(v.origin), "x": _value_to_json(v.x), "y": _value_to_json(v.y)}
	if v is Transform3D: return {"origin": _value_to_json(v.origin), "basis": _value_to_json(v.basis)}
	if v is Object:
		if v is Resource:
			return v.resource_path if not v.resource_path.is_empty() else str(v)
		return str(v)
	return v

func _collect_resources(path: String, type_filter: String, result: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not item.begins_with("."):
			var full := path.path_join(item)
			if dir.current_is_dir():
				_collect_resources(full, type_filter, result)
			else:
				var ext := "." + item.get_extension()
				if type_filter.is_empty() or ext == type_filter:
					result.append(full)
		item = dir.get_next()
	dir.list_dir_end()

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _get_game_state(_args: Dictionary) -> Dictionary:
	var is_playing := EditorInterface.is_playing_scene()
	var root := EditorInterface.get_edited_scene_root()
	return {
		"is_playing": is_playing,
		"is_paused": Engine.time_scale == 0.0 if is_playing else false,
		"time_scale": Engine.time_scale,
		"active_scene": root.scene_file_path if root else "",
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_frames": Engine.get_process_frames(),
	}

func _list_loaded_resources(args: Dictionary) -> Dictionary:
	var type_filter: String = args.get("type_filter", "")
	var path_prefix: String = args.get("path_prefix", "res://")
	var resources: Array = []
	_collect_resources(path_prefix, type_filter, resources)
	return {"resources": resources, "total": resources.size()}

func _inspect_node_at_runtime(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var props: Dictionary = {}
	for prop in node.get_property_list():
		if prop.get("usage", 0) & PROPERTY_USAGE_EDITOR:
			var val = node.get(prop.name)
			props[prop.name] = _value_to_json(val)

	var result := {
		"name": node.name,
		"type": node.get_class(),
		"path": str(node.get_path()),
		"script": node.get_script().resource_path if node.get_script() else "",
		"groups": node.get_groups(),
		"properties": props,
	}

	if args.get("include_children", false):
		var children: Array = []
		for child in node.get_children():
			children.append({
				"name": child.name,
				"type": child.get_class(),
				"path": str(child.get_path()),
			})
		result["children"] = children

	return result

func _get_performance_metrics(args: Dictionary) -> Dictionary:
	var monitor_map := {
		"fps":          Performance.TIME_FPS,
		"process_ms":   Performance.TIME_PROCESS,
		"physics_ms":   Performance.TIME_PHYSICS_PROCESS,
		"memory_static":Performance.MEMORY_STATIC,
		"memory_dynamic":Performance.MEMORY_DYNAMIC,
		"object_count": Performance.OBJECT_COUNT,
		"node_count":   Performance.OBJECT_NODE_COUNT,
		"orphan_nodes": Performance.OBJECT_ORPHAN_NODE_COUNT,
		"resource_count":Performance.OBJECT_RESOURCE_COUNT,
		"draw_calls":   Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME,
		"primitives":   Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME,
		"video_mem_mb": Performance.RENDER_VIDEO_MEM_USED,
	}

	var requested: Array = args.get("monitors", monitor_map.keys())
	var result: Dictionary = {}
	for key in requested:
		if key in monitor_map:
			var val := Performance.get_monitor(monitor_map[key])
			result[key] = snappedf(val, 0.01) if key.ends_with("_ms") else val
	# Always include unit info for memory
	if "memory_static" in result:
		result["memory_static_mb"] = snappedf(result["memory_static"] / 1_048_576.0, 0.01)
	if "video_mem_mb" in result:
		result["video_mem_mb"] = snappedf(result["video_mem_mb"] / 1_048_576.0, 0.01)
	return result

func _record_gameplay(args: Dictionary) -> Dictionary:
	var duration: float = clampf(float(args.get("duration", 5.0)), 0.1, 60.0)
	var include_snaps: bool = args.get("include_snapshots", false)

	var recorder := GameplayRecorder.new()
	recorder.include_snapshots = include_snaps
	_plugin.add_child(recorder)

	await _plugin.get_tree().create_timer(duration).timeout

	var captured_events := recorder.events.duplicate()
	var captured_snaps  := recorder.snapshots.duplicate()
	recorder.queue_free()

	# Convert absolute timestamps to relative delays
	var with_delays: Array = []
	var prev_ts: float = 0.0
	for ev in captured_events:
		var entry: Dictionary = ev.duplicate()
		entry["delay"] = ev.get("timestamp", 0.0) - prev_ts
		prev_ts = ev.get("timestamp", 0.0)
		entry.erase("timestamp")
		with_delays.append(entry)

	return {
		"duration": duration,
		"events": with_delays,
		"event_count": with_delays.size(),
		"snapshots": captured_snaps,
	}

func _replay_gameplay(args: Dictionary) -> Dictionary:
	var events: Array = args.get("events", [])
	if events.is_empty():
		return {"error": "'events' array is required"}
	var speed: float = maxf(float(args.get("speed_scale", 1.0)), 0.01)
	var replayed := 0
	for event_data in events:
		var delay: float = float(event_data.get("delay", 0.0)) / speed
		if delay > 0.001:
			await _plugin.get_tree().create_timer(delay).timeout
		match event_data.get("type", "key"):
			"key":
				var e := InputEventKey.new()
				e.keycode       = OS.find_keycode_from_string(event_data.get("key", ""))
				e.pressed       = event_data.get("pressed", true)
				e.shift_pressed = event_data.get("shift", false)
				e.ctrl_pressed  = event_data.get("ctrl", false)
				e.alt_pressed   = event_data.get("alt", false)
				Input.parse_input_event(e)
			"mouse_button":
				var e := InputEventMouseButton.new()
				e.position = Vector2(float(event_data.get("x", 0)), float(event_data.get("y", 0)))
				match event_data.get("button", "left"):
					"right":  e.button_index = MOUSE_BUTTON_RIGHT
					"middle": e.button_index = MOUSE_BUTTON_MIDDLE
					_:        e.button_index = MOUSE_BUTTON_LEFT
				e.pressed = event_data.get("pressed", true)
				Input.parse_input_event(e)
		replayed += 1
	return {"success": true, "replayed": replayed}

func _navigate_to_node(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	var sel := EditorInterface.get_selection()
	sel.clear()
	sel.add_node(node)
	return {"success": true, "selected": str(node.get_path())}

func _click_ui_element(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not node is Control:
		return {"error": "Node is not a Control: %s" % node.get_class()}

	var method: String = args.get("method", "press")
	match method:
		"press":
			if node.has_method("press"):
				node.press()
			elif node.has_signal("pressed"):
				node.emit_signal("pressed")
			else:
				# Simulate click via InputEvent at control center
				var center := (node as Control).get_global_rect().get_center()
				var down := InputEventMouseButton.new()
				down.position = center
				down.button_index = MOUSE_BUTTON_LEFT
				down.pressed = true
				node.get_viewport().push_input(down)
				var up := down.duplicate() as InputEventMouseButton
				up.pressed = false
				node.get_viewport().push_input(up)
		"toggle":
			if node.has_method("set_pressed"):
				node.set_pressed(not node.get("button_pressed"))
			else:
				return {"error": "Node does not support toggle"}
		"gui_input":
			var ev := InputEventMouseButton.new()
			ev.position = (node as Control).get_global_rect().get_center()
			ev.button_index = MOUSE_BUTTON_LEFT
			ev.pressed = true
			node.emit_signal("gui_input", ev)
			var ev_up := ev.duplicate() as InputEventMouseButton
			ev_up.pressed = false
			node.emit_signal("gui_input", ev_up)

	return {"success": true, "node_path": node_path, "method": method}

func _get_node_tree_runtime(args: Dictionary) -> Dictionary:
	var max_depth: int = int(args.get("max_depth", 3))
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return {"error": "No scene is open"}
	return {
		"is_playing": EditorInterface.is_playing_scene(),
		"root": _node_runtime_dict(root, 0, max_depth),
	}

func _pause_game(_args: Dictionary) -> Dictionary:
	if not EditorInterface.is_playing_scene():
		return {"error": "Game is not running"}
	_prev_time_scale = Engine.time_scale if Engine.time_scale > 0.0 else 1.0
	Engine.time_scale = 0.0
	return {"success": true, "paused": true}

func _resume_game(_args: Dictionary) -> Dictionary:
	if not EditorInterface.is_playing_scene():
		return {"error": "Game is not running"}
	Engine.time_scale = _prev_time_scale
	return {"success": true, "paused": false}

func _set_game_speed(args: Dictionary) -> Dictionary:
	var scale: float = float(args.get("time_scale", 1.0))
	if scale < 0:
		return {"error": "time_scale must be >= 0"}
	var old := Engine.time_scale
	Engine.time_scale = scale
	return {"success": true, "old_time_scale": old, "new_time_scale": scale}

func _list_autoloads(_args: Dictionary) -> Dictionary:
	var autoloads: Array = []
	for prop in ProjectSettings.get_property_list():
		var name: String = prop.get("name", "")
		if name.begins_with("autoload/"):
			var al_name := name.substr("autoload/".length())
			var al_path: String = str(ProjectSettings.get_setting(name))
			var is_singleton := al_path.begins_with("*")
			if is_singleton:
				al_path = al_path.substr(1)
			autoloads.append({
				"name":         al_name,
				"path":         al_path,
				"is_singleton": is_singleton,
			})
	return {"autoloads": autoloads, "total": autoloads.size()}

func _call_function(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var method: String    = args.get("method", "")
	if node_path.is_empty() or method.is_empty():
		return {"error": "'node_path' and 'method' are required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not node.has_method(method):
		return {"error": "Method '%s' not found on %s" % [method, node.get_class()]}
	var call_args: Array = args.get("args", [])
	var result = node.callv(method, call_args)
	return {
		"success": true,
		"return_value": _value_to_json(result),
	}

func _get_variable_value(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var variable: String  = args.get("variable", "")
	if node_path.is_empty() or variable.is_empty():
		return {"error": "'node_path' and 'variable' are required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	var val = node.get(variable)
	if val == null and not variable in node.get_property_list().map(func(p): return p.name):
		return {"error": "Property '%s' not found on node" % variable}
	return {
		"node_path": node_path,
		"variable": variable,
		"value": _value_to_json(val),
	}

func _set_variable_value(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var variable: String  = args.get("variable", "")
	if node_path.is_empty() or variable.is_empty():
		return {"error": "'node_path' and 'variable' are required"}
	if not args.has("value"):
		return {"error": "'value' is required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	var old_val = node.get(variable)
	node.set(variable, args.get("value"))
	return {
		"success": true,
		"variable": variable,
		"old_value": _value_to_json(old_val),
		"new_value": _value_to_json(node.get(variable)),
	}

func _get_signal_connections(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var direction: String = args.get("direction", "outgoing")
	var result: Dictionary = {"node_path": node_path, "outgoing": [], "incoming": []}

	# Outgoing: signals this node emits that are connected
	if direction in ["outgoing", "both"]:
		for sig in node.get_signal_list():
			for conn in node.get_signal_connection_list(sig.name):
				var tgt = conn.callable.get_object()
				result["outgoing"].append({
					"signal": sig.name,
					"target": str(tgt.get_path()) if tgt and tgt.has_method("get_path") else str(tgt),
					"method": conn.callable.get_method(),
				})

	# Incoming: other nodes connected to this node's methods
	# (not trivially accessible without scanning all nodes)
	if direction in ["incoming", "both"]:
		var root := EditorInterface.get_edited_scene_root()
		if root:
			_find_incoming_connections(root, node, result["incoming"])

	return result

func _find_incoming_connections(scan_node: Node, target: Node, result: Array) -> void:
	for sig in scan_node.get_signal_list():
		for conn in scan_node.get_signal_connection_list(sig.name):
			if conn.callable.get_object() == target:
				result.append({
					"from": str(scan_node.get_path()),
					"signal": sig.name,
					"method": conn.callable.get_method(),
				})
	for child in scan_node.get_children():
		_find_incoming_connections(child, target, result)

func _emit_signal_tool(args: Dictionary) -> Dictionary:
	var node_path: String   = args.get("node_path", "")
	var signal_name: String = args.get("signal_name", "")
	if node_path.is_empty() or signal_name.is_empty():
		return {"error": "'node_path' and 'signal_name' are required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not node.has_signal(signal_name):
		return {"error": "Signal '%s' not found on %s" % [signal_name, node.get_class()]}
	var signal_args: Array = args.get("args", [])
	node.callv("emit_signal", [signal_name] + signal_args)
	return {"success": true, "signal": signal_name}

func _listen_to_signal(args: Dictionary) -> Dictionary:
	var node_path: String   = args.get("node_path", "")
	var signal_name: String = args.get("signal_name", "")
	var timeout: float      = clampf(float(args.get("timeout", 5.0)), 0.1, 30.0)

	if node_path.is_empty() or signal_name.is_empty():
		return {"error": "'node_path' and 'signal_name' are required"}
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not node.has_signal(signal_name):
		return {"error": "Signal '%s' not found on node" % signal_name}

	var fired := {"value": false}
	var cb := func(): fired.value = true
	node.connect(signal_name, cb, CONNECT_ONE_SHOT)

	var start_ms := Time.get_ticks_msec()
	while not fired.value:
		await _plugin.get_tree().process_frame
		if (Time.get_ticks_msec() - start_ms) / 1000.0 >= timeout:
			if node.is_connected(signal_name, cb):
				node.disconnect(signal_name, cb)
			return {"fired": false, "timed_out": true, "timeout": timeout}

	return {"fired": true, "signal": signal_name, "elapsed": (Time.get_ticks_msec() - start_ms) / 1000.0}
