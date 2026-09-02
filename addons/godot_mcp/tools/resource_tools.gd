@tool
extends GodotMCPToolBase

class_name GodotMCPResourceTools

## Implements 6 Resource tools: read_resource, edit_resource, create_resource,
## save_resource, get_project_autoloads, set_autoload.
## All resource file operations use ResourceLoader/ResourceSaver (no UndoRedo).
## Autoload management uses EditorPlugin.add/remove_autoload_singleton.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("read_resource",         GodotMCPCallableTool.new(_read_resource))
	registry.register_tool("edit_resource",         GodotMCPCallableTool.new(_edit_resource))
	registry.register_tool("create_resource",       GodotMCPCallableTool.new(_create_resource))
	registry.register_tool("save_resource",         GodotMCPCallableTool.new(_save_resource))
	registry.register_tool("get_project_autoloads", GodotMCPCallableTool.new(_get_project_autoloads))
	registry.register_tool("set_autoload",          GodotMCPCallableTool.new(_set_autoload))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _value_to_json(val: Variant) -> Variant:
	if val == null:          return null
	if val is bool:          return val
	if val is int:           return val
	if val is float:         return val
	if val is String:        return val
	if val is StringName:    return str(val)
	if val is NodePath:      return str(val)
	if val is Vector2:       return {"x": val.x, "y": val.y}
	if val is Vector2i:      return {"x": val.x, "y": val.y}
	if val is Vector3:       return {"x": val.x, "y": val.y, "z": val.z}
	if val is Vector3i:      return {"x": val.x, "y": val.y, "z": val.z}
	if val is Vector4:       return {"x": val.x, "y": val.y, "z": val.z, "w": val.w}
	if val is Quaternion:    return {"x": val.x, "y": val.y, "z": val.z, "w": val.w}
	if val is Color:
		return {"r": val.r, "g": val.g, "b": val.b, "a": val.a, "html": "#%s" % val.to_html(true)}
	if val is Rect2:
		return {"x": val.position.x, "y": val.position.y, "w": val.size.x, "h": val.size.y}
	if val is Rect2i:
		return {"x": val.position.x, "y": val.position.y, "w": val.size.x, "h": val.size.y}
	if val is Basis:
		return {"x": _value_to_json(val.x), "y": _value_to_json(val.y), "z": _value_to_json(val.z)}
	if val is Transform3D:
		return {"basis": _value_to_json(val.basis), "origin": _value_to_json(val.origin)}
	if val is Transform2D:
		return {"x": _value_to_json(val.x), "y": _value_to_json(val.y), "origin": _value_to_json(val.origin)}
	if val is Array:
		var out: Array = []
		for item in val:
			out.append(_value_to_json(item))
		return out
	if val is Dictionary:
		var out: Dictionary = {}
		for k in val:
			out[str(k)] = _value_to_json(val[k])
		return out
	if val is Resource:
		return {"class": val.get_class(), "path": val.resource_path if not val.resource_path.is_empty() else null}
	if val is Object:
		return {"class": val.get_class()}
	# Packed arrays (PackedFloat32Array, PackedVector2Array, etc.)
	if val is PackedFloat32Array or val is PackedFloat64Array:
		var out: Array = []
		for f in val:
			out.append(float(f))
		return out
	if val is PackedInt32Array or val is PackedInt64Array:
		var out: Array = []
		for i in val:
			out.append(int(i))
		return out
	if val is PackedStringArray:
		var out: Array = []
		for s in val:
			out.append(str(s))
		return out
	if val is PackedVector2Array:
		var out: Array = []
		for v in val:
			out.append({"x": v.x, "y": v.y})
		return out
	if val is PackedVector3Array:
		var out: Array = []
		for v in val:
			out.append({"x": v.x, "y": v.y, "z": v.z})
		return out
	if val is PackedColorArray:
		var out: Array = []
		for c in val:
			out.append({"r": c.r, "g": c.g, "b": c.b, "a": c.a})
		return out
	if val is PackedByteArray:
		if val.size() <= 64:
			var out: Array = []
			for b in val:
				out.append(int(b))
			return out
		return {"type": "PackedByteArray", "size": val.size(), "preview_hex": val.slice(0, 16).hex_encode()}
	return str(val)

func _parse_prop_value(val: Variant, expected_type: int) -> Variant:
	if val == null:
		return null
	match expected_type:
		TYPE_BOOL:
			return _as_bool(val)
		TYPE_INT:
			return int(val)
		TYPE_FLOAT:
			return float(val)
		TYPE_STRING:
			return str(val)
		TYPE_STRING_NAME:
			return StringName(str(val))
		TYPE_NODE_PATH:
			return NodePath(str(val))
		TYPE_VECTOR2:
			if val is Array and val.size() >= 2:
				return Vector2(float(val[0]), float(val[1]))
			if val is Dictionary:
				return Vector2(float(val.get("x", 0.0)), float(val.get("y", 0.0)))
		TYPE_VECTOR2I:
			if val is Array and val.size() >= 2:
				return Vector2i(int(val[0]), int(val[1]))
			if val is Dictionary:
				return Vector2i(int(val.get("x", 0)), int(val.get("y", 0)))
		TYPE_VECTOR3:
			if val is Array and val.size() >= 3:
				return Vector3(float(val[0]), float(val[1]), float(val[2]))
			if val is Dictionary:
				return Vector3(float(val.get("x", 0.0)), float(val.get("y", 0.0)), float(val.get("z", 0.0)))
		TYPE_VECTOR3I:
			if val is Array and val.size() >= 3:
				return Vector3i(int(val[0]), int(val[1]), int(val[2]))
			if val is Dictionary:
				return Vector3i(int(val.get("x", 0)), int(val.get("y", 0)), int(val.get("z", 0)))
		TYPE_VECTOR4:
			if val is Array and val.size() >= 4:
				return Vector4(float(val[0]), float(val[1]), float(val[2]), float(val[3]))
			if val is Dictionary:
				return Vector4(float(val.get("x", 0.0)), float(val.get("y", 0.0)),
					float(val.get("z", 0.0)), float(val.get("w", 0.0)))
		TYPE_COLOR:
			if val is Array and val.size() >= 3:
				return Color(float(val[0]), float(val[1]), float(val[2]),
					float(val[3]) if val.size() >= 4 else 1.0)
			if val is Dictionary and (val.has("r") or val.has("g") or val.has("b")):
				return Color(float(val.get("r", 0.0)), float(val.get("g", 0.0)),
					float(val.get("b", 0.0)), float(val.get("a", 1.0)))
			if val is String:
				var s := str(val).strip_edges()
				if Color.html_is_valid(s):       return Color.html(s)
				if Color.html_is_valid("#" + s): return Color.html("#" + s)
		TYPE_RECT2:
			if val is Dictionary:
				return Rect2(float(val.get("x", 0.0)), float(val.get("y", 0.0)),
					float(val.get("w", 0.0)), float(val.get("h", 0.0)))
		TYPE_RECT2I:
			if val is Array and val.size() >= 4:
				return Rect2i(int(val[0]), int(val[1]), int(val[2]), int(val[3]))
			if val is Dictionary:
				return Rect2i(int(val.get("x", 0)), int(val.get("y", 0)),
					int(val.get("w", 0)), int(val.get("h", 0)))
		TYPE_QUATERNION:
			if val is Array and val.size() >= 4:
				return Quaternion(float(val[0]), float(val[1]), float(val[2]), float(val[3]))
			if val is Dictionary:
				return Quaternion(float(val.get("x", 0.0)), float(val.get("y", 0.0)),
					float(val.get("z", 0.0)), float(val.get("w", 1.0)))
		TYPE_BASIS:
			if val is Dictionary:
				return _parse_basis(val)
		TYPE_TRANSFORM3D:
			if val is Dictionary:
				var b := _parse_basis(val["basis"]) if val.has("basis") and val["basis"] is Dictionary else Basis.IDENTITY
				var o := _parse_v3(val["origin"]) if val.has("origin") and val["origin"] is Dictionary else Vector3.ZERO
				return Transform3D(b, o)
		TYPE_TRANSFORM2D:
			if val is Dictionary:
				var _xv := _parse_v2(val["x"]) if val.has("x") and val["x"] is Dictionary else Vector2(1.0, 0.0)
				var _yv := _parse_v2(val["y"]) if val.has("y") and val["y"] is Dictionary else Vector2(0.0, 1.0)
				var _ov := _parse_v2(val["origin"]) if val.has("origin") and val["origin"] is Dictionary else Vector2.ZERO
				return Transform2D(_xv, _yv, _ov)
		TYPE_OBJECT:
			if val is String:
				var s := str(val)
				if s.begins_with("res://") and ResourceLoader.exists(s):
					return ResourceLoader.load(s)
			if val is Resource:
				return val
	return val

func _parse_v2(d: Dictionary) -> Vector2:
	return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))

func _parse_v3(d: Dictionary) -> Vector3:
	return Vector3(float(d.get("x", 0.0)), float(d.get("y", 0.0)), float(d.get("z", 0.0)))

func _parse_basis(d: Dictionary) -> Basis:
	var bx = d.get("x", null)
	var by = d.get("y", null)
	var bz = d.get("z", null)
	return Basis(
		_parse_v3(bx) if bx is Dictionary else Vector3(1.0, 0.0, 0.0),
		_parse_v3(by) if by is Dictionary else Vector3(0.0, 1.0, 0.0),
		_parse_v3(bz) if bz is Dictionary else Vector3(0.0, 0.0, 1.0)
	)

func _get_prop_types(resource: Resource) -> Dictionary:
	var types: Dictionary = {}
	for p in resource.get_property_list():
		types[str(p.get("name", ""))] = int(p.get("type", TYPE_NIL))
	return types

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _read_resource(args: Dictionary) -> Dictionary:
	var resource_path: String = args.get("resource_path", "")
	if resource_path.is_empty():
		return {"error": "'resource_path' is required (e.g. 'res://data/my.tres')"}
	if not ResourceLoader.exists(resource_path):
		return {"error": "Resource not found: %s" % resource_path}

	var resource = ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		return {"error": "Failed to load resource: %s" % resource_path}

	var props: Dictionary = {}
	for p in resource.get_property_list():
		var pname: String = str(p.get("name", ""))
		var usage: int = int(p.get("usage", 0))
		if not (usage & PROPERTY_USAGE_STORAGE):
			continue
		if pname == "Script":
			continue
		props[pname] = _value_to_json(resource.get(pname))

	var result: Dictionary = {
		"resource_path": resource_path,
		"class":         resource.get_class(),
		"properties":    props,
	}
	if not resource.resource_name.is_empty():
		result["resource_name"] = resource.resource_name
	return result

func _edit_resource(args: Dictionary) -> Dictionary:
	var resource_path: String = args.get("resource_path", "")
	if resource_path.is_empty():
		return {"error": "'resource_path' is required"}
	if not resource_path.begins_with("res://"):
		return {"error": "'resource_path' must start with 'res://' (got '%s')" % resource_path}

	if not args.has("properties") or not args["properties"] is Dictionary:
		return {"error": "'properties' is required (dict mapping property names to new values)"}
	var properties: Dictionary = args["properties"]
	if properties.is_empty():
		return {"error": "'properties' must contain at least one entry"}

	if not ResourceLoader.exists(resource_path):
		return {"error": "Resource not found: %s" % resource_path}

	var resource = ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		return {"error": "Failed to load resource: %s" % resource_path}

	var prop_types := _get_prop_types(resource)
	var updated: Dictionary = {}
	var skipped: Dictionary = {}

	for key in properties:
		var pname: String = str(key)
		if not prop_types.has(pname):
			skipped[pname] = "property not found on %s" % resource.get_class()
			continue
		var parsed = _parse_prop_value(properties[key], prop_types[pname])
		resource.set(pname, parsed)
		updated[pname] = _value_to_json(resource.get(pname))

	if updated.is_empty():
		return {
			"success":       false,
			"resource_path": resource_path,
			"class":         resource.get_class(),
			"updated":       {},
			"skipped":       skipped,
			"warning":       "No properties were updated — all requested names not found on %s. Use read_resource to list valid property names." % resource.get_class(),
		}

	var err := ResourceSaver.save(resource, resource_path)
	if err != OK:
		return {"error": "Failed to save resource to '%s' (error %d)" % [resource_path, err]}

	var result: Dictionary = {
		"success":       true,
		"resource_path": resource_path,
		"class":         resource.get_class(),
		"updated":       updated,
	}
	if not skipped.is_empty():
		result["skipped"] = skipped
	return result

func _create_resource(args: Dictionary) -> Dictionary:
	var resource_class: String = args.get("resource_class", "")
	var resource_path: String = args.get("resource_path", "")

	if resource_class.is_empty():
		return {"error": "'resource_class' is required (e.g. 'Environment', 'AudioStreamWAV', 'Resource')"}
	if resource_path.is_empty():
		return {"error": "'resource_path' is required (e.g. 'res://data/my.tres')"}
	if not resource_path.ends_with(".tres") and not resource_path.ends_with(".res"):
		return {"error": "'resource_path' must end with .tres or .res"}

	if not ClassDB.class_exists(resource_class):
		return {"error": "Class '%s' does not exist in Godot's ClassDB" % resource_class}
	if resource_class != "Resource" and not ClassDB.is_parent_class(resource_class, "Resource"):
		return {"error": "Class '%s' is not a Resource subclass" % resource_class}
	if not ClassDB.can_instantiate(resource_class):
		return {"error": "Class '%s' cannot be instantiated (abstract or virtual)" % resource_class}

	if ResourceLoader.exists(resource_path) and not _as_bool(args.get("overwrite", false)):
		return {"error": "Resource already exists at '%s'. Pass overwrite: true to replace it." % resource_path}

	var resource = ClassDB.instantiate(resource_class)
	if resource == null:
		return {"error": "Failed to instantiate class '%s'" % resource_class}
	if not resource is Resource:
		if resource is Object and not resource is RefCounted:
			resource.free()
		return {"error": "Class '%s' does not instantiate as a Resource" % resource_class}

	var properties: Dictionary = {}
	if args.has("properties") and args["properties"] is Dictionary:
		properties = args["properties"]

	var prop_types := _get_prop_types(resource)
	var set_results: Dictionary = {}
	for key in properties:
		var pname: String = str(key)
		if prop_types.has(pname):
			var parsed = _parse_prop_value(properties[key], prop_types[pname])
			resource.set(pname, parsed)
			set_results[pname] = "set"
		else:
			set_results[pname] = "skipped (property not found)"

	var err := ResourceSaver.save(resource, resource_path)
	if err != OK:
		return {"error": "Failed to save to '%s' (error %d)" % [resource_path, err]}

	var result: Dictionary = {
		"success":       true,
		"resource_path": resource_path,
		"class":         resource.get_class(),
	}
	if not set_results.is_empty():
		result["set_results"] = set_results
	return result

func _save_resource(args: Dictionary) -> Dictionary:
	var source_path: String = args.get("source_path", "")
	if source_path.is_empty():
		return {"error": "'source_path' is required"}
	if not ResourceLoader.exists(source_path):
		return {"error": "Resource not found: %s" % source_path}

	var resource = ResourceLoader.load(source_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		return {"error": "Failed to load resource: %s" % source_path}

	var dest_path: String = args.get("dest_path", "")
	var target := dest_path if not dest_path.is_empty() else source_path

	var err := ResourceSaver.save(resource, target)
	if err != OK:
		return {"error": "Failed to save to '%s' (error %d)" % [target, err]}

	return {
		"success":     true,
		"source_path": source_path,
		"dest_path":   target,
		"class":       resource.get_class(),
		"copied":      target != source_path,
	}

func _get_project_autoloads(args: Dictionary) -> Dictionary:
	var autoloads: Array = []
	for prop in ProjectSettings.get_property_list():
		var pname: String = str(prop.get("name", ""))
		if not pname.begins_with("autoload/"):
			continue
		var autoload_name: String = pname.trim_prefix("autoload/")
		if autoload_name.is_empty():
			continue
		var value: String = str(ProjectSettings.get_setting(pname, ""))
		var is_singleton := value.begins_with("*")
		var path := value.trim_prefix("*")
		autoloads.append({
			"name":         autoload_name,
			"path":         path,
			"is_singleton": is_singleton,
		})
	return {
		"autoloads": autoloads,
		"count":     autoloads.size(),
	}

func _set_autoload(args: Dictionary) -> Dictionary:
	var autoload_name: String = args.get("name", "")
	if autoload_name.is_empty():
		return {"error": "'name' is required (the autoload singleton name, e.g. 'GameManager')"}
	if not autoload_name.is_valid_identifier():
		return {"error": "Autoload name '%s' is not a valid GDScript identifier" % autoload_name}

	var action: String = str(args.get("action", "add")).to_lower()
	if action not in ["add", "modify", "remove"]:
		return {"error": "Unknown action '%s'. Valid values: 'add', 'modify', 'remove'" % action}

	if action == "remove":
		var setting_key := "autoload/" + autoload_name
		if not ProjectSettings.has_setting(setting_key):
			return {"error": "Autoload '%s' is not registered in project settings" % autoload_name}
		_plugin.remove_autoload_singleton(autoload_name)
		ProjectSettings.save()
		return {"success": true, "action": "remove", "name": autoload_name}

	# action == "add" or "modify"
	var path: String = args.get("path", "")
	if path.is_empty():
		return {"error": "'path' is required when action is 'add' or 'modify' (e.g. 'res://scripts/game_manager.gd')"}
	if not ResourceLoader.exists(path):
		return {"error": "Script or scene file not found: %s" % path}

	# If already registered, remove first to update cleanly
	var setting_key := "autoload/" + autoload_name
	var was_existing := ProjectSettings.has_setting(setting_key)
	if was_existing:
		_plugin.remove_autoload_singleton(autoload_name)

	_plugin.add_autoload_singleton(autoload_name, path)
	ProjectSettings.save()

	return {
		"success": true,
		"action":  "modify" if was_existing else "add",
		"name":    autoload_name,
		"path":    path,
	}
