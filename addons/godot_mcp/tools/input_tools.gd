@tool
extends GodotMCPToolBase

class_name GodotMCPInputTools

## Implements all 7 input tools.
## simulate_* tools inject events via Input.parse_input_event().
## record_input_sequence is async (uses await + timer).

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("simulate_key_press",      GodotMCPCallableTool.new(_simulate_key_press))
	registry.register_tool("simulate_mouse_click",    GodotMCPCallableTool.new(_simulate_mouse_click))
	registry.register_tool("simulate_mouse_move",     GodotMCPCallableTool.new(_simulate_mouse_move))
	registry.register_tool("trigger_input_action",    GodotMCPCallableTool.new(_trigger_input_action))
	registry.register_tool("record_input_sequence",   GodotMCPCallableTool.new(_record_input_sequence))
	registry.register_tool("replay_input_sequence",   GodotMCPCallableTool.new(_replay_input_sequence))
	registry.register_tool("configure_input_mapping", GodotMCPCallableTool.new(_configure_input_mapping))

# ---------------------------------------------------------------------------
# Inner class: records keyboard/mouse events for a duration
# ---------------------------------------------------------------------------

class InputRecorder extends Node:
	var events: Array = []
	var _start_ms: float = 0.0
	var plugin: EditorPlugin

	func _ready() -> void:
		_start_ms = Time.get_ticks_msec()
		set_process_input(true)

	func _input(event: InputEvent) -> void:
		if not plugin.get_editor_interface().is_playing_scene():
			return
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
				"echo": event.echo,
			})
		elif event is InputEventMouseButton:
			events.append({
				"type": "mouse_button",
				"timestamp": ts,
				"button": _button_name(event.button_index),
				"pressed": event.pressed,
				"x": event.position.x,
				"y": event.position.y,
				"double_click": event.double_click,
			})

	static func _button_name(idx: int) -> String:
		match idx:
			MOUSE_BUTTON_LEFT:   return "left"
			MOUSE_BUTTON_RIGHT:  return "right"
			MOUSE_BUTTON_MIDDLE: return "middle"
		return "button%d" % idx

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _button_index(name: String) -> int:
	match name:
		"right":  return MOUSE_BUTTON_RIGHT
		"middle": return MOUSE_BUTTON_MIDDLE
		_:        return MOUSE_BUTTON_LEFT

func _dispatch_event(event_data: Dictionary) -> void:
	match event_data.get("type", "key"):
		"key":
			var e := InputEventKey.new()
			e.keycode       = OS.find_keycode_from_string(event_data.get("key", "Space"))
			e.pressed       = event_data.get("pressed", true)
			e.shift_pressed = event_data.get("shift", false)
			e.ctrl_pressed  = event_data.get("ctrl", false)
			e.alt_pressed   = event_data.get("alt", false)
			e.echo          = event_data.get("echo", false)
			Input.parse_input_event(e)
		"mouse_button":
			var e := InputEventMouseButton.new()
			e.position     = Vector2(float(event_data.get("x", 0)), float(event_data.get("y", 0)))
			e.button_index = _button_index(event_data.get("button", "left"))
			e.pressed      = event_data.get("pressed", true)
			e.double_click = event_data.get("double_click", false)
			Input.parse_input_event(e)
		"action":
			var action: String = event_data.get("action", "")
			if action.is_empty() or not InputMap.has_action(action):
				return
			if event_data.get("pressed", true):
				Input.action_press(action, float(event_data.get("strength", 1.0)))
			else:
				Input.action_release(action)

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _simulate_key_press(args: Dictionary) -> Dictionary:
	var key: String = args.get("key", "")
	if key.is_empty():
		return {"error": "'key' is required"}

	var keycode := OS.find_keycode_from_string(key)
	if keycode == KEY_NONE:
		return {"error": "Unknown key name: '%s'. Use names like 'Space', 'Enter', 'A', 'F1'." % key}

	var event := InputEventKey.new()
	event.keycode       = keycode
	event.pressed       = args.get("pressed", true)
	event.shift_pressed = args.get("shift", false)
	event.ctrl_pressed  = args.get("ctrl", false)
	event.alt_pressed   = args.get("alt", false)
	event.echo          = args.get("echo", false)

	Input.parse_input_event(event)
	return {"success": true, "key": key, "pressed": event.pressed}

func _simulate_mouse_click(args: Dictionary) -> Dictionary:
	var x: float = float(args.get("x", 0))
	var y: float = float(args.get("y", 0))

	var event := InputEventMouseButton.new()
	event.position     = Vector2(x, y)
	event.button_index = _button_index(args.get("button", "left"))
	event.pressed      = args.get("pressed", true)
	event.double_click = args.get("double_click", false)

	Input.parse_input_event(event)
	return {"success": true, "x": x, "y": y, "pressed": event.pressed}

func _simulate_mouse_move(args: Dictionary) -> Dictionary:
	var x: float = float(args.get("x", 0))
	var y: float = float(args.get("y", 0))

	var event := InputEventMouseMotion.new()
	event.position = Vector2(x, y)
	event.relative = Vector2(float(args.get("relative_x", 0)), float(args.get("relative_y", 0)))

	Input.parse_input_event(event)
	return {"success": true, "x": x, "y": y}

func _trigger_input_action(args: Dictionary) -> Dictionary:
	var action: String = args.get("action", "")
	if action.is_empty():
		return {"error": "'action' is required"}
	if not InputMap.has_action(action):
		return {"error": "Input action not found: '%s'. Check Project Settings > Input Map." % action}

	var pressed: bool  = args.get("pressed", true)
	var strength: float = float(args.get("strength", 1.0))

	if pressed:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)

	return {"success": true, "action": action, "pressed": pressed, "strength": strength}

func _record_input_sequence(args: Dictionary) -> Dictionary:
	var duration: float = clampf(float(args.get("duration", 3.0)), 0.1, 30.0)

	var recorder := InputRecorder.new()
	recorder.plugin = _plugin
	_plugin.add_child(recorder)

	await _plugin.get_tree().create_timer(duration).timeout

	if not is_instance_valid(_plugin):
		recorder.queue_free()
		return {"error": "Plugin was disabled during recording"}

	var captured := recorder.events.duplicate()
	recorder.queue_free()

	# Convert absolute timestamps to relative delays for replay_input_sequence
	var with_delays: Array = []
	var prev_ts: float = 0.0
	for ev in captured:
		var entry: Dictionary = ev.duplicate()
		entry["delay"] = ev.get("timestamp", 0.0) - prev_ts
		prev_ts = ev.get("timestamp", 0.0)
		entry.erase("timestamp")
		with_delays.append(entry)

	return {
		"duration": duration,
		"events": with_delays,
		"count": with_delays.size(),
	}

func _replay_input_sequence(args: Dictionary) -> Dictionary:
	var events: Array = args.get("events", [])
	if events.is_empty():
		return {"error": "'events' array is required and must not be empty"}

	var speed: float = maxf(float(args.get("speed_scale", 1.0)), 0.01)
	var replayed := 0

	for event_data in events:
		var delay: float = float(event_data.get("delay", 0.0)) / speed
		if delay > 0.001:
			await _plugin.get_tree().create_timer(delay).timeout
			if not is_instance_valid(_plugin):
				return {"error": "Plugin was disabled during replay", "replayed": replayed}
		_dispatch_event(event_data)
		replayed += 1

	return {"success": true, "replayed": replayed}

func _configure_input_mapping(args: Dictionary) -> Dictionary:
	var operation: String  = args.get("operation", "list")
	var action_name: String = args.get("action_name", "")

	match operation:
		"list":
			var actions: Array = []
			for action in InputMap.get_actions():
				actions.append(action)
			return {"actions": actions, "total": actions.size()}

		"add":
			if action_name.is_empty():
				return {"error": "'action_name' is required"}
			if InputMap.has_action(action_name):
				return {"error": "Action already exists: %s" % action_name}
			InputMap.add_action(action_name)
			ProjectSettings.set_setting("input/%s" % action_name, {"deadzone": 0.5, "events": []})
			ProjectSettings.save()
			return {"success": true, "added": action_name}

		"remove":
			if action_name.is_empty():
				return {"error": "'action_name' is required"}
			if not InputMap.has_action(action_name):
				return {"error": "Action not found: %s" % action_name}
			InputMap.erase_action(action_name)
			if ProjectSettings.has_setting("input/%s" % action_name):
				ProjectSettings.set_setting("input/%s" % action_name, null)
				ProjectSettings.save()
			return {"success": true, "removed": action_name}

		"add_key_binding":
			if action_name.is_empty():
				return {"error": "'action_name' is required"}
			var key_name: String = args.get("key", "")
			if key_name.is_empty():
				return {"error": "'key' is required for add_key_binding"}
			var keycode := OS.find_keycode_from_string(key_name)
			if keycode == KEY_NONE:
				return {"error": "Unknown key: %s" % key_name}
			if not InputMap.has_action(action_name):
				InputMap.add_action(action_name)
			var event := InputEventKey.new()
			event.keycode = keycode
			InputMap.action_add_event(action_name, event)
			var setting_key := "input/%s" % action_name
			var current: Dictionary = ProjectSettings.get_setting(setting_key, {"deadzone": 0.5, "events": []})
			var existing_events: Array = current.get("events", [])
			existing_events.append(event)
			ProjectSettings.set_setting(setting_key, {"deadzone": current.get("deadzone", 0.5), "events": existing_events})
			ProjectSettings.save()
			return {"success": true, "action": action_name, "bound_key": key_name}

		"get_events":
			if action_name.is_empty():
				return {"error": "'action_name' is required"}
			if not InputMap.has_action(action_name):
				return {"error": "Action not found: %s" % action_name}
			var event_descs: Array = []
			for ev in InputMap.action_get_events(action_name):
				event_descs.append(ev.as_text())
			return {"action": action_name, "events": event_descs}

	return {"error": "Unknown operation: '%s'. Use list/add/remove/add_key_binding/get_events." % operation}
