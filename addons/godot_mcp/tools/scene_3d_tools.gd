@tool
extends GodotMCPToolBase

class_name GodotMCP3DSceneTools

## Implements 6 3D Scene tools: add_mesh, add_camera, add_light,
## set_environment, add_gridmap, get_3d_scene_info.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("add_mesh",          GodotMCPCallableTool.new(_add_mesh))
	registry.register_tool("add_camera",        GodotMCPCallableTool.new(_add_camera))
	registry.register_tool("add_light",         GodotMCPCallableTool.new(_add_light))
	registry.register_tool("set_environment",   GodotMCPCallableTool.new(_set_environment))
	registry.register_tool("add_gridmap",       GodotMCPCallableTool.new(_add_gridmap))
	registry.register_tool("get_3d_scene_info", GodotMCPCallableTool.new(_get_3d_scene_info))
func _property_type(obj: Object, prop_name: String) -> int:
	for prop in obj.get_property_list():
		if prop.get("name", "") == prop_name:
			return int(prop.get("type", TYPE_NIL))
	return -1

## JSON values arrive as float/string, so a Vector3 property would otherwise be
## assigned a number and quietly keep its old value.
func _coerce(value: Variant, prop_type: int) -> Variant:
	match prop_type:
		TYPE_VECTOR3: return GodotMCPTypeUtils.to_vector3(value)
		TYPE_VECTOR2: return GodotMCPTypeUtils.to_vector2(value)
		TYPE_FLOAT:   return float(value)
		TYPE_INT:     return int(value)
		TYPE_BOOL:    return _as_bool(value)
	return value
func _readable(value: Variant) -> Variant:
	if value is Vector3: return {"x": value.x, "y": value.y, "z": value.z}
	if value is Vector2: return {"x": value.x, "y": value.y}
	return value
func _find_world_environment(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		return node as WorldEnvironment
	for child in node.get_children():
		var found := _find_world_environment(child)
		if found != null:
			return found
	return null

## Recursively collect Node3D entries into `out`.
## depth counts Node3D levels only; non-3D wrapper nodes are transparent and
## do not consume the depth budget.
func _collect_3d_nodes(node: Node, root: Node, out: Array, depth: int) -> void:
	if node is Node3D:
		if depth <= 0:
			return
		var n3d := node as Node3D
		var entry: Dictionary = {
			"name":     node.name,
			"path":     str(root.get_path_to(node)),
			"type":     node.get_class(),
			"position": {"x": n3d.position.x, "y": n3d.position.y, "z": n3d.position.z},
			"rotation": {"x": n3d.rotation_degrees.x, "y": n3d.rotation_degrees.y, "z": n3d.rotation_degrees.z},
			"scale":    {"x": n3d.scale.x, "y": n3d.scale.y, "z": n3d.scale.z},
			"visible":  n3d.visible,
		}
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			entry["mesh"] = mi.mesh.get_class() if mi.mesh != null else ""
		elif node is Camera3D:
			var cam := node as Camera3D
			entry["fov"] = cam.fov
			entry["current"] = cam.current
			match cam.projection:
				Camera3D.PROJECTION_ORTHOGONAL: entry["projection"] = "orthogonal"
				Camera3D.PROJECTION_FRUSTUM:    entry["projection"] = "frustum"
				_:                              entry["projection"] = "perspective"
		elif node is Light3D:
			var light := node as Light3D
			entry["light_color"]    = {"r": light.light_color.r, "g": light.light_color.g, "b": light.light_color.b}
			entry["light_energy"]   = light.light_energy
			entry["shadow_enabled"] = light.shadow_enabled
		elif node is WorldEnvironment:
			entry["has_environment"] = (node as WorldEnvironment).environment != null
		elif node is GridMap:
			var gm := node as GridMap
			entry["cell_size"]        = {"x": gm.cell_size.x, "y": gm.cell_size.y, "z": gm.cell_size.z}
			entry["has_mesh_library"] = gm.mesh_library != null
		out.append(entry)
		for child in node.get_children():
			_collect_3d_nodes(child, root, out, depth - 1)
	else:
		# Non-3D organizer node: traverse children without spending depth budget.
		for child in node.get_children():
			_collect_3d_nodes(child, root, out, depth)
# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _add_mesh(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var node_name: String   = args.get("node_name", "MeshInstance3D")
	var requested_type: String = str(args.get("mesh_type", "box"))

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	# Accept both "sphere" and "SphereMesh"; an unrecognised type used to fall
	# through to a box, so a typo silently built the wrong shape.
	var mesh_type := requested_type.to_lower()
	if mesh_type.ends_with("mesh"):
		mesh_type = mesh_type.substr(0, mesh_type.length() - 4)

	var mesh: PrimitiveMesh
	match mesh_type:
		"box":      mesh = BoxMesh.new()
		"sphere":   mesh = SphereMesh.new()
		"cylinder": mesh = CylinderMesh.new()
		"plane":    mesh = PlaneMesh.new()
		"capsule":  mesh = CapsuleMesh.new()
		"torus":    mesh = TorusMesh.new()
		"quad":     mesh = QuadMesh.new()
		"prism":    mesh = PrismMesh.new()
		_:
			return {"error": "Unknown mesh_type '%s'. Use box, sphere, cylinder, plane, capsule, torus, quad or prism." % requested_type}

	# Primitives are otherwise born at engine defaults, so anything with a real
	# size had to be finished off in a script afterwards.
	var applied: Dictionary = {}
	var unknown: Array = []
	var mesh_properties: Dictionary = args.get("mesh_properties", {})
	for key in mesh_properties:
		var prop_name: String = str(key)
		var prop_type := _property_type(mesh, prop_name)
		if prop_type == -1:
			unknown.append(prop_name)
			continue
		mesh.set(prop_name, _coerce(mesh_properties[key], prop_type))
		applied[prop_name] = _readable(mesh.get(prop_name))

	var material_note := ""
	if args.has("material"):
		var material_path := str(args["material"])
		var loaded := ResourceLoader.load(material_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if loaded == null or not (loaded is Material):
			return {"error": "Material not found or not a Material: %s" % material_path}
		mesh.material = loaded
		material_note = material_path
	elif args.has("material_color"):
		var standard := StandardMaterial3D.new()
		standard.albedo_color = _parse_color(args["material_color"])
		mesh.material = standard
		material_note = "StandardMaterial3D albedo %s" % standard.albedo_color.to_html()

	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if args.has("position"):
		mi.position = _parse_vector3(args["position"])
	if args.has("rotation"):
		mi.rotation_degrees = _parse_vector3(args["rotation"])
	if args.has("scale"):
		mi.scale = _parse_vector3(args["scale"], Vector3.ONE)

	var result := _add_to_scene(mi, parent, node_name, "Add Mesh '%s'" % node_name)
	result["mesh_type"] = mesh_type
	if not applied.is_empty():
		result["mesh_properties"] = applied
	# A misspelled property would otherwise be dropped without a word.
	if not unknown.is_empty():
		result["unknown_properties"] = unknown
	if not material_note.is_empty():
		result["material"] = material_note
	return result

func _add_camera(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String  = args.get("parent_path", "")
	var node_name: String    = args.get("node_name", "Camera3D")
	var projection_str: String = args.get("projection", "perspective")

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var cam := Camera3D.new()
	cam.fov  = float(args.get("fov",  75.0))
	cam.near = float(args.get("near",  0.05))
	cam.far  = float(args.get("far", 4000.0))
	# The only parameter that frames an orthographic view; fov does nothing there.
	cam.size = float(args.get("size", 1.0))

	match projection_str:
		"orthogonal": cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		"frustum":    cam.projection = Camera3D.PROJECTION_FRUSTUM
		_:
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE
			projection_str = "perspective"

	if args.has("position"):
		cam.position = _parse_vector3(args["position"])
	if args.has("rotation"):
		cam.rotation_degrees = _parse_vector3(args["rotation"])
	if args.has("current"):
		cam.current = bool(args["current"])

	var result := _add_to_scene(cam, parent, node_name, "Add Camera3D '%s'" % node_name)
	result["projection"] = projection_str
	# Report the field that actually governs this projection.
	if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		result["size"] = cam.size
	else:
		result["fov"] = cam.fov
	return result

func _add_light(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var light_type: String  = args.get("light_type", "directional")
	var node_name: String   = args.get("node_name", "")

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var light: Light3D
	var default_name: String
	match light_type:
		"omni":
			light = OmniLight3D.new()
			default_name = "OmniLight3D"
		"spot":
			light = SpotLight3D.new()
			default_name = "SpotLight3D"
		_:
			light = DirectionalLight3D.new()
			default_name = "DirectionalLight3D"
			light_type = "directional"

	if node_name.is_empty():
		node_name = default_name

	light.light_energy = float(args.get("energy", 1.0))
	if args.has("color"):
		light.light_color = _parse_color(args["color"])
	if args.has("cast_shadow"):
		light.shadow_enabled = bool(args["cast_shadow"])
	if args.has("position"):
		light.position = _parse_vector3(args["position"])
	if args.has("rotation"):
		light.rotation_degrees = _parse_vector3(args["rotation"])

	var result := _add_to_scene(light, parent, node_name, "Add Light3D '%s'" % node_name)
	result["light_type"] = light_type
	return result

func _set_environment(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var we_path: String = args.get("node_path", "")
	var we: WorldEnvironment
	var created_new := false

	if not we_path.is_empty():
		var node = _resolve_node(we_path)
		if node == null:
			return {"error": "Node not found: %s" % we_path}
		if not node is WorldEnvironment:
			return {"error": "Node is not a WorldEnvironment (got %s)" % node.get_class()}
		we = node as WorldEnvironment
	else:
		we = _find_world_environment(root)
		if we == null:
			we = WorldEnvironment.new()
			we.name = args.get("node_name", "WorldEnvironment")
			created_new = true

	# Duplicate existing Environment or create fresh
	var old_env: Environment = we.environment if is_instance_valid(we) and we.environment != null else null
	var new_env: Environment = (old_env.duplicate() as Environment) if old_env != null else Environment.new()

	# Apply background
	var bg_mode: String = args.get("background_mode", "")
	if not bg_mode.is_empty():
		match bg_mode:
			"color":       new_env.background_mode = Environment.BG_COLOR
			"sky":         new_env.background_mode = Environment.BG_SKY
			"canvas":      new_env.background_mode = Environment.BG_CANVAS
			"keep":        new_env.background_mode = Environment.BG_KEEP
			"camera_feed": new_env.background_mode = Environment.BG_CAMERA_FEED
			_:             new_env.background_mode = Environment.BG_CLEAR_COLOR

	if args.has("background_color"):
		new_env.background_color = _parse_color(args["background_color"])
	if args.has("background_energy"):
		new_env.background_energy_multiplier = float(args["background_energy"])
	if args.has("ambient_light_color"):
		new_env.ambient_light_color = _parse_color(args["ambient_light_color"])
	if args.has("ambient_light_energy"):
		new_env.ambient_light_energy = float(args["ambient_light_energy"])
	if args.has("fog_enabled"):
		new_env.fog_enabled = bool(args["fog_enabled"])
	if args.has("fog_density"):
		new_env.fog_density = float(args["fog_density"])

	var tonemap: String = args.get("tonemap_mode", "")
	if not tonemap.is_empty():
		match tonemap:
			"reinhard": new_env.tonemap_mode = Environment.TONE_MAPPER_REINHARDT
			"filmic":   new_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
			"aces":     new_env.tonemap_mode = Environment.TONE_MAPPER_ACES
			_:          new_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR

	var ur := _plugin.get_undo_redo()
	if created_new:
		ur.create_action("Add WorldEnvironment")
		ur.add_do_method(root, "add_child", we, true)
		ur.add_do_property(we, "environment", new_env)
		ur.add_do_property(we, "owner", root)
		ur.add_do_reference(we)
		ur.add_undo_method(root, "remove_child", we)
		ur.add_undo_reference(we)
		ur.commit_action()
	else:
		ur.create_action("Set WorldEnvironment properties")
		ur.add_do_property(we, "environment", new_env)
		ur.add_undo_property(we, "environment", old_env)
		ur.commit_action()

	return {
		"success": true,
		"created": created_new,
		"node_path": str(root.get_path_to(we)),
		"background_mode": bg_mode if not bg_mode.is_empty() else "unchanged",
	}

func _add_gridmap(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var node_name: String   = args.get("node_name", "GridMap")

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var gm := GridMap.new()
	if args.has("cell_size"):
		gm.cell_size = _parse_vector3(args["cell_size"], Vector3.ONE)
	if args.has("position"):
		gm.position = _parse_vector3(args["position"])

	var mesh_lib_path: String = args.get("mesh_library", "")
	if not mesh_lib_path.is_empty():
		var lib = load(mesh_lib_path)
		if lib == null:
			return {"error": "Failed to load MeshLibrary from: %s" % mesh_lib_path}
		if not lib is MeshLibrary:
			return {"error": "Resource at '%s' is not a MeshLibrary" % mesh_lib_path}
		gm.mesh_library = lib as MeshLibrary

	var result := _add_to_scene(gm, parent, node_name, "Add GridMap '%s'" % node_name)
	result["cell_size"] = {"x": gm.cell_size.x, "y": gm.cell_size.y, "z": gm.cell_size.z}
	return result

func _get_3d_scene_info(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var scan_path: String = args.get("node_path", "")
	var scan_root: Node
	if scan_path.is_empty():
		scan_root = root
	else:
		scan_root = _resolve_node(scan_path)
		if scan_root == null:
			return {"error": "Node not found: %s" % scan_path}

	var max_depth: int = int(args.get("depth", 64))
	var nodes: Array = []
	_collect_3d_nodes(scan_root, root, nodes, max_depth)

	return {
		"scene_name":    root.name,
		"node_count_3d": nodes.size(),
		"nodes":         nodes,
	}
