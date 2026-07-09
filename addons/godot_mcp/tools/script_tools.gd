@tool
extends RefCounted

class_name GodotMCPScriptTools

## Implements all 8 script-level tools.

var _plugin: EditorPlugin

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("read_script",       GodotMCPCallableTool.new(_read_script))
	registry.register_tool("create_script",     GodotMCPCallableTool.new(_create_script))
	registry.register_tool("edit_script",       GodotMCPCallableTool.new(_edit_script))
	registry.register_tool("attach_script",     GodotMCPCallableTool.new(_attach_script))
	registry.register_tool("validate_syntax",   GodotMCPCallableTool.new(_validate_syntax))
	registry.register_tool("search_in_scripts", GodotMCPCallableTool.new(_search_in_scripts))
	registry.register_tool("get_script_info",   GodotMCPCallableTool.new(_get_script_info))
	registry.register_tool("reload_scripts",    GodotMCPCallableTool.new(_reload_scripts))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _read_file(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	return text

func _write_file(path: String, content: String) -> Error:
	# Ensure parent directory exists
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file.close()
	return OK

func _resolve_node(node_path: String) -> Variant:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return null
	if node_path == "." or node_path == root.name or node_path == "/root/" + root.name:
		return root
	return root.get_node_or_null(node_path)

func _script_template(extends_type: String, class_name_str: String) -> String:
	var lines: Array = []
	if not class_name_str.is_empty():
		lines.append("class_name %s" % class_name_str)
	if not extends_type.is_empty():
		lines.append("extends %s" % extends_type)
	if lines.size() > 0:
		lines.append("")
	lines.append("")
	return "\n".join(lines)

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _read_script(args: Dictionary) -> Dictionary:
	var script_path: String = args.get("script_path", "")
	if script_path.is_empty():
		return {"error": "'script_path' is required"}

	var abs_path := ProjectSettings.globalize_path(script_path)
	if not FileAccess.file_exists(abs_path):
		return {"error": "Script not found: %s" % script_path}

	var content = _read_file(abs_path)
	if content == null:
		return {"error": "Failed to read script: %s" % script_path}

	var lines: PackedStringArray = (content as String).split("\n")
	return {
		"script_path": script_path,
		"content": content,
		"line_count": lines.size(),
	}

func _create_script(args: Dictionary) -> Dictionary:
	var script_path: String   = args.get("script_path", "")
	if script_path.is_empty():
		return {"error": "'script_path' is required"}

	var abs_path := ProjectSettings.globalize_path(script_path)
	if FileAccess.file_exists(abs_path):
		return {"error": "Script already exists: %s (use edit_script to modify)" % script_path}

	var content: String = args.get("content", "")
	if content.is_empty():
		var extends_type: String   = args.get("extends_type", "")
		var class_name_str: String = args.get("class_name_str", "")
		content = _script_template(extends_type, class_name_str)

	var err := _write_file(abs_path, content)
	if err != OK:
		return {"error": "Failed to create script: %s" % error_string(err)}

	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "script_path": script_path, "line_count": content.split("\n").size()}

func _edit_script(args: Dictionary) -> Dictionary:
	var script_path: String = args.get("script_path", "")
	var new_content: String = args.get("content", "")
	if script_path.is_empty():
		return {"error": "'script_path' is required"}
	if new_content.is_empty():
		return {"error": "'content' is required"}

	var abs_path := ProjectSettings.globalize_path(script_path)
	if not FileAccess.file_exists(abs_path):
		return {"error": "Script not found: %s" % script_path}

	var start_line: int = int(args.get("start_line", 0))
	var end_line: int   = int(args.get("end_line", 0))

	if (start_line > 0) != (end_line > 0):
		return {"error": "'start_line' and 'end_line' must both be provided for partial replacement"}

	if start_line > 0 and end_line > 0:
		# Partial replacement
		var existing = _read_file(abs_path)
		if existing == null:
			return {"error": "Failed to read script"}
		var lines: Array = Array((existing as String).split("\n"))
		if start_line > end_line:
			return {"error": "'start_line' (%d) must be <= 'end_line' (%d)" % [start_line, end_line]}
		if end_line > lines.size():
			return {"error": "'end_line' (%d) exceeds file length (%d lines)" % [end_line, lines.size()]}
		var before: Array = lines.slice(0, start_line - 1)
		var after: Array  = lines.slice(end_line)       # end_line is inclusive
		var replacement: Array = Array(new_content.split("\n"))
		var merged: Array = before + replacement + after
		new_content = "\n".join(merged)

	var err := _write_file(abs_path, new_content)
	if err != OK:
		return {"error": "Failed to write script: %s" % error_string(err)}

	# Reload the script resource in editor
	var script: GDScript = ResourceLoader.load(script_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if script:
		script.reload()

	return {"success": true, "script_path": script_path, "line_count": new_content.split("\n").size()}

func _attach_script(args: Dictionary) -> Dictionary:
	var node_path: String   = args.get("node_path", "")
	var script_path: String = args.get("script_path", "")
	if node_path.is_empty() or script_path.is_empty():
		return {"error": "'node_path' and 'script_path' are required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var abs_path := ProjectSettings.globalize_path(script_path)
	var created := false

	# Create the script file if it doesn't exist
	if not FileAccess.file_exists(abs_path):
		var extends_type: String = args.get("extends_type", node.get_class())
		var template := _script_template(extends_type, "")
		var err := _write_file(abs_path, template)
		if err != OK:
			return {"error": "Failed to create script file: %s" % error_string(err)}
		EditorInterface.get_resource_filesystem().scan()
		created = true

	var script: GDScript = ResourceLoader.load(script_path)
	if script == null:
		return {"error": "Failed to load script: %s" % script_path}

	var old_script = node.get_script()
	var ur := _plugin.get_undo_redo()
	ur.create_action("Attach Script: %s" % script_path.get_file())
	ur.add_do_property(node, "script", script)
	ur.add_undo_property(node, "script", old_script)
	ur.commit_action()

	return {
		"success": true,
		"node_path": node_path,
		"script_path": script_path,
		"created_file": created,
	}

func _validate_syntax(args: Dictionary) -> Dictionary:
	var source: String      = args.get("source_code", "")
	var script_path: String = args.get("script_path", "")

	if source.is_empty() and script_path.is_empty():
		return {"error": "Provide 'source_code' or 'script_path'"}

	if source.is_empty():
		var abs_path := ProjectSettings.globalize_path(script_path)
		var content = _read_file(abs_path)
		if content == null:
			return {"error": "Script not found: %s" % script_path}
		source = content as String

	var test_script := GDScript.new()
	test_script.source_code = source
	var err := test_script.reload(false)

	if err == OK:
		return {"valid": true, "line_count": source.split("\n").size()}

	return {
		"valid": false,
		"error_code": err,
		"error": "Syntax error (code %d) — open in Godot editor for details" % err,
	}

func _search_in_scripts(args: Dictionary) -> Dictionary:
	var query: String = args.get("query", "")
	if query.is_empty():
		return {"error": "'query' is required"}

	var root_path: String    = args.get("path", "res://")
	var case_sensitive: bool = args.get("case_sensitive", false)
	var search_query := query if case_sensitive else query.to_lower()

	var matches: Array = []
	_search_recursive(root_path, search_query, case_sensitive, matches)

	return {"query": query, "matches": matches, "total_matches": matches.size()}

func _search_recursive(path: String, query: String, case_sensitive: bool, results: Array) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var item := dir.get_next()
	while item != "":
		if not item.begins_with("."):
			var full := path.path_join(item)
			if dir.current_is_dir():
				_search_recursive(full, query, case_sensitive, results)
			elif item.ends_with(".gd"):
				var abs_path := ProjectSettings.globalize_path(full)
				var content = _read_file(abs_path)
				if content != null:
					var lines: Array = Array((content as String).split("\n"))
					for i in range(lines.size()):
						var line: String = lines[i]
						var compare := line if case_sensitive else line.to_lower()
						if compare.contains(query):
							results.append({
								"file": full,
								"line": i + 1,
								"text": line.strip_edges(),
							})
		item = dir.get_next()
	dir.list_dir_end()

func _get_script_info(args: Dictionary) -> Dictionary:
	var script_path: String = args.get("script_path", "")
	if script_path.is_empty():
		return {"error": "'script_path' is required"}

	if not ResourceLoader.exists(script_path):
		return {"error": "Script not found: %s" % script_path}

	var script: GDScript = ResourceLoader.load(script_path)
	if script == null:
		return {"error": "Failed to load script: %s" % script_path}

	# Methods
	var methods: Array = []
	for m in script.get_script_method_list():
		var name: String = m.get("name", "")
		if not name.begins_with("_") or name in ["_ready", "_process", "_physics_process", "_input", "_unhandled_input", "_init"]:
			methods.append(name)

	# Signals
	var signals: Array = []
	for s in script.get_script_signal_list():
		signals.append(s.get("name", ""))

	# Properties
	var properties: Array = []
	for p in script.get_script_property_list():
		if p.get("usage", 0) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			properties.append({"name": p.name, "type": type_string(p.type)})

	# Read source for class_name and extends
	var abs_path := ProjectSettings.globalize_path(script_path)
	var class_name_str := ""
	var extends_str := ""
	var content = _read_file(abs_path)
	if content != null:
		for line in (content as String).split("\n"):
			var stripped := line.strip_edges()
			if stripped.begins_with("class_name "):
				class_name_str = stripped.trim_prefix("class_name ").split(" ")[0]
			elif stripped.begins_with("extends "):
				extends_str = stripped.trim_prefix("extends ").split(" ")[0]
			elif stripped.length() > 0 and not stripped.begins_with("#") and not stripped.begins_with("@"):
				break  # stop at first real code line

	return {
		"script_path": script_path,
		"class_name": class_name_str,
		"extends": extends_str,
		"methods": methods,
		"signals": signals,
		"properties": properties,
	}

func _reload_scripts(_args: Dictionary) -> Dictionary:
	# ScriptEditor.reload_scripts() is not exposed to scripting in Godot 4.0-4.4 —
	# reload each open script from disk and rescan the filesystem instead
	var reloaded: Array = []
	for script in EditorInterface.get_script_editor().get_open_scripts():
		if not script is Script or script.resource_path.is_empty():
			continue
		var text = _read_file(script.resource_path)
		if text is String:
			script.source_code = text
			script.reload(true)
			reloaded.append(script.resource_path)
	EditorInterface.get_resource_filesystem().scan_sources()
	return {"success": true, "reloaded": reloaded, "count": reloaded.size()}
