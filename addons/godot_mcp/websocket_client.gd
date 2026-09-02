@tool
extends Node

class_name GodotMCPWebSocketClient

## WebSocket client for MCP communication

signal connection_established
signal connection_closed
signal error_received(error: String)
signal message_received(data: String)

## Godot's WebSocketPeer defaults to 64 KB in each direction, which a real
## response outgrows silently: send() fails with ERR_OUT_OF_MEMORY, the reply is
## dropped, and the only symptom is the server's timeout minutes later. A scene
## tree, a project-wide file listing or a script search all pass that mark on a
## normal project. Must be set before connect_to_url() -- the peer sizes its
## buffers at connect time.
const BUFFER_SIZE: int = 4 * 1024 * 1024

var websocket: WebSocketPeer
var server_url: String = ""
var _last_state: WebSocketPeer.State = WebSocketPeer.STATE_CLOSED

func _enter_tree() -> void:
	websocket = WebSocketPeer.new()
	websocket.inbound_buffer_size = BUFFER_SIZE
	websocket.outbound_buffer_size = BUFFER_SIZE
	_last_state = WebSocketPeer.STATE_CLOSED

func _exit_tree() -> void:
	if websocket:
		websocket.close()

func _process(_delta: float) -> void:
	if not websocket:
		return

	websocket.poll()

	var state := websocket.get_ready_state()

	if state != _last_state:
		if state == WebSocketPeer.STATE_OPEN:
			connection_established.emit()
		elif state == WebSocketPeer.STATE_CLOSED:
			connection_closed.emit()
		_last_state = state

	while websocket.get_ready_state() == WebSocketPeer.STATE_OPEN and websocket.get_available_packet_count() > 0:
		var packet := websocket.get_packet()
		if packet.is_empty():
			continue
		message_received.emit(packet.get_string_from_utf8())

func set_server_url(url: String) -> void:
	server_url = url

func connect_to_server() -> void:
	if not websocket:
		error_received.emit("WebSocket not initialized")
		return

	var state := websocket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN or state == WebSocketPeer.STATE_CONNECTING:
		return

	var url := server_url
	if url.is_empty():
		url = "ws://127.0.0.1:6505"

	var err := websocket.connect_to_url(url)
	if err != OK:
		error_received.emit("Failed to connect: %s" % error_string(err))
		connection_closed.emit()

func disconnect_from_server() -> void:
	if websocket:
		websocket.close()

## Returns the send error so the caller can react -- a dropped reply used to be
## invisible to everything except the server's timeout.
func send_message(data: String) -> Error:
	if not websocket or websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return ERR_UNAVAILABLE
	var err := websocket.send(data.to_utf8_buffer(), WebSocketPeer.WRITE_MODE_TEXT)
	if err != OK:
		error_received.emit("Failed to send message: %s" % error_string(err))
	return err
