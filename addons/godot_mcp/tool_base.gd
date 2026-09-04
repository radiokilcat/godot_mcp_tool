@tool
extends RefCounted

class_name GodotMCPToolBase

## Base for the 23 tool classes. Holds the plugin reference and the handful of
## helpers every tool file needs to reach the edited scene.
##
## These lived as copies in each file until they drifted: `_resolve_node` existed
## in 13 files as 6 different implementations, so the same bad path from an agent
## behaved differently depending on which tool it reached, and a fix had to be
## repeated N times to land everywhere (6.6.14 had to patch four files at once;
## 3.17b patched one copy of `_write_file` and missed the other).
##
## Where the copies disagreed, the version adopted here accepts the union of what
## they accepted -- see the notes on each method.

var _plugin: EditorPlugin

## The default lets a tool class that needs no editor access be constructed
## bare, the way GodotMCPProjectTools is.
func _init(plugin: EditorPlugin = null) -> void:
	_plugin = plugin

## Root of the scene currently open in the editor, or null when none is.
func _scene_root() -> Node:
	return EditorInterface.get_edited_scene_root()

## Resolve a node by a scene-relative path.
##
## Union of the six previous variants: an empty path, ".", the root's own name and
## "/root/<root name>" all mean the scene root -- callers wrote all four, and the
## variant that happened to serve a given tool decided whether it worked. Tools
## that must reject an empty path validate it before calling here; that is the
## caller's decision, not this function's.
func _resolve_node(node_path: String) -> Variant:
	var root := _scene_root()
	if root == null:
		return null
	if node_path.is_empty() or node_path == "." or node_path == root.name \
			or node_path == "/root/" + root.name:
		return root
	return root.get_node_or_null(NodePath(node_path))

## Resolve the parent for a node being added. Takes the root explicitly because
## callers have usually already fetched and null-checked it.
func _resolve_parent(root: Node, parent_path: String) -> Node:
	if parent_path.is_empty() or parent_path == "." or parent_path == root.name:
		return root
	return root.get_node_or_null(NodePath(parent_path))

## Add a freshly built node under `parent` as one undoable action, and describe
## it the way every add_* tool answers: scene-relative path, never the editor's
## absolute one (6.6.10).
func _add_to_scene(new_node: Node, parent: Node, node_name: String, action_name: String) -> Dictionary:
	var root := _scene_root()
	new_node.name = node_name
	var ur := _plugin.get_undo_redo()
	ur.create_action(action_name)
	ur.add_do_method(parent, "add_child", new_node, true)
	ur.add_do_property(new_node, "owner", root)
	ur.add_do_reference(new_node)
	ur.add_undo_method(parent, "remove_child", new_node)
	ur.add_undo_reference(new_node)
	ur.commit_action()
	return {
		"success": true,
		"node_name": new_node.name,
		"node_path": str(root.get_path_to(new_node)),
	}

## Booleans arrive over JSON as real bools, but also as "true"/"1"/"yes" from
## clients that stringify everything, and as 1/0 from those that send numbers.
## `bool("false")` is true in GDScript -- any non-empty string is -- which is why
## this exists at all (3.16b). Eight of the nine copies only recognised the
## literal string "true" and answered false for 1; this one takes all three forms.
## An explicit JSON null must be handled before bool(): `bool(null)` is not a
## valid constructor call in GDScript, so it answers false *and* pushes
## "Invalid call. Nonexistent 'bool' constructor" into the Output panel — the
## same kind of engine-error spam 9.8 went through the tools to remove.
func _as_bool(value: Variant) -> bool:
	if value == null:
		return false
	if value is String:
		return value.to_lower() in ["true", "1", "yes"]
	return bool(value)

## Coercion of the values that arrive over JSON. Thin on purpose: the rules live
## in GodotMCPTypeUtils, which the server-side schemas mirror, and these exist so
## every tool file reaches them by the same name it always used.
func _parse_vector2(val: Variant, default_val: Vector2 = Vector2.ZERO) -> Vector2:
	return GodotMCPTypeUtils.to_vector2(val, default_val)

func _parse_vector3(val: Variant, default_val: Vector3 = Vector3.ZERO) -> Vector3:
	return GodotMCPTypeUtils.to_vector3(val, default_val)

func _parse_color(val: Variant, default_val: Color = Color.WHITE) -> Color:
	return GodotMCPTypeUtils.to_color(val, default_val)

## One Godot value as something JSON can carry. Scalars only -- a caller that
## must descend into containers wraps this (editor_tools._json_safe does).
##
## The copies this replaces disagreed on the harder types: the node_tools one
## rendered a Transform2D as `str(v)`, i.e. "[X: (1, 0), Y: (0, 1), O: (0, 0)]",
## which a client can display but not read. The structured form is used here.
func _value_to_json(v: Variant) -> Variant:
	if v is Vector2 or v is Vector2i:   return {"x": v.x, "y": v.y}
	if v is Vector3 or v is Vector3i:   return {"x": v.x, "y": v.y, "z": v.z}
	if v is Vector4 or v is Vector4i:   return {"x": v.x, "y": v.y, "z": v.z, "w": v.w}
	if v is Color:       return {"r": v.r, "g": v.g, "b": v.b, "a": v.a}
	if v is Rect2 or v is Rect2i:
		return {"x": v.position.x, "y": v.position.y, "w": v.size.x, "h": v.size.y}
	if v is Quaternion:  return {"x": v.x, "y": v.y, "z": v.z, "w": v.w}
	if v is Basis:       return {"x": _value_to_json(v.x), "y": _value_to_json(v.y), "z": _value_to_json(v.z)}
	if v is Transform2D: return {"origin": _value_to_json(v.origin), "x": _value_to_json(v.x), "y": _value_to_json(v.y)}
	if v is Transform3D: return {"origin": _value_to_json(v.origin), "basis": _value_to_json(v.basis)}
	if v is Object:
		if v is Resource:
			return v.resource_path if not v.resource_path.is_empty() else str(v)
		return str(v)
	return v

## Create the directory a res:// file is about to be written into. Returns "" on
## success or a message describing the failure.
##
## Uses the instance API rather than DirAccess.make_dir_recursive_absolute(),
## which only exists from Godot 4.1 -- 3.17b fixed that in shader_tools and left
## the same call standing in two other files, which is exactly the duplication
## this base class is here to end. The project targets 4.0+.
func _ensure_dir_for(res_path: String) -> String:
	var dir_path := res_path.get_base_dir()
	if dir_path.is_empty() or dir_path == "res:/" or dir_path == "res://":
		return ""
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
		return ""
	var root := DirAccess.open("res://")
	if root == null:
		return "Cannot access res:// directory"
	var err := root.make_dir_recursive(dir_path.trim_prefix("res://"))
	if err != OK:
		return "Failed to create directory %s: %s" % [dir_path, error_string(err)]
	return ""
