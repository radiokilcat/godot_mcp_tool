@tool
extends Node

class_name GodotMCPWebSocketClient

## WebSocket client for MCP communication

signal connection_established
signal connection_closed
signal error_received(error: String)
signal message_received(data: String)

var websocket: WebSocketClient
var server_url: String = ""
var is_connected: bool = false

func _enter_tree() -> void:
	websocket = WebSocketClient.new()
	websocket.connected_to_server.connect(_on_connected_to_server)
	websocket.connection_closed.connect(_on_connection_closed)
	websocket.server_close_request.connect(_on_server_close_request)
	websocket.data_received.connect(_on_data_received)

func _exit_tree() -> void:
	if websocket:
		websocket.disconnect_from_host()

func _process(_delta: float) -> void:
	if websocket:
		websocket.poll()

func set_server_url(url: String) -> void:
	server_url = url

func connect_to_server() -> void:
	if not websocket:
		error_received.emit("WebSocket not initialized")
		return

	if is_connected:
		return

	var url = server_url
	if url.is_empty():
		url = "ws://localhost:6505"

	var error = websocket.connect_to_url(url)
	if error != OK:
		error_received.emit("Failed to connect: %s" % error_as_text(error))

func disconnect_from_server() -> void:
	if websocket and is_connected:
		websocket.disconnect_from_host()

func send_message(data: String) -> void:
	if websocket and is_connected:
		websocket.get_peer(1).put_packet(data.to_utf8_buffer())

func _on_connected_to_server() -> void:
	is_connected = true
	connection_established.emit()

func _on_connection_closed(was_clean: bool = false) -> void:
	is_connected = false
	connection_closed.emit()

func _on_server_close_request(code: int, reason: String) -> void:
	is_connected = false
	connection_closed.emit()

func _on_data_received() -> void:
	var peer = websocket.get_peer(1)
	while peer.is_connected() and peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet.is_empty():
			continue
		var data = packet.get_string_from_utf8()
		message_received.emit(data)

func error_as_text(error: Error) -> String:
	match error:
		ERR_CONNECTION_ERROR:
			return "Connection error"
		ERR_INVALID_PARAMETER:
			return "Invalid parameter"
		ERR_CANT_CONNECT:
			return "Can't connect"
		_:
			return "Unknown error (%d)" % error
