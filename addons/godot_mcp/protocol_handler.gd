@tool
extends Node

class_name GodotMCPProtocolHandler

## MCP protocol message handler

signal message_received(message: GodotMCPMessageSerializer.Message)
signal response_received(request_id: String, result: Variant)
signal error_received(request_id: String, error: GodotMCPErrorHandler.GodotMCPError)

var pending_requests: Dictionary = {}  # request_id -> timeout_timer
var request_timeout: float = 30.0  # 30 seconds default

func handle_message(json_string: String) -> void:
	"""Parse and handle incoming message"""
	var message = GodotMCPMessageSerializer.Message.from_json(json_string)
	if message == null:
		push_error("Failed to parse message")
		return

	message_received.emit(message)

	match message.type:
		"response":
			_handle_response(message)
		"error":
			_handle_error(message)
		"ping":
			_handle_ping(message)
		"pong":
			_handle_pong(message)
		"notification":
			_handle_notification(message)
		_:
			print("Unknown message type: %s" % message.type)

func send_request(method: String, params: Dictionary = {}, callback: Callable = Callable()) -> String:
	"""Send a request and return request ID"""
	var request_id = str(randi())
	var message = GodotMCPMessageSerializer.create_request(request_id, method, params)

	# Store request info for timeout handling
	var timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = request_timeout
	timer.timeout.connect(func() -> void: _handle_request_timeout(request_id))
	timer.start()

	pending_requests[request_id] = {
		"timer": timer,
		"callback": callback
	}

	return request_id

func _handle_response(message: GodotMCPMessageSerializer.Message) -> void:
	"""Handle response message"""
	var request_id = message.data.get("id", "")
	var result = message.data.get("result", null)

	if not request_id in pending_requests:
		return

	var request_info = pending_requests[request_id]
	request_info["timer"].queue_free()
	pending_requests.erase(request_id)

	response_received.emit(request_id, result)

	if request_info["callback"].is_valid():
		request_info["callback"].call(result)

func _handle_error(message: GodotMCPMessageSerializer.Message) -> void:
	"""Handle error message"""
	var request_id = message.data.get("id", "")
	var code = message.data.get("code", -1)
	var error_message = message.data.get("message", "Unknown error")

	if not request_id in pending_requests:
		return

	var request_info = pending_requests[request_id]
	request_info["timer"].queue_free()
	pending_requests.erase(request_id)

	var error = GodotMCPErrorHandler.GodotMCPError.new(code, error_message)
	error_received.emit(request_id, error)

func _handle_ping(message: GodotMCPMessageSerializer.Message) -> void:
	"""Handle ping message"""
	var ping_id = message.data.get("id", str(randi()))
	var pong = GodotMCPMessageSerializer.create_pong(ping_id)
	# TODO: Send pong back through WebSocket

func _handle_pong(message: GodotMCPMessageSerializer.Message) -> void:
	"""Handle pong message"""
	# Heartbeat received
	pass

func _handle_notification(message: GodotMCPMessageSerializer.Message) -> void:
	"""Handle notification message (no response expected)"""
	var method = message.data.get("method", "")
	var params = message.data.get("params", {})
	# TODO: Process notification

func _handle_request_timeout(request_id: String) -> void:
	"""Handle request timeout"""
	if not request_id in pending_requests:
		return

	var request_info = pending_requests[request_id]
	request_info["timer"].queue_free()
	pending_requests.erase(request_id)

	var error = GodotMCPErrorHandler.timeout_error("No response from server")
	error_received.emit(request_id, error)
