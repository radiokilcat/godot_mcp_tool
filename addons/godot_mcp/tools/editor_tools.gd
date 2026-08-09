@tool
extends RefCounted

class_name GodotMCPEditorTools

## Implements 8 editor-level tools.
## (reload_scripts lives in script_tools.gd to avoid duplication)

var _plugin: EditorPlugin

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

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _take_screenshot(args: Dictionary) -> Dictionary:
	var save_path: String = args.get("save_path", "res://screenshot.png")
	var viewport_type: String = args.get("viewport", "editor")

	var image: Image

	if viewport_type == "editor":
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
	return {
		"success": true,
		"save_path": save_path,
		"width": image.get_width(),
		"height": image.get_height(),
	}

func _get_error_log(args: Dictionary) -> Dictionary:
	var last_n: int = int(args.get("last_n_lines", 100))
	var filter: String = args.get("filter", "all")

	# Editor logs live in the editor data dir, not the game's user:// dir
	var log_path := EditorInterface.get_editor_paths().get_data_dir().path_join("logs/godot.log")

	var raw_lines: Array = []
	if log_path.is_empty() or not FileAccess.file_exists(log_path):
		return {"lines": [], "total": 0, "note": "Log file not found. Run project with --verbose to generate logs."}

	var file := FileAccess.open(log_path, FileAccess.READ)
	if file == null:
		return {"error": "Cannot open log file: %s" % log_path}

	var content := file.get_as_text()
	file.close()
	raw_lines = Array(content.split("\n"))

	# Apply filter
	var filtered: Array = []
	for line in raw_lines:
		if line.strip_edges().is_empty():
			continue
		match filter:
			"errors":
				if "ERROR" in line or "SCRIPT ERROR" in line:
					filtered.append(line)
			"warnings":
				if "WARNING" in line or "WARN" in line:
					filtered.append(line)
			_:
				filtered.append(line)

	# Return last N lines
	var start := max(0, filtered.size() - last_n)
	var result_lines: Array = filtered.slice(start)

	return {
		"lines": result_lines,
		"total": result_lines.size(),
		"log_path": log_path,
	}

func _execute_script(args: Dictionary) -> Dictionary:
	var code: String = args.get("code", "")
	if code.is_empty():
		return {"error": "'code' is required"}

	# Wrap code in an EditorScript if it doesn't declare one
	var wrapped: String
	if "extends EditorScript" in code:
		wrapped = code
	else:
		# Auto-wrap: if user wrote statements, put them in _run()
		if "func _run(" in code:
			wrapped = "@tool\nextends EditorScript\n\n" + code
		else:
			wrapped = "@tool\nextends EditorScript\n\nfunc _run():\n"
			for line in code.split("\n"):
				wrapped += "\t" + line + "\n"

	var script := GDScript.new()
	script.source_code = wrapped
	var compile_err := script.reload(false)
	if compile_err != OK:
		return {"error": "Script compilation failed (code %d). Check syntax." % compile_err, "source": wrapped}

	var instance = script.new()
	if not instance.has_method("_run"):
		return {"error": "Script must define func _run()"}

	# EditorScript.run() returns void; capture print output via workaround not available
	# Just call _run() and check for exceptions
	instance._run()

	return {"success": true, "note": "Script executed. Check Godot Output panel for any print() output."}

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
