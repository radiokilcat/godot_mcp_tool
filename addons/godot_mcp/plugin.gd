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

## The instances must be held for the life of the plugin: they are RefCounted,
## and when they were temporaries inside _register_tools() the GC freed them the
## moment registration returned, leaving every tool bound to a null instance (3.25).
var _tools: Array = []

# Configuration
# 127.0.0.1, not "localhost": the server binds IPv4 loopback, while "localhost"
# resolves to ::1 first on Windows — the connection would go to an address the
# bridge is not listening on. Set GODOT_MCP_HOST on the server to move both ends.
var server_host: String = "127.0.0.1"
var server_port: int = 6505
var auto_connect: bool = true
var reconnect_delay: float = 1.0  # Start at 1 second
var max_reconnect_delay: float = 60.0

# State
var is_initialized: bool = false
var is_connected: bool = false
var reconnect_attempts: int = 0
var _tool_busy: bool = false
## The pending reconnect, kept so shutdown can cut it short. See _schedule_reconnect.
var _reconnect_timer: SceneTreeTimer = null

## Called when plugin is enabled
func _enter_tree() -> void:
	print_log("Loading Godot MCP v%s" % VERSION)
	_initialize_plugin()

## Called when plugin is disabled
func _exit_tree() -> void:
	print_log("Unloading Godot MCP")
	_shutdown_plugin()

## Initialize all plugin components
func _initialize_plugin() -> void:
	if is_initialized:
		return

	# Env override so test harnesses can isolate from a live setup on the default port
	var env_port := OS.get_environment("GODOT_MCP_PORT")
	if env_port.is_valid_int():
		server_port = int(env_port)

	# Same override the server reads, so both ends stay on one address
	var env_host := OS.get_environment("GODOT_MCP_HOST")
	if not env_host.is_empty():
		server_host = env_host

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
	heartbeat.send_fn = func(): _send_message({"type": "ping"})

	# Create tool registry
	tool_registry = GodotMCPToolRegistry.new()
	_register_tools()

	is_initialized = true
	print_log("Plugin initialized")

	# Auto-connect if enabled
	if auto_connect:
		_connect_to_server()

## Shutdown all plugin components
func _shutdown_plugin() -> void:
	if not is_initialized:
		return

	# Cleared first, before anything below can emit: closing the socket signals a
	# disconnect, and a disconnect schedules a reconnect. Today that emission is
	# deferred to the client's _process, which no longer runs — but a shutdown that
	# depends on that is one refactor away from re-arming the timer it just cancelled.
	is_initialized = false

	# Cut a pending reconnect short: zeroing time_left makes the timer fire on the
	# next frame, so the awaiting coroutine resumes, sees is_initialized false, and
	# releases its reference to this plugin now rather than up to a minute from now.
	if _reconnect_timer != null:
		_reconnect_timer.time_left = 0.0
		_reconnect_timer = null

	# Stop heartbeat
	if heartbeat:
		heartbeat.stop()
		heartbeat = null

	# Disconnect WebSocket
	if websocket_client:
		websocket_client.disconnect_from_server()
		websocket_client = null

	_tools.clear()
	tool_registry = null
	is_connected = false
	print_log("Plugin shutdown complete")

## Connect to MCP server
func _connect_to_server() -> void:
	if not is_initialized:
		return

	if is_connected:
		return

	print_log("Connecting to MCP server at %s:%d" % [server_host, server_port])
	websocket_client.connect_to_server()

## Disconnect from MCP server
func _disconnect_from_server() -> void:
	if not is_connected:
		return

	websocket_client.disconnect_from_server()

## Register all available tools. The categories are listed as classes rather than
## as 23 fields plus 23 constructor calls plus 23 register() calls, so adding one
## is a single line. Local rather than a const because an Array literal is not a
## constant expression in GDScript.
func _register_tools() -> void:
	var tool_classes: Array = [
		GodotMCPProjectTools,
		GodotMCPSceneTools,
		GodotMCPNodeTools,
		GodotMCPScriptTools,
		GodotMCPEditorTools,
		GodotMCPInputTools,
		GodotMCPRuntimeTools,
		GodotMCPAnimationTools,
		GodotMCPAnimationTreeTools,
		GodotMCP3DSceneTools,
		GodotMCPPhysicsTools,
		GodotMCPParticleTools,
		GodotMCPNavigationTools,
		GodotMCPAudioTools,
		GodotMCPTileMapTools,
		GodotMCPThemeTools,
		GodotMCPShaderTools,
		GodotMCPResourceTools,
		GodotMCPBatchTools,
		GodotMCPAnalysisTools,
		GodotMCPTestingTools,
		GodotMCPProfilingTools,
		GodotMCPExportTools,
	]
	_tools.clear()
	for tool_class in tool_classes:
		var instance: GodotMCPToolBase = tool_class.new(self)
		_tools.append(instance)
		instance.register(tool_registry)

	print_log("Registered %d tools from %d categories" % [tool_registry.get_tool_count(), _tools.size()])

## Handle a tool call from the server
func _handle_tool_call(tool_name: String, args: Dictionary) -> Variant:
	var tool = tool_registry.get_tool(tool_name)
	if tool == null:
		push_error("%s Tool not found: %s" % [LOG_PREFIX, tool_name])
		return {"error": "Tool not found: %s" % tool_name}

	print_log("Executing tool: %s" % tool_name)
	return await tool.execute(args)

# ============================================================================
# WebSocket Event Handlers
# ============================================================================

## Handle WebSocket connection established
func _on_websocket_connected() -> void:
	is_connected = true
	reconnect_attempts = 0
	reconnect_delay = 1.0
	print_log("Connected to MCP server")

	# Start heartbeat
	if heartbeat:
		heartbeat.start()

	# Notify that we're ready
	_send_ready_message()

## Handle WebSocket connection closed
func _on_websocket_disconnected() -> void:
	if is_connected:
		print_log("Disconnected from MCP server")
	is_connected = false

	# Stop heartbeat
	if heartbeat:
		heartbeat.stop()

	# Attempt to reconnect with exponential backoff
	if auto_connect:
		_schedule_reconnect()

## Handle WebSocket error
func _on_websocket_error(error: String) -> void:
	push_error("%s WebSocket error: %s" % [LOG_PREFIX, error])

## Handle message received from WebSocket
func _on_websocket_message(data: String) -> void:
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
			if _tool_busy:
				_send_tool_result(message.get("id"), {"error": "Another tool call is already in progress"})
				return
			_tool_busy = true
			var result = await _handle_tool_call(
				message.get("tool", ""),
				message.get("args", {})
			)
			_tool_busy = false
			_send_tool_result(message.get("id"), result)
		_:
			print_log("Unknown message type: %s" % msg_type)

## Handle heartbeat ping timeout
func _on_ping_timeout() -> void:
	print_log("Ping timeout - reconnecting")
	_disconnect_from_server()

# ============================================================================
# Heartbeat Handlers
# ============================================================================

## Handle ping from server
func _handle_ping() -> void:
	_send_message({"type": "pong"})

## Handle pong response from server
func _handle_pong() -> void:
	if heartbeat:
		heartbeat.on_pong_received()

# ============================================================================
# Message Sending
# ============================================================================

## Send ready message to server
func _send_ready_message() -> void:
	_send_message({
		"type": "ready",
		"godot_version": Engine.get_version_info().get("string", ""),
		"plugin_version": VERSION,
		"plugin_id": str(get_instance_id())
	})

## Send tool execution result. If result has an 'error' key, send it as error field.
func _send_tool_result(message_id: String, result: Variant) -> void:
	var msg: Dictionary = {"type": "tool_result", "id": message_id}
	if result is Dictionary and result.has("error"):
		msg["error"] = result.get("error", "Unknown error")
	else:
		msg["result"] = result

	if _send_message(msg) == OK:
		return

	# The reply did not go out -- in practice it outgrew the socket's outbound
	# buffer. Say so in a message small enough to get through, rather than
	# leaving the caller to wait out a timeout on a result that will never
	# arrive and guess why.
	var size := JSON.stringify(msg).length()
	var reason := "Result could not be sent (%d bytes, socket buffer is %d bytes). Narrow the request: a path, a filter, a smaller max_depth or limit." % [size, GodotMCPWebSocketClient.BUFFER_SIZE]
	push_error("%s %s" % [LOG_PREFIX, reason])
	_send_message({"type": "tool_result", "id": message_id, "error": reason})

## Send a message to the server. Returns the send error, OK on success.
func _send_message(message: Dictionary) -> Error:
	if not is_connected or not websocket_client:
		push_error("%s Cannot send message: not connected" % LOG_PREFIX)
		return ERR_UNAVAILABLE

	var json_string = JSON.stringify(message)
	return websocket_client.send_message(json_string)

# ============================================================================
# Reconnect Logic
# ============================================================================

## Schedule a reconnection attempt.
##
## `await` on a SceneTreeTimer holds a reference to this plugin until the timer
## fires, so a plugin disabled while a reconnect is pending stayed alive for up to
## max_reconnect_delay — a minute at the top of the backoff, long enough that
## quitting the editor inside that window reports leaked ObjectDB instances. The
## timer is therefore kept, and _shutdown_plugin zeroes it to let the coroutine
## resume and drop the reference on the next frame.
func _schedule_reconnect() -> void:
	if not is_initialized:
		return
	var tree := get_tree()
	if tree == null:
		return

	reconnect_attempts += 1
	var delay = min(reconnect_delay * pow(2, reconnect_attempts - 1), max_reconnect_delay)
	print_log("Scheduling reconnect in %.1f seconds (attempt %d)" % [delay, reconnect_attempts])

	var timer := tree.create_timer(delay)
	_reconnect_timer = timer
	await timer.timeout

	# _connect_to_server guards on is_initialized too, but checking the identity
	# here also stops a superseded timer from reconnecting out of turn.
	if not is_initialized or _reconnect_timer != timer:
		return
	_reconnect_timer = null
	_connect_to_server()

# ============================================================================
# Utility Functions
# ============================================================================

## Print log message with plugin prefix
func print_log(message: String) -> void:
	print("%s %s" % [LOG_PREFIX, message])

## Get the current connection status
func get_connection_status() -> bool:
	return is_connected

## Get the plugin version
func get_version() -> String:
	return VERSION
