@tool
extends Node

class_name GodotMCPMessageSerializer

## Serializes and deserializes MCP protocol messages

class Message:
	var type: String
	var data: Dictionary

	func _init(p_type: String, p_data: Dictionary = {}) -> void:
		type = p_type
		data = p_data

	func to_json() -> String:
		var json_obj = {
			"type": type,
			"data": data
		}
		return JSON.stringify(json_obj)

	static func from_json(json_string: String) -> Variant:
		var parsed = JSON.parse_string(json_string)
		if parsed == null or not parsed is Dictionary:
			return null

		var msg_type = parsed.get("type", "")
		var msg_data = parsed.get("data", {})

		if msg_type.is_empty():
			return null

		return Message.new(msg_type, msg_data)

## Create a request message
static func create_request(request_id: String, method: String, params: Dictionary = {}) -> Message:
	return Message.new("request", {
		"id": request_id,
		"method": method,
		"params": params
	})

## Create a response message
static func create_response(request_id: String, result: Variant) -> Message:
	return Message.new("response", {
		"id": request_id,
		"result": result
	})

## Create an error response message
static func create_error(request_id: String, code: int, message: String, data: Dictionary = {}) -> Message:
	return Message.new("error", {
		"id": request_id,
		"code": code,
		"message": message,
		"data": data
	})

## Create a ping message
static func create_ping(ping_id: String = "") -> Message:
	if ping_id.is_empty():
		ping_id = str(randi())
	return Message.new("ping", {"id": ping_id})

## Create a pong message
static func create_pong(ping_id: String) -> Message:
	return Message.new("pong", {"id": ping_id})

## Create a notification message (no response expected)
static func create_notification(method: String, params: Dictionary = {}) -> Message:
	return Message.new("notification", {
		"method": method,
		"params": params
	})
