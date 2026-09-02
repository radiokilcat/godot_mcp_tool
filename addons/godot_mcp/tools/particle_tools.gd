@tool
extends GodotMCPToolBase

class_name GodotMCPParticleTools

## Implements 5 Particle tools: create_particle_system, set_particle_material,
## set_particle_gradient, load_particle_preset, get_particle_info.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("create_particle_system", GodotMCPCallableTool.new(_create_particle_system))
	registry.register_tool("set_particle_material",  GodotMCPCallableTool.new(_set_particle_material))
	registry.register_tool("set_particle_gradient",  GodotMCPCallableTool.new(_set_particle_gradient))
	registry.register_tool("load_particle_preset",   GodotMCPCallableTool.new(_load_particle_preset))
	registry.register_tool("get_particle_info",      GodotMCPCallableTool.new(_get_particle_info))
func _is_particle_node(node: Node) -> bool:
	return node is GPUParticles3D or node is GPUParticles2D

## Duplicate the existing ParticleProcessMaterial or create a fresh one.
func _dup_or_new_material(node: Node) -> ParticleProcessMaterial:
	var old_mat = node.get("process_material")
	if old_mat is ParticleProcessMaterial:
		return (old_mat as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
	return ParticleProcessMaterial.new()

func _emission_shape_name(shape: int) -> String:
	match shape:
		ParticleProcessMaterial.EMISSION_SHAPE_SPHERE:         return "sphere"
		ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE: return "sphere_surface"
		ParticleProcessMaterial.EMISSION_SHAPE_BOX:            return "box"
		ParticleProcessMaterial.EMISSION_SHAPE_RING:           return "ring"
		_:                                                     return "point"

func _apply_emission_shape(mat: ParticleProcessMaterial, shape_str: String) -> void:
	match shape_str:
		"sphere":         mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		"sphere_surface": mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
		"box":            mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		"ring":           mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		_:                mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _create_particle_system(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var node_name: String   = args.get("node_name", "")
	var dimension: String   = args.get("dimension", "3d")
	var amount: int         = int(args.get("amount", 100))
	var lifetime: float     = float(args.get("lifetime", 1.0))
	var emitting: bool      = bool(args.get("emitting", true))
	var one_shot: bool      = bool(args.get("one_shot", false))

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var particles: Node

	if dimension == "2d":
		var p := GPUParticles2D.new()
		p.amount   = amount
		p.lifetime = lifetime
		p.emitting = emitting
		p.one_shot = one_shot
		if args.has("position"):
			p.position = _parse_vector2(args["position"])
		if node_name.is_empty():
			node_name = "GPUParticles2D"
		particles = p
	else:
		var p := GPUParticles3D.new()
		p.amount   = amount
		p.lifetime = lifetime
		p.emitting = emitting
		p.one_shot = one_shot
		if args.has("position"):
			p.position = _parse_vector3(args["position"])
		if node_name.is_empty():
			node_name = "GPUParticles3D"
		particles = p
		dimension = "3d"

	var result := _add_to_scene(particles, parent, node_name, "Create Particle System '%s'" % node_name)
	result["dimension"] = dimension
	result["amount"]    = amount
	result["lifetime"]  = lifetime
	return result

func _set_particle_material(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not _is_particle_node(node):
		return {"error": "Node '%s' is not a GPUParticles node (got %s)" % [node_path, node.get_class()]}

	var old_mat = node.get("process_material")
	var mat := _dup_or_new_material(node)

	if args.has("direction"):
		mat.direction = _parse_vector3(args["direction"])
	if args.has("spread"):
		mat.spread = float(args["spread"])
	if args.has("gravity"):
		mat.gravity = _parse_vector3(args["gravity"])
	if args.has("initial_velocity_min"):
		mat.initial_velocity_min = float(args["initial_velocity_min"])
	if args.has("initial_velocity_max"):
		mat.initial_velocity_max = float(args["initial_velocity_max"])
	if args.has("angular_velocity_min"):
		mat.angular_velocity_min = float(args["angular_velocity_min"])
	if args.has("angular_velocity_max"):
		mat.angular_velocity_max = float(args["angular_velocity_max"])
	if args.has("scale_min"):
		mat.scale_min = float(args["scale_min"])
	if args.has("scale_max"):
		mat.scale_max = float(args["scale_max"])
	if args.has("damping_min"):
		mat.damping_min = float(args["damping_min"])
	if args.has("damping_max"):
		mat.damping_max = float(args["damping_max"])
	if args.has("color"):
		mat.color = _parse_color(args["color"])
	if args.has("emission_shape"):
		_apply_emission_shape(mat, str(args["emission_shape"]))
	if args.has("emission_sphere_radius"):
		mat.emission_sphere_radius = float(args["emission_sphere_radius"])
	if args.has("emission_box_extents"):
		mat.emission_box_extents = _parse_vector3(args["emission_box_extents"], Vector3.ONE)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set ParticleProcessMaterial on '%s'" % node_path)
	ur.add_do_property(node, "process_material", mat)
	ur.add_undo_property(node, "process_material", old_mat)
	ur.commit_action()

	return {
		"success":         true,
		"node_path":       node_path,
		"material":        "ParticleProcessMaterial",
		"emission_shape":  _emission_shape_name(mat.emission_shape),
	}

func _set_particle_gradient(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not _is_particle_node(node):
		return {"error": "Node '%s' is not a GPUParticles node (got %s)" % [node_path, node.get_class()]}

	var old_mat = node.get("process_material")
	if not old_mat is ParticleProcessMaterial:
		return {"error": "Node '%s' has no ParticleProcessMaterial. Call set_particle_material first." % node_path}

	var colors_arr: Array = args.get("colors", [])
	if colors_arr.is_empty():
		return {"error": "'colors' array is required. Each entry: {\"offset\": 0.0, \"color\": \"#rrggbb\"}"}

	# Build gradient using packed arrays — avoids Gradient's minimum-point constraint
	var g_offsets := PackedFloat32Array()
	var g_colors  := PackedColorArray()
	for point_info in colors_arr:
		if not point_info is Dictionary:
			continue
		g_offsets.append(float(point_info.get("offset", 0.0)))
		g_colors.append(_parse_color(point_info.get("color", "#ffffff")))
	if g_offsets.size() < 2:
		return {"error": "'colors' must contain at least 2 valid entries"}
	var gradient := Gradient.new()
	gradient.offsets = g_offsets
	gradient.colors  = g_colors

	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient

	var gradient_property: String = args.get("gradient_type", "color_ramp")
	if gradient_property not in ["color_ramp", "color_initial_ramp"]:
		return {"error": "Invalid gradient_type '%s'. Valid values: color_ramp, color_initial_ramp" % gradient_property}

	# Duplicate the material so undo fully restores the old state
	var new_mat := (old_mat as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
	new_mat.set(gradient_property, grad_tex)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set particle gradient '%s' on '%s'" % [gradient_property, node_path])
	ur.add_do_property(node, "process_material", new_mat)
	ur.add_undo_property(node, "process_material", old_mat)
	ur.commit_action()

	return {
		"success":        true,
		"node_path":      node_path,
		"gradient_type":  gradient_property,
		"point_count":    gradient.get_point_count(),
	}

func _load_particle_preset(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var preset: String    = args.get("preset", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	if preset.is_empty():
		return {"error": "'preset' is required. Valid: fire, smoke, sparks, rain, snow, explosion, magic"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not _is_particle_node(node):
		return {"error": "Node '%s' is not a GPUParticles node (got %s)" % [node_path, node.get_class()]}

	var old_mat      = node.get("process_material")
	var old_amount   := int(node.get("amount"))
	var old_lifetime := float(node.get("lifetime"))
	var old_one_shot := bool(node.get("one_shot"))

	var mat := ParticleProcessMaterial.new()
	var new_amount: int     = 100
	var new_lifetime: float = 1.0
	var new_one_shot: bool  = false

	match preset:
		"fire":
			mat.direction            = Vector3(0, 1, 0)
			mat.spread               = 15.0
			mat.gravity              = Vector3(0, -0.5, 0)
			mat.initial_velocity_min = 2.0
			mat.initial_velocity_max = 4.0
			mat.scale_min            = 0.1
			mat.scale_max            = 0.3
			mat.color                = Color(1.0, 0.5, 0.0, 1.0)
			mat.damping_min          = 0.5
			mat.damping_max          = 1.0
			new_amount  = 150
			new_lifetime = 0.8
		"smoke":
			mat.direction            = Vector3(0, 1, 0)
			mat.spread               = 30.0
			mat.gravity              = Vector3(0, 0.1, 0)
			mat.initial_velocity_min = 0.5
			mat.initial_velocity_max = 1.5
			mat.scale_min            = 0.5
			mat.scale_max            = 2.0
			mat.color                = Color(0.5, 0.5, 0.5, 0.3)
			new_amount  = 80
			new_lifetime = 3.0
		"sparks":
			mat.direction            = Vector3(0, 1, 0)
			mat.spread               = 60.0
			mat.gravity              = Vector3(0, -9.8, 0)
			mat.initial_velocity_min = 3.0
			mat.initial_velocity_max = 8.0
			mat.scale_min            = 0.05
			mat.scale_max            = 0.15
			mat.color                = Color(1.0, 0.9, 0.2, 1.0)
			new_amount  = 200
			new_lifetime = 0.5
		"rain":
			mat.direction            = Vector3(0, -1, 0)
			mat.spread               = 5.0
			mat.gravity              = Vector3(0, -9.8, 0)
			mat.initial_velocity_min = 8.0
			mat.initial_velocity_max = 12.0
			mat.scale_min            = 0.02
			mat.scale_max            = 0.05
			mat.color                = Color(0.7, 0.8, 1.0, 0.6)
			new_amount  = 300
			new_lifetime = 1.5
		"snow":
			mat.direction            = Vector3(0, -1, 0)
			mat.spread               = 20.0
			mat.gravity              = Vector3(0.2, -2.0, 0)
			mat.initial_velocity_min = 0.5
			mat.initial_velocity_max = 1.5
			mat.scale_min            = 0.05
			mat.scale_max            = 0.2
			mat.color                = Color(1.0, 1.0, 1.0, 0.9)
			new_amount  = 200
			new_lifetime = 4.0
		"explosion":
			mat.direction            = Vector3(0, 0, 0)
			mat.spread               = 180.0
			mat.gravity              = Vector3(0, -4.0, 0)
			mat.initial_velocity_min = 5.0
			mat.initial_velocity_max = 15.0
			mat.scale_min            = 0.1
			mat.scale_max            = 0.5
			mat.color                = Color(1.0, 0.3, 0.0, 1.0)
			mat.damping_min          = 2.0
			mat.damping_max          = 5.0
			new_amount   = 300
			new_lifetime = 0.5
			new_one_shot = true
		"magic":
			mat.direction              = Vector3(0, 1, 0)
			mat.spread                 = 90.0
			mat.gravity                = Vector3(0, 0.5, 0)
			mat.initial_velocity_min   = 1.0
			mat.initial_velocity_max   = 3.0
			mat.angular_velocity_min   = -90.0
			mat.angular_velocity_max   = 90.0
			mat.scale_min              = 0.05
			mat.scale_max              = 0.2
			mat.color                  = Color(0.8, 0.3, 1.0, 0.9)
			new_amount  = 100
			new_lifetime = 2.0
		_:
			return {"error": "Unknown preset '%s'. Valid: fire, smoke, sparks, rain, snow, explosion, magic" % preset}

	var ur := _plugin.get_undo_redo()
	ur.create_action("Load particle preset '%s' on '%s'" % [preset, node_path])
	ur.add_do_property(node, "process_material", mat)
	ur.add_do_property(node, "amount",   new_amount)
	ur.add_do_property(node, "lifetime", new_lifetime)
	ur.add_do_property(node, "one_shot", new_one_shot)
	ur.add_undo_property(node, "process_material", old_mat)
	ur.add_undo_property(node, "amount",   old_amount)
	ur.add_undo_property(node, "lifetime", old_lifetime)
	ur.add_undo_property(node, "one_shot", old_one_shot)
	ur.commit_action()

	return {
		"success":   true,
		"node_path": node_path,
		"preset":    preset,
		"amount":    new_amount,
		"lifetime":  new_lifetime,
		"one_shot":  new_one_shot,
	}

func _get_particle_info(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not _is_particle_node(node):
		return {"error": "Node '%s' is not a GPUParticles node (got %s)" % [node_path, node.get_class()]}

	var info: Dictionary = {
		"node_path":      node_path,
		"type":           node.get_class(),
		"dimension":      "3d" if node is GPUParticles3D else "2d",
		"amount":         node.get("amount"),
		"lifetime":       node.get("lifetime"),
		"emitting":       node.get("emitting"),
		"one_shot":       node.get("one_shot"),
		"explosiveness":  node.get("explosiveness"),
		"speed_scale":    node.get("speed_scale"),
	}

	var mat = node.get("process_material")
	if mat is ParticleProcessMaterial:
		var pm := mat as ParticleProcessMaterial
		info["material"] = {
			"type":                "ParticleProcessMaterial",
			"direction":           {"x": pm.direction.x, "y": pm.direction.y, "z": pm.direction.z},
			"spread":              pm.spread,
			"gravity":             {"x": pm.gravity.x, "y": pm.gravity.y, "z": pm.gravity.z},
			"initial_velocity_min": pm.initial_velocity_min,
			"initial_velocity_max": pm.initial_velocity_max,
			"scale_min":           pm.scale_min,
			"scale_max":           pm.scale_max,
			"color":               {"r": pm.color.r, "g": pm.color.g, "b": pm.color.b, "a": pm.color.a},
			"emission_shape":      _emission_shape_name(pm.emission_shape),
			"has_color_ramp":         pm.get("color_ramp") != null,
			"has_color_initial_ramp": pm.get("color_initial_ramp") != null,
		}
	elif mat != null:
		info["material"] = {"type": mat.get_class()}
	else:
		info["material"] = null

	return info
