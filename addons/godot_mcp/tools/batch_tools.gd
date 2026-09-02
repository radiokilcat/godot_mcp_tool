@tool
extends GodotMCPToolBase

class_name GodotMCPBatchTools

## Implements 8 Batch/Refactor tools:
## find_by_node_type, find_by_script, find_by_group, bulk_rename,
## cross_scene_update, find_dependencies, orphaned_resources, refactor_signals.
## Scene-scanning tools read SceneState (no instantiation).
## Scene-modifying tools (cross_scene_update, bulk_rename all_scenes, refactor_signals)
## instantiate scenes, modify, re-pack, and save — bypassing UndoRedo.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("find_by_node_type",    GodotMCPCallableTool.new(_find_by_node_type))
	registry.register_tool("find_by_script",       GodotMCPCallableTool.new(_find_by_script))
	registry.register_tool("find_by_group",        GodotMCPCallableTool.new(_find_by_group))
	registry.register_tool("bulk_rename",          GodotMCPCallableTool.new(_bulk_rename))
	registry.register_tool("cross_scene_update",   GodotMCPCallableTool.new(_cross_scene_update))
	registry.register_tool("find_dependencies",    GodotMCPCallableTool.new(_find_dependencies))
	registry.register_tool("orphaned_resources",   GodotMCPCallableTool.new(_orphaned_resources))
	registry.register_tool("refactor_signals",     GodotMCPCallableTool.new(_refactor_signals))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _get_filesystem() -> EditorFileSystemDirectory:
	return _plugin.get_editor_interface().get_resource_filesystem().get_filesystem()

## Collect all .tscn/.scn files under the given directory, optionally filtered by a substring.
func _collect_scene_files(dir: EditorFileSystemDirectory, filter: String, out: Array) -> void:
	for i in dir.get_file_count():
		var fp: String = dir.get_file_path(i)
		if fp.ends_with(".tscn") or fp.ends_with(".scn"):
			if filter.is_empty() or fp.contains(filter):
				out.append(fp)
	for i in dir.get_subdir_count():
		_collect_scene_files(dir.get_subdir(i), filter, out)

## Collect all files that match any of the given extensions.
func _collect_files_by_ext(dir: EditorFileSystemDirectory, extensions: Array, out: Dictionary) -> void:
	for i in dir.get_file_count():
		var fp: String = dir.get_file_path(i)
		for ext in extensions:
			if fp.ends_with(ext):
				out[fp] = true
				break
	for i in dir.get_subdir_count():
		_collect_files_by_ext(dir.get_subdir(i), extensions, out)

## Recursively collect nodes whose name matches a pattern.
## If re is non-null, use regex search; otherwise use substring contains.
func _collect_matching_nodes(node: Node, pattern: String, re: RegEx, out: Array) -> void:
	var node_name: String = node.name
	if re != null:
		if re.search(node_name) != null:
			out.append(node)
	elif pattern in node_name:
		out.append(node)
	for child in node.get_children():
		_collect_matching_nodes(child, pattern, re, out)

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _find_by_node_type(args: Dictionary) -> Dictionary:
	var node_type: String = args.get("node_type", "")
	if node_type.is_empty():
		return {"error": "'node_type' is required (built-in class name, e.g. 'Sprite2D', 'MeshInstance3D')"}
	if not ClassDB.class_exists(node_type):
		return {"error": "Class '%s' not found in ClassDB. Use find_by_script for custom GDScript classes." % node_type}

	var scene_filter: String = args.get("scene_filter", "")
	var include_inherited: bool = _as_bool(args.get("include_inherited", true))
	var max_results: int = int(args.get("max_results", 500))

	var scene_files: Array = []
	_collect_scene_files(_get_filesystem(), scene_filter, scene_files)

	var results: Array = []
	for scene_path in scene_files:
		if results.size() >= max_results:
			break
		var ps = ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not ps is PackedScene:
			continue
		var state: SceneState = ps.get_state()
		for i in state.get_node_count():
			var nt: String = state.get_node_type(i)
			if nt.is_empty():
				continue
			var matched: bool = false
			if include_inherited:
				matched = nt == node_type or ClassDB.is_parent_class(nt, node_type)
			else:
				matched = nt == node_type
			if matched:
				results.append({
					"scene":     scene_path,
					"node_path": str(state.get_node_path(i)),
					"node_name": str(state.get_node_name(i)),
					"node_type": nt,
				})
				if results.size() >= max_results:
					break

	return {
		"results":   results,
		"count":     results.size(),
		"truncated": results.size() >= max_results,
	}

func _find_by_script(args: Dictionary) -> Dictionary:
	var script_path: String = args.get("script_path", "")
	if script_path.is_empty():
		return {"error": "'script_path' is required (e.g. 'res://scripts/player.gd')"}
	if not ResourceLoader.exists(script_path):
		return {"error": "Script not found: %s" % script_path}

	var scene_filter: String = args.get("scene_filter", "")
	var max_results: int = int(args.get("max_results", 500))

	var scene_files: Array = []
	_collect_scene_files(_get_filesystem(), scene_filter, scene_files)

	var results: Array = []
	for scene_path in scene_files:
		if results.size() >= max_results:
			break
		var ps = ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not ps is PackedScene:
			continue
		var state: SceneState = ps.get_state()
		for i in state.get_node_count():
			for pi in state.get_node_property_count(i):
				if str(state.get_node_property_name(i, pi)) == "script":
					var val = state.get_node_property_value(i, pi)
					if val is Script and val.resource_path == script_path:
						results.append({
							"scene":     scene_path,
							"node_path": str(state.get_node_path(i)),
							"node_name": str(state.get_node_name(i)),
							"node_type": str(state.get_node_type(i)),
						})
					break
			if results.size() >= max_results:
				break

	return {
		"results":   results,
		"count":     results.size(),
		"truncated": results.size() >= max_results,
	}

func _find_by_group(args: Dictionary) -> Dictionary:
	var group_name: String = args.get("group_name", "")
	if group_name.is_empty():
		return {"error": "'group_name' is required"}

	var scene_filter: String = args.get("scene_filter", "")
	var max_results: int = int(args.get("max_results", 500))

	var scene_files: Array = []
	_collect_scene_files(_get_filesystem(), scene_filter, scene_files)

	var results: Array = []
	for scene_path in scene_files:
		if results.size() >= max_results:
			break
		var ps = ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not ps is PackedScene:
			continue
		var state: SceneState = ps.get_state()
		for i in state.get_node_count():
			var groups: Array = state.get_node_groups(i)
			if group_name in groups:
				results.append({
					"scene":     scene_path,
					"node_path": str(state.get_node_path(i)),
					"node_name": str(state.get_node_name(i)),
					"node_type": str(state.get_node_type(i)),
				})
				if results.size() >= max_results:
					break

	return {
		"results":   results,
		"count":     results.size(),
		"truncated": results.size() >= max_results,
	}

func _bulk_rename(args: Dictionary) -> Dictionary:
	var match_str: String = args.get("match", "")
	var replacement: String = args.get("replacement", "")
	var use_regex: bool = _as_bool(args.get("regex", false))
	var scope: String = str(args.get("scope", "current_scene")).to_lower()

	if match_str.is_empty():
		return {"error": "'match' is required (substring or regex pattern to search in node names)"}

	# Compile regex once if needed
	var re: RegEx = null
	if use_regex:
		re = RegEx.new()
		if re.compile(match_str) != OK:
			return {"error": "Invalid regex pattern: '%s'" % match_str}

	if scope == "current_scene":
		var edited_root: Node = _plugin.get_editor_interface().get_edited_scene_root()
		if edited_root == null:
			return {"error": "No scene is currently open in the editor"}

		var matches: Array = []
		_collect_matching_nodes(edited_root, match_str, re, matches)

		if matches.is_empty():
			return {"renamed": [], "count": 0, "message": "No nodes matched pattern '%s'" % match_str}

		var renamed: Array = []
		var ur := _plugin.get_undo_redo()
		ur.create_action("Bulk Rename Nodes")

		for node in matches:
			var old_name: String = node.name
			var new_name: String = ""
			if re != null:
				new_name = re.sub(old_name, replacement)
			else:
				new_name = old_name.replace(match_str, replacement)
			if new_name == old_name or new_name.is_empty():
				continue
			ur.add_do_method(node, "set_name", new_name)
			ur.add_undo_method(node, "set_name", old_name)
			renamed.append({"old": old_name, "new": new_name, "path": str(node.get_path())})

		if renamed.is_empty():
			ur.commit_action(false)  # discard: no rename was actually queued
			return {"renamed": [], "count": 0, "message": "No effective renames (all produced unchanged or empty names)"}
		ur.commit_action()
		return {"renamed": renamed, "count": renamed.size()}

	elif scope == "all_scenes":
		var scene_filter: String = args.get("scene_filter", "")
		var dry_run: bool = _as_bool(args.get("dry_run", false))

		var scene_files: Array = []
		_collect_scene_files(_get_filesystem(), scene_filter, scene_files)

		var summary: Array = []
		for scene_path in scene_files:
			var ps = ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if not ps is PackedScene:
				continue

			# Pre-scan SceneState to check if any node names match before instantiating.
			# Instantiation is expensive; skip scenes with no candidates.
			var state: SceneState = ps.get_state()
			var has_candidate := false
			for si in state.get_node_count():
				var sname: String = str(state.get_node_name(si))
				if re != null:
					if re.search(sname) != null:
						has_candidate = true
						break
				elif match_str in sname:
					has_candidate = true
					break
			if not has_candidate:
				continue

			var root = ps.instantiate()
			if root == null:
				continue

			var matches: Array = []
			_collect_matching_nodes(root, match_str, re, matches)

			var renames: Array = []
			for node in matches:
				var old_name: String = node.name
				var new_name: String = ""
				if re != null:
					new_name = re.sub(old_name, replacement)
				else:
					new_name = old_name.replace(match_str, replacement)
				if new_name == old_name or new_name.is_empty():
					continue
				renames.append({"old": old_name, "new": new_name})
				if not dry_run:
					node.name = new_name

			if not renames.is_empty():
				if not dry_run:
					var new_ps := PackedScene.new()
					new_ps.pack(root)
					var err := ResourceSaver.save(new_ps, scene_path)
					if err != OK:
						root.free()
						summary.append({"scene": scene_path, "error": "save failed (error %d)" % err})
						continue
				summary.append({"scene": scene_path, "renamed": renames})

			root.free()

		return {
			"dry_run": dry_run,
			"scenes":  summary,
			"count":   summary.size(),
		}

	else:
		return {"error": "Unknown scope '%s'. Valid values: 'current_scene', 'all_scenes'" % scope}

func _cross_scene_update(args: Dictionary) -> Dictionary:
	var node_type: String = args.get("node_type", "")
	var property: String = args.get("property", "")

	if node_type.is_empty():
		return {"error": "'node_type' is required (built-in class name to search for)"}
	if property.is_empty():
		return {"error": "'property' is required (property name to update)"}
	if not args.has("value"):
		return {"error": "'value' is required (new property value)"}
	var value = args["value"]

	if not ClassDB.class_exists(node_type):
		return {"error": "Class '%s' not found in ClassDB" % node_type}

	var scene_filter: String = args.get("scene_filter", "")
	var dry_run: bool = _as_bool(args.get("dry_run", false))

	var scene_files: Array = []
	_collect_scene_files(_get_filesystem(), scene_filter, scene_files)

	var updated_scenes: Array = []
	var total_nodes := 0

	for scene_path in scene_files:
		var ps = ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not ps is PackedScene:
			continue
		var state: SceneState = ps.get_state()

		# Check if scene has any matching nodes before instantiating
		var candidate_paths: Array = []
		for i in state.get_node_count():
			var nt: String = state.get_node_type(i)
			if nt.is_empty():
				continue
			if nt == node_type or ClassDB.is_parent_class(nt, node_type):
				candidate_paths.append(str(state.get_node_path(i)))

		if candidate_paths.is_empty():
			continue

		if dry_run:
			updated_scenes.append({
				"scene":          scene_path,
				"nodes_to_update": candidate_paths,
			})
			total_nodes += candidate_paths.size()
			continue

		# Instantiate, modify, re-pack
		var root = ps.instantiate()
		if root == null:
			continue

		var changed := 0
		for np in candidate_paths:
			var node: Node = root.get_node_or_null(np)
			if node == null:
				continue
			node.set(property, value)
			changed += 1

		if changed > 0:
			var new_ps := PackedScene.new()
			new_ps.pack(root)
			var err := ResourceSaver.save(new_ps, scene_path)
			if err == OK:
				updated_scenes.append({"scene": scene_path, "nodes_updated": changed})
				total_nodes += changed
			else:
				updated_scenes.append({"scene": scene_path, "error": "save failed (error %d)" % err})

		root.free()

	return {
		"dry_run":      dry_run,
		"scenes":       updated_scenes,
		"total_nodes":  total_nodes,
		"scene_count":  updated_scenes.size(),
	}

func _find_dependencies(args: Dictionary) -> Dictionary:
	var resource_path: String = args.get("resource_path", "")
	if resource_path.is_empty():
		return {"error": "'resource_path' is required"}
	if not ResourceLoader.exists(resource_path):
		return {"error": "Resource not found: %s" % resource_path}

	var recursive: bool = _as_bool(args.get("recursive", false))

	var direct_deps: PackedStringArray = ResourceLoader.get_dependencies(resource_path)

	if not recursive:
		return {
			"resource_path": resource_path,
			"dependencies":  Array(direct_deps),
			"count":         direct_deps.size(),
		}

	# BFS for transitive dependencies
	var all_deps: Dictionary = {}
	var queue: Array = Array(direct_deps)
	var visited: Dictionary = {resource_path: true}

	while not queue.is_empty():
		var dep: String = queue.pop_front()
		if dep in visited:
			continue
		visited[dep] = true
		all_deps[dep] = true
		if dep.begins_with("res://") and ResourceLoader.exists(dep):
			for sub_dep in ResourceLoader.get_dependencies(dep):
				if not sub_dep in visited:
					queue.append(sub_dep)

	return {
		"resource_path": resource_path,
		"dependencies":  all_deps.keys(),
		"count":         all_deps.size(),
		"recursive":     true,
	}

func _orphaned_resources(args: Dictionary) -> Dictionary:
	var check_extensions: Array = args.get("extensions", [".tres", ".res", ".gdshader"])
	var include_scripts: bool = _as_bool(args.get("include_scripts", false))
	var include_scenes: bool = _as_bool(args.get("include_scenes", false))

	if include_scripts and not ".gd" in check_extensions:
		check_extensions.append(".gd")
	if include_scenes:
		for ext in [".tscn", ".scn"]:
			if not ext in check_extensions:
				check_extensions.append(ext)

	var fs := _get_filesystem()

	# Step 1: Collect all candidate files
	var candidates: Dictionary = {}
	_collect_files_by_ext(fs, check_extensions, candidates)

	# Step 2: Collect all dependency sources (scenes + resources that can reference others)
	var dep_sources: Dictionary = {}
	var scan_exts := [".tscn", ".scn", ".tres", ".res", ".gd"]
	_collect_files_by_ext(fs, scan_exts, dep_sources)

	# Step 3: Build set of all referenced paths
	var referenced: Dictionary = {}

	# Project setting entry points
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if not main_scene.is_empty():
		referenced[main_scene] = true

	for autoload_prop in ProjectSettings.get_property_list():
		var pname: String = str(autoload_prop.get("name", ""))
		if pname.begins_with("autoload/"):
			var val: String = str(ProjectSettings.get_setting(pname, "")).trim_prefix("*")
			if not val.is_empty():
				referenced[val] = true

	# Scan dependency graph
	for src in dep_sources:
		for dep in ResourceLoader.get_dependencies(src):
			if dep.begins_with("res://"):
				referenced[dep] = true

	# Step 4: Find orphans (candidates not in referenced set)
	var orphans: Array = []
	for path in candidates:
		if not referenced.has(path):
			orphans.append(path)
	orphans.sort()

	return {
		"orphaned":       orphans,
		"count":          orphans.size(),
		"total_checked":  candidates.size(),
	}

func _refactor_signals(args: Dictionary) -> Dictionary:
	var old_method: String = args.get("old_method", "")
	var new_method: String = args.get("new_method", "")

	if old_method.is_empty():
		return {"error": "'old_method' is required (current signal handler method name)"}
	if new_method.is_empty():
		return {"error": "'new_method' is required (replacement method name)"}

	var scene_filter: String = args.get("scene_filter", "")
	var signal_filter: String = args.get("signal_name", "")
	var dry_run: bool = _as_bool(args.get("dry_run", false))

	var scene_files: Array = []
	_collect_scene_files(_get_filesystem(), scene_filter, scene_files)

	var updated_scenes: Array = []

	for scene_path in scene_files:
		var ps = ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not ps is PackedScene:
			continue
		var state: SceneState = ps.get_state()

		# Find matching signal connections
		var conn_matches: Array = []
		for i in state.get_connection_count():
			var method: String = str(state.get_connection_method(i))
			if method != old_method:
				continue
			var sig: String = str(state.get_connection_signal(i))
			if not signal_filter.is_empty() and sig != signal_filter:
				continue
			conn_matches.append({
				"signal":     sig,
				"source":     str(state.get_connection_source(i)),
				"target":     str(state.get_connection_target(i)),
				"old_method": old_method,
				"new_method": new_method,
			})

		if conn_matches.is_empty():
			continue

		if dry_run:
			updated_scenes.append({"scene": scene_path, "connections": conn_matches})
			continue

		# Instantiate, update connections, re-pack
		var root = ps.instantiate()
		if root == null:
			continue

		var updated := 0
		for conn in conn_matches:
			var source: Node = root.get_node_or_null(conn["source"])
			var target: Node = root.get_node_or_null(conn["target"])
			if source == null or target == null:
				continue
			var sig_name: StringName = StringName(conn["signal"])
			var old_callable := Callable(target, old_method)
			var new_callable := Callable(target, new_method)
			if source.is_connected(sig_name, old_callable):
				source.disconnect(sig_name, old_callable)
				source.connect(sig_name, new_callable)
				updated += 1

		if updated > 0:
			var new_ps := PackedScene.new()
			new_ps.pack(root)
			var err := ResourceSaver.save(new_ps, scene_path)
			if err == OK:
				updated_scenes.append({"scene": scene_path, "updated": updated, "connections": conn_matches})
			else:
				updated_scenes.append({"scene": scene_path, "error": "save failed (error %d)" % err, "connections": conn_matches})

		root.free()

	return {
		"dry_run":      dry_run,
		"scenes":       updated_scenes,
		"scene_count":  updated_scenes.size(),
	}
