@tool
extends GodotMCPToolBase

class_name GodotMCPSceneTools

## Implements all 10 scene-level tools.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("get_scene_tree",    GodotMCPCallableTool.new(_get_scene_tree))
	registry.register_tool("create_scene",      GodotMCPCallableTool.new(_create_scene))
	registry.register_tool("save_scene",        GodotMCPCallableTool.new(_save_scene))
	registry.register_tool("open_scene",        GodotMCPCallableTool.new(_open_scene))
	registry.register_tool("delete_scene",      GodotMCPCallableTool.new(_delete_scene))
	registry.register_tool("play_scene",        GodotMCPCallableTool.new(_play_scene))
	registry.register_tool("stop_scene",        GodotMCPCallableTool.new(_stop_scene))
	registry.register_tool("instantiate_scene", GodotMCPCallableTool.new(_instantiate_scene))
	registry.register_tool("get_scene_info",    GodotMCPCallableTool.new(_get_scene_info))
	registry.register_tool("list_open_scenes",  GodotMCPCallableTool.new(_list_open_scenes))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _get_scene_tree(args: Dictionary) -> Dictionary:
	var scene_path: String = args.get("scene_path", "")
	var max_depth: int = int(args.get("max_depth", -1))
	var root: Node

	if scene_path.is_empty():
		root = EditorInterface.get_edited_scene_root()
		if root == null:
			return {"error": "No scene is currently open in the editor"}
	else:
		if not ResourceLoader.exists(scene_path):
			return {"error": "Scene file not found: %s" % scene_path}
		var packed: PackedScene = ResourceLoader.load(scene_path)
		if packed == null:
			return {"error": "Failed to load scene: %s" % scene_path}
		root = packed.instantiate()
		if root == null:
			return {"error": "Failed to instantiate scene: %s" % scene_path}
		var tree_data := _node_to_dict(root, 0, max_depth)
		root.queue_free()
		return {
			"scene_path": scene_path,
			"root": tree_data,
		}

	return {
		"scene_path": root.scene_file_path,
		"root": _node_to_dict(root, 0, max_depth),
	}

func _node_to_dict(node: Node, depth: int, max_depth: int) -> Dictionary:
	var d := {
		"name": node.name,
		"type": node.get_class(),
		"path": str(node.get_path()) if node.is_inside_tree() else node.name,
		"script": node.get_script().resource_path if node.get_script() else "",
		"children": [],
	}
	if max_depth < 0 or depth < max_depth:
		for child in node.get_children():
			d["children"].append(_node_to_dict(child, depth + 1, max_depth))
	return d

func _create_scene(args: Dictionary) -> Dictionary:
	var name: String = args.get("name", "")
	if name.is_empty():
		return {"error": "'name' parameter is required"}
	var root_type: String = args.get("root_type", "Node")
	var save_path: String = args.get("path", "res://%s.tscn" % name)
	var open_after: bool = args.get("open_after_create", true)

	# Create root node
	var root := _create_node_by_type(root_type)
	if root == null:
		return {"error": "Unknown node type: %s" % root_type}
	root.name = name

	# Pack and save
	var packed := PackedScene.new()
	var err := packed.pack(root)
	root.free()
	if err != OK:
		return {"error": "Failed to pack scene: %s" % error_string(err)}

	var dir_err := _ensure_dir_for(save_path)
	if not dir_err.is_empty():
		return {"error": dir_err}

	err = ResourceSaver.save(packed, save_path)
	if err != OK:
		return {"error": "Failed to save scene to %s: %s" % [save_path, error_string(err)]}

	# Refresh filesystem
	EditorInterface.get_resource_filesystem().scan()

	if open_after:
		EditorInterface.open_scene_from_path(save_path)

	return {"success": true, "scene_path": save_path}

## Commit the scene currently open in the editor to disk. The mutation tools (add_node,
## set_node_property, add_mesh, …) change the in-memory scene only — without this their work
## is lost when the editor closes.
func _save_scene(args: Dictionary) -> Dictionary:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return {"error": "No scene is currently open in the editor"}

	var save_path: String = args.get("scene_path", "")
	var target: String = save_path if not save_path.is_empty() else root.scene_file_path
	if target.is_empty():
		return {"error": "Scene has never been saved to disk — pass 'scene_path' to choose a location"}

	var dir_err := _ensure_dir_for(target)
	if not dir_err.is_empty():
		return {"error": dir_err}

	# EditorInterface.save_scene() is what Ctrl+S runs: it writes the scene exactly as the
	# editor holds it, including the owner relationships that a hand-rolled
	# PackedScene.pack() of the edited root gets wrong for instanced children.
	if save_path.is_empty():
		var err := EditorInterface.save_scene()
		if err != OK:
			return {"error": "Failed to save scene to %s: %s" % [target, error_string(err)]}
	else:
		# save_scene_as() returns void, so confirm the write by checking the file landed
		# rather than reporting a success we never verified.
		EditorInterface.save_scene_as(target, true)
		if not FileAccess.file_exists(ProjectSettings.globalize_path(target)):
			return {"error": "Failed to save scene to %s" % target}

	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "scene_path": target}

func _create_node_by_type(type_name: String) -> Node:
	if ClassDB.class_exists(type_name):
		var obj = ClassDB.instantiate(type_name)
		if obj is Node:
			return obj as Node
	return null

func _open_scene(args: Dictionary) -> Dictionary:
	var scene_path: String = args.get("scene_path", "")
	if scene_path.is_empty():
		return {"error": "'scene_path' parameter is required"}
	if not ResourceLoader.exists(scene_path):
		return {"error": "Scene not found: %s" % scene_path}
	EditorInterface.open_scene_from_path(scene_path)
	return {"success": true, "scene_path": scene_path}

func _delete_scene(args: Dictionary) -> Dictionary:
	var scene_path: String = args.get("scene_path", "")
	if scene_path.is_empty():
		return {"error": "'scene_path' parameter is required"}

	var abs_path := ProjectSettings.globalize_path(scene_path)
	if not FileAccess.file_exists(abs_path):
		return {"error": "Scene file not found: %s" % scene_path}

	# Check if scene is open in editor — open scenes may be file-locked on Windows
	var open_scenes := EditorInterface.get_open_scenes()
	var is_open := scene_path in open_scenes

	var err := OS.move_to_trash(abs_path)
	if err != OK:
		# Fallback: direct delete
		err = DirAccess.remove_absolute(abs_path)
		if err != OK:
			return {"error": "Failed to delete scene: %s" % error_string(err)}

	# Verify the file was actually removed — move_to_trash can return OK but leave
	# the file on disk when Godot's resource cache holds a lock (common with scenes
	# that have attached scripts).
	if FileAccess.file_exists(abs_path):
		if is_open:
			return {"error": "Scene '%s' is currently open in the editor. Open a different scene first, then retry delete_scene." % scene_path}
		return {"error": "Deletion reported success but '%s' still exists on disk. The file may be locked by Godot's resource cache." % scene_path}

	# Clean up the .uid sidecar file if present
	var uid_path := abs_path + ".uid"
	if FileAccess.file_exists(uid_path):
		DirAccess.remove_absolute(uid_path)

	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "deleted_path": scene_path}

func _play_scene(args: Dictionary) -> Dictionary:
	var scene_path: String = args.get("scene_path", "")
	if scene_path == "main":
		EditorInterface.play_main_scene()
	elif scene_path.is_empty():
		EditorInterface.play_current_scene()
	else:
		if not ResourceLoader.exists(scene_path):
			return {"error": "Scene not found: %s" % scene_path}
		EditorInterface.play_custom_scene(scene_path)
	return {"success": true}

func _stop_scene(_args: Dictionary) -> Dictionary:
	EditorInterface.stop_playing_scene()
	return {"success": true}

func _instantiate_scene(args: Dictionary) -> Dictionary:
	var scene_path: String = args.get("scene_path", "")
	var parent_path: String = args.get("parent_path", "")
	if scene_path.is_empty():
		return {"error": "'scene_path' parameter is required"}
	if parent_path.is_empty():
		return {"error": "'parent_path' parameter is required"}

	if not ResourceLoader.exists(scene_path):
		return {"error": "Scene not found: %s" % scene_path}

	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return {"error": "No scene is currently open in the editor"}

	var parent: Node
	if parent_path == ".":
		parent = root
	else:
		parent = root.get_node_or_null(parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if packed == null:
		return {"error": "Failed to load scene: %s" % scene_path}

	var instance := packed.instantiate()
	if instance == null:
		return {"error": "Failed to instantiate scene: %s" % scene_path}

	var node_name: String = args.get("node_name", scene_path.get_file().get_basename())
	instance.name = node_name

	var undo_redo := _plugin.get_undo_redo()
	undo_redo.create_action("Instantiate Scene: %s" % node_name)
	undo_redo.add_do_method(parent, "add_child", instance, true)
	undo_redo.add_do_property(instance, "owner", root)
	undo_redo.add_undo_method(parent, "remove_child", instance)
	undo_redo.commit_action()

	return {
		"success": true,
		"node_path": str(instance.get_path()),
		"node_name": instance.name,
	}

func _get_scene_info(args: Dictionary) -> Dictionary:
	var scene_path: String = args.get("scene_path", "")
	if scene_path.is_empty():
		return {"error": "'scene_path' parameter is required"}
	if not ResourceLoader.exists(scene_path):
		return {"error": "Scene not found: %s" % scene_path}

	var packed: PackedScene = ResourceLoader.load(scene_path)
	if packed == null:
		return {"error": "Failed to load scene: %s" % scene_path}

	var instance := packed.instantiate()
	if instance == null:
		return {"error": "Failed to instantiate scene for inspection: %s" % scene_path}

	var count := _count_nodes(instance)
	var root_type := instance.get_class()
	var script_path: String = instance.get_script().resource_path if instance.get_script() else ""
	instance.free()

	# Check if open in editor
	var is_open := false
	for open_path in EditorInterface.get_open_scenes():
		if open_path == scene_path:
			is_open = true
			break

	return {
		"scene_path": scene_path,
		"root_type": root_type,
		"root_script": script_path,
		"node_count": count,
		"is_open": is_open,
	}

func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total

func _list_open_scenes(_args: Dictionary) -> Dictionary:
	var scenes: Array = []
	var active_root := EditorInterface.get_edited_scene_root()
	var active_path := active_root.scene_file_path if active_root else ""

	for path in EditorInterface.get_open_scenes():
		scenes.append({
			"path": path,
			"is_active": path == active_path,
		})

	return {"open_scenes": scenes, "total": scenes.size()}
