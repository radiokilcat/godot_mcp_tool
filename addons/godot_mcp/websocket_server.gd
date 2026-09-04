@tool
extends Node

class_name GodotMCPWebSocketServer

## The editor hosts the bridge; MCP server processes connect to it (progress.md 6.5).
##
## This replaces websocket_client.gd. The direction was inverted because the
## machine-wide resource — a TCP port — was owned by the most ephemeral process in
## the chain: an MCP session lasts minutes, the editor lasts a working day. With
## the editor listening, nobody has to "start the shared server", the listener dies
## with the project it belongs to, and N sessions attaching to one editor falls out
## for free instead of being a feature to build.
##
## Authentication is a shared secret in the URL path. It is the only thing standing
## between `execute_script` and any web page the developer has open, because
## WebSocket is exempt from same-origin and a page may freely connect to
## ws://127.0.0.1:<port>. A page cannot read the token off disk; that is the whole
## boundary. Godot's listener cannot see request headers (probed — see 9.5), so the
## URL is where the secret has to travel.

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal message_received(peer_id: int, text: String)
signal server_error(message: String)

## 9.4.2: Godot's 64 KB default silently dropped larger replies into a push_error,
## and the only symptom was the caller's timeout.
const BUFFER_SIZE := 4 * 1024 * 1024
const MAX_QUEUED_PACKETS := 2048
## A client that connects but never completes the handshake must not hold a slot.
const HANDSHAKE_TIMEOUT_MS := 10_000

var _tcp := TCPServer.new()
var _token := ""
var _port := 0
## peer_id -> {peer: WebSocketPeer, state: int, since: int, authed: bool}
var _peers: Dictionary = {}
var _next_peer_id := 1

func get_port() -> int:
	return _port

func is_listening() -> bool:
	return _tcp.is_listening()

func peer_ids() -> Array:
	return _peers.keys()

## Bind the listener. `port` may be 0 to let the OS pick a free one, which is what
## makes two open projects stop colliding.
func start(port: int, token: String, host: String = "127.0.0.1") -> Error:
	stop()
	_token = token
	var err := _tcp.listen(port, host)
	if err != OK:
		return err
	_port = _tcp.get_local_port()
	return OK

func stop() -> void:
	for id in _peers.keys():
		var entry: Dictionary = _peers[id]
		(entry["peer"] as WebSocketPeer).close(1001, "editor shutting down")
	_peers.clear()
	if _tcp.is_listening():
		_tcp.stop()
	_port = 0

func _process(_delta: float) -> void:
	if not _tcp.is_listening():
		return
	_accept_pending()
	_poll_peers()

func _accept_pending() -> void:
	while _tcp.is_connection_available():
		var peer := WebSocketPeer.new()
		peer.inbound_buffer_size = BUFFER_SIZE
		peer.outbound_buffer_size = BUFFER_SIZE
		peer.max_queued_packets = MAX_QUEUED_PACKETS
		var err := peer.accept_stream(_tcp.take_connection())
		if err != OK:
			server_error.emit("Could not accept connection: %s" % error_string(err))
			continue
		var id := _next_peer_id
		_next_peer_id += 1
		_peers[id] = {
			"peer": peer,
			"state": WebSocketPeer.STATE_CONNECTING,
			"since": Time.get_ticks_msec(),
			"authed": false,
		}

func _poll_peers() -> void:
	for id in _peers.keys():
		var entry: Dictionary = _peers[id]
		var peer: WebSocketPeer = entry["peer"]
		peer.poll()
		var state := peer.get_ready_state()

		if state == WebSocketPeer.STATE_OPEN and not entry["authed"]:
			if not _authorize(id, peer):
				continue
			entry["authed"] = true
			entry["state"] = state
			peer_connected.emit(id)

		elif state == WebSocketPeer.STATE_CONNECTING:
			# Drop a connection that opened a socket and then said nothing. Without
			# this a peer that never finishes the handshake sits in the pool forever.
			if Time.get_ticks_msec() - int(entry["since"]) > HANDSHAKE_TIMEOUT_MS:
				peer.close(1002, "handshake timed out")
				_forget(id, false)
			continue

		elif state == WebSocketPeer.STATE_CLOSED:
			_forget(id, entry["authed"])
			continue

		while peer.get_ready_state() == WebSocketPeer.STATE_OPEN and peer.get_available_packet_count() > 0:
			var packet := peer.get_packet()
			if packet.is_empty():
				continue
			if entry["authed"]:
				message_received.emit(id, packet.get_string_from_utf8())

## Compare the secret carried in the request path. Closes with an application code
## (4001) rather than dropping silently: a real client that read the wrong
## discovery file gets a reason it can show the user, while a browser gets nothing
## it did not already know.
func _authorize(id: int, peer: WebSocketPeer) -> bool:
	if _token.is_empty():
		return true
	var presented := token_from_url(peer.get_requested_url())
	if presented.is_empty() or not _constant_time_equals(presented, _token):
		peer.close(4001, "invalid or missing token")
		_forget(id, false)
		return false
	return true

## Last path segment of a request URL, with any query or fragment removed.
## `String.get_file()` alone is not enough: it splits on "/" only, so it would
## hand back "tok3n?q=1" and every token comparison would fail the moment a client
## appended anything.
static func token_from_url(url: String) -> String:
	var path := url
	for separator in ["?", "#"]:
		var at := path.find(separator)
		if at != -1:
			path = path.substr(0, at)
	return path.get_file()

## Compare without leaking the match position through timing. Overkill on loopback,
## but it costs one line and removes the need to think about it again.
func _constant_time_equals(a: String, b: String) -> bool:
	if a.length() != b.length():
		return false
	var diff := 0
	for i in a.length():
		diff |= a.unicode_at(i) ^ b.unicode_at(i)
	return diff == 0

func _forget(id: int, was_authed: bool) -> void:
	_peers.erase(id)
	if was_authed:
		peer_disconnected.emit(id)

## Returns the send error rather than swallowing it (9.4.2): a reply too large for
## the socket buffer used to vanish into a push_error, leaving the caller to wait
## out a timeout on a result that was never coming.
func send_to(peer_id: int, text: String) -> Error:
	if not _peers.has(peer_id):
		return ERR_DOES_NOT_EXIST
	var entry: Dictionary = _peers[peer_id]
	var peer: WebSocketPeer = entry["peer"]
	if peer.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return ERR_UNAVAILABLE
	return peer.send_text(text)

func outbound_buffer_size() -> int:
	return BUFFER_SIZE
