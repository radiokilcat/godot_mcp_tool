@tool
extends RefCounted

class_name GodotMCPAnalysisTools

## Implements 4 Analysis tools:
## analyze_scene_complexity, trace_signal_flow, find_unused_resources, get_code_metrics

var _plugin: EditorPlugin

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("analyze_scene_complexity", GodotMCPCallableTool.new(_analyze_scene_complexity))
	registry.register_tool("trace_signal_flow",        GodotMCPCallableTool.new(_trace_signal_flow))
	registry.register_tool("find_unused_resources",    GodotMCPCallableTool.new(_find_unused_resources))
	registry.register_tool("get_code_metrics",         GodotMCPCallableTool.new(_get_code_metrics))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _as_bool(val: Variant) -> bool:
	if val is bool: return val
	return str(val).to_lower() == "true"

func _get_filesystem() -> EditorFileSystemDirectory:
	return _plugin.get_editor_interface().get_resource_filesystem().get_filesystem()

func _collect_files_by_ext(dir: EditorFileSystemDirectory, extensions: Array, out: Dictionary) -> void:
	for i in dir.get_file_count():
		var fp: String = dir.get_file_path(i)
		for ext in extensions:
			if fp.ends_with(ext):
				out[fp] = true
				break
	for i in dir.get_subdir_count():
		_collect_files_by_ext(dir.get_subdir(i), extensions, out)

## Load a PackedScene from args["scene_path"], or from the currently open scene if omitted.
## Returns {"ps": PackedScene, "path": String} on success, or {"error": String} on failure.
func _resolve_scene(args: Dictionary) -> Dictionary:
	var scene_path: String = args.get("scene_path", "")
	if scene_path.is_empty():
		var root: Node = _plugin.get_editor_interface().get_edited_scene_root()
		if root == null:
			return {"error": "No scene is currently open. Provide 'scene_path' or open a scene first."}
		scene_path = root.scene_file_path
		if scene_path.is_empty():
			return {"error": "Current scene has not been saved yet. Save it first or provide 'scene_path'."}
	if not ResourceLoader.exists(scene_path):
		return {"error": "Scene not found: %s" % scene_path}
	var ps = ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not ps is PackedScene:
		return {"error": "Not a valid PackedScene: %s" % scene_path}
	return {"ps": ps, "path": scene_path}

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _analyze_scene_complexity(args: Dictionary) -> Dictionary:
	var resolved := _resolve_scene(args)
	if resolved.has("error"):
		return resolved
	var ps: PackedScene = resolved["ps"]
	var scene_path: String = resolved["path"]

	var state: SceneState = ps.get_state()
	var node_count: int = state.get_node_count()
	var max_depth: int = 0
	var script_count: int = 0
	var instanced_scenes: int = 0
	var node_types: Dictionary = {}
	var external_resources: Dictionary = {}

	for i in node_count:
		var np_str: String = str(state.get_node_path(i))
		var depth: int = 0 if np_str == "." else np_str.count("/") + 1
		if depth > max_depth:
			max_depth = depth

		var nt: String = state.get_node_type(i)
		if nt.is_empty():
			instanced_scenes += 1
			continue

		node_types[nt] = node_types.get(nt, 0) + 1

		for pi in state.get_node_property_count(i):
			var pname: String = str(state.get_node_property_name(i, pi))
			var pval = state.get_node_property_value(i, pi)
			if pname == "script":
				script_count += 1
			elif pval is Resource:
				var rpath: String = pval.resource_path
				if not rpath.is_empty() and rpath.begins_with("res://"):
					external_resources[rpath] = true

	# Sort node types by frequency descending
	var type_list: Array = []
	for nt in node_types:
		type_list.append({"type": nt, "count": node_types[nt]})
	type_list.sort_custom(func(a, b): return a["count"] > b["count"])

	return {
		"scene_path":                 scene_path,
		"node_count":                 node_count,
		"max_depth":                  max_depth,
		"scripted_nodes":             script_count,
		"instanced_scenes":           instanced_scenes,
		"signal_connections":         state.get_connection_count(),
		"unique_external_resources":  external_resources.size(),
		"node_type_breakdown":        type_list,
	}


func _trace_signal_flow(args: Dictionary) -> Dictionary:
	var resolved := _resolve_scene(args)
	if resolved.has("error"):
		return resolved
	var ps: PackedScene = resolved["ps"]
	var scene_path: String = resolved["path"]

	var node_filter: String = args.get("node_path", "")
	var include_flags: bool = _as_bool(args.get("include_flags", false))

	var state: SceneState = ps.get_state()
	var connections: Array = []

	for i in state.get_connection_count():
		var source_path: String = str(state.get_connection_source(i))
		var target_path: String = str(state.get_connection_target(i))

		if not node_filter.is_empty():
			var matches: bool = (
				source_path == node_filter or target_path == node_filter or
				source_path.begins_with(node_filter + "/") or
				target_path.begins_with(node_filter + "/")
			)
			if not matches:
				continue

		var conn: Dictionary = {
			"signal": str(state.get_connection_signal(i)),
			"source": source_path,
			"target": target_path,
			"method": str(state.get_connection_method(i)),
		}
		if include_flags:
			conn["flags"] = state.get_connection_flags(i)
		connections.append(conn)

	return {
		"scene_path":  scene_path,
		"connections": connections,
		"count":       connections.size(),
	}


func _find_unused_resources(args: Dictionary) -> Dictionary:
	# Default to common raw asset types (not .tres/.res — those are covered by orphaned_resources).
	# In Godot 4 .tscn files reference original asset paths (res://texture.png),
	# so ResourceLoader.get_dependencies() correctly surfaces them.
	var check_extensions: Array = args.get("extensions", [
		".png", ".jpg", ".jpeg", ".webp", ".svg", ".bmp",
		".ogg", ".mp3", ".wav",
		".ttf", ".otf", ".woff",
		".glb", ".gltf", ".obj",
	])
	var scene_filter: String = args.get("scene_filter", "")

	var fs := _get_filesystem()

	# Collect candidate asset files
	var candidates: Dictionary = {}
	_collect_files_by_ext(fs, check_extensions, candidates)

	if candidates.is_empty():
		return {
			"unused": [], "count": 0, "total_checked": 0,
			"message": "No assets found matching the given extensions.",
		}

	# Collect dependency source files (.tscn, .tres, .res)
	var dep_sources: Dictionary = {}
	_collect_files_by_ext(fs, [".tscn", ".scn", ".tres", ".res"], dep_sources)

	if not scene_filter.is_empty():
		var filtered: Dictionary = {}
		for src in dep_sources:
			if src.contains(scene_filter):
				filtered[src] = true
		dep_sources = filtered

	# Build the set of all referenced paths.
	# Godot 4.3+ may store ext_resource entries with uid= only (no path=),
	# so get_dependencies() can return "uid://..." strings. Resolve those via ResourceUID.
	var referenced: Dictionary = {}
	for src in dep_sources:
		for dep in ResourceLoader.get_dependencies(src):
			if dep.begins_with("res://"):
				referenced[dep] = true
			elif dep.begins_with("uid://"):
				var uid_val: int = ResourceUID.text_to_id(dep)
				if ResourceUID.has_id(uid_val):
					referenced[ResourceUID.get_id_path(uid_val)] = true

	# Find unreferenced assets
	var unused: Array = []
	for asset_path in candidates:
		if not referenced.has(asset_path):
			unused.append(asset_path)
	unused.sort()

	return {
		"unused":        unused,
		"count":         unused.size(),
		"total_checked": candidates.size(),
	}


func _get_code_metrics(args: Dictionary) -> Dictionary:
	var script_path: String = args.get("script_path", "")
	var directory: String = args.get("directory", "")
	var max_files: int = int(args.get("max_files", 200))

	var scripts: Array = []

	if not script_path.is_empty():
		if not ResourceLoader.exists(script_path):
			return {"error": "Script not found: %s" % script_path}
		scripts.append(script_path)
	else:
		var ext_dict: Dictionary = {}
		_collect_files_by_ext(_get_filesystem(), [".gd"], ext_dict)
		for sp in ext_dict:
			if directory.is_empty() or sp.begins_with(directory):
				scripts.append(sp)
		scripts.sort()
		if scripts.size() > max_files:
			scripts = scripts.slice(0, max_files)

	if scripts.is_empty():
		return {"error": "No scripts found%s" % (" in '%s'" % directory if not directory.is_empty() else "")}

	var results: Array = []
	var totals: Dictionary = {
		"total_lines": 0, "code_lines": 0, "comment_lines": 0, "blank_lines": 0,
		"function_count": 0, "class_count": 0, "signal_count": 0, "export_count": 0,
		"branch_count": 0, "loop_count": 0,
	}

	for sp in scripts:
		var fa := FileAccess.open(sp, FileAccess.READ)
		if fa == null:
			results.append({"script": sp, "error": "cannot read file"})
			continue
		var content: String = fa.get_as_text()
		fa.close()
		var m := _compute_metrics(content, sp)
		results.append(m)
		for key in totals:
			totals[key] += m.get(key, 0)

	if results.size() == 1:
		var r: Dictionary = results[0]
		if r.has("error"):
			return {"error": "Failed to read %s: %s" % [r.get("script", "?"), r.get("error", "unknown")]}
		return r

	var analyzed_count: int = 0
	for r in results:
		if not r.has("error"):
			analyzed_count += 1
	return {
		"scripts": results,
		"count":   analyzed_count,
		"totals":  totals,
	}


func _compute_metrics(content: String, script_path: String) -> Dictionary:
	var lines: PackedStringArray = content.split("\n")
	var total_lines: int = lines.size()
	var code_lines: int = 0
	var comment_lines: int = 0
	var blank_lines: int = 0
	var function_count: int = 0
	var class_count: int = 0
	var signal_count: int = 0
	var export_count: int = 0
	var branch_count: int = 0
	var loop_count: int = 0

	for line in lines:
		var stripped: String = line.strip_edges()
		if stripped.is_empty():
			blank_lines += 1
			continue
		if stripped.begins_with("#"):
			comment_lines += 1
			continue
		code_lines += 1
		# Strip inline comment: find " #" outside of context (best-effort, not a full parser)
		var code_part: String = stripped
		var comment_pos: int = stripped.find(" #")
		if comment_pos >= 0:
			code_part = stripped.left(comment_pos).strip_edges()
		if code_part.begins_with("func ") or code_part.begins_with("static func "):
			function_count += 1
		elif code_part.begins_with("class "):
			class_count += 1
		elif code_part.begins_with("signal "):
			signal_count += 1
		elif code_part.begins_with("@export"):
			export_count += 1
		if code_part.begins_with("if ") or code_part.begins_with("elif ") or code_part.begins_with("match "):
			branch_count += 1
		if code_part.begins_with("for ") or code_part.begins_with("while "):
			loop_count += 1

	return {
		"script":         script_path,
		"total_lines":    total_lines,
		"code_lines":     code_lines,
		"comment_lines":  comment_lines,
		"blank_lines":    blank_lines,
		"function_count": function_count,
		"class_count":    class_count,
		"signal_count":   signal_count,
		"export_count":   export_count,
		"branch_count":   branch_count,
		"loop_count":     loop_count,
		"comment_ratio":  float(comment_lines) / float(max(total_lines, 1)),
	}
