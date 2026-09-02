@tool
extends GodotMCPToolBase

class_name GodotMCPNavigationTools

## Implements 6 Navigation tools: add_navigation_region, add_navigation_agent,
## bake_navigation, set_navigation_layer, get_navigation_path, get_navigation_info.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("add_navigation_region", GodotMCPCallableTool.new(_add_navigation_region))
	registry.register_tool("add_navigation_agent",  GodotMCPCallableTool.new(_add_navigation_agent))
	registry.register_tool("bake_navigation",       GodotMCPCallableTool.new(_bake_navigation))
	registry.register_tool("set_navigation_layer",  GodotMCPCallableTool.new(_set_navigation_layer))
	registry.register_tool("get_navigation_path",   GodotMCPCallableTool.new(_get_navigation_path))
	registry.register_tool("get_navigation_info",   GodotMCPCallableTool.new(_get_navigation_info))
func _parse_layers(val: Variant, default_val: int = 1) -> int:
	if val is int:   return val
	if val is float: return int(val)
	if val is Array:
		var mask := 0
		for layer in val:
			var n := int(layer)
			if n >= 1 and n <= 32:
				mask |= (1 << (n - 1))
		return mask
	return default_val
func _is_navigation_node(node: Node) -> bool:
	return (node is NavigationRegion3D or node is NavigationRegion2D or
			node is NavigationAgent3D   or node is NavigationAgent2D)

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _add_navigation_region(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var node_name: String   = args.get("node_name", "")
	var dimension: String   = args.get("dimension", "3d")
	var nav_layers: int     = _parse_layers(args.get("navigation_layers", 1))

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var region: Node
	if dimension == "2d":
		var r := NavigationRegion2D.new()
		r.navigation_polygon = NavigationPolygon.new()
		r.navigation_layers  = nav_layers
		if node_name.is_empty():
			node_name = "NavigationRegion2D"
		region = r
	else:
		var r := NavigationRegion3D.new()
		r.navigation_mesh   = NavigationMesh.new()
		r.navigation_layers = nav_layers
		if node_name.is_empty():
			node_name = "NavigationRegion3D"
		region = r
		dimension = "3d"

	var result := _add_to_scene(region, parent, node_name, "Add Navigation Region '%s'" % node_name)
	result["dimension"]         = dimension
	result["navigation_layers"] = nav_layers
	return result

func _add_navigation_agent(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path: String = args.get("parent_path", "")
	var node_name: String   = args.get("node_name", "")
	var dimension: String   = args.get("dimension", "3d")
	var nav_layers: int     = _parse_layers(args.get("navigation_layers", 1))

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var agent: Node
	if dimension == "2d":
		var a := NavigationAgent2D.new()
		a.navigation_layers = nav_layers
		if args.has("max_speed"):
			a.max_speed = float(args["max_speed"])
		if args.has("path_desired_distance"):
			a.path_desired_distance = float(args["path_desired_distance"])
		if args.has("target_desired_distance"):
			a.target_desired_distance = float(args["target_desired_distance"])
		if node_name.is_empty():
			node_name = "NavigationAgent2D"
		agent = a
	else:
		var a := NavigationAgent3D.new()
		a.navigation_layers = nav_layers
		if args.has("max_speed"):
			a.max_speed = float(args["max_speed"])
		if args.has("path_desired_distance"):
			a.path_desired_distance = float(args["path_desired_distance"])
		if args.has("target_desired_distance"):
			a.target_desired_distance = float(args["target_desired_distance"])
		if node_name.is_empty():
			node_name = "NavigationAgent3D"
		agent = a
		dimension = "3d"

	var result := _add_to_scene(agent, parent, node_name, "Add Navigation Agent '%s'" % node_name)
	result["dimension"]         = dimension
	result["navigation_layers"] = nav_layers
	return result

func _bake_navigation(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}

	if node is NavigationRegion3D:
		var region := node as NavigationRegion3D
		if region.navigation_mesh == null:
			region.navigation_mesh = NavigationMesh.new()
		region.bake_navigation_mesh(false)
		return {
			"success":   true,
			"node_path": node_path,
			"type":      "NavigationRegion3D",
		}
	elif node is NavigationRegion2D:
		var region := node as NavigationRegion2D
		if region.navigation_polygon == null:
			region.navigation_polygon = NavigationPolygon.new()
		region.bake_navigation_polygon(false)
		return {
			"success":   true,
			"node_path": node_path,
			"type":      "NavigationRegion2D",
		}
	else:
		return {"error": "Node '%s' is not a NavigationRegion (got %s). Provide a path to NavigationRegion3D or NavigationRegion2D." % [node_path, node.get_class()]}

func _set_navigation_layer(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	if not args.has("navigation_layers"):
		return {"error": "'navigation_layers' is required (integer bitmask or array of layer numbers 1–32)"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not _is_navigation_node(node):
		return {"error": "Node '%s' does not support navigation_layers (got %s)" % [node_path, node.get_class()]}

	var new_layers: int = _parse_layers(args["navigation_layers"])
	var old_layers: int = int(node.get("navigation_layers"))

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set navigation_layers on '%s'" % node_path)
	ur.add_do_property(node, "navigation_layers", new_layers)
	ur.add_undo_property(node, "navigation_layers", old_layers)
	ur.commit_action()

	return {
		"success":           true,
		"node_path":         node_path,
		"navigation_layers": new_layers,
	}

func _get_navigation_path(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}
	if not args.has("from"):
		return {"error": "'from' is required (start position)"}
	if not args.has("to"):
		return {"error": "'to' is required (target position)"}

	var dimension: String = args.get("dimension", "3d")
	var nav_layers: int   = _parse_layers(args.get("navigation_layers", 1))

	if dimension == "2d":
		var from_pos := _parse_vector2(args["from"])
		var to_pos   := _parse_vector2(args["to"])
		var map_rid: RID = root.get_viewport().get_world_2d().get_navigation_map()
		var path: PackedVector2Array = NavigationServer2D.map_get_path(map_rid, from_pos, to_pos, true, nav_layers)
		var points: Array = []
		for p in path:
			points.append({"x": p.x, "y": p.y})
		return {
			"success":     true,
			"dimension":   "2d",
			"from":        {"x": from_pos.x, "y": from_pos.y},
			"to":          {"x": to_pos.x, "y": to_pos.y},
			"point_count": points.size(),
			"path":        points,
		}
	else:
		var from_pos := _parse_vector3(args["from"])
		var to_pos   := _parse_vector3(args["to"])
		var map_rid: RID = root.get_viewport().get_world_3d().get_navigation_map()
		var path: PackedVector3Array = NavigationServer3D.map_get_path(map_rid, from_pos, to_pos, true, nav_layers)
		var points: Array = []
		for p in path:
			points.append({"x": p.x, "y": p.y, "z": p.z})
		return {
			"success":     true,
			"dimension":   "3d",
			"from":        {"x": from_pos.x, "y": from_pos.y, "z": from_pos.z},
			"to":          {"x": to_pos.x, "y": to_pos.y, "z": to_pos.z},
			"point_count": points.size(),
			"path":        points,
		}

func _get_navigation_info(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")

	if not node_path.is_empty():
		var node = _resolve_node(node_path)
		if node == null:
			return {"error": "Node not found: %s" % node_path}

		var info: Dictionary = {"node_path": node_path, "type": node.get_class()}

		if node is NavigationRegion3D:
			var r := node as NavigationRegion3D
			info["navigation_layers"]  = r.navigation_layers
			info["enabled"]            = r.enabled
			if r.navigation_mesh != null:
				info["has_navigation_mesh"] = true
				info["cell_size"]    = r.navigation_mesh.cell_size
				info["cell_height"]  = r.navigation_mesh.cell_height
				info["agent_height"] = r.navigation_mesh.agent_height
				info["agent_radius"] = r.navigation_mesh.agent_radius
			else:
				info["has_navigation_mesh"] = false
		elif node is NavigationRegion2D:
			var r := node as NavigationRegion2D
			info["navigation_layers"]     = r.navigation_layers
			info["enabled"]               = r.enabled
			info["has_navigation_polygon"] = r.navigation_polygon != null
		elif node is NavigationAgent3D:
			var a := node as NavigationAgent3D
			info["navigation_layers"]        = a.navigation_layers
			info["max_speed"]                = a.max_speed
			info["path_desired_distance"]    = a.path_desired_distance
			info["target_desired_distance"]  = a.target_desired_distance
			info["avoidance_enabled"]        = a.get("avoidance_enabled")
		elif node is NavigationAgent2D:
			var a := node as NavigationAgent2D
			info["navigation_layers"]        = a.navigation_layers
			info["max_speed"]                = a.max_speed
			info["path_desired_distance"]    = a.path_desired_distance
			info["target_desired_distance"]  = a.target_desired_distance
			info["avoidance_enabled"]        = a.get("avoidance_enabled")
		else:
			return {"error": "Node '%s' is not a navigation node (got %s)" % [node_path, node.get_class()]}

		return info

	# Scene-wide scan
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var regions_3d: Array = []
	var regions_2d: Array = []
	var agents_3d:  Array = []
	var agents_2d:  Array = []

	for node in root.find_children("*", "", true, false):
		var np := str(root.get_path_to(node))
		if node is NavigationRegion3D:
			var r := node as NavigationRegion3D
			regions_3d.append({"node_path": np, "navigation_layers": r.navigation_layers, "has_mesh": r.navigation_mesh != null})
		elif node is NavigationRegion2D:
			var r := node as NavigationRegion2D
			regions_2d.append({"node_path": np, "navigation_layers": r.navigation_layers, "has_polygon": r.navigation_polygon != null})
		elif node is NavigationAgent3D:
			agents_3d.append({"node_path": np, "max_speed": (node as NavigationAgent3D).max_speed})
		elif node is NavigationAgent2D:
			agents_2d.append({"node_path": np, "max_speed": (node as NavigationAgent2D).max_speed})

	return {
		"success":                true,
		"navigation_regions_3d": regions_3d,
		"navigation_regions_2d": regions_2d,
		"navigation_agents_3d":  agents_3d,
		"navigation_agents_2d":  agents_2d,
		"region_count":           regions_3d.size() + regions_2d.size(),
		"agent_count":            agents_3d.size() + agents_2d.size(),
	}
