@tool
extends GodotMCPToolBase

class_name GodotMCPProfilingTools

## Implements 2 Profiling tools:
## get_performance_monitors, get_memory_usage
##
## Note: get_performance_metrics is already provided by runtime_tools.gd.
## These tools expose the full Performance monitor table and detailed
## memory breakdown not available through the runtime tool.
##
## Compatibility note: navigation monitors require Godot 4.1+.
## list_cached_resources() in get_memory_usage requires Godot 4.1+.
## dynamic_bytes/dynamic_memory (Performance.MEMORY_DYNAMIC) only appear on
## Godot 4.0-4.3, where that monitor still exists; see version_utils.gd.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("get_performance_monitors", GodotMCPCallableTool.new(_get_performance_monitors))
	registry.register_tool("get_memory_usage",         GodotMCPCallableTool.new(_get_memory_usage))

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _get_performance_monitors(args: Dictionary) -> Dictionary:
	## Return current values for all (or a subset of) Godot Performance monitors.
	var category_filter: String = args.get("category", "")

	var monitors: Dictionary = {
		"time": {
			"fps":          Performance.get_monitor(Performance.TIME_FPS),
			"process_ms":   Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"physics_ms":   Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		},
		"memory": {
			"static_bytes":        Performance.get_monitor(Performance.MEMORY_STATIC),
			"static_max_bytes":    Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
			# MEMORY_MESSAGE_BUFFER_MAX is a fixed queue-size ceiling, not current usage.
			"message_buffer_max_bytes": Performance.get_monitor(Performance.MEMORY_MESSAGE_BUFFER_MAX),
		},
		"render": {
			"total_objects":    Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"total_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"total_draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"video_mem_bytes":  Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
			"texture_mem_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
			"buffer_mem_bytes": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),
		},
		"physics_2d": {
			"active_objects":  Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS),
			"collision_pairs": Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS),
			"island_count":    Performance.get_monitor(Performance.PHYSICS_2D_ISLAND_COUNT),
		},
		"physics_3d": {
			"active_objects":  Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
			"collision_pairs": Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS),
			"island_count":    Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT),
		},
		"audio": {
			"output_latency_sec": Performance.get_monitor(Performance.AUDIO_OUTPUT_LATENCY),
		},
	}

	# MEMORY_DYNAMIC was removed in Godot 4.4. Looked up dynamically by name
	# (ClassDB, not a static Performance.MEMORY_DYNAMIC reference) so this
	# script still parses on 4.4+ builds; only present in the result when
	# the running engine actually has it (Godot 4.0-4.3).
	if GodotMCPVersionUtils.has_constant("Performance", "MEMORY_DYNAMIC"):
		var dynamic_monitor: int = GodotMCPVersionUtils.get_constant("Performance", "MEMORY_DYNAMIC")
		monitors["memory"]["dynamic_bytes"] = Performance.get_monitor(dynamic_monitor)

	# Navigation monitors and TIME_NAVIGATION_PROCESS were added in Godot 4.1.
	# Guard to maintain Godot 4.0+ compatibility.
	if GodotMCPVersionUtils.at_least(4, 1):
		monitors["time"]["navigation_ms"] = Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS) * 1000.0
		monitors["navigation"] = {
			"active_maps":            Performance.get_monitor(Performance.NAVIGATION_ACTIVE_MAPS),
			"region_count":           Performance.get_monitor(Performance.NAVIGATION_REGION_COUNT),
			"agent_count":            Performance.get_monitor(Performance.NAVIGATION_AGENT_COUNT),
			"link_count":             Performance.get_monitor(Performance.NAVIGATION_LINK_COUNT),
			"polygon_count":          Performance.get_monitor(Performance.NAVIGATION_POLYGON_COUNT),
			"edge_count":             Performance.get_monitor(Performance.NAVIGATION_EDGE_COUNT),
			"edge_merge_count":       Performance.get_monitor(Performance.NAVIGATION_EDGE_MERGE_COUNT),
			"edge_connection_count":  Performance.get_monitor(Performance.NAVIGATION_EDGE_CONNECTION_COUNT),
			"edge_free_count":        Performance.get_monitor(Performance.NAVIGATION_EDGE_FREE_COUNT),
		}

	if not category_filter.is_empty():
		if not monitors.has(category_filter):
			return {
				"error":      "Unknown category '%s'." % category_filter,
				"categories": monitors.keys(),
			}
		return {
			"category": category_filter,
			"monitors": monitors[category_filter],
		}

	return {"monitors": monitors}

func _get_memory_usage(args: Dictionary) -> Dictionary:
	## Return a breakdown of Godot's memory consumption.
	var include_resources: bool = true
	if args.has("include_resources"):
		include_resources = _as_bool(args.get("include_resources"))
	var max_resources: int = int(clamp(int(args.get("max_resources", 50)), 1, 500))

	var static_bytes: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var static_max: float   = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	var video_mem: float    = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var texture_mem: float  = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	var buffer_mem: float   = Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)

	var result: Dictionary = {
		"static_memory": {
			"used_bytes":  int(static_bytes),
			"used_mb":     _round2(static_bytes / 1048576.0),
			"peak_bytes":  int(static_max),
			"peak_mb":     _round2(static_max / 1048576.0),
		},
		"render_memory": {
			"video_mem_bytes":    int(video_mem),
			"video_mem_mb":       _round2(video_mem / 1048576.0),
			"texture_mem_bytes":  int(texture_mem),
			"texture_mem_mb":     _round2(texture_mem / 1048576.0),
			"buffer_mem_bytes":   int(buffer_mem),
			"buffer_mem_mb":      _round2(buffer_mem / 1048576.0),
		},
	}

	# MEMORY_DYNAMIC was removed in Godot 4.4; only report it where it exists.
	if GodotMCPVersionUtils.has_constant("Performance", "MEMORY_DYNAMIC"):
		var dynamic_bytes: float = Performance.get_monitor(GodotMCPVersionUtils.get_constant("Performance", "MEMORY_DYNAMIC"))
		result["dynamic_memory"] = {
			"used_bytes": int(dynamic_bytes),
			"used_mb":    _round2(dynamic_bytes / 1048576.0),
		}

	if include_resources:
		# list_cached_resources() requires Godot 4.1+
		if ResourceLoader.has_method("list_cached_resources"):
			# Use .call() to bypass Godot 4.4 parse-time static method validation.
			var all_resources: Array = Array(ResourceLoader.call("list_cached_resources"))
			var full_count: int = all_resources.size()
			all_resources.sort()
			if all_resources.size() > max_resources:
				all_resources = all_resources.slice(0, max_resources)
			result["cached_resources"] = {
				"count":  full_count,
				"sample": all_resources,
				"note":   "Showing %d of %d cached resources." % [all_resources.size(), full_count] if full_count > max_resources else "",
			}
		else:
			result["cached_resources"] = {
				"count":  0,
				"sample": [],
				"note":   "ResourceLoader.list_cached_resources() requires Godot 4.1+.",
			}

	return result

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _round2(v: float) -> float:
	return roundf(v * 100.0) / 100.0
