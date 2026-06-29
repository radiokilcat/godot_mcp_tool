@tool
extends Node

class_name GodotMCPToolRegistry

## Registry for managing all available tools

var tools: Dictionary = {}

func register_tool(tool_name: String, tool: Node) -> void:
	"""Register a tool"""
	if tool_name in tools:
		push_error("Tool already registered: %s" % tool_name)
		return

	tools[tool_name] = tool

func unregister_tool(tool_name: String) -> void:
	"""Unregister a tool"""
	if tool_name in tools:
		tools.erase(tool_name)

func get_tool(tool_name: String) -> Variant:
	"""Get a tool by name"""
	return tools.get(tool_name, null)

func get_all_tools() -> Array:
	"""Get all registered tools"""
	return tools.keys()

func get_tool_count() -> int:
	"""Get total number of registered tools"""
	return tools.size()
