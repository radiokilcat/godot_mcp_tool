@tool
extends GodotMCPToolBase

class_name GodotMCPAnimationTreeTools

## Implements all 8 AnimationTree tools.
## Covers StateMachine states/transitions, BlendTree, BlendSpace 1D/2D.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("create_animation_tree",      GodotMCPCallableTool.new(_create_animation_tree))
	registry.register_tool("create_state_machine",       GodotMCPCallableTool.new(_create_state_machine))
	registry.register_tool("add_transition",             GodotMCPCallableTool.new(_add_transition))
	registry.register_tool("add_blend_tree",             GodotMCPCallableTool.new(_add_blend_tree))
	registry.register_tool("set_active_state",           GodotMCPCallableTool.new(_set_active_state))
	registry.register_tool("get_state_machine_info",     GodotMCPCallableTool.new(_get_state_machine_info))
	registry.register_tool("edit_blend_space",           GodotMCPCallableTool.new(_edit_blend_space))
	registry.register_tool("delete_animation_tree_node", GodotMCPCallableTool.new(_delete_animation_tree_node))
func _get_animation_tree(node_path: String) -> Variant:
	var node := _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not node is AnimationTree:
		return {"error": "Node is not an AnimationTree (got %s)" % node.get_class()}
	return node

func _get_state_machine(tree: AnimationTree) -> Variant:
	var root := tree.tree_root
	if root == null:
		return {"error": "AnimationTree has no tree_root"}
	if not root is AnimationNodeStateMachine:
		return {"error": "tree_root is not an AnimationNodeStateMachine (got %s)" % root.get_class()}
	return root as AnimationNodeStateMachine

func _switch_mode_enum(mode: String) -> int:
	match mode:
		"sync":   return AnimationNodeStateMachineTransition.SWITCH_MODE_SYNC
		"at_end": return AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
		_:        return AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE

func _switch_mode_name(mode: int) -> String:
	match mode:
		AnimationNodeStateMachineTransition.SWITCH_MODE_SYNC:   return "sync"
		AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END: return "at_end"
		_:                                                       return "immediate"

func _tree_root_type_name(root: AnimationNode) -> String:
	if root is AnimationNodeStateMachine: return "state_machine"
	if root is AnimationNodeBlendTree:    return "blend_tree"
	if root is AnimationNodeBlendSpace1D: return "blend_space_1d"
	if root is AnimationNodeBlendSpace2D: return "blend_space_2d"
	return root.get_class()

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _create_animation_tree(args: Dictionary) -> Dictionary:
	var parent_path: String     = args.get("parent_path", "")
	var node_name: String       = args.get("node_name", "AnimationTree")
	var anim_player_path: String = args.get("anim_player_path", "")
	var tree_root_type: String  = args.get("tree_root_type", "state_machine")

	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent: Node
	if parent_path.is_empty() or parent_path == "." or parent_path == root.name:
		parent = root
	else:
		parent = root.get_node_or_null(parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var tree_root: AnimationNode
	match tree_root_type:
		"blend_tree":     tree_root = AnimationNodeBlendTree.new()
		"blend_space_1d": tree_root = AnimationNodeBlendSpace1D.new()
		"blend_space_2d": tree_root = AnimationNodeBlendSpace2D.new()
		_:                tree_root = AnimationNodeStateMachine.new()

	var at := AnimationTree.new()
	at.name = node_name
	at.tree_root = tree_root
	at.active = false
	if not anim_player_path.is_empty():
		at.anim_player = NodePath(anim_player_path)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Create AnimationTree '%s'" % node_name)
	ur.add_do_method(parent, "add_child", at, true)
	ur.add_do_property(at, "owner", root)
	ur.add_do_reference(at)
	ur.add_undo_method(parent, "remove_child", at)
	ur.add_undo_reference(at)
	ur.commit_action()

	return {
		"success": true,
		"node_name": node_name,
		"node_path": str(root.get_path_to(at)),
		"tree_root_type": tree_root_type,
		"anim_player_path": anim_player_path,
	}

func _create_state_machine(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var result = _get_animation_tree(node_path)
	if result is Dictionary:
		return result
	var tree: AnimationTree = result

	var sm := AnimationNodeStateMachine.new()
	var old_root := tree.tree_root

	# Populate states before UndoRedo so they're baked into the sm resource.
	# Undo reverts tree_root to old_root; redo restores sm with its states.
	var states: Array = args.get("states", [])
	var added_states: Array = []
	for state_info in states:
		if not state_info is Dictionary:
			continue
		var state_name: String = state_info.get("name", "")
		var anim_name: String  = state_info.get("animation", "")
		if state_name.is_empty():
			continue
		# "Start" and "End" are built-in nodes in every AnimationNodeStateMachine;
		# adding them again silently fails in Godot's C++ (ERR_FAIL_COND).
		if state_name in ["Start", "End"]:
			push_warning("[GodotMCP] create_state_machine: '%s' is a reserved state name and was skipped." % state_name)
			continue
		var anim_node := AnimationNodeAnimation.new()
		if not anim_name.is_empty():
			anim_node.animation = StringName(anim_name)
		sm.add_node(StringName(state_name), anim_node)
		added_states.append(state_name)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Create State Machine on '%s'" % node_path)
	ur.add_do_property(tree, "tree_root", sm)
	ur.add_undo_property(tree, "tree_root", old_root)
	ur.commit_action()

	return {
		"success": true,
		"node_path": node_path,
		"states_added": added_states,
	}

func _add_transition(args: Dictionary) -> Dictionary:
	var node_path: String  = args.get("node_path", "")
	var from_state: String = args.get("from_state", "")
	var to_state: String   = args.get("to_state", "")

	if node_path.is_empty() or from_state.is_empty() or to_state.is_empty():
		return {"error": "'node_path', 'from_state', and 'to_state' are required"}

	var result = _get_animation_tree(node_path)
	if result is Dictionary:
		return result
	var tree: AnimationTree = result

	var sm_result = _get_state_machine(tree)
	if sm_result is Dictionary:
		return sm_result
	var sm: AnimationNodeStateMachine = sm_result

	# "Start" and "End" are built-in nodes; regular states must exist
	var built_in := ["Start", "End"]
	if not sm.has_node(StringName(from_state)) and not (from_state in built_in):
		return {"error": "State not found: '%s'" % from_state}
	if not sm.has_node(StringName(to_state)) and not (to_state in built_in):
		return {"error": "State not found: '%s'" % to_state}

	if sm.has_transition(StringName(from_state), StringName(to_state)):
		return {"error": "Transition '%s' → '%s' already exists" % [from_state, to_state]}

	var tr := AnimationNodeStateMachineTransition.new()
	tr.xfade_time  = float(args.get("xfade_time", 0.0))
	tr.switch_mode = _switch_mode_enum(args.get("switch_mode", "immediate"))
	var advance_condition: String = args.get("advance_condition", "")
	if not advance_condition.is_empty():
		tr.advance_condition = StringName(advance_condition)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Add Transition %s → %s" % [from_state, to_state])
	ur.add_do_method(sm, "add_transition", StringName(from_state), StringName(to_state), tr)
	ur.add_undo_method(sm, "remove_transition", StringName(from_state), StringName(to_state))
	ur.commit_action()

	return {
		"success": true,
		"from_state": from_state,
		"to_state": to_state,
		"xfade_time": tr.xfade_time,
		"switch_mode": _switch_mode_name(tr.switch_mode),
		"advance_condition": advance_condition,
	}

func _add_blend_tree(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var result = _get_animation_tree(node_path)
	if result is Dictionary:
		return result
	var tree: AnimationTree = result

	var old_root := tree.tree_root
	var blend_tree := AnimationNodeBlendTree.new()

	# Add optional nodes before UndoRedo (baked into resource)
	var nodes: Array = args.get("nodes", [])
	var added_nodes: Array = []
	for node_info in nodes:
		if not node_info is Dictionary:
			continue
		var bname: String = node_info.get("name", "")
		var btype: String = node_info.get("type", "animation")
		var bx: float     = float(node_info.get("x", 0.0))
		var by: float     = float(node_info.get("y", 0.0))
		if bname.is_empty():
			continue

		var blend_node: AnimationNode
		match btype:
			"blend2":      blend_node = AnimationNodeBlend2.new()
			"blend3":      blend_node = AnimationNodeBlend3.new()
			"one_shot":    blend_node = AnimationNodeOneShot.new()
			"time_scale":  blend_node = AnimationNodeTimeScale.new()
			"transition":  blend_node = AnimationNodeTransition.new()
			_:
				var anode := AnimationNodeAnimation.new()
				var anim_name: String = node_info.get("animation", "")
				if not anim_name.is_empty():
					anode.animation = StringName(anim_name)
				blend_node = anode

		blend_tree.add_node(StringName(bname), blend_node, Vector2(bx, by))
		added_nodes.append(bname)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set Blend Tree on '%s'" % node_path)
	ur.add_do_property(tree, "tree_root", blend_tree)
	ur.add_undo_property(tree, "tree_root", old_root)
	ur.commit_action()

	return {
		"success": true,
		"node_path": node_path,
		"tree_root_type": "blend_tree",
		"nodes_added": added_nodes,
	}

func _set_active_state(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	if not args.has("active") and args.get("state_name", "").is_empty():
		return {"error": "Either 'active' (bool) or 'state_name' (string) is required"}

	var result = _get_animation_tree(node_path)
	if result is Dictionary:
		return result
	var tree: AnimationTree = result

	var response: Dictionary = {"success": true, "node_path": node_path}

	# Handle active flag first — independent of state_name
	if args.has("active"):
		var active: bool     = bool(args.get("active", false))
		var old_active: bool = tree.active
		var ur := _plugin.get_undo_redo()
		ur.create_action("Set AnimationTree active = %s" % str(active))
		ur.add_do_property(tree, "active", active)
		ur.add_undo_property(tree, "active", old_active)
		ur.commit_action()
		response["active"] = active

	# Handle state_name — add Start → state transition (sets initial state)
	var state_name: String = args.get("state_name", "")
	if not state_name.is_empty():
		var sm_result = _get_state_machine(tree)
		if sm_result is Dictionary:
			return sm_result
		var sm: AnimationNodeStateMachine = sm_result

		if not sm.has_node(StringName(state_name)):
			return {"error": "State not found: '%s'" % state_name}

		if sm.has_transition(StringName("Start"), StringName(state_name)):
			response["initial_state"]  = state_name
			response["already_set"]    = true
		else:
			var tr := AnimationNodeStateMachineTransition.new()
			tr.xfade_time  = 0.0
			tr.switch_mode = AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
			var ur := _plugin.get_undo_redo()
			ur.create_action("Set initial state to '%s'" % state_name)
			ur.add_do_method(sm, "add_transition", StringName("Start"), StringName(state_name), tr)
			ur.add_undo_method(sm, "remove_transition", StringName("Start"), StringName(state_name))
			ur.commit_action()
			response["initial_state"] = state_name

	return response

func _get_state_machine_info(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var result = _get_animation_tree(node_path)
	if result is Dictionary:
		return result
	var tree: AnimationTree = result

	var info: Dictionary = {
		"node_path": node_path,
		"active": tree.active,
		"anim_player": str(tree.anim_player),
	}

	var root := tree.tree_root
	if root == null:
		info["tree_root_type"] = "none"
		return info

	info["tree_root_type"] = _tree_root_type_name(root)

	if root is AnimationNodeStateMachine:
		var sm := root as AnimationNodeStateMachine
		var states: Array = []
		# AnimationNodeStateMachine exposes no get_node_list() in Godot 4.x —
		# states are only enumerable via its dynamic "states/<name>/node" properties
		for prop in sm.get_property_list():
			var pname: String = prop.get("name", "")
			if not (pname.begins_with("states/") and pname.ends_with("/node")):
				continue
			var sn := pname.trim_prefix("states/").trim_suffix("/node")
			var snode: AnimationNode = sm.get_node(sn)
			if snode == null:
				continue
			var state_info: Dictionary = {
				"name": str(sn),
				"type": snode.get_class(),
			}
			if snode is AnimationNodeAnimation:
				state_info["animation"] = str((snode as AnimationNodeAnimation).animation)
			states.append(state_info)
		info["states"] = states
		info["state_count"] = states.size()

		if args.get("include_transitions", true):
			var transitions: Array = []
			for i in range(sm.get_transition_count()):
				var from := sm.get_transition_from(i)
				var to   := sm.get_transition_to(i)
				var tr   := sm.get_transition(i)
				transitions.append({
					"from": str(from),
					"to":   str(to),
					"xfade_time":        tr.xfade_time,
					"switch_mode":       _switch_mode_name(tr.switch_mode),
					"advance_condition": str(tr.advance_condition),
				})
			info["transitions"] = transitions
			info["transition_count"] = transitions.size()

	elif root is AnimationNodeBlendSpace1D:
		var bs := root as AnimationNodeBlendSpace1D
		var points: Array = []
		for i in range(bs.get_blend_point_count()):
			var bnode := bs.get_blend_point_node(i)
			points.append({
				"index": i,
				"pos": bs.get_blend_point_position(i),
				"animation": str((bnode as AnimationNodeAnimation).animation) if bnode is AnimationNodeAnimation else "",
			})
		info["blend_points"] = points
		info["blend_point_count"] = points.size()

	elif root is AnimationNodeBlendSpace2D:
		var bs := root as AnimationNodeBlendSpace2D
		var points: Array = []
		for i in range(bs.get_blend_point_count()):
			var bnode := bs.get_blend_point_node(i)
			var pos   := bs.get_blend_point_position(i)
			points.append({
				"index": i,
				"x": pos.x,
				"y": pos.y,
				"animation": str((bnode as AnimationNodeAnimation).animation) if bnode is AnimationNodeAnimation else "",
			})
		info["blend_points"] = points
		info["blend_point_count"] = points.size()

	return info

func _edit_blend_space(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var action: String    = args.get("action", "list_points")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var result = _get_animation_tree(node_path)
	if result is Dictionary:
		return result
	var tree: AnimationTree = result

	var root := tree.tree_root
	if root == null:
		return {"error": "AnimationTree has no tree_root"}

	if root is AnimationNodeBlendSpace1D:
		return _edit_bs1d(root as AnimationNodeBlendSpace1D, action, args)
	elif root is AnimationNodeBlendSpace2D:
		return _edit_bs2d(root as AnimationNodeBlendSpace2D, action, args)
	else:
		return {"error": "tree_root is not a BlendSpace (got %s)" % root.get_class()}

func _edit_bs1d(bs: AnimationNodeBlendSpace1D, action: String, args: Dictionary) -> Dictionary:
	match action:
		"add_point":
			var anim_name: String = args.get("animation", "")
			var pos: float        = float(args.get("pos", 0.0))
			var anim_node := AnimationNodeAnimation.new()
			if not anim_name.is_empty():
				anim_node.animation = StringName(anim_name)
			var new_idx := bs.get_blend_point_count()
			var ur := _plugin.get_undo_redo()
			ur.create_action("Add BlendSpace1D point at pos=%.2f" % pos)
			ur.add_do_method(bs, "add_blend_point", anim_node, pos)
			ur.add_undo_method(bs, "remove_blend_point", new_idx)
			ur.commit_action()
			return {"success": true, "action": "add_point", "index": new_idx, "pos": pos, "animation": anim_name}

		"remove_point":
			var idx: int = int(args.get("index", -1))
			if idx < 0 or idx >= bs.get_blend_point_count():
				return {"error": "Invalid index: %d (count=%d)" % [idx, bs.get_blend_point_count()]}
			var old_node := bs.get_blend_point_node(idx)
			var old_pos  := bs.get_blend_point_position(idx)
			var ur := _plugin.get_undo_redo()
			ur.create_action("Remove BlendSpace1D point %d" % idx)
			ur.add_do_method(bs, "remove_blend_point", idx)
			ur.add_undo_method(bs, "add_blend_point", old_node, old_pos, idx)
			ur.commit_action()
			return {"success": true, "action": "remove_point", "index": idx}

		"set_point":
			var idx: int   = int(args.get("index", -1))
			var pos: float = float(args.get("pos", 0.0))
			if idx < 0 or idx >= bs.get_blend_point_count():
				return {"error": "Invalid index: %d" % idx}
			var old_pos := bs.get_blend_point_position(idx)
			var ur := _plugin.get_undo_redo()
			ur.create_action("Set BlendSpace1D point %d pos=%.2f" % [idx, pos])
			ur.add_do_method(bs, "set_blend_point_position", idx, pos)
			ur.add_undo_method(bs, "set_blend_point_position", idx, old_pos)
			ur.commit_action()
			return {"success": true, "action": "set_point", "index": idx, "pos": pos}

		"list_points":
			var points: Array = []
			for i in range(bs.get_blend_point_count()):
				var bnode := bs.get_blend_point_node(i)
				points.append({
					"index": i,
					"pos": bs.get_blend_point_position(i),
					"animation": str((bnode as AnimationNodeAnimation).animation) if bnode is AnimationNodeAnimation else "",
				})
			return {"points": points, "count": points.size()}

	return {"error": "Unknown action: '%s'. Use add_point, remove_point, set_point, list_points" % action}

func _edit_bs2d(bs: AnimationNodeBlendSpace2D, action: String, args: Dictionary) -> Dictionary:
	match action:
		"add_point":
			var anim_name: String = args.get("animation", "")
			var x: float          = float(args.get("x", 0.0))
			var y: float          = float(args.get("y", 0.0))
			var anim_node := AnimationNodeAnimation.new()
			if not anim_name.is_empty():
				anim_node.animation = StringName(anim_name)
			var new_idx := bs.get_blend_point_count()
			var ur := _plugin.get_undo_redo()
			ur.create_action("Add BlendSpace2D point at (%.2f, %.2f)" % [x, y])
			ur.add_do_method(bs, "add_blend_point", anim_node, Vector2(x, y))
			ur.add_undo_method(bs, "remove_blend_point", new_idx)
			ur.commit_action()
			return {"success": true, "action": "add_point", "index": new_idx, "x": x, "y": y, "animation": anim_name}

		"remove_point":
			var idx: int = int(args.get("index", -1))
			if idx < 0 or idx >= bs.get_blend_point_count():
				return {"error": "Invalid index: %d (count=%d)" % [idx, bs.get_blend_point_count()]}
			var old_node := bs.get_blend_point_node(idx)
			var old_pos  := bs.get_blend_point_position(idx)
			var ur := _plugin.get_undo_redo()
			ur.create_action("Remove BlendSpace2D point %d" % idx)
			ur.add_do_method(bs, "remove_blend_point", idx)
			ur.add_undo_method(bs, "add_blend_point", old_node, old_pos, idx)
			ur.commit_action()
			return {"success": true, "action": "remove_point", "index": idx}

		"set_point":
			var idx: int = int(args.get("index", -1))
			var x: float = float(args.get("x", 0.0))
			var y: float = float(args.get("y", 0.0))
			if idx < 0 or idx >= bs.get_blend_point_count():
				return {"error": "Invalid index: %d" % idx}
			var old_pos := bs.get_blend_point_position(idx)
			var ur := _plugin.get_undo_redo()
			ur.create_action("Set BlendSpace2D point %d pos=(%.2f, %.2f)" % [idx, x, y])
			ur.add_do_method(bs, "set_blend_point_position", idx, Vector2(x, y))
			ur.add_undo_method(bs, "set_blend_point_position", idx, old_pos)
			ur.commit_action()
			return {"success": true, "action": "set_point", "index": idx, "x": x, "y": y}

		"list_points":
			var points: Array = []
			for i in range(bs.get_blend_point_count()):
				var bnode := bs.get_blend_point_node(i)
				var pos   := bs.get_blend_point_position(i)
				points.append({
					"index": i,
					"x": pos.x,
					"y": pos.y,
					"animation": str((bnode as AnimationNodeAnimation).animation) if bnode is AnimationNodeAnimation else "",
				})
			return {"points": points, "count": points.size()}

	return {"error": "Unknown action: '%s'. Use add_point, remove_point, set_point, list_points" % action}

func _delete_animation_tree_node(args: Dictionary) -> Dictionary:
	var node_path: String  = args.get("node_path", "")
	var state_name: String = args.get("state_name", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var result = _get_animation_tree(node_path)
	if result is Dictionary:
		return result
	var tree: AnimationTree = result

	# No state_name → delete the AnimationTree node itself from the scene
	if state_name.is_empty():
		var node := _resolve_node(node_path)
		if node == null:
			return {"error": "Node not found: %s" % node_path}
		var parent: Node = node.get_parent()
		if parent == null:
			return {"error": "Node has no parent (cannot delete scene root)"}
		var idx: int = node.get_index()
		var root := _scene_root()
		var ur   := _plugin.get_undo_redo()
		ur.create_action("Delete AnimationTree '%s'" % node_path)
		ur.add_do_method(parent, "remove_child", node)
		ur.add_do_reference(node)
		ur.add_undo_property(node, "owner", root)
		ur.add_undo_method(parent, "move_child", node, idx)
		ur.add_undo_method(parent, "add_child", node, true)
		ur.add_undo_reference(node)
		ur.commit_action()
		return {"success": true, "deleted": "animation_tree", "node_path": node_path}

	# state_name provided → delete a state from the StateMachine
	var sm_result = _get_state_machine(tree)
	if sm_result is Dictionary:
		return sm_result
	var sm: AnimationNodeStateMachine = sm_result

	if not sm.has_node(StringName(state_name)):
		return {"error": "State not found: '%s'" % state_name}

	var old_node := sm.get_node(StringName(state_name))
	var ur := _plugin.get_undo_redo()
	ur.create_action("Delete State '%s'" % state_name)
	ur.add_do_method(sm, "remove_node", StringName(state_name))
	ur.add_undo_method(sm, "add_node", StringName(state_name), old_node, Vector2.ZERO)
	ur.commit_action()

	return {
		"success": true,
		"deleted": "state",
		"state_name": state_name,
	}
