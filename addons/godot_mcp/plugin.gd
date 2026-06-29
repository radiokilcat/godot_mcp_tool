@tool
extends EditorPlugin

class_name GodotMCPPlugin

## Main plugin class for Godot MCP Integration
## Handles initialization, WebSocket connection, and tool discovery

const VERSION: String = "1.0.0"
const LOG_PREFIX: String = "[Godot MCP]"

# Plugin components
var websocket_client: GodotMCPWebSocketClient
var heartbeat: GodotMCPHeartbeat
var tool_registry: GodotMCPToolRegistry

# Configuration
var server_host: String = "localhost"
var server_port: int = 6505
var auto_connect: bool = true
var reconnect_delay: float = 1.0  # Start at 1 second
var max_reconnect_delay: float = 60.0

# State
var is_initialized: bool = false
var is_connected: bool = false
var reconnect_attempts: int = 0

func _enter_tree() -> void:
	"""Called when plugin is enabled"""
	print_log("Loading Godot MCP v%s" % VERSION)
	_initialize_plugin()

func _exit_tree() -> void:
	"""Called when plugin is disabled"""
	print_log("Unloading Godot MCP")
	_shutdown_plugin()

func _initialize_plugin() -> void:
	"""Initialize all plugin components"""
	if is_initialized:
		return

	# Create WebSocket client
	websocket_client = GodotMCPWebSocketClient.new()
	add_child(websocket_client)
	websocket_client.set_server_url("ws://%s:%d" % [server_host, server_port])
	websocket_client.connection_established.connect(_on_websocket_connected)
	websocket_client.connection_closed.connect(_on_websocket_disconnected)
	websocket_client.error_received.connect(_on_websocket_error)
	websocket_client.message_received.connect(_on_websocket_message)

	# Create heartbeat system
	heartbeat = GodotMCPHeartbeat.new()
	add_child(heartbeat)
	heartbeat.ping_timeout.connect(_on_ping_timeout)

	# Create tool registry
	tool_registry = GodotMCPToolRegistry.new()
	_register_tools()

	is_initialized = true
	print_log("Plugin initialized")

	# Auto-connect if enabled
	if auto_connect:
		_connect_to_server()

func _shutdown_plugin() -> void:
	"""Shutdown all plugin components"""
	if not is_initialized:
		return

	# Stop heartbeat
	if heartbeat:
		heartbeat.stop()
		heartbeat = null

	# Disconnect WebSocket
	if websocket_client:
		websocket_client.disconnect_from_server()
		websocket_client = null

	tool_registry = null
	is_initialized = false
	is_connected = false
	print_log("Plugin shutdown complete")

func _connect_to_server() -> void:
	"""Connect to MCP server"""
	if not is_initialized:
		return

	if is_connected:
		return

	print_log("Connecting to MCP server at %s:%d" % [server_host, server_port])
	websocket_client.connect_to_server()

func _disconnect_from_server() -> void:
	"""Disconnect from MCP server"""
	if not is_connected:
		return

	websocket_client.disconnect_from_server()

func _register_tools() -> void:
	"""Register all available tools"""
	GodotMCPProjectTools.new().register(tool_registry)
	GodotMCPSceneTools.new(self).register(tool_registry)
	GodotMCPNodeTools.new(self).register(tool_registry)
	# Script, Editor, … tools registered here as implemented

	print_log("Registered %d tools" % tool_registry.get_tool_count())

func _handle_tool_call(tool_name: String, args: Dictionary) -> Variant:
	"""Handle a tool call from the server"""
	var tool = tool_registry.get_tool(tool_name)
	if tool == null:
		push_error("%s Tool not found: %s" % [LOG_PREFIX, tool_name])
		return {"error": "Tool not found: %s" % tool_name}

	print_log("Executing tool: %s" % tool_name)
	return await tool.execute(args)

# ============================================================================
# WebSocket Event Handlers
# ============================================================================

func _on_websocket_connected() -> void:
	"""Handle WebSocket connection established"""
	is_connected = true
	reconnect_attempts = 0
	reconnect_delay = 1.0
	print_log("Connected to MCP server")

	# Start heartbeat
	if heartbeat:
		heartbeat.start()

	# Notify that we're ready
	_send_ready_message()

func _on_websocket_disconnected() -> void:
	"""Handle WebSocket connection closed"""
	if is_connected:
		print_log("Disconnected from MCP server")
	is_connected = false

	# Stop heartbeat
	if heartbeat:
		heartbeat.stop()

	# Attempt to reconnect with exponential backoff
	if auto_connect:
		_schedule_reconnect()

func _on_websocket_error(error: String) -> void:
	"""Handle WebSocket error"""
	push_error("%s WebSocket error: %s" % [LOG_PREFIX, error])

func _on_websocket_message(data: String) -> void:
	"""Handle message received from WebSocket"""
	var message = JSON.parse_string(data)
	if message == null:
		push_error("%s Failed to parse message" % LOG_PREFIX)
		return

	if not message is Dictionary:
		return

	var msg_type = message.get("type", "")

	match msg_type:
		"ping":
			_handle_ping()
		"pong":
			_handle_pong()
		"tool_call":
			var result = await _handle_tool_call(
				message.get("tool", ""),
				message.get("args", {})
			)
			_send_tool_result(message.get("id"), result)
		_:
			print_log("Unknown message type: %s" % msg_type)

func _on_ping_timeout() -> void:
	"""Handle heartbeat ping timeout"""
	print_log("Ping timeout - reconnecting")
	_disconnect_from_server()

# ============================================================================
# Heartbeat Handlers
# ============================================================================

func _handle_ping() -> void:
	"""Handle ping from server"""
	_send_message({"type": "pong"})

func _handle_pong() -> void:
	"""Handle pong response from server"""
	if heartbeat:
		heartbeat.on_pong_received()

# ============================================================================
# Message Sending
# ============================================================================

func _send_ready_message() -> void:
	"""Send ready message to server"""
	_send_message({
		"type": "ready",
		"godot_version": Engine.get_version_info().get("string", ""),
		"plugin_version": VERSION,
		"plugin_id": str(get_instance_id())
	})

func _send_tool_result(message_id: String, result: Variant) -> void:
	"""Send tool execution result. If result has an 'error' key, send it as error field."""
	var msg: Dictionary = {"type": "tool_result", "id": message_id}
	if result is Dictionary and result.has("error"):
		msg["error"] = result.get("error", "Unknown error")
	else:
		msg["result"] = result
	_send_message(msg)

func _send_message(message: Dictionary) -> void:
	"""Send a message to the server"""
	if not is_connected or not websocket_client:
		push_error("%s Cannot send message: not connected" % LOG_PREFIX)
		return

	var json_string = JSON.stringify(message)
	websocket_client.send_message(json_string)

# ============================================================================
# Reconnect Logic
# ============================================================================

func _schedule_reconnect() -> void:
	"""Schedule a reconnection attempt"""
	reconnect_attempts += 1
	var delay = min(reconnect_delay * pow(2, reconnect_attempts - 1), max_reconnect_delay)
	print_log("Scheduling reconnect in %.1f seconds (attempt %d)" % [delay, reconnect_attempts])

	await get_tree().create_timer(delay).timeout
	_connect_to_server()

# ============================================================================
# Utility Functions
# ============================================================================

func print_log(message: String) -> void:
	"""Print log message with plugin prefix"""
	print("%s %s" % [LOG_PREFIX, message])

## Get the current connection status
func get_connection_status() -> bool:
	return is_connected

## Get the plugin version
func get_version() -> String:
	return VERSION
