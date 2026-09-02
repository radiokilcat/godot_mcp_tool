@tool
extends GodotMCPToolBase

class_name GodotMCPProjectTools

## Implements all 7 project-level tools.
## Each method matches the tool name called from the MCP server.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("get_project_info",     GodotMCPCallableTool.new(_get_project_info))
	registry.register_tool("list_project_files",   GodotMCPCallableTool.new(_list_project_files))
	registry.register_tool("search_files",         GodotMCPCallableTool.new(_search_files))
	registry.register_tool("get_project_settings", GodotMCPCallableTool.new(_get_project_settings))
	registry.register_tool("set_project_setting",  GodotMCPCallableTool.new(_set_project_setting))
	registry.register_tool("convert_uid",          GodotMCPCallableTool.new(_convert_uid))
	registry.register_tool("get_project_metadata", GodotMCPCallableTool.new(_get_project_metadata))

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _get_project_info(_args: Dictionary) -> Dictionary:
	var ver := Engine.get_version_info()
	return {
		"project_name": ProjectSettings.get_setting("application/config/name", ""),
		"project_version": ProjectSettings.get_setting("application/config/version", ""),
		"godot_version": "%d.%d.%d" % [ver.get("major", 4), ver.get("minor", 0), ver.get("patch", 0)],
		"project_path": ProjectSettings.globalize_path("res://"),
		"main_scene": ProjectSettings.get_setting("application/run/main_scene", ""),
	}

func _list_project_files(args: Dictionary) -> Dictionary:
	var path: String = args.get("path", "res://")
	var filter: String = args.get("filter", "")
	var files: Array = []
	_collect_files(path, filter, files)
	return {"files": files, "total": files.size()}

func _collect_files(path: String, filter: String, result: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not item.begins_with("."):
			var full := path.path_join(item)
			if dir.current_is_dir():
				_collect_files(full, filter, result)
			elif filter.is_empty() or item.ends_with(filter):
				result.append(full)
		item = dir.get_next()
	dir.list_dir_end()

func _search_files(args: Dictionary) -> Dictionary:
	var query: String = args.get("query", "")
	if query.is_empty():
		return {"error": "'query' parameter is required"}
	var search_type: String = args.get("type", "name")
	var results: Array = []
	if search_type == "content":
		_search_by_content("res://", query, results)
	else:
		_search_by_name("res://", query.to_lower(), results)
	return {"results": results, "total": results.size()}

func _search_by_name(path: String, query: String, results: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not item.begins_with("."):
			var full := path.path_join(item)
			if dir.current_is_dir():
				_search_by_name(full, query, results)
			elif item.to_lower().contains(query):
				results.append({"path": full, "name": item})
		item = dir.get_next()
	dir.list_dir_end()

func _search_by_content(path: String, query: String, results: Array) -> void:
	var text_exts := [".gd", ".tscn", ".tres", ".gdshader", ".glsl", ".json", ".cfg"]
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not item.begins_with("."):
			var full := path.path_join(item)
			if dir.current_is_dir():
				_search_by_content(full, query, results)
			else:
				var ext := "." + item.get_extension()
				if ext in text_exts:
					var file := FileAccess.open(full, FileAccess.READ)
					if file:
						if file.get_as_text().contains(query):
							results.append({"path": full, "name": item})
						file.close()
		item = dir.get_next()
	dir.list_dir_end()

func _get_project_settings(args: Dictionary) -> Dictionary:
	var setting_path: String = args.get("setting_path", "")
	if not setting_path.is_empty():
		if not ProjectSettings.has_setting(setting_path):
			return {"error": "Setting not found: %s" % setting_path}
		return {"settings": {setting_path: ProjectSettings.get_setting(setting_path)}}
	# Return a useful subset of common settings
	var keys := [
		"application/config/name",
		"application/config/version",
		"application/run/main_scene",
		"display/window/size/viewport_width",
		"display/window/size/viewport_height",
		"physics/2d/default_gravity",
		"rendering/renderer/rendering_method",
	]
	var result := {}
	for k in keys:
		if ProjectSettings.has_setting(k):
			result[k] = ProjectSettings.get_setting(k)
	return {"settings": result}

func _set_project_setting(args: Dictionary) -> Dictionary:
	var setting_path: String = args.get("setting_path", "")
	if setting_path.is_empty():
		return {"error": "'setting_path' parameter is required"}
	if not args.has("value"):
		return {"error": "'value' parameter is required"}
	var value = args.get("value")

	# JSON has no integer type, so every number arrives as a float and an int setting would be
	# written as "viewport_width=1920.0". Coerce to the type the setting already holds.
	if ProjectSettings.has_setting(setting_path):
		value = _coerce_numeric(value, typeof(ProjectSettings.get_setting(setting_path)))

	ProjectSettings.set_setting(setting_path, value)
	var err := ProjectSettings.save()
	if err != OK:
		return {"error": "Failed to save project settings: %s" % error_string(err)}

	# Report what the setting actually holds now rather than echoing the input: Godot omits
	# values equal to the engine default when saving, so a call that "succeeded" may leave
	# nothing in project.godot at all. Without the read-back the two cases look identical.
	var effective = ProjectSettings.get_setting(setting_path)
	var result: Dictionary = {"success": true, "path": setting_path, "value": effective}
	if ProjectSettings.property_can_revert(setting_path) \
			and ProjectSettings.property_get_revert(setting_path) == effective:
		result["is_engine_default"] = true
		result["note"] = "Value equals the engine default, so Godot does not write it to project.godot. The setting is in effect regardless."
	return result

## Convert a JSON-decoded number to the type a setting already uses. Only numeric types are
## converted — coercing a String would silently turn a typo into 0.
func _coerce_numeric(value: Variant, target_type: int) -> Variant:
	if typeof(value) == target_type:
		return value
	match target_type:
		TYPE_INT:
			if value is float or value is bool:
				return int(value)
		TYPE_FLOAT:
			if value is int or value is bool:
				return float(value)
		TYPE_BOOL:
			if value is int or value is float:
				return bool(value)
	return value

func _convert_uid(args: Dictionary) -> Dictionary:
	var uid_str: String = args.get("uid", "")
	var path: String = args.get("path", "")
	if not uid_str.is_empty():
		if not uid_str.begins_with("uid://"):
			return {"error": "UID must start with 'uid://'"}
		var uid_int := ResourceUID.text_to_id(uid_str)
		if uid_int == ResourceUID.INVALID_ID:
			return {"error": "Invalid UID: %s" % uid_str}
		return {"uid": uid_str, "path": ResourceUID.get_id_path(uid_int)}
	elif not path.is_empty():
		var uid_int := ResourceLoader.get_resource_uid(path)
		if uid_int == ResourceUID.INVALID_ID:
			return {"error": "No UID found for path: %s" % path}
		return {"path": path, "uid": ResourceUID.id_to_text(uid_int)}
	return {"error": "Provide either 'uid' or 'path'"}

func _get_project_metadata(_args: Dictionary) -> Dictionary:
	var features: Array = []
	for f in ["mobile", "web", "windows", "macos", "linux", "android", "ios"]:
		if OS.has_feature(f):
			features.append(f)
	var renderer: String = ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus")
	var w := ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
	var h := ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	return {
		"features": features,
		"renderer": renderer,
		"viewport_size": {"width": w, "height": h},
		"physics_2d_gravity": ProjectSettings.get_setting("physics/2d/default_gravity", 980.0),
		"supported_platforms": ["windows", "macos", "linux", "android", "ios", "web"],
	}
