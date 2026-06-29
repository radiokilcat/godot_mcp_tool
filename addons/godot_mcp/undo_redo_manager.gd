@tool
extends Node

class_name GodotMCPUndoRedo

## UndoRedo integration for all mutations
## Provides wrapper for undo/redo operations with transaction support

var undo_redo: EditorUndoRedo
var transaction_stack: Array[Dictionary] = []
var current_version: int = 0

func _init(p_undo_redo: EditorUndoRedo) -> void:
	undo_redo = p_undo_redo

## Begin a transaction (can be nested)
func begin_transaction(action_name: String) -> void:
	var transaction = {
		"name": action_name,
		"version": current_version,
		"created": Time.get_ticks_msec()
	}
	transaction_stack.append(transaction)

## Commit the current transaction
func commit_transaction() -> void:
	if transaction_stack.is_empty():
		push_error("No active transaction to commit")
		return

	var transaction = transaction_stack.pop_back()
	current_version += 1

	if transaction_stack.is_empty():
		# This was the top-level transaction, create the action
		undo_redo.create_action(transaction["name"])
		undo_redo.commit_action()

## Rollback the current transaction
func rollback_transaction() -> void:
	if transaction_stack.is_empty():
		push_error("No active transaction to rollback")
		return

	transaction_stack.pop_back()
	current_version -= 1

## Set a node property with undo/redo support
func set_property(node: Node, property: String, value: Variant) -> void:
	if not _should_create_action():
		return

	undo_redo.create_action("Set %s.%s" % [node.name, property])
	undo_redo.add_do_property(node, property, value)
	undo_redo.add_undo_property(node, property, node.get(property))
	undo_redo.commit_action()

## Create a new node with undo/redo support
func create_node(parent: Node, node_type: String, node_name: String = "") -> Node:
	if not _should_create_action():
		return null

	var node = ClassDB.instantiate(node_type)
	if node_name:
		node.name = node_name

	undo_redo.create_action("Create %s: %s" % [node_type, node.name])
	undo_redo.add_do_method(parent, "add_child", node)
	undo_redo.add_do_reference(node)
	undo_redo.add_undo_method(parent, "remove_child", node)
	undo_redo.commit_action()

	return node

## Delete a node with undo/redo support
func delete_node(node: Node) -> void:
	if not _should_create_action():
		return

	var parent = node.get_parent()
	if not parent:
		push_error("Node has no parent")
		return

	undo_redo.create_action("Delete node: %s" % node.name)
	undo_redo.add_do_method(parent, "remove_child", node)
	undo_redo.add_do_reference(node)
	undo_redo.add_undo_method(parent, "add_child", node)
	undo_redo.add_undo_reference(node)
	undo_redo.commit_action()

## Move a node to a new parent with undo/redo support
func move_node(node: Node, new_parent: Node, index: int = -1) -> void:
	if not _should_create_action():
		return

	var old_parent = node.get_parent()
	var old_index = node.get_index()

	undo_redo.create_action("Move node: %s" % node.name)
	
	# Do: move to new parent
	undo_redo.add_do_method(old_parent, "remove_child", node)
	undo_redo.add_do_method(new_parent, "add_child", node)
	if index >= 0:
		undo_redo.add_do_method(new_parent, "move_child", node, index)
	
	# Undo: move back to old parent (LIFO order: remove_child → add_child → move_child)
	undo_redo.add_undo_method(old_parent, "move_child", node, old_index)
	undo_redo.add_undo_method(old_parent, "add_child", node)
	undo_redo.add_undo_method(new_parent, "remove_child", node)
	
	undo_redo.commit_action()

## Rename a node with undo/redo support
func rename_node(node: Node, new_name: String) -> void:
	if not _should_create_action():
		return

	var old_name = node.name

	undo_redo.create_action("Rename node: %s → %s" % [old_name, new_name])
	undo_redo.add_do_property(node, "name", new_name)
	undo_redo.add_undo_property(node, "name", old_name)
	undo_redo.commit_action()

## Attach a script to a node with undo/redo support
func attach_script(node: Node, script_path: String) -> void:
	if not _should_create_action():
		return

	var old_script = node.get_script()
	var new_script = load(script_path)

	if not new_script:
		push_error("Failed to load script: %s" % script_path)
		return

	undo_redo.create_action("Attach script: %s" % script_path)
	undo_redo.add_do_property(node, "script", new_script)
	undo_redo.add_undo_property(node, "script", old_script)
	undo_redo.commit_action()

## Connect a signal with undo/redo support
func connect_signal(source: Node, signal_name: String, target: Node, method_name: String) -> void:
	if not _should_create_action():
		return

	undo_redo.create_action("Connect signal: %s.%s → %s.%s" % [source.name, signal_name, target.name, method_name])
	undo_redo.add_do_method(source, "connect", signal_name, Callable(target, method_name))
	undo_redo.add_undo_method(source, "disconnect", signal_name, Callable(target, method_name))
	undo_redo.commit_action()

## Disconnect a signal with undo/redo support
func disconnect_signal(source: Node, signal_name: String, target: Node, method_name: String) -> void:
	if not _should_create_action():
		return

	undo_redo.create_action("Disconnect signal: %s.%s → %s.%s" % [source.name, signal_name, target.name, method_name])
	undo_redo.add_do_method(source, "disconnect", signal_name, Callable(target, method_name))
	undo_redo.add_undo_method(source, "connect", signal_name, Callable(target, method_name))
	undo_redo.commit_action()

## Add node to group with undo/redo support
func add_to_group(node: Node, group_name: String) -> void:
	if not _should_create_action():
		return

	undo_redo.create_action("Add to group: %s" % group_name)
	undo_redo.add_do_method(node, "add_to_group", group_name)
	undo_redo.add_undo_method(node, "remove_from_group", group_name)
	undo_redo.commit_action()

## Remove node from group with undo/redo support
func remove_from_group(node: Node, group_name: String) -> void:
	if not _should_create_action():
		return

	undo_redo.create_action("Remove from group: %s" % group_name)
	undo_redo.add_do_method(node, "remove_from_group", group_name)
	undo_redo.add_undo_method(node, "add_to_group", group_name)
	undo_redo.commit_action()

## Get the number of undo steps available
func get_undo_count() -> int:
	if not undo_redo:
		return 0
	return undo_redo.get_version()

## Get the current undo/redo version
func get_version() -> int:
	return current_version

## Check if we should create an action (not in transaction)
func _should_create_action() -> bool:
	return transaction_stack.is_empty()
