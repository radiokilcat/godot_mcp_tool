@tool
extends EditorPlugin

class_name GodotMCPPlugin

## Main plugin class for Godot MCP Integration
## Handles initialization, WebSocket connection, and tool discovery

const VERSION: String = "1.0.0"
const LOG_PREFIX: String = "[Godot MCP]"

# Plugin components
var ws_server: GodotMCPWebSocketServer
var tool_registry: GodotMCPToolRegistry

## The instances must be held for the life of the plugin: they are RefCounted,
## and when they were temporaries inside _register_tools() the GC freed them the
## moment registration returned, leaving every tool bound to a null instance (3.25).
var _tools: Array = []

# Configuration
# 127.0.0.1, not "localhost": "localhost" resolves to ::1 first on Windows, and a
# client dialling IPv4 would find nobody there. Set GODOT_MCP_HOST to move both ends.
var listen_host: String = "127.0.0.1"
## 0 lets the OS pick, which is what stops two open projects colliding — the port
## is published through the discovery registry rather than agreed in advance.
## GODOT_MCP_PORT pins it, which the e2e harness relies on (6.4.8).
var listen_port: int = 0

# State
var is_initialized: bool = false
var _token: String = ""
var _discovery_path: String = ""
## Calls waiting their turn. The editor is single-threaded and tool bodies await,
## so exactly one runs at a time; with N sessions attached, arriving mid-call is
## routine rather than exceptional, and rejecting would make every second client
## unusable (6.5.7).
var _queue: Array = []
var _running: bool = false

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

	# Env override so test harnesses can isolate from a live setup (6.4.8)
	var env_port := OS.get_environment("GODOT_MCP_PORT")
	if env_port.is_valid_int():
		listen_port = int(env_port)

	# Same override the server reads, so both ends stay on one address
	var env_host := OS.get_environment("GODOT_MCP_HOST")
	if not env_host.is_empty():
		listen_host = env_host

	# Create tool registry first: a client can connect the moment we listen, and it
	# must never find the registry half built.
	tool_registry = GodotMCPToolRegistry.new()
	_register_tools()

	ws_server = GodotMCPWebSocketServer.new()
	add_child(ws_server)
	ws_server.peer_connected.connect(_on_peer_connected)
	ws_server.peer_disconnected.connect(_on_peer_disconnected)
	ws_server.message_received.connect(_on_peer_message)
	ws_server.server_error.connect(_on_server_error)

	_token = GodotMCPDiscovery.generate_token()
	var err := ws_server.start(listen_port, _token, listen_host)
	if err != OK:
		push_error("%s Could not listen on %s:%d — %s" % [LOG_PREFIX, listen_host, listen_port, error_string(err)])
	else:
		listen_port = ws_server.get_port()
		_discovery_path = GodotMCPDiscovery.publish(listen_port, _token, VERSION)
		if _discovery_path.is_empty():
			push_error("%s Listening on %d but could not publish the discovery file; set GODOT_MCP_PORT and GODOT_MCP_TOKEN on the MCP server to connect." % [LOG_PREFIX, listen_port])
		else:
			print_log("Listening on ws://%s:%d (advertised in %s)" % [listen_host, listen_port, _discovery_path])

	is_initialized = true
	print_log("Plugin initialized")

## Shutdown all plugin components
func _shutdown_plugin() -> void:
	if not is_initialized:
		return

	# Cleared first, before anything below can emit: closing peers signals
	# disconnects, and a handler that assumed the plugin was still up would act on
	# a half-torn-down registry.
	is_initialized = false

	# Withdraw before closing, so a client that reconnects in the gap does not find
	# a stale entry pointing at a port nobody is listening on.
	GodotMCPDiscovery.withdraw(_discovery_path)
	_discovery_path = ""

	# Anything still queued will never run; say so rather than leaving the caller
	# to wait out its timeout.
	for entry in _queue:
		_send_tool_result(entry["peer_id"], entry["id"], {"error": "The editor's MCP plugin was disabled while this call was queued."})
	_queue.clear()
	_running = false

	if ws_server:
		ws_server.stop()
		ws_server = null

	_tools.clear()
	tool_registry = null
	print_log("Plugin shutdown complete")

## True while the editor is hosting the bridge.
func is_bridge_listening() -> bool:
	return ws_server != null and ws_server.is_listening()

## How many MCP sessions are attached right now.
func connected_client_count() -> int:
	return ws_server.peer_ids().size() if ws_server != null else 0

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

## Handle a tool call from one client.
##
## The client id is in the log line because the editor's state is global — one
## current scene, one selection, one UndoRedo stack — so with two sessions
## attached the interesting question about any change is *which* of them made it.
## Without this the failure mode is a rare, timing-dependent "something undid my
## edit" with nothing in the Output panel to attribute it to (6.5.8).
func _handle_tool_call(peer_id: int, tool_name: String, args: Dictionary) -> Variant:
	var tool = tool_registry.get_tool(tool_name)
	if tool == null:
		push_error("%s Tool not found: %s" % [LOG_PREFIX, tool_name])
		return {"error": "Tool not found: %s" % tool_name}

	print_log("client %d → %s" % [peer_id, tool_name])
	return await tool.execute(args)

# ============================================================================
# WebSocket Event Handlers
# ============================================================================

## An MCP session attached and passed the token check.
func _on_peer_connected(peer_id: int) -> void:
	print_log("MCP client %d connected (%d attached)" % [peer_id, connected_client_count()])
	_send_ready_message(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print_log("MCP client %d disconnected (%d attached)" % [peer_id, connected_client_count()])
	# Its queued work has nowhere to go back to. Drop it rather than spending the
	# editor's single-threaded attention on a result nobody will read.
	var kept: Array = []
	var dropped := 0
	for entry in _queue:
		if entry["peer_id"] == peer_id:
			dropped += 1
		else:
			kept.append(entry)
	_queue = kept
	if dropped > 0:
		print_log("Dropped %d queued call(s) from client %d" % [dropped, peer_id])

func _on_server_error(message: String) -> void:
	push_error("%s %s" % [LOG_PREFIX, message])

func _on_peer_message(peer_id: int, data: String) -> void:
	var message = JSON.parse_string(data)
	if message == null or not message is Dictionary:
		push_error("%s Failed to parse message from client %d" % [LOG_PREFIX, peer_id])
		return

	match message.get("type", ""):
		"ping":
			_send_to(peer_id, {"type": "pong"})
		"pong":
			pass  # liveness is the client's business now; it dialled in
		"tool_call":
			_queue.append({
				"peer_id": peer_id,
				"id": message.get("id", ""),
				"tool": message.get("tool", ""),
				"args": message.get("args", {}),
			})
			_pump()
		_:
			print_log("Unknown message type from client %d: %s" % [peer_id, message.get("type", "")])

## Run queued calls one at a time.
##
## `_running` is not a lock against threads — GDScript here is single-threaded —
## but against re-entry: a tool body awaits, which returns to the main loop, which
## can deliver the next message and call this again mid-flight.
func _pump() -> void:
	if _running or _queue.is_empty():
		return
	_running = true
	while not _queue.is_empty():
		var entry: Dictionary = _queue.pop_front()
		var result = await _handle_tool_call(entry["peer_id"], entry["tool"], entry["args"])
		# The plugin may have been disabled while that awaited.
		if not is_initialized:
			_running = false
			return
		_send_tool_result(entry["peer_id"], entry["id"], result)
	_running = false

# ============================================================================
# Message Sending
# ============================================================================

## Tell a freshly attached client who it is talking to.
func _send_ready_message(peer_id: int) -> void:
	_send_to(peer_id, {
		"type": "ready",
		"godot_version": Engine.get_version_info().get("string", ""),
		"plugin_version": VERSION,
		"plugin_id": str(get_instance_id())
	})

## Send tool execution result. If result has an 'error' key, send it as error field.
func _send_tool_result(peer_id: int, message_id: String, result: Variant) -> void:
	var msg: Dictionary = {"type": "tool_result", "id": message_id}
	if result is Dictionary and result.has("error"):
		msg["error"] = result.get("error", "Unknown error")
	else:
		msg["result"] = result

	if _send_to(peer_id, msg) == OK:
		return

	# The reply did not go out -- in practice it outgrew the socket's outbound
	# buffer. Say so in a message small enough to get through, rather than
	# leaving the caller to wait out a timeout on a result that will never
	# arrive and guess why.
	var size := JSON.stringify(msg).length()
	var reason := "Result could not be sent (%d bytes, socket buffer is %d bytes). Narrow the request: a path, a filter, a smaller max_depth or limit." % [size, GodotMCPWebSocketServer.BUFFER_SIZE]
	push_error("%s %s" % [LOG_PREFIX, reason])
	_send_to(peer_id, {"type": "tool_result", "id": message_id, "error": reason})

## Send a message to one client. Returns the send error, OK on success.
func _send_to(peer_id: int, message: Dictionary) -> Error:
	if ws_server == null:
		return ERR_UNAVAILABLE
	return ws_server.send_to(peer_id, JSON.stringify(message))

# ============================================================================
# Utility Functions
# ============================================================================

## Print log message with plugin prefix
func print_log(message: String) -> void:
	print("%s %s" % [LOG_PREFIX, message])

## True when the bridge is up and at least one MCP session is attached.
func get_connection_status() -> bool:
	return connected_client_count() > 0

## Get the plugin version
func get_version() -> String:
	return VERSION
