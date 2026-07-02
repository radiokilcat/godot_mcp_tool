@tool
extends Node

class_name GodotMCPHeartbeat

## Heartbeat system for keeping WebSocket connection alive
## Implements ping/pong with configurable timeout

signal ping_timeout

const PING_INTERVAL: float = 10.0  # Send ping every 10 seconds
const PING_TIMEOUT: float = 5.0    # Wait 5 seconds for pong response

var is_running: bool = false
var last_ping_time: float = 0.0
var timer: Timer
var send_fn: Callable  # Set by plugin to actually send the ping over WebSocket

func _enter_tree() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)

func start() -> void:
	if is_running:
		return

	is_running = true
	last_ping_time = 0.0

	if timer:
		timer.wait_time = PING_INTERVAL
		timer.start()

func stop() -> void:
	if not is_running:
		return

	is_running = false

	if timer:
		timer.stop()

func on_pong_received() -> void:
	"""Called when pong response is received"""
	last_ping_time = 0.0  # Reset timeout

func _on_timer_timeout() -> void:
	if not is_running:
		return

	if last_ping_time == 0.0:
		# Send ping
		last_ping_time = Time.get_ticks_msec() / 1000.0
		_send_ping()
	else:
		# Check for ping timeout
		var elapsed = (Time.get_ticks_msec() / 1000.0) - last_ping_time
		if elapsed > PING_TIMEOUT:
			ping_timeout.emit()
			last_ping_time = 0.0

func _send_ping() -> void:
	if send_fn.is_valid():
		send_fn.call()
