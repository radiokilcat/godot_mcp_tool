@tool
extends RefCounted

class_name GodotMCPEditorTools

## Implements 8 editor-level tools.
## (reload_scripts lives in script_tools.gd to avoid duplication)

var _plugin: EditorPlugin

## Collects mcp_print() output from an executed script and its return value.
## The executed script talks to this object through the injected _mcp_sink var.
class ScriptOutput extends RefCounted:
	const LINE_LIMIT := 500

	var lines: Array = []
	var errors: Array = []
	var dropped: int = 0
	var done: bool = false
	var value: Variant = null

	func write(kind: String, text: String) -> void:
		var target: Array = errors if kind == "err" else lines
		if target.size() >= LINE_LIMIT:
			dropped += 1
			return
		target.append(text)

	func finish(v: Variant) -> void:
		value = v
		done = true

## The caller's _run() is renamed to this before compiling. EditorScript._run()
## is a void virtual, and since Godot 4.7 returning a value from an override of
## it is a parse error ("A void function cannot return a value") -- which would
## break the documented "return a value from _run()" convention on 4.7+.
const SCRIPT_ENTRY := "_mcp_body"

## Appended to every executed script. Gives the body a way to hand text and a
## return value back to the caller: print() itself cannot be intercepted --
## GDScript resolves it to the built-in utility function at parse time, so a
## same-named method in the script is never called.
const OUTPUT_CAPTURE_BLOCK := """

# --- injected by godot_mcp ---
var _mcp_sink = null

func _mcp_main() -> void:
	var _mcp_returned = await _mcp_body()
	if _mcp_sink != null:
		_mcp_sink.finish(_mcp_returned)

func _mcp_write(_mcp_kind: String, _mcp_parts: Array) -> void:
	var _mcp_text := PackedStringArray()
	for _mcp_arg in _mcp_parts:
		if typeof(_mcp_arg) == TYPE_STRING and _mcp_arg == "__mcp_nil_a91f__":
			break
		_mcp_text.append(str(_mcp_arg))
	var _mcp_line := "".join(_mcp_text)
	if _mcp_kind == "err":
		printerr(_mcp_line)
	else:
		print(_mcp_line)
	if _mcp_sink != null:
		_mcp_sink.write(_mcp_kind, _mcp_line)

func mcp_print(a = "__mcp_nil_a91f__", b = "__mcp_nil_a91f__", c = "__mcp_nil_a91f__", d = "__mcp_nil_a91f__", e = "__mcp_nil_a91f__", f = "__mcp_nil_a91f__", g = "__mcp_nil_a91f__", h = "__mcp_nil_a91f__") -> void:
	_mcp_write("out", [a, b, c, d, e, f, g, h])

func mcp_printerr(a = "__mcp_nil_a91f__", b = "__mcp_nil_a91f__", c = "__mcp_nil_a91f__", d = "__mcp_nil_a91f__", e = "__mcp_nil_a91f__", f = "__mcp_nil_a91f__", g = "__mcp_nil_a91f__", h = "__mcp_nil_a91f__") -> void:
	_mcp_write("err", [a, b, c, d, e, f, g, h])
"""

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("take_screenshot",      GodotMCPCallableTool.new(_take_screenshot))
	registry.register_tool("get_error_log",        GodotMCPCallableTool.new(_get_error_log))
	registry.register_tool("execute_script",       GodotMCPCallableTool.new(_execute_script))
	registry.register_tool("open_editor_settings", GodotMCPCallableTool.new(_open_editor_settings))
	registry.register_tool("get_editor_version",   GodotMCPCallableTool.new(_get_editor_version))
	registry.register_tool("get_editor_state",     GodotMCPCallableTool.new(_get_editor_state))
	registry.register_tool("select_node_in_editor",GodotMCPCallableTool.new(_select_node_in_editor))
	registry.register_tool("focus_editor",         GodotMCPCallableTool.new(_focus_editor))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _resolve_node(node_path: String) -> Variant:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return null
	if node_path == "." or node_path == root.name or node_path == "/root/" + root.name:
		return root
	return root.get_node_or_null(node_path)

## Recursive JSON conversion for values a user script returns from _run() --
## unlike the per-tool _value_to_json helpers this one descends into containers,
## because the returned value has no schema we control.
func _json_safe(v: Variant) -> Variant:
	match typeof(v):
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for k in v:
				out[str(k)] = _json_safe(v[k])
			return out
		TYPE_ARRAY:
			var arr: Array = []
			for item in v:
				arr.append(_json_safe(item))
			return arr
		TYPE_PACKED_BYTE_ARRAY:
			# Mirrors resource_tools: a texture or audio buffer would otherwise
			# arrive as a multi-megabyte number list.
			if v.size() <= 64:
				var bytes: Array = []
				for b in v:
					bytes.append(int(b))
				return bytes
			return {"type": "PackedByteArray", "size": v.size(), "preview_hex": v.slice(0, 16).hex_encode()}
	if typeof(v) >= TYPE_PACKED_BYTE_ARRAY:
		var packed: Array = []
		for item in v:
			packed.append(_json_safe(item))
		return packed
	if v is Vector2 or v is Vector2i:   return {"x": v.x, "y": v.y}
	if v is Vector3 or v is Vector3i:   return {"x": v.x, "y": v.y, "z": v.z}
	if v is Vector4 or v is Vector4i:   return {"x": v.x, "y": v.y, "z": v.z, "w": v.w}
	if v is Color:       return {"r": v.r, "g": v.g, "b": v.b, "a": v.a}
	if v is Rect2 or v is Rect2i:
		return {"x": v.position.x, "y": v.position.y, "w": v.size.x, "h": v.size.y}
	if v is Quaternion:  return {"x": v.x, "y": v.y, "z": v.z, "w": v.w}
	if v is Basis:       return {"x": _json_safe(v.x), "y": _json_safe(v.y), "z": _json_safe(v.z)}
	if v is Transform2D: return {"origin": _json_safe(v.origin), "x": _json_safe(v.x), "y": _json_safe(v.y)}
	if v is Transform3D: return {"origin": _json_safe(v.origin), "basis": _json_safe(v.basis)}
	if v is Node:
		var scene_root := EditorInterface.get_edited_scene_root()
		if scene_root != null and (v == scene_root or scene_root.is_ancestor_of(v)):
			return str(scene_root.get_path_to(v))
		return str(v.name)
	if v is Object:
		if v is Resource:
			return v.resource_path if not v.resource_path.is_empty() else str(v)
		return str(v)
	return v

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

## First camera in the open scene, preferring one already marked current.
func _find_scene_camera(node: Node) -> Node:
	var fallback: Node = null
	var queue: Array = [node]
	while not queue.is_empty():
		var current: Node = queue.pop_front()
		if current is Camera3D or current is Camera2D:
			# Camera3D marks intent with 'current', Camera2D with 'enabled'.
			var active: Variant = current.get("current")
			if active == null:
				active = current.get("enabled")
			if bool(active):
				return current
			if fallback == null:
				fallback = current
		queue.append_array(current.get_children())
	return fallback

## Copies a camera's settings onto a stand-in of the same class. Done through
## the property list rather than field by field so the stand-in keeps working
## on engine versions that add, drop or rename camera properties.
func _clone_camera_settings(source: Node, target: Node) -> void:
	var skip: Array = ["name", "owner", "script", "unique_name_in_owner", "scene_file_path"]
	for prop in source.get_property_list():
		var prop_name: String = prop.get("name", "")
		var usage: int = int(prop.get("usage", 0))
		if prop_name.is_empty() or skip.has(prop_name):
			continue
		if not (usage & PROPERTY_USAGE_STORAGE):
			continue
		target.set(prop_name, source.get(prop_name))

## Renders the open scene through one of its cameras into an offscreen
## SubViewport that shares the scene's world, which is the closest thing to
## "what the player sees": the running game runs in its own OS process and its
## window is not reachable from the editor.
func _render_through_camera(args: Dictionary) -> Dictionary:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return {"error": "No scene is open — open the scene whose camera you want to render through"}

	var camera_path: String = str(args.get("camera_path", ""))
	var camera: Node = null
	if camera_path.is_empty():
		camera = _find_scene_camera(root)
		if camera == null:
			return {"error": "No Camera3D or Camera2D in the open scene — add one or pass 'camera_path'"}
	else:
		var found = _resolve_node(camera_path)
		if found == null:
			return {"error": "Camera node not found: %s" % camera_path}
		if not (found is Camera3D or found is Camera2D):
			return {"error": "Node '%s' is a %s, not a Camera3D or Camera2D" % [camera_path, found.get_class()]}
		camera = found

	# Default to the size the player's window will have, so framing and an
	# orthographic camera's size read the same as they will in the game.
	var width: int = int(clamp(int(args.get("width", ProjectSettings.get_setting("display/window/size/viewport_width", 1152))), 16, 4096))
	var height: int = int(clamp(int(args.get("height", ProjectSettings.get_setting("display/window/size/viewport_height", 648))), 16, 4096))

	var sub := SubViewport.new()
	sub.size = Vector2i(width, height)
	sub.transparent_bg = bool(args.get("transparent_bg", false))
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub.handle_input_locally = false

	var stand_in: Node
	if camera is Camera3D:
		sub.world_3d = root.get_viewport().find_world_3d()
		stand_in = Camera3D.new()
	else:
		sub.world_2d = root.get_viewport().find_world_2d()
		stand_in = Camera2D.new()
	_clone_camera_settings(camera, stand_in)
	sub.add_child(stand_in)
	EditorInterface.get_base_control().add_child(sub)

	stand_in.global_transform = camera.global_transform
	# The stand-in is a rendering probe, not scene content: a hidden Camera3D
	# renders nothing, and the caller asked for this camera's view either way.
	stand_in.visible = true
	if stand_in is Camera3D:
		stand_in.current = true
	else:
		stand_in.make_current()

	# process_frame rather than RenderingServer.frame_post_draw: the tree is
	# guaranteed to tick (this tool call arrived through the plugin's _process),
	# so the wait cannot hang the bridge if the editor is not drawing.
	var image: Image = null
	for attempt in 2:
		await _plugin.get_tree().process_frame
		await _plugin.get_tree().process_frame
		if not is_instance_valid(sub):
			return {"error": "Render viewport was freed while capturing"}
		image = sub.get_texture().get_image()
		if image != null and not image.is_empty():
			break

	var info: Dictionary = {"camera": str(root.get_path_to(camera))}
	if camera is Camera3D:
		info["projection"] = ["perspective", "orthogonal", "frustum"][int(camera.projection)]
		if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
			info["size"] = camera.size
		else:
			info["fov"] = camera.fov
	else:
		info["zoom"] = {"x": camera.zoom.x, "y": camera.zoom.y}

	sub.queue_free()

	if image == null or image.is_empty():
		return {"error": "Camera render came back empty — the editor may be running without rendering (--headless)"}
	info["image"] = image
	return info

func _take_screenshot(args: Dictionary) -> Dictionary:
	var save_path: String = args.get("save_path", "res://screenshot.png")
	var viewport_type: String = args.get("viewport", "editor")

	var image: Image
	var extra: Dictionary = {}

	if viewport_type == "camera":
		var render: Dictionary = await _render_through_camera(args)
		if render.has("error"):
			return render
		image = render["image"]
		render.erase("image")
		extra = render
	elif viewport_type == "editor":
		# Render the editor's own window. A desktop grab (screen_get_image) would
		# capture whatever window happens to sit on top of the editor instead.
		var vp := EditorInterface.get_base_control().get_viewport()
		image = vp.get_texture().get_image()
	elif viewport_type == "2d":
		var vp := EditorInterface.get_editor_viewport_2d()
		image = vp.get_texture().get_image()
	else: # "3d"
		var vp := EditorInterface.get_editor_viewport_3d(0)
		image = vp.get_texture().get_image()

	if image == null or image.is_empty():
		return {"error": "Failed to capture viewport image"}

	var abs_path := ProjectSettings.globalize_path(save_path)
	var err := image.save_png(abs_path)
	if err != OK:
		return {"error": "Failed to save screenshot: %s" % error_string(err)}

	EditorInterface.get_resource_filesystem().scan()
	var result: Dictionary = {
		"success": true,
		"save_path": save_path,
		"width": image.get_width(),
		"height": image.get_height(),
	}
	result.merge(extra)
	return result

## Directories Godot may keep godot.log (and its rotated copies) in, newest
## file wins. The editor process itself writes no log at all -- only a running
## project or a --script run does -- so the project's user:// dir is the one
## that answers "did the scene start clean?".
func _error_log_dirs() -> Array:
	var dirs: Array = []
	var configured: String = str(ProjectSettings.get_setting("debug/file_logging/log_path", "user://logs/godot.log"))
	for candidate in [
		ProjectSettings.globalize_path(configured).get_base_dir(),
		OS.get_user_data_dir().path_join("logs"),
		EditorInterface.get_editor_paths().get_data_dir().path_join("logs"),
	]:
		if not candidate.is_empty() and not dirs.has(candidate):
			dirs.append(candidate)
	return dirs

## Most recently modified *.log across the candidate directories.
func _newest_log_file(dirs: Array) -> String:
	var newest_path := ""
	var newest_time := -1
	for entry in dirs:
		var dir_path: String = entry
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		for name in dir.get_files():
			var file_name: String = name
			if not file_name.ends_with(".log"):
				continue
			var full: String = dir_path.path_join(file_name)
			var mtime: int = int(FileAccess.get_modified_time(full))
			if mtime > newest_time:
				newest_time = mtime
				newest_path = full
	return newest_path

func _get_error_log(args: Dictionary) -> Dictionary:
	var last_n: int = int(args.get("last_n_lines", 100))
	var filter: String = args.get("filter", "all")
	var log_path: String = str(args.get("log_path", ""))

	var dirs := _error_log_dirs()
	if log_path.is_empty():
		log_path = _newest_log_file(dirs)
	elif log_path.begins_with("res://") or log_path.begins_with("user://"):
		log_path = ProjectSettings.globalize_path(log_path)

	var logging_enabled := bool(ProjectSettings.get_setting("debug/file_logging/enable_file_logging", false))
	if log_path.is_empty() or not FileAccess.file_exists(log_path):
		return {
			"lines": [],
			"total": 0,
			"file_logging_enabled": logging_enabled,
			"searched": dirs,
			"note": ("No log file found. Note the Godot editor never writes one — only a running project does, "
				+ "so play the scene (play_scene) and read the log afterwards. "
				+ ("File logging is currently disabled: set debug/file_logging/enable_file_logging to true and restart the project." if not logging_enabled else "")),
		}

	var file := FileAccess.open(log_path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot open log file: %s" % log_path}

	var content := file.get_as_text()
	file.close()
	var raw_lines: Array = Array(content.split("\n"))

	# Apply filter. Godot writes an error's location and backtrace on the
	# indented lines that follow it, so a filtered error keeps them -- without
	# them the message names no file and no line.
	var filtered: Array = []
	var keep_continuation := false
	for line in raw_lines:
		if line.strip_edges().is_empty():
			continue
		var is_continuation: bool = line.begins_with(" ") or line.begins_with("\t")
		if is_continuation and filter != "all":
			if keep_continuation:
				filtered.append(line)
			continue
		keep_continuation = false
		match filter:
			"errors":
				if "ERROR" in line:
					filtered.append(line)
					keep_continuation = true
			"warnings":
				if "WARNING" in line or "WARN" in line:
					filtered.append(line)
					keep_continuation = true
			_:
				filtered.append(line)

	# Return last N lines
	var start := max(0, filtered.size() - last_n)
	var result_lines: Array = filtered.slice(start)

	return {
		"lines": result_lines,
		"total": result_lines.size(),
		"log_path": log_path,
		"modified_time": int(FileAccess.get_modified_time(log_path)),
		"file_logging_enabled": logging_enabled,
	}

func _execute_script(args: Dictionary) -> Dictionary:
	var code: String = args.get("code", "")
	if code.is_empty():
		return {"error": "'code' is required"}
	var timeout: float = clampf(float(args.get("timeout", 10.0)), 0.1, 60.0)

	# Wrap code in an EditorScript if it doesn't declare one, and run the body
	# under SCRIPT_ENTRY rather than _run() so it may return a value.
	var wrapped: String
	if "func _run(" in code:
		var header := "" if "extends EditorScript" in code else "@tool\nextends EditorScript\n\n"
		wrapped = header + code.replace("func _run(", "func %s(" % SCRIPT_ENTRY)
	elif "extends EditorScript" in code:
		wrapped = code
	else:
		# Auto-wrap: the caller wrote bare statements
		wrapped = "@tool\nextends EditorScript\n\nfunc %s():\n" % SCRIPT_ENTRY
		for line in code.split("\n"):
			wrapped += "\t" + line + "\n"

	var script := GDScript.new()
	script.source_code = wrapped + OUTPUT_CAPTURE_BLOCK
	var compile_err := script.reload(false)
	var captured := compile_err == OK
	if not captured:
		# The injected helpers can collide with names the script already
		# declares. Run it as written rather than failing on a helper the
		# caller never asked for.
		script = GDScript.new()
		script.source_code = wrapped
		compile_err = script.reload(false)
	if compile_err != OK:
		return {"error": "Script compilation failed (code %d). Check syntax." % compile_err, "source": wrapped}

	var instance = script.new()
	if not instance.has_method(SCRIPT_ENTRY):
		return {"error": "Script must define func _run()"}

	var response: Dictionary = {"success": true}
	var returned: Variant = null

	if captured:
		var sink := ScriptOutput.new()
		instance.set("_mcp_sink", sink)
		# Deferred so a _run() that suspends on an await is resumed by the
		# engine instead of being dropped on the floor; polling the sink keeps
		# a script that awaits something that never fires from wedging the
		# bridge (the plugin serves one tool call at a time).
		instance.call_deferred("_mcp_main")
		var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
		while not sink.done and Time.get_ticks_msec() < deadline:
			await _plugin.get_tree().create_timer(0.02).timeout
			if not is_instance_valid(_plugin):
				return {"error": "Plugin was disabled while the script was running"}
		if not sink.done:
			return {
				"error": "Script did not finish within %.1fs — it is awaiting something that has not happened and keeps running in the background" % timeout,
				"output": sink.lines,
				"errors": sink.errors,
				"partial": true,
			}
		returned = sink.value
		response["output"] = sink.lines
		if not sink.errors.is_empty():
			response["errors"] = sink.errors
		if sink.dropped > 0:
			response["output_dropped"] = sink.dropped
			response["note"] = "Output truncated at %d lines; %d more were dropped." % [ScriptOutput.LINE_LIMIT, sink.dropped]
	else:
		# Direct call on purpose: the VM resumes a coroutine awaited this way.
		# The name is SCRIPT_ENTRY, spelled out because it is a call, not a string.
		returned = await instance._mcp_body()
		response["output_capture"] = false
		response["note"] = "Output capture is unavailable for this script (the injected mcp_print helpers clash with a name it declares); print() output went to the Godot Output panel only."

	if returned != null:
		response["result"] = _json_safe(returned)

	if not response.has("note") and response.get("output", []).is_empty() and not response.has("result") \
			and ("print(" in code) and not ("mcp_print(" in code):
		response["note"] = "print() writes to the Godot Output panel only. Use mcp_print(...) — same signature — to get the text back here, or return a value from _run()."

	return response

func _open_editor_settings(args: Dictionary) -> Dictionary:
	var prefix: String = args.get("prefix", "")
	var settings := EditorInterface.get_editor_settings()
	var result: Dictionary = {}

	for key in settings.get_property_list():
		var name: String = key.get("name", "")
		if name.is_empty() or name.begins_with("_"):
			continue
		if not prefix.is_empty() and not name.begins_with(prefix):
			continue
		result[name] = settings.get_setting(name)

	return {"settings": result, "count": result.size()}

func _get_editor_version(_args: Dictionary) -> Dictionary:
	var info := Engine.get_version_info()
	return {
		"major": info.get("major", 0),
		"minor": info.get("minor", 0),
		"patch": info.get("patch", 0),
		"string": info.get("string", ""),
		"build": info.get("build", ""),
		"status": info.get("status", ""),
		"year": info.get("year", 0),
	}

func _get_editor_state(_args: Dictionary) -> Dictionary:
	var root := EditorInterface.get_edited_scene_root()
	var scene_path := root.scene_file_path if root else ""

	# Selected nodes
	var selection := EditorInterface.get_selection()
	var selected: Array = []
	for node in selection.get_selected_nodes():
		selected.append({
			"name": node.name,
			"type": node.get_class(),
			"path": str(node.get_path()),
		})

	# Open scenes
	var open_scenes: Array = Array(EditorInterface.get_open_scenes())

	return {
		"active_scene": scene_path,
		"open_scenes": open_scenes,
		"selected_nodes": selected,
		"has_open_scene": root != null,
		"plugin_version": _plugin.get_version() if _plugin.has_method("get_version") else "1.0.0",
		"godot_version": Engine.get_version_info().get("string", ""),
	}

func _select_node_in_editor(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var selection := EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)

	# Add additional nodes if provided
	var extra: Array = args.get("additional_paths", [])
	for extra_path in extra:
		var extra_node := _resolve_node(extra_path)
		if extra_node:
			selection.add_node(extra_node)

	var selected_paths: Array = []
	for n in selection.get_selected_nodes():
		selected_paths.append(str(n.get_path()))

	return {"success": true, "selected": selected_paths}

func _focus_editor(_args: Dictionary) -> Dictionary:
	DisplayServer.window_move_to_foreground()
	DisplayServer.window_request_attention()
	return {"success": true}
