@tool
extends GodotMCPToolBase

class_name GodotMCPPhysicsTools

## Implements 6 Physics tools: add_rigid_body, add_collision_shape,
## set_collision_layer, set_collision_mask, add_raycast, get_physics_info.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("add_rigid_body",      GodotMCPCallableTool.new(_add_rigid_body))
	registry.register_tool("add_collision_shape", GodotMCPCallableTool.new(_add_collision_shape))
	registry.register_tool("set_collision_layer", GodotMCPCallableTool.new(_set_collision_layer))
	registry.register_tool("set_collision_mask",  GodotMCPCallableTool.new(_set_collision_mask))
	registry.register_tool("add_raycast",         GodotMCPCallableTool.new(_add_raycast))
	registry.register_tool("get_physics_info",    GodotMCPCallableTool.new(_get_physics_info))
func _parse_layer_mask(val: Variant) -> int:
	if val is int:
		return val
	if val is float:
		return int(val)
	if val is Array:
		var mask: int = 0
		for item in val:
			var layer := int(item)
			if layer >= 1 and layer <= 32:
				mask |= (1 << (layer - 1))
		return mask
	return 0

## Return list of 1-based layer numbers that are set in the bitmask.
func _mask_to_layers(mask: int) -> Array:
	var layers: Array = []
	for i in range(32):
		if mask & (1 << i):
			layers.append(i + 1)
	return layers
func _add_rigid_body(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var body_type: String   = args.get("body_type", "rigid")
	var dimension: String   = args.get("dimension", "3d")
	var node_name: String   = args.get("node_name", "")

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var body: Node
	var default_name: String

	if dimension == "2d":
		match body_type:
			"static":
				body = StaticBody2D.new()
				default_name = "StaticBody2D"
			"character":
				body = CharacterBody2D.new()
				default_name = "CharacterBody2D"
			"animatable":
				body = AnimatableBody2D.new()
				default_name = "AnimatableBody2D"
			_:
				body = RigidBody2D.new()
				default_name = "RigidBody2D"
				body_type = "rigid"
	else:
		match body_type:
			"static":
				body = StaticBody3D.new()
				default_name = "StaticBody3D"
			"character":
				body = CharacterBody3D.new()
				default_name = "CharacterBody3D"
			"animatable":
				body = AnimatableBody3D.new()
				default_name = "AnimatableBody3D"
			_:
				body = RigidBody3D.new()
				default_name = "RigidBody3D"
				body_type = "rigid"
		dimension = "3d"

	if node_name.is_empty():
		node_name = default_name

	# Mass / gravity_scale (rigid bodies only)
	if body is RigidBody3D:
		(body as RigidBody3D).mass          = float(args.get("mass", 1.0))
		(body as RigidBody3D).gravity_scale = float(args.get("gravity_scale", 1.0))
	elif body is RigidBody2D:
		(body as RigidBody2D).mass          = float(args.get("mass", 1.0))
		(body as RigidBody2D).gravity_scale = float(args.get("gravity_scale", 1.0))

	# Transform
	if body is Node3D:
		if args.has("position"):
			(body as Node3D).position = _parse_vector3(args["position"])
		if args.has("rotation"):
			(body as Node3D).rotation_degrees = _parse_vector3(args["rotation"])
	elif body is Node2D:
		if args.has("position"):
			(body as Node2D).position = _parse_vector2(args["position"])
		if args.has("rotation"):
			var rot_val = args["rotation"]
			if rot_val is Dictionary:
				(body as Node2D).rotation_degrees = float(rot_val.get("z", 0.0))
			else:
				(body as Node2D).rotation_degrees = float(rot_val)

	# Collision layer / mask
	if args.has("collision_layer"):
		body.set("collision_layer", _parse_layer_mask(args["collision_layer"]))
	if args.has("collision_mask"):
		body.set("collision_mask", _parse_layer_mask(args["collision_mask"]))

	var result := _add_to_scene(body, parent, node_name, "Add %s '%s'" % [default_name, node_name])
	result["body_type"] = body_type
	result["dimension"] = dimension
	return result

func _add_collision_shape(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var shape_type: String  = args.get("shape_type", "box")
	var dimension: String   = args.get("dimension", "3d")
	var node_name: String   = args.get("node_name", "")

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var cs: Node

	# Reject clearly cross-dimension shape types before entering the match
	var _invalid_for_2d := ["sphere", "cylinder"]
	var _invalid_for_3d := ["rectangle", "circle", "segment"]
	if dimension == "2d" and shape_type in _invalid_for_2d:
		return {"error": "shape_type '%s' is only valid for dimension='3d'. Valid 2D shapes: rectangle, circle, capsule, segment" % shape_type}
	if dimension == "3d" and shape_type in _invalid_for_3d:
		return {"error": "shape_type '%s' is only valid for dimension='2d'. Valid 3D shapes: box, sphere, capsule, cylinder" % shape_type}

	if dimension == "2d":
		var shape: Shape2D
		match shape_type:
			"circle":
				var s := CircleShape2D.new()
				s.radius = float(args.get("radius", 10.0))
				shape = s
			"capsule":
				var s := CapsuleShape2D.new()
				s.radius = float(args.get("radius", 10.0))
				s.height = float(args.get("height", 30.0))
				shape = s
			"segment":
				var s := SegmentShape2D.new()
				s.a = _parse_vector2(args.get("point_a", {}), Vector2(-10.0, 0.0))
				s.b = _parse_vector2(args.get("point_b", {}), Vector2(10.0, 0.0))
				shape = s
			_:
				var s := RectangleShape2D.new()
				s.size = _parse_vector2(args.get("size", {}), Vector2(20.0, 20.0))
				shape = s
				shape_type = "rectangle"

		var cs2 := CollisionShape2D.new()
		cs2.shape = shape
		if args.has("position"):
			cs2.position = _parse_vector2(args["position"])
		if node_name.is_empty():
			node_name = "CollisionShape2D"
		cs = cs2
	else:
		var shape: Shape3D
		match shape_type:
			"sphere":
				var s := SphereShape3D.new()
				s.radius = float(args.get("radius", 0.5))
				shape = s
			"capsule":
				var s := CapsuleShape3D.new()
				s.radius = float(args.get("radius", 0.5))
				s.height = float(args.get("height", 2.0))
				shape = s
			"cylinder":
				var s := CylinderShape3D.new()
				s.radius = float(args.get("radius", 0.5))
				s.height = float(args.get("height", 2.0))
				shape = s
			_:
				var s := BoxShape3D.new()
				s.size = _parse_vector3(args.get("size", {}), Vector3.ONE)
				shape = s
				shape_type = "box"

		var cs3 := CollisionShape3D.new()
		cs3.shape = shape
		if args.has("position"):
			cs3.position = _parse_vector3(args["position"])
		if args.has("rotation"):
			cs3.rotation_degrees = _parse_vector3(args["rotation"])
		if node_name.is_empty():
			node_name = "CollisionShape3D"
		cs = cs3

	var result := _add_to_scene(cs, parent, node_name, "Add CollisionShape '%s'" % node_name)
	result["shape_type"] = shape_type
	result["dimension"]  = dimension
	return result

func _set_collision_layer(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	if not "collision_layer" in node:
		return {"error": "Node '%s' has no collision_layer property (got %s)" % [node_path, node.get_class()]}

	if not args.has("layers"):
		return {"error": "'layers' is required (int bitmask or Array of 1-based layer numbers)"}

	var old_layer: int = node.get("collision_layer")
	var new_layer: int = _parse_layer_mask(args["layers"])

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set collision_layer on '%s'" % node_path)
	ur.add_do_property(node, "collision_layer", new_layer)
	ur.add_undo_property(node, "collision_layer", old_layer)
	ur.commit_action()

	return {
		"success":       true,
		"node_path":     node_path,
		"collision_layer": new_layer,
		"active_layers": _mask_to_layers(new_layer),
	}

func _set_collision_mask(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	if not "collision_mask" in node:
		return {"error": "Node '%s' has no collision_mask property (got %s)" % [node_path, node.get_class()]}

	if not args.has("layers"):
		return {"error": "'layers' is required (int bitmask or Array of 1-based layer numbers)"}

	var old_mask: int = node.get("collision_mask")
	var new_mask: int = _parse_layer_mask(args["layers"])

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set collision_mask on '%s'" % node_path)
	ur.add_do_property(node, "collision_mask", new_mask)
	ur.add_undo_property(node, "collision_mask", old_mask)
	ur.commit_action()

	return {
		"success":        true,
		"node_path":      node_path,
		"collision_mask": new_mask,
		"active_layers":  _mask_to_layers(new_mask),
	}

func _add_raycast(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var dimension: String   = args.get("dimension", "3d")
	var node_name: String   = args.get("node_name", "")
	var enabled: bool       = bool(args.get("enabled", true))
	var col_mask: int       = _parse_layer_mask(args.get("collision_mask", 1))

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var result: Dictionary

	if dimension == "2d":
		var rc := RayCast2D.new()
		rc.enabled         = enabled
		rc.collision_mask  = col_mask
		rc.target_position = _parse_vector2(args.get("target_position", {}), Vector2(0.0, 100.0))
		if args.has("position"):
			rc.position = _parse_vector2(args["position"])
		if node_name.is_empty():
			node_name = "RayCast2D"
		result = _add_to_scene(rc, parent, node_name, "Add RayCast2D '%s'" % node_name)
		result["target_position"] = {"x": rc.target_position.x, "y": rc.target_position.y}
	else:
		var rc := RayCast3D.new()
		rc.enabled         = enabled
		rc.collision_mask  = col_mask
		rc.target_position = _parse_vector3(args.get("target_position", {}), Vector3(0.0, -1.0, 0.0))
		if args.has("position"):
			rc.position = _parse_vector3(args["position"])
		if node_name.is_empty():
			node_name = "RayCast3D"
		result = _add_to_scene(rc, parent, node_name, "Add RayCast3D '%s'" % node_name)
		result["target_position"] = {"x": rc.target_position.x, "y": rc.target_position.y, "z": rc.target_position.z}

	result["dimension"]      = dimension
	result["enabled"]        = enabled
	result["collision_mask"] = col_mask
	return result

func _get_physics_info(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	var info: Dictionary = {
		"node_path": node_path,
		"type":      node.get_class(),
	}

	# Collision layer / mask (CollisionObject3D/2D or RayCast)
	if "collision_layer" in node:
		var layer: int = node.get("collision_layer")
		info["collision_layer"]      = layer
		info["collision_layer_list"] = _mask_to_layers(layer)
	if "collision_mask" in node:
		var mask: int = node.get("collision_mask")
		info["collision_mask"]      = mask
		info["collision_mask_list"] = _mask_to_layers(mask)

	# Type-specific properties
	if node is RigidBody3D:
		var rb := node as RigidBody3D
		info["mass"]             = rb.mass
		info["gravity_scale"]    = rb.gravity_scale
		info["linear_velocity"]  = {"x": rb.linear_velocity.x,  "y": rb.linear_velocity.y,  "z": rb.linear_velocity.z}
		info["angular_velocity"] = {"x": rb.angular_velocity.x, "y": rb.angular_velocity.y, "z": rb.angular_velocity.z}
	elif node is RigidBody2D:
		var rb := node as RigidBody2D
		info["mass"]             = rb.mass
		info["gravity_scale"]    = rb.gravity_scale
		info["linear_velocity"]  = {"x": rb.linear_velocity.x, "y": rb.linear_velocity.y}
		info["angular_velocity"] = {"z": rb.angular_velocity}
	elif node is RayCast3D:
		var rc := node as RayCast3D
		info["enabled"]          = rc.enabled
		info["target_position"]  = {"x": rc.target_position.x, "y": rc.target_position.y, "z": rc.target_position.z}
		rc.force_raycast_update()
		info["is_colliding"]     = rc.is_colliding()
	elif node is RayCast2D:
		var rc := node as RayCast2D
		info["enabled"]          = rc.enabled
		info["target_position"]  = {"x": rc.target_position.x, "y": rc.target_position.y}
		rc.force_raycast_update()
		info["is_colliding"]     = rc.is_colliding()

	# Collect child CollisionShape nodes (one level deep)
	var shapes: Array = []
	for child in node.get_children():
		if child is CollisionShape3D:
			var cs := child as CollisionShape3D
			var se: Dictionary = {
				"name":     child.name,
				"path":     str(node.get_path_to(child)),
				"disabled": cs.disabled,
			}
			if cs.shape != null:
				se["shape_type"] = cs.shape.get_class()
				if cs.shape is BoxShape3D:
					var s := cs.shape as BoxShape3D
					se["size"] = {"x": s.size.x, "y": s.size.y, "z": s.size.z}
				elif cs.shape is SphereShape3D:
					se["radius"] = (cs.shape as SphereShape3D).radius
				elif cs.shape is CapsuleShape3D:
					var s := cs.shape as CapsuleShape3D
					se["radius"] = s.radius
					se["height"] = s.height
				elif cs.shape is CylinderShape3D:
					var s := cs.shape as CylinderShape3D
					se["radius"] = s.radius
					se["height"] = s.height
			shapes.append(se)
		elif child is CollisionShape2D:
			var cs := child as CollisionShape2D
			var se: Dictionary = {
				"name":     child.name,
				"path":     str(node.get_path_to(child)),
				"disabled": cs.disabled,
			}
			if cs.shape != null:
				se["shape_type"] = cs.shape.get_class()
				if cs.shape is RectangleShape2D:
					var s := cs.shape as RectangleShape2D
					se["size"] = {"x": s.size.x, "y": s.size.y}
				elif cs.shape is CircleShape2D:
					se["radius"] = (cs.shape as CircleShape2D).radius
				elif cs.shape is CapsuleShape2D:
					var s := cs.shape as CapsuleShape2D
					se["radius"] = s.radius
					se["height"] = s.height
			shapes.append(se)

	info["collision_shapes"]      = shapes
	info["collision_shape_count"] = shapes.size()

	return info
