@tool
extends RefCounted

class_name GodotMCPShaderTools

## Implements 6 Shader tools: create_shader, edit_shader, assign_material,
## set_shader_param, get_shader_info, validate_shader.
## File-based tools (create/edit) write to disk without UndoRedo.
## Node-mutation tools (assign_material, set_shader_param) use EditorUndoRedo.

var _plugin: EditorPlugin

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("create_shader",    GodotMCPCallableTool.new(_create_shader))
	registry.register_tool("edit_shader",      GodotMCPCallableTool.new(_edit_shader))
	registry.register_tool("assign_material",  GodotMCPCallableTool.new(_assign_material))
	registry.register_tool("set_shader_param", GodotMCPCallableTool.new(_set_shader_param))
	registry.register_tool("get_shader_info",  GodotMCPCallableTool.new(_get_shader_info))
	registry.register_tool("validate_shader",  GodotMCPCallableTool.new(_validate_shader))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _as_bool(val: Variant) -> bool:
	if val is bool:
		return val
	return str(val).to_lower() == "true"

static func _skeleton_for_type(t: String) -> String:
	match t:
		"spatial":
			return "shader_type spatial;\n\nvoid fragment() {\n\t// ALBEDO = vec3(1.0);\n}\n"
		"canvas_item":
			return "shader_type canvas_item;\n\nvoid fragment() {\n\t// COLOR = vec4(1.0);\n}\n"
		"particles":
			return "shader_type particles;\n\nvoid process() {\n\t// ACTIVE = true;\n}\n"
		"sky":
			return "shader_type sky;\n\nvoid sky() {\n\t// COLOR = vec3(0.0, 0.5, 1.0);\n}\n"
		"fog":
			return "shader_type fog;\n\nvoid fog() {\n\t// ALBEDO = vec3(0.5);\n}\n"
		_:
			return "shader_type spatial;\n\nvoid fragment() {\n}\n"

func _get_node(node_path: String) -> Variant:
	var scene_root = _plugin.get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		return {"error": "No scene is currently open"}
	var node = scene_root.get_node_or_null(NodePath(node_path))
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	return node

func _get_node_material(node: Node, surface_idx: int) -> Variant:
	if node is GeometryInstance3D:
		return node.get_surface_override_material(surface_idx)
	if node is CanvasItem:
		return node.material
	return null

func _get_shader_mat(node: Node, surface_idx: int) -> Variant:
	var mat = _get_node_material(node, surface_idx)
	if mat == null:
		return {"error": "Node '%s' has no material assigned on surface %d" % [node.name, surface_idx]}
	if not mat is ShaderMaterial:
		return {"error": "Node '%s' material is '%s', not ShaderMaterial" % [node.name, mat.get_class()]}
	return mat

func _shader_mode_name(mode: int) -> String:
	match mode:
		Shader.MODE_SPATIAL:     return "spatial"
		Shader.MODE_CANVAS_ITEM: return "canvas_item"
		Shader.MODE_PARTICLES:   return "particles"
		Shader.MODE_SKY:         return "sky"
		Shader.MODE_FOG:         return "fog"
		_:                       return "unknown(%d)" % mode

func _type_name(t: int) -> String:
	match t:
		TYPE_BOOL:        return "bool"
		TYPE_INT:         return "int"
		TYPE_FLOAT:       return "float"
		TYPE_STRING:      return "String"
		TYPE_VECTOR2:     return "vec2"
		TYPE_VECTOR3:     return "vec3"
		TYPE_VECTOR4:     return "vec4"
		TYPE_COLOR:       return "vec4 (color)"
		TYPE_OBJECT:      return "sampler2D"
		TYPE_BASIS:       return "mat3"
		TYPE_TRANSFORM3D: return "mat4"
		_:                return "type(%d)" % t

func _uniform_list(shader: Shader) -> Array:
	var out: Array = []
	for p in RenderingServer.shader_get_param_list(shader.get_rid()):
		out.append({
			"name": str(p.get("name", "")),
			"type": _type_name(int(p.get("type", TYPE_FLOAT))),
		})
	return out

func _write_file(path: String, content: String) -> String:
	var parent := path.get_base_dir()
	if not parent.is_empty() and DirAccess.open(parent) == null:
		# Use instance-based make_dir_recursive for Godot 4.0 compatibility
		# (DirAccess.make_dir_recursive_absolute was added in Godot 4.1)
		var root := DirAccess.open("res://")
		if root == null:
			return "Cannot access res:// directory"
		var err := root.make_dir_recursive(parent.trim_prefix("res://"))
		if err != OK:
			return "Failed to create directory '%s' (error %d)" % [parent, err]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "Failed to open '%s' for writing (error %d)" % [path, FileAccess.get_open_error()]
	f.store_string(content)
	f.close()
	return ""

func _read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return {"error": "File not found: %s" % path}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"error": "Failed to open '%s' (error %d)" % [path, FileAccess.get_open_error()]}
	var text := f.get_as_text()
	f.close()
	return text

func _parse_param_value(val: Variant) -> Variant:
	if val is bool or val is int or val is float:
		return val
	if val is Array:
		match val.size():
			1: return float(val[0])
			2: return Vector2(float(val[0]), float(val[1]))
			3: return Vector3(float(val[0]), float(val[1]), float(val[2]))
			4: return Color(float(val[0]), float(val[1]), float(val[2]), float(val[3]))
		return val  # Array with unhandled size (5+); pass through as-is
	if val is Dictionary:
		if val.has("r") or val.has("g") or val.has("b"):
			return Color(float(val.get("r", 0)), float(val.get("g", 0)),
				float(val.get("b", 0)), float(val.get("a", 1)))
		if val.has("x") and val.has("z"):
			return Vector3(float(val.get("x", 0)), float(val.get("y", 0)), float(val.get("z", 0)))
		if val.has("x"):
			return Vector2(float(val.get("x", 0)), float(val.get("y", 0)))
	if val is String:
		var s: String = val.strip_edges()
		if s.begins_with("Color("):
			var inner := s.trim_prefix("Color(").trim_suffix(")")
			var p := inner.split(",")
			if p.size() >= 3:
				return Color(float(p[0]), float(p[1]), float(p[2]),
					float(p[3]) if p.size() >= 4 else 1.0)
		if s.begins_with("Vector3("):
			var inner := s.trim_prefix("Vector3(").trim_suffix(")")
			var p := inner.split(",")
			if p.size() == 3:
				return Vector3(float(p[0]), float(p[1]), float(p[2]))
		if s.begins_with("Vector2("):
			var inner := s.trim_prefix("Vector2(").trim_suffix(")")
			var p := inner.split(",")
			if p.size() == 2:
				return Vector2(float(p[0]), float(p[1]))
		if Color.html_is_valid(s):
			return Color.html(s)
		if Color.html_is_valid("#" + s):
			return Color.html("#" + s)
		if s == "true":  return true
		if s == "false": return false
		if s.is_valid_float():
			return float(s)
		if s.begins_with("res://") and ResourceLoader.exists(s):
			return ResourceLoader.load(s)
	return val

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _create_shader(args: Dictionary) -> Dictionary:
	var shader_path: String = args.get("shader_path", "")
	if shader_path.is_empty():
		return {"error": "'shader_path' is required (e.g. 'res://shaders/my_shader.gdshader')"}
	if not shader_path.ends_with(".gdshader"):
		return {"error": "'shader_path' must end with .gdshader"}

	if FileAccess.file_exists(shader_path) and not _as_bool(args.get("overwrite", false)):
		return {"error": "Shader already exists at '%s'. Pass overwrite: true to replace it." % shader_path}

	var shader_type: String = str(args.get("shader_type", "spatial")).to_lower()
	if shader_type not in ["spatial", "canvas_item", "particles", "sky", "fog"]:
		return {"error": "Unknown shader_type '%s'. Valid: spatial, canvas_item, particles, sky, fog" % shader_type}

	var code: String
	if args.has("code") and not str(args["code"]).strip_edges().is_empty():
		code = str(args["code"])
		# Prepend shader_type directive if caller omitted it
		if not code.strip_edges().begins_with("shader_type"):
			code = "shader_type %s;\n\n" % shader_type + code
	else:
		code = _skeleton_for_type(shader_type)

	var err_str := _write_file(shader_path, code)
	if not err_str.is_empty():
		return {"error": err_str}

	# Optionally create companion ShaderMaterial
	var material_path: String = args.get("material_path", "")
	if not material_path.is_empty():
		if not material_path.ends_with(".tres") and not material_path.ends_with(".res"):
			return {"error": "'material_path' must end with .tres or .res"}
		var shader = ResourceLoader.load(shader_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if shader == null or not shader is Shader:
			return {"error": "Shader written but could not be reloaded from '%s'" % shader_path}
		var mat := ShaderMaterial.new()
		mat.shader = shader
		var mat_err := ResourceSaver.save(mat, material_path)
		if mat_err != OK:
			return {"error": "Shader created but failed to save material to '%s' (error %d)" % [material_path, mat_err]}

	return {
		"success":       true,
		"shader_path":   shader_path,
		"shader_type":   shader_type,
		"material_path": material_path if not material_path.is_empty() else null,
	}


func _edit_shader(args: Dictionary) -> Dictionary:
	var shader_path: String = args.get("shader_path", "")
	if shader_path.is_empty():
		return {"error": "'shader_path' is required"}
	if not shader_path.ends_with(".gdshader"):
		return {"error": "'shader_path' must end with .gdshader"}
	if not FileAccess.file_exists(shader_path):
		return {"error": "Shader file not found: %s" % shader_path}
	if not args.has("code"):
		return {"error": "'code' is required (new shader source code)"}

	var new_code: String = str(args["code"])

	if _as_bool(args.get("append", false)):
		var existing = _read_file(shader_path)
		if existing is Dictionary:
			return existing
		new_code = str(existing) + "\n" + new_code

	var err_str := _write_file(shader_path, new_code)
	if not err_str.is_empty():
		return {"error": err_str}

	return {
		"success":     true,
		"shader_path": shader_path,
		"code_length": new_code.length(),
	}


func _assign_material(args: Dictionary) -> Dictionary:
	var node_path: String     = args.get("node_path", "")
	var shader_path: String   = args.get("shader_path", "")
	var material_path: String = args.get("material_path", "")

	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	if shader_path.is_empty() and material_path.is_empty():
		return {"error": "Either 'shader_path' or 'material_path' is required"}

	var node_result = _get_node(node_path)
	if node_result is Dictionary:
		return node_result
	var node: Node = node_result

	if not (node is GeometryInstance3D or node is CanvasItem):
		return {"error": "Node '%s' (%s) does not support shader materials. Expected GeometryInstance3D or CanvasItem." % [node_path, node.get_class()]}

	var surface_idx: int = int(args.get("surface_index", 0))

	var new_mat: ShaderMaterial
	if not material_path.is_empty():
		if not ResourceLoader.exists(material_path):
			return {"error": "Material file not found: %s" % material_path}
		var res = ResourceLoader.load(material_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not res is ShaderMaterial:
			return {"error": "Resource at '%s' is not a ShaderMaterial (got %s)" % [material_path, res.get_class() if res else "null"]}
		new_mat = res
	else:
		if not FileAccess.file_exists(shader_path):
			return {"error": "Shader file not found: %s" % shader_path}
		var shader = ResourceLoader.load(shader_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if shader == null or not shader is Shader:
			return {"error": "Failed to load shader from '%s'" % shader_path}
		new_mat = ShaderMaterial.new()
		new_mat.shader = shader
		var save_path: String = args.get("save_material_path", "")
		if not save_path.is_empty():
			if not save_path.ends_with(".tres") and not save_path.ends_with(".res"):
				return {"error": "'save_material_path' must end with .tres or .res"}
			var save_err := ResourceSaver.save(new_mat, save_path)
			if save_err != OK:
				return {"error": "Failed to save material to '%s' (error %d)" % [save_path, save_err]}

	var ur := _plugin.get_undo_redo()
	if node is GeometryInstance3D:
		var old_mat = node.get_surface_override_material(surface_idx)
		ur.create_action("Assign Shader Material to %s" % node.name)
		ur.add_do_method(node, "set_surface_override_material", surface_idx, new_mat)
		ur.add_undo_method(node, "set_surface_override_material", surface_idx, old_mat)
		ur.commit_action()
	else:
		var old_mat = node.material
		ur.create_action("Assign Shader Material to %s" % node.name)
		ur.add_do_property(node, "material", new_mat)
		ur.add_undo_property(node, "material", old_mat)
		ur.commit_action()

	return {
		"success":       true,
		"node_path":     node_path,
		"shader_path":   new_mat.shader.resource_path if new_mat.shader else "",
		"material_path": material_path,
		"surface_index": surface_idx if node is GeometryInstance3D else null,
	}


func _set_shader_param(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	if not args.has("param_name"):
		return {"error": "'param_name' is required"}
	if not args.has("param_value"):
		return {"error": "'param_value' is required"}
	if args["param_value"] == null:
		return {"error": "'param_value' cannot be null. Use a number, array, color string, or texture path."}

	var node_result = _get_node(node_path)
	if node_result is Dictionary:
		return node_result
	var node: Node = node_result

	var surface_idx: int = int(args.get("surface_index", 0))
	var mat_result = _get_shader_mat(node, surface_idx)
	if mat_result is Dictionary:
		return mat_result
	var mat := mat_result as ShaderMaterial

	var param_name: String = str(args["param_name"])
	if param_name.is_empty():
		return {"error": "'param_name' cannot be empty"}
	var parsed_val = _parse_param_value(args["param_value"])
	var old_val = mat.get_shader_parameter(param_name)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set Shader Param '%s' on %s" % [param_name, node.name])
	ur.add_do_method(mat, "set_shader_parameter", param_name, parsed_val)
	ur.add_undo_method(mat, "set_shader_parameter", param_name, old_val)
	ur.commit_action()

	return {
		"success":    true,
		"node_path":  node_path,
		"param_name": param_name,
		"old_value":  str(old_val),
		"new_value":  str(parsed_val),
	}


func _get_shader_info(args: Dictionary) -> Dictionary:
	var shader_path: String   = args.get("shader_path", "")
	var node_path: String     = args.get("node_path", "")
	var material_path: String = args.get("material_path", "")

	var shader: Shader = null
	var mat: ShaderMaterial = null

	if not shader_path.is_empty():
		if not FileAccess.file_exists(shader_path):
			return {"error": "Shader file not found: %s" % shader_path}
		var res = ResourceLoader.load(shader_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res == null or not res is Shader:
			return {"error": "Failed to load Shader from '%s'" % shader_path}
		shader = res
	elif not material_path.is_empty():
		if not ResourceLoader.exists(material_path):
			return {"error": "Material file not found: %s" % material_path}
		var res = ResourceLoader.load(material_path)
		if not res is ShaderMaterial:
			return {"error": "Resource at '%s' is not a ShaderMaterial" % material_path}
		mat = res
		shader = mat.shader
	elif not node_path.is_empty():
		var node_result = _get_node(node_path)
		if node_result is Dictionary:
			return node_result
		var node: Node = node_result
		var surface_idx: int = int(args.get("surface_index", 0))
		var mat_result = _get_shader_mat(node, surface_idx)
		if mat_result is Dictionary:
			return mat_result
		mat = mat_result as ShaderMaterial
		shader = mat.shader
	else:
		return {"error": "One of 'shader_path', 'material_path', or 'node_path' is required"}

	if shader == null:
		return {"error": "Material has no shader assigned"}

	var uniforms := _uniform_list(shader)
	var result: Dictionary = {
		"shader_path": shader.resource_path,
		"shader_type": _shader_mode_name(shader.get_mode()),
		"code":        shader.code,
		"uniforms":    uniforms,
	}
	if mat != null:
		result["material_path"] = mat.resource_path
		var param_values: Dictionary = {}
		for u in uniforms:
			var pname: String = u["name"]
			param_values[pname] = str(mat.get_shader_parameter(pname))
		result["param_values"] = param_values
	return result


func _validate_shader(args: Dictionary) -> Dictionary:
	var shader_path: String = args.get("shader_path", "")
	var code: String = args.get("code", "")

	if shader_path.is_empty() and code.is_empty():
		return {"error": "Either 'shader_path' or 'code' is required"}

	if not shader_path.is_empty():
		if not FileAccess.file_exists(shader_path):
			return {"error": "Shader file not found: %s" % shader_path}
		var text = _read_file(shader_path)
		if text is Dictionary:
			return text
		code = str(text)

	# Find shader_type declaration, handling // line comments and /* */ block comments
	var declared_type := ""
	var in_block_comment := false
	for line in code.split("\n"):
		var s := line.strip_edges()
		if in_block_comment:
			if s.contains("*/"):
				in_block_comment = false
			continue
		if s.is_empty() or s.begins_with("//"):
			continue
		if s.begins_with("/*"):
			if not s.contains("*/"):
				in_block_comment = true
			continue
		if s.begins_with("shader_type"):
			# Strip any trailing inline comment before parsing
			var code_part := s
			var comment_pos := code_part.find("//")
			if comment_pos >= 0:
				code_part = code_part.left(comment_pos)
			var parts := code_part.strip_edges().trim_suffix(";").strip_edges().split(" ", false)
			if parts.size() >= 2:
				declared_type = parts[1].strip_edges().to_lower()
			break
		# First real code line is not shader_type
		break

	if declared_type.is_empty():
		return {
			"valid":    false,
			"issues":   ["Missing 'shader_type' declaration — must be the first statement (e.g. 'shader_type spatial;')"],
			"uniforms": [],
		}

	if declared_type not in ["spatial", "canvas_item", "particles", "sky", "fog"]:
		return {
			"valid":         false,
			"declared_type": declared_type,
			"issues":        ["Unknown shader type '%s'. Valid: spatial, canvas_item, particles, sky, fog" % declared_type],
			"uniforms":      [],
		}

	# Create a temporary Shader to let Godot parse it
	var temp := Shader.new()
	temp.code = code
	var detected := _shader_mode_name(temp.get_mode())
	var uniforms := _uniform_list(temp)

	var issues: Array = []
	if detected != declared_type:
		issues.append("Declared 'shader_type %s' but Godot parsed mode as '%s' — likely a syntax error in the shader_type line" % [declared_type, detected])

	return {
		"valid":         issues.is_empty(),
		"declared_type": declared_type,
		"detected_type": detected,
		"uniforms":      uniforms,
		"uniform_count": uniforms.size(),
		"issues":        issues,
		"code_length":   code.length(),
		"note":          "Full GLSL syntax errors inside function bodies are not detectable via GDScript. Check Godot's Output panel for shader compile errors.",
	}
