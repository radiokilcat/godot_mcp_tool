@tool
extends Node

class_name GodotMCPToolRegistry

## Registry for managing all available tools

var tools: Dictionary = {}

## Register a tool (tool must have an execute(args) method)
func register_tool(tool_name: String, tool: Object) -> void:
	if tool_name in tools:
		push_error("Tool already registered: %s" % tool_name)
		return

	tools[tool_name] = tool

## Unregister a tool
func unregister_tool(tool_name: String) -> void:
	if tool_name in tools:
		tools.erase(tool_name)

## Get a tool by name
func get_tool(tool_name: String) -> Variant:
	return tools.get(tool_name, null)

## Get all registered tools
func get_all_tools() -> Array:
	return tools.keys()

## Get total number of registered tools
func get_tool_count() -> int:
	return tools.size()
