@tool
extends RefCounted

class_name GodotMCPNodeTools

## Implements all 14 node-level tools.
## All mutations go through UndoRedo so Ctrl+Z works in the editor.

var _plugin: EditorPlugin

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("add_node",            GodotMCPCallableTool.new(_add_node))
	registry.register_tool("delete_node",         GodotMCPCallableTool.new(_delete_node))
	registry.register_tool("duplicate_node",      GodotMCPCallableTool.new(_duplicate_node))
	registry.register_tool("move_node",           GodotMCPCallableTool.new(_move_node))
	registry.register_tool("rename_node",         GodotMCPCallableTool.new(_rename_node))
	registry.register_tool("get_node_properties", GodotMCPCallableTool.new(_get_node_properties))
	registry.register_tool("set_node_property",   GodotMCPCallableTool.new(_set_node_property))
	registry.register_tool("get_node_signals",    GodotMCPCallableTool.new(_get_node_signals))
	registry.register_tool("connect_signal",      GodotMCPCallableTool.new(_connect_signal))
	registry.register_tool("add_to_group",        GodotMCPCallableTool.new(_add_to_group))
	registry.register_tool("remove_from_group",   GodotMCPCallableTool.new(_remove_from_group))
	registry.register_tool("get_node_groups",     GodotMCPCallableTool.new(_get_node_groups))
	registry.register_tool("get_node_parent",     GodotMCPCallableTool.new(_get_node_parent))
	registry.register_tool("get_node_children",   GodotMCPCallableTool.new(_get_node_children))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _scene_root() -> Node:
	return EditorInterface.get_edited_scene_root()

func _resolve_node(node_path: String) -> Variant:
	var root := _scene_root()
	if root == null:
		return null
	if node_path == "." or node_path == root.name or node_path == "/root/" + root.name:
		return root
	return root.get_node_or_null(node_path)

func _node_summary(node: Node) -> Dictionary:
	return {
		"name": node.name,
		"type": node.get_class(),
		"path": str(node.get_path()),
		"script": node.get_script().resource_path if node.get_script() else "",
	}

## Convert a JSON value to the Godot type expected by a property.
## Uses the property's declared TYPE_* so strings like "Vector2(10,20)" parse correctly.
func _coerce_value(node: Node, property: String, value: Variant) -> Variant:
	if not value is String:
		return value
	var s: String = value
	for prop in node.get_property_list():
		if prop.name != property:
			continue
		match prop.type:
			TYPE_BOOL:
				return s.to_lower() in ["true", "1", "yes"]
			TYPE_INT:
				return int(s)
			TYPE_FLOAT:
				return float(s)
			TYPE_VECTOR2:
				return _parse_vector2(s)
			TYPE_VECTOR2I:
				var v := _parse_vector2(s)
				return Vector2i(int(v.x), int(v.y))
			TYPE_VECTOR3:
				return _parse_vector3(s)
			TYPE_VECTOR3I:
				var v := _parse_vector3(s)
				return Vector3i(int(v.x), int(v.y), int(v.z))
			TYPE_COLOR:
				return _parse_color(s)
			TYPE_RECT2:
				return _parse_rect2(s)
		break
	return value

## Pull the numbers out of a Godot type literal.
## Only the text inside the parentheses is scanned, so digits in the type name
## itself ("Vector2", "Rect2") are not mistaken for components.
func _extract_floats(s: String) -> Array:
	var body := s
	var open := s.find("(")
	var close := s.rfind(")")
	if open != -1 and close > open:
		body = s.substr(open + 1, close - open - 1)
	var nums: Array = []
	var re := RegEx.new()
	re.compile(r"-?\d+(\.\d+)?")
	for m in re.search_all(body):
		nums.append(float(m.get_string()))
	return nums

func _parse_vector2(s: String) -> Vector2:
	var n := _extract_floats(s)
	return Vector2(n[0] if n.size() > 0 else 0.0, n[1] if n.size() > 1 else 0.0)

func _parse_vector3(s: String) -> Vector3:
	var n := _extract_floats(s)
	return Vector3(n[0] if n.size() > 0 else 0.0, n[1] if n.size() > 1 else 0.0, n[2] if n.size() > 2 else 0.0)

func _parse_color(s: String) -> Color:
	if s.begins_with("#"):
		return Color(s)
	var n := _extract_floats(s)
	if n.size() >= 3:
		return Color(n[0], n[1], n[2], n[3] if n.size() > 3 else 1.0)
	return Color.WHITE

func _parse_rect2(s: String) -> Rect2:
	var n := _extract_floats(s)
	if n.size() >= 4:
		return Rect2(n[0], n[1], n[2], n[3])
	return Rect2()

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _add_node(args: Dictionary) -> Dictionary:
	var parent_path: String = args.get("parent_path", "")
	var node_type: String  = args.get("node_type", "")
	if node_type.is_empty():
		return {"error": "'node_type' is required"}

	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent := _resolve_node(parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	if not ClassDB.class_exists(node_type):
		return {"error": "Unknown node type: %s" % node_type}

	var obj = ClassDB.instantiate(node_type)
	if not obj is Node:
		if obj and not obj is RefCounted:
			obj.free()
		return {"error": "%s is not a Node type" % node_type}

	var node: Node = obj
	node.name = args.get("node_name", node_type)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Add Node: %s" % node.name)
	ur.add_do_method(parent, "add_child", node, true)
	ur.add_do_property(node, "owner", root)
	ur.add_do_reference(node)
	ur.add_undo_method(parent, "remove_child", node)
	ur.add_undo_reference(node)
	ur.commit_action()

	return {"success": true, "node_path": str(node.get_path()), "node_name": node.name}

func _delete_node(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	if node == _scene_root():
		return {"error": "Cannot delete the scene root node"}

	var parent: Node = node.get_parent()
	var idx: int = node.get_index()

	var ur := _plugin.get_undo_redo()
	ur.create_action("Delete Node: %s" % node.name)
	ur.add_do_method(parent, "remove_child", node)
	ur.add_do_reference(node)
	# LIFO undo order: add_child runs first, then move_child, then owner
	ur.add_undo_property(node, "owner", _scene_root())
	ur.add_undo_method(parent, "move_child", node, idx)
	ur.add_undo_method(parent, "add_child", node, true)
	ur.add_undo_reference(node)
	ur.commit_action()

	return {"success": true, "deleted_path": node_path}

func _duplicate_node(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var root := _scene_root()
	var parent: Node = node.get_parent()
	var dupe: Node = node.duplicate()
	dupe.name = args.get("new_name", node.name + "2")

	var ur := _plugin.get_undo_redo()
	ur.create_action("Duplicate Node: %s" % node.name)
	ur.add_do_method(parent, "add_child", dupe, true)
	ur.add_do_property(dupe, "owner", root)
	ur.add_do_reference(dupe)
	ur.add_undo_method(parent, "remove_child", dupe)
	ur.add_undo_reference(dupe)
	ur.commit_action()

	return {"success": true, "new_node_path": str(dupe.get_path()), "new_name": dupe.name}

func _move_node(args: Dictionary) -> Dictionary:
	var node_path: String       = args.get("node_path", "")
	var new_parent_path: String = args.get("new_parent_path", "")
	if node_path.is_empty() or new_parent_path.is_empty():
		return {"error": "'node_path' and 'new_parent_path' are required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var new_parent: Node = _resolve_node(new_parent_path)
	if new_parent == null:
		return {"error": "New parent not found: %s" % new_parent_path}

	var old_parent: Node = node.get_parent()
	var old_idx: int = node.get_index()
	var new_idx: int = int(args.get("index", -1))
	var root := _scene_root()

	var ur := _plugin.get_undo_redo()
	ur.create_action("Move Node: %s" % node.name)
	ur.add_do_method(old_parent, "remove_child", node)
	ur.add_do_method(new_parent, "add_child", node, true)
	ur.add_do_property(node, "owner", root)
	if new_idx >= 0:
		ur.add_do_method(new_parent, "move_child", node, new_idx)
	# LIFO undo order: remove_child(new) → add_child(old) → move_child(old) → owner
	ur.add_undo_property(node, "owner", root)
	ur.add_undo_method(old_parent, "move_child", node, old_idx)
	ur.add_undo_method(old_parent, "add_child", node, true)
	ur.add_undo_method(new_parent, "remove_child", node)
	ur.commit_action()

	return {"success": true, "new_path": str(node.get_path())}

func _rename_node(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var new_name: String  = args.get("new_name", "")
	if node_path.is_empty() or new_name.is_empty():
		return {"error": "'node_path' and 'new_name' are required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var old_name: StringName = node.name

	var ur := _plugin.get_undo_redo()
	ur.create_action("Rename Node: %s → %s" % [old_name, new_name])
	ur.add_do_property(node, "name", new_name)
	ur.add_undo_property(node, "name", old_name)
	ur.commit_action()

	return {"success": true, "old_name": old_name, "new_name": new_name, "new_path": str(node.get_path())}

func _get_node_properties(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var include_cats: bool = args.get("include_categories", false)
	var properties: Array = []

	for prop in node.get_property_list():
		var usage: int = prop.get("usage", 0)
		# Include editor-visible and script-defined properties
		if not (usage & PROPERTY_USAGE_EDITOR):
			continue
		if prop.type == TYPE_NIL and not include_cats:
			continue  # category separator
		var entry: Dictionary = {
			"name": prop.name,
			"type": type_string(prop.type),
			"value": _value_to_json(node.get(prop.name)),
		}
		if include_cats and prop.type == TYPE_NIL:
			entry["is_category"] = true
		properties.append(entry)

	return {
		"node_path": node_path,
		"node_type": node.get_class(),
		"properties": properties,
	}

func _value_to_json(v: Variant) -> Variant:
	if v is Vector2:
		return {"x": v.x, "y": v.y}
	if v is Vector2i:
		return {"x": v.x, "y": v.y}
	if v is Vector3:
		return {"x": v.x, "y": v.y, "z": v.z}
	if v is Vector3i:
		return {"x": v.x, "y": v.y, "z": v.z}
	if v is Color:
		return {"r": v.r, "g": v.g, "b": v.b, "a": v.a}
	if v is Rect2:
		return {"x": v.position.x, "y": v.position.y, "w": v.size.x, "h": v.size.y}
	if v is Transform2D or v is Transform3D or v is Basis:
		return str(v)
	if v is Object:
		if v is Resource:
			return v.resource_path if not v.resource_path.is_empty() else str(v)
		return str(v)
	return v

func _set_node_property(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var property: String  = args.get("property", "")
	if node_path.is_empty() or property.is_empty():
		return {"error": "'node_path' and 'property' are required"}
	if not args.has("value"):
		return {"error": "'value' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var raw_value = args.get("value")
	var value = _coerce_value(node, property, raw_value)
	var old_value = node.get(property)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set Property: %s.%s" % [node.name, property])
	ur.add_do_property(node, property, value)
	ur.add_undo_property(node, property, old_value)
	ur.commit_action()

	return {
		"success": true,
		"node_path": node_path,
		"property": property,
		"old_value": _value_to_json(old_value),
		"new_value": _value_to_json(value),
	}

func _get_node_signals(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var signals: Array = []
	for sig in node.get_signal_list():
		var connections: Array = []
		for conn in node.get_signal_connection_list(sig.name):
			connections.append({
				"target": str(conn.callable.get_object().get_path()) if conn.callable.get_object() else "",
				"method": conn.callable.get_method(),
			})
		signals.append({
			"name": sig.name,
			"connections": connections,
			"connected": connections.size() > 0,
		})

	return {"node_path": node_path, "signals": signals}

func _connect_signal(args: Dictionary) -> Dictionary:
	var src_path: String      = args.get("source_node_path", "")
	var signal_name: String   = args.get("signal_name", "")
	var tgt_path: String      = args.get("target_node_path", "")
	var callback: String      = args.get("callback_name", "")

	if src_path.is_empty() or signal_name.is_empty() or tgt_path.is_empty() or callback.is_empty():
		return {"error": "All four parameters are required"}

	var src := _resolve_node(src_path)
	if src == null:
		return {"error": "Source node not found: %s" % src_path}

	var tgt := _resolve_node(tgt_path)
	if tgt == null:
		return {"error": "Target node not found: %s" % tgt_path}

	if not src.has_signal(signal_name):
		return {"error": "Signal '%s' not found on %s" % [signal_name, src.get_class()]}

	if not tgt.has_method(callback):
		return {"error": "Method '%s' not found on target node" % callback}

	var callable := Callable(tgt, callback)
	if src.is_connected(signal_name, callable):
		return {"error": "Signal '%s' is already connected to '%s'" % [signal_name, callback]}

	var ur := _plugin.get_undo_redo()
	ur.create_action("Connect Signal: %s → %s" % [signal_name, callback])
	ur.add_do_method(src, "connect", signal_name, callable)
	ur.add_undo_method(src, "disconnect", signal_name, callable)
	ur.commit_action()

	return {
		"success": true,
		"source": src_path,
		"signal": signal_name,
		"target": tgt_path,
		"method": callback,
	}

func _add_to_group(args: Dictionary) -> Dictionary:
	var node_path: String  = args.get("node_path", "")
	var group_name: String = args.get("group_name", "")
	if node_path.is_empty() or group_name.is_empty():
		return {"error": "'node_path' and 'group_name' are required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	if node.is_in_group(group_name):
		return {"error": "Node is already in group '%s'" % group_name}

	var ur := _plugin.get_undo_redo()
	ur.create_action("Add to Group: %s" % group_name)
	ur.add_do_method(node, "add_to_group", group_name, true)
	ur.add_undo_method(node, "remove_from_group", group_name)
	ur.commit_action()

	return {"success": true, "node_path": node_path, "group": group_name}

func _remove_from_group(args: Dictionary) -> Dictionary:
	var node_path: String  = args.get("node_path", "")
	var group_name: String = args.get("group_name", "")
	if node_path.is_empty() or group_name.is_empty():
		return {"error": "'node_path' and 'group_name' are required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	if not node.is_in_group(group_name):
		return {"error": "Node is not in group '%s'" % group_name}

	var ur := _plugin.get_undo_redo()
	ur.create_action("Remove from Group: %s" % group_name)
	ur.add_do_method(node, "remove_from_group", group_name)
	ur.add_undo_method(node, "add_to_group", group_name, true)
	ur.commit_action()

	return {"success": true, "node_path": node_path, "group": group_name}

func _get_node_groups(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	return {"node_path": node_path, "groups": node.get_groups()}

func _get_node_parent(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var parent: Node = node.get_parent()
	if parent == null:
		return {"node_path": node_path, "parent": null, "is_root": true}

	return {"node_path": node_path, "parent": _node_summary(parent), "is_root": false}

func _get_node_children(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var children: Array = []
	for child in node.get_children():
		children.append(_node_summary(child))

	return {"node_path": node_path, "children": children, "total": children.size()}
