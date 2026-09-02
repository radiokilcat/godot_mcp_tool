@tool
extends RefCounted

class_name GodotMCPAnimationTools

## Implements all 6 animation tools for AnimationPlayer.

var _plugin: EditorPlugin

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("create_animation",    GodotMCPCallableTool.new(_create_animation))
	registry.register_tool("add_animation_track", GodotMCPCallableTool.new(_add_animation_track))
	registry.register_tool("add_keyframe",        GodotMCPCallableTool.new(_add_keyframe))
	registry.register_tool("set_easing",          GodotMCPCallableTool.new(_set_easing))
	registry.register_tool("get_animation_info",  GodotMCPCallableTool.new(_get_animation_info))
	registry.register_tool("delete_animation",    GodotMCPCallableTool.new(_delete_animation))

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

func _get_player(node_path: String) -> Variant:
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not node is AnimationPlayer:
		return {"error": "Node is not an AnimationPlayer (got %s)" % node.get_class()}
	return node

func _loop_mode_enum(mode: String) -> int:
	match mode:
		"linear":   return Animation.LOOP_LINEAR
		"pingpong": return Animation.LOOP_PINGPONG
		_:          return Animation.LOOP_NONE

func _interp_enum(mode: String) -> int:
	match mode:
		"nearest":      return Animation.INTERPOLATION_NEAREST
		"cubic":        return Animation.INTERPOLATION_CUBIC
		"linear_angle": return Animation.INTERPOLATION_LINEAR_ANGLE
		"cubic_angle":  return Animation.INTERPOLATION_CUBIC_ANGLE
		_:              return Animation.INTERPOLATION_LINEAR

func _track_type_enum(type: String) -> int:
	match type:
		"method":    return Animation.TYPE_METHOD
		"bezier":    return Animation.TYPE_BEZIER
		"audio":     return Animation.TYPE_AUDIO
		"animation": return Animation.TYPE_ANIMATION
		_:           return Animation.TYPE_VALUE

func _coerce_value(raw: Variant) -> Variant:
	if not raw is String:
		return raw
	var s: String = (raw as String).strip_edges()

	# Vector2(x, y)
	var re2 := RegEx.new()
	re2.compile(r"^Vector2\(\s*([-+\d.e]+)\s*,\s*([-+\d.e]+)\s*\)$")
	var m := re2.search(s)
	if m:
		return Vector2(float(m.get_string(1)), float(m.get_string(2)))

	# Vector3(x, y, z)
	var re3 := RegEx.new()
	re3.compile(r"^Vector3\(\s*([-+\d.e]+)\s*,\s*([-+\d.e]+)\s*,\s*([-+\d.e]+)\s*\)$")
	m = re3.search(s)
	if m:
		return Vector3(float(m.get_string(1)), float(m.get_string(2)), float(m.get_string(3)))

	# Color(r,g,b) or Color(r,g,b,a)
	var rec := RegEx.new()
	rec.compile(r"^Color\(\s*([-+\d.e]+)\s*,\s*([-+\d.e]+)\s*,\s*([-+\d.e]+)(?:\s*,\s*([-+\d.e]+))?\s*\)$")
	m = rec.search(s)
	if m:
		var a := 1.0 if m.get_string(4).is_empty() else float(m.get_string(4))
		return Color(float(m.get_string(1)), float(m.get_string(2)), float(m.get_string(3)), a)

	# #RRGGBB / #RRGGBBAA
	if s.begins_with("#"):
		return Color(s)

	# plain number
	if s.is_valid_float():
		return float(s)
	if s.is_valid_int():
		return int(s)

	return raw

func _value_to_json(v: Variant) -> Variant:
	if v is Vector2:  return {"x": v.x, "y": v.y}
	if v is Vector3:  return {"x": v.x, "y": v.y, "z": v.z}
	if v is Color:    return {"r": v.r, "g": v.g, "b": v.b, "a": v.a}
	if v is Rect2:    return {"x": v.position.x, "y": v.position.y, "w": v.size.x, "h": v.size.y}
	if v is Object:
		if v is Resource:
			return v.resource_path if not v.resource_path.is_empty() else str(v)
		return str(v)
	return v

func _track_type_name(t: int) -> String:
	match t:
		Animation.TYPE_VALUE:     return "value"
		Animation.TYPE_METHOD:    return "method"
		Animation.TYPE_BEZIER:    return "bezier"
		Animation.TYPE_AUDIO:     return "audio"
		Animation.TYPE_ANIMATION: return "animation"
	return "unknown"

func _loop_mode_name(m: int) -> String:
	match m:
		Animation.LOOP_LINEAR:   return "linear"
		Animation.LOOP_PINGPONG: return "pingpong"
	return "none"

func _interp_name(i: int) -> String:
	match i:
		Animation.INTERPOLATION_NEAREST:      return "nearest"
		Animation.INTERPOLATION_CUBIC:        return "cubic"
		Animation.INTERPOLATION_LINEAR_ANGLE: return "linear_angle"
		Animation.INTERPOLATION_CUBIC_ANGLE:  return "cubic_angle"
	return "linear"

func _capture_track_data(anim: Animation, track_idx: int) -> Dictionary:
	var data: Dictionary = {
		"type": anim.track_get_type(track_idx),
		"path": str(anim.track_get_path(track_idx)),
		"enabled": anim.track_is_enabled(track_idx),
		"keys": [],
	}
	if data["type"] == Animation.TYPE_VALUE:
		data["interp"] = anim.track_get_interpolation_type(track_idx)
	for k in range(anim.track_get_key_count(track_idx)):
		data["keys"].append({
			"time": anim.track_get_key_time(track_idx, k),
			"value": anim.track_get_key_value(track_idx, k),
			"transition": anim.track_get_key_transition(track_idx, k),
		})
	return data

func _restore_track_data(anim: Animation, track_idx: int, data: Dictionary) -> void:
	anim.add_track(data["type"], track_idx)
	anim.track_set_path(track_idx, NodePath(data["path"]))
	anim.track_set_enabled(track_idx, data["enabled"])
	if data["type"] == Animation.TYPE_VALUE and data.has("interp"):
		anim.track_set_interpolation_type(track_idx, data["interp"])
	for kd in data["keys"]:
		anim.track_insert_key(track_idx, kd["time"], kd["value"], kd.get("transition", 1.0))

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _create_animation(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var anim_name: String = args.get("animation_name", "")
	if node_path.is_empty() or anim_name.is_empty():
		return {"error": "'node_path' and 'animation_name' are required"}

	var result = _get_player(node_path)
	if result is Dictionary:
		return result
	var player: AnimationPlayer = result

	if player.has_animation(anim_name):
		return {"error": "Animation already exists: '%s'" % anim_name}

	# Ask before fetching: get_animation_library() on a name the player does not
	# have is an ERR_FAIL_COND inside the engine, so using it as an existence
	# probe printed "Method/function failed. Returning: Ref<AnimationLibrary>()"
	# into the Output panel on every first animation added to a player.
	var needs_new_lib := not player.has_animation_library("")
	var anim_lib: AnimationLibrary = null if needs_new_lib else player.get_animation_library("")
	if needs_new_lib:
		anim_lib = AnimationLibrary.new()

	var anim := Animation.new()
	anim.length = float(args.get("length", 1.0))
	anim.loop_mode = _loop_mode_enum(args.get("loop_mode", "none"))

	var ur := _plugin.get_undo_redo()
	ur.create_action("Create Animation '%s'" % anim_name)
	if needs_new_lib:
		ur.add_do_method(player, "add_animation_library", "", anim_lib)
		ur.add_do_method(anim_lib, "add_animation", anim_name, anim)
		ur.add_undo_method(player, "remove_animation_library", "")
	else:
		ur.add_do_method(anim_lib, "add_animation", anim_name, anim)
		ur.add_undo_method(anim_lib, "remove_animation", anim_name)
	ur.commit_action()

	return {
		"success": true,
		"animation_name": anim_name,
		"length": anim.length,
		"loop_mode": _loop_mode_name(anim.loop_mode),
	}

func _add_animation_track(args: Dictionary) -> Dictionary:
	var node_path: String  = args.get("node_path", "")
	var anim_name: String  = args.get("animation_name", "")
	var target_path: String = args.get("target_path", "")
	if node_path.is_empty() or anim_name.is_empty() or target_path.is_empty():
		return {"error": "'node_path', 'animation_name', and 'target_path' are required"}

	var result = _get_player(node_path)
	if result is Dictionary:
		return result
	var player: AnimationPlayer = result

	if not player.has_animation(anim_name):
		return {"error": "Animation not found: '%s'" % anim_name}

	var anim: Animation = player.get_animation(anim_name)
	var track_type := _track_type_enum(args.get("track_type", "value"))
	var track_idx := anim.get_track_count()

	var ur := _plugin.get_undo_redo()
	ur.create_action("Add Track to '%s'" % anim_name)
	ur.add_do_method(anim, "add_track", track_type, -1)
	ur.add_do_method(anim, "track_set_path", track_idx, NodePath(target_path))
	if track_type == Animation.TYPE_VALUE:
		var interp := _interp_enum(args.get("interpolation", "linear"))
		ur.add_do_method(anim, "track_set_interpolation_type", track_idx, interp)
	ur.add_undo_method(anim, "remove_track", track_idx)
	ur.commit_action()

	return {
		"success": true,
		"track_index": track_idx,
		"track_type": _track_type_name(track_type),
		"target_path": target_path,
	}

func _add_keyframe(args: Dictionary) -> Dictionary:
	var node_path: String  = args.get("node_path", "")
	var anim_name: String  = args.get("animation_name", "")
	var track_idx: int     = int(args.get("track_index", -1))
	var time: float        = float(args.get("time", 0.0))

	if node_path.is_empty() or anim_name.is_empty() or track_idx < 0:
		return {"error": "'node_path', 'animation_name', and 'track_index' are required"}
	if not args.has("value"):
		return {"error": "'value' is required"}

	var result = _get_player(node_path)
	if result is Dictionary:
		return result
	var player: AnimationPlayer = result

	if not player.has_animation(anim_name):
		return {"error": "Animation not found: '%s'" % anim_name}

	var anim: Animation = player.get_animation(anim_name)
	if track_idx >= anim.get_track_count():
		return {"error": "Track index %d out of range (animation has %d tracks)" % [track_idx, anim.get_track_count()]}

	var raw_value = args.get("value")
	var value = _coerce_value(raw_value)
	var transition: float = float(args.get("transition", 1.0))

	var track_type := anim.track_get_type(track_idx)
	var ur := _plugin.get_undo_redo()
	ur.create_action("Add Keyframe to Track %d" % track_idx)

	if track_type == Animation.TYPE_VALUE:
		ur.add_do_method(anim, "track_insert_key", track_idx, time, value, transition)
		ur.add_undo_method(anim, "track_remove_key_at_time", track_idx, time)
	elif track_type == Animation.TYPE_BEZIER:
		ur.add_do_method(anim, "bezier_track_insert_key", track_idx, time, float(value))
		ur.add_undo_method(anim, "track_remove_key_at_time", track_idx, time)
	else:
		ur.commit_action()
		return {"error": "Unsupported track type for add_keyframe: %s" % _track_type_name(track_type)}

	ur.commit_action()
	var key_idx := anim.track_find_key(track_idx, time)

	return {
		"success": true,
		"track_index": track_idx,
		"key_index": key_idx,
		"time": time,
		"value": _value_to_json(value),
	}

func _set_easing(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var anim_name: String = args.get("animation_name", "")
	var track_idx: int    = int(args.get("track_index", -1))
	var key_idx: int      = int(args.get("key_index", -1))

	if node_path.is_empty() or anim_name.is_empty() or track_idx < 0 or key_idx < 0:
		return {"error": "'node_path', 'animation_name', 'track_index', and 'key_index' are required"}

	var result = _get_player(node_path)
	if result is Dictionary:
		return result
	var player: AnimationPlayer = result

	if not player.has_animation(anim_name):
		return {"error": "Animation not found: '%s'" % anim_name}

	var anim: Animation = player.get_animation(anim_name)
	if track_idx >= anim.get_track_count():
		return {"error": "Track index %d out of range" % track_idx}
	if key_idx >= anim.track_get_key_count(track_idx):
		return {"error": "Key index %d out of range" % key_idx}

	var old_transition: float = anim.track_get_key_transition(track_idx, key_idx)
	var new_transition: float = float(args.get("transition", old_transition))

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set Easing on Track %d Key %d" % [track_idx, key_idx])
	ur.add_do_method(anim, "track_set_key_transition", track_idx, key_idx, new_transition)
	ur.add_undo_method(anim, "track_set_key_transition", track_idx, key_idx, old_transition)
	ur.commit_action()

	return {
		"success": true,
		"track_index": track_idx,
		"key_index": key_idx,
		"transition": new_transition,
	}

func _get_animation_info(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var result = _get_player(node_path)
	if result is Dictionary:
		return result
	var player: AnimationPlayer = result

	var anim_name: String = args.get("animation_name", "")

	# No animation specified — list all animations
	if anim_name.is_empty():
		var names: Array = []
		for lib_name in player.get_animation_library_list():
			var lib: AnimationLibrary = player.get_animation_library(lib_name)
			for name in lib.get_animation_list():
				names.append(lib_name + "/" + name if not lib_name.is_empty() else name)
		return {
			"player_path": node_path,
			"current_animation": player.current_animation,
			"animations": names,
			"total": names.size(),
		}

	if not player.has_animation(anim_name):
		return {"error": "Animation not found: '%s'" % anim_name}

	var anim: Animation = player.get_animation(anim_name)
	var include_keys: bool = args.get("include_keyframes", false)

	var tracks: Array = []
	for i in range(anim.get_track_count()):
		var track_info := {
			"index": i,
			"type": _track_type_name(anim.track_get_type(i)),
			"path": str(anim.track_get_path(i)),
			"enabled": anim.track_is_enabled(i),
			"key_count": anim.track_get_key_count(i),
		}
		if anim.track_get_type(i) == Animation.TYPE_VALUE:
			track_info["interpolation"] = _interp_name(anim.track_get_interpolation_type(i))
		if include_keys:
			var keys: Array = []
			for k in range(anim.track_get_key_count(i)):
				keys.append({
					"index": k,
					"time": anim.track_get_key_time(i, k),
					"value": _value_to_json(anim.track_get_key_value(i, k)),
					"transition": anim.track_get_key_transition(i, k),
				})
			track_info["keyframes"] = keys
		tracks.append(track_info)

	return {
		"name": anim_name,
		"length": anim.length,
		"loop_mode": _loop_mode_name(anim.loop_mode),
		"step": anim.step,
		"track_count": anim.get_track_count(),
		"tracks": tracks,
	}

func _delete_animation(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var anim_name: String = args.get("animation_name", "")
	if node_path.is_empty() or anim_name.is_empty():
		return {"error": "'node_path' and 'animation_name' are required"}

	var result = _get_player(node_path)
	if result is Dictionary:
		return result
	var player: AnimationPlayer = result

	if not player.has_animation(anim_name):
		return {"error": "Animation not found: '%s'" % anim_name}

	# Remove only a track if track_index is provided
	if args.has("track_index"):
		var track_idx: int = int(args.get("track_index"))
		var anim: Animation = player.get_animation(anim_name)
		if track_idx >= anim.get_track_count():
			return {"error": "Track index %d out of range" % track_idx}
		var track_data := _capture_track_data(anim, track_idx)
		var ur := _plugin.get_undo_redo()
		ur.create_action("Remove Track %d from '%s'" % [track_idx, anim_name])
		ur.add_do_method(anim, "remove_track", track_idx)
		ur.add_undo_method(self, "_restore_track_data", anim, track_idx, track_data)
		ur.commit_action()
		return {
			"success": true,
			"removed": "track",
			"track_index": track_idx,
			"animation_name": anim_name,
		}

	# Remove whole animation — resolve library from qualified name (e.g. "combat/idle")
	var lib_name := ""
	var pure_anim_name := anim_name
	if "/" in anim_name:
		var sep := anim_name.find("/")
		lib_name = anim_name.left(sep)
		pure_anim_name = anim_name.substr(sep + 1)

	# has_ before get_, for the same reason as in _create_animation
	if not player.has_animation_library(lib_name):
		return {"error": "Animation library '%s' not found" % lib_name}
	var anim_lib := player.get_animation_library(lib_name)

	var anim_copy: Animation = player.get_animation(anim_name)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Delete Animation '%s'" % anim_name)
	ur.add_do_method(anim_lib, "remove_animation", pure_anim_name)
	ur.add_undo_method(anim_lib, "add_animation", pure_anim_name, anim_copy)
	ur.commit_action()

	return {
		"success": true,
		"removed": "animation",
		"animation_name": anim_name,
	}
