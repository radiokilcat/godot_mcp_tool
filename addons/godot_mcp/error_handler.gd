@tool
extends Node

class_name GodotMCPErrorHandler

## Error handling with contextual suggestions

const ERROR_SUGGESTIONS: Dictionary = {
	"connection_failed": [
		"Make sure the MCP server is running on localhost:6505",
		"Check if the port is not blocked by firewall",
		"Verify the server address in plugin settings",
		"Try restarting both Godot and the MCP server"
	],
	"timeout": [
		"The server is taking too long to respond",
		"Check if the server is overloaded",
		"Try increasing the timeout value in settings",
		"Restart the server if it seems unresponsive"
	],
	"tool_not_found": [
		"Verify that the tool is registered in the tool registry",
		"Make sure the tool category is loaded",
		"Check the tool name spelling",
		"Look at the plugin console for registration errors"
	],
	"invalid_parameters": [
		"Check the tool's input schema",
		"Verify parameter types match expected types",
		"Make sure all required parameters are provided",
		"See the documentation for this tool"
	],
	"godot_error": [
		"Check Godot's error console for more details",
		"Verify the scene or node exists",
		"Make sure you have proper permissions",
		"Check if the operation is valid in the current state"
	],
}

## Standard error codes (JSON-RPC style)
enum ErrorCode {
	PARSE_ERROR = -32700,
	INVALID_REQUEST = -32600,
	METHOD_NOT_FOUND = -32601,
	INVALID_PARAMS = -32602,
	INTERNAL_ERROR = -32603,
	SERVER_ERROR = -32000,
	CONNECTION_ERROR = 1000,
	TIMEOUT = 1001,
	TOOL_NOT_FOUND = 2000,
	GODOT_ERROR = 2001,
}

class GodotMCPError:
	var code: int
	var message: String
	var suggestions: Array[String]
	var data: Dictionary

	func _init(p_code: int, p_message: String, p_suggestions: Array[String] = [], p_data: Dictionary = {}) -> void:
		code = p_code
		message = p_message
		suggestions = p_suggestions
		data = p_data

	func to_dict() -> Dictionary:
		return {
			"code": code,
			"message": message,
			"suggestions": suggestions,
			"data": data
		}

## Create a parse error
static func parse_error(details: String = "") -> GodotMCPError:
	var suggestions: Array[String] = []
	if not details.is_empty():
		suggestions.append("Details: " + details)
	return GodotMCPError.new(
		ErrorCode.PARSE_ERROR,
		"Parse error",
		suggestions
	)

## Create an invalid request error
static func invalid_request(details: String = "") -> GodotMCPError:
	var suggestions: Array[String] = [
		"Verify the request format",
		"Check required fields are present"
	]
	if not details.is_empty():
		suggestions.append("Details: " + details)
	return GodotMCPError.new(
		ErrorCode.INVALID_REQUEST,
		"Invalid request",
		suggestions
	)

## Create a method not found error
static func method_not_found(method: String) -> GodotMCPError:
	var suggestions = ERROR_SUGGESTIONS.get("tool_not_found", [])
	return GodotMCPError.new(
		ErrorCode.METHOD_NOT_FOUND,
		"Method not found: %s" % method,
		suggestions
	)

## Create an invalid parameters error
static func invalid_params(details: String = "") -> GodotMCPError:
	var suggestions = ERROR_SUGGESTIONS.get("invalid_parameters", [])
	if not details.is_empty():
		suggestions.append("Details: " + details)
	return GodotMCPError.new(
		ErrorCode.INVALID_PARAMS,
		"Invalid parameters",
		suggestions
	)

## Create an internal error
static func internal_error(details: String = "") -> GodotMCPError:
	var suggestions: Array[String] = ["Check the plugin console for error details"]
	if not details.is_empty():
		suggestions.append("Details: " + details)
	return GodotMCPError.new(
		ErrorCode.INTERNAL_ERROR,
		"Internal error",
		suggestions
	)

## Create a connection error
static func connection_error(details: String = "") -> GodotMCPError:
	var suggestions = ERROR_SUGGESTIONS.get("connection_failed", [])
	if not details.is_empty():
		suggestions.append("Details: " + details)
	return GodotMCPError.new(
		ErrorCode.CONNECTION_ERROR,
		"Connection error",
		suggestions
	)

## Create a timeout error
static func timeout_error(details: String = "") -> GodotMCPError:
	var suggestions = ERROR_SUGGESTIONS.get("timeout", [])
	if not details.is_empty():
		suggestions.append("Details: " + details)
	return GodotMCPError.new(
		ErrorCode.TIMEOUT,
		"Request timeout",
		suggestions
	)

## Create a tool not found error
static func tool_not_found(tool_name: String) -> GodotMCPError:
	var suggestions = ERROR_SUGGESTIONS.get("tool_not_found", [])
	suggestions.append("Tool name: %s" % tool_name)
	return GodotMCPError.new(
		ErrorCode.TOOL_NOT_FOUND,
		"Tool not found: %s" % tool_name,
		suggestions
	)

## Create a Godot-specific error
static func godot_error(details: String) -> GodotMCPError:
	var suggestions = ERROR_SUGGESTIONS.get("godot_error", [])
	suggestions.append("Error details: " + details)
	return GodotMCPError.new(
		ErrorCode.GODOT_ERROR,
		"Godot operation failed",
		suggestions
	)
