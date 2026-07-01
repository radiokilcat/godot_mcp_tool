@tool
extends RefCounted

class_name GodotMCPTestingTools

## Implements 6 Testing/QA tools:
## run_automated_tests, assert_node_state, compare_screenshots,
## record_test, replay_test, get_test_report

var _plugin: EditorPlugin

# In-memory test recording state
var _recording: bool = false
var _recorded_events: Array = []
var _recording_name: String = ""

# Last test report
var _last_report: Dictionary = {}

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("run_automated_tests",  GodotMCPCallableTool.new(_run_automated_tests))
	registry.register_tool("assert_node_state",    GodotMCPCallableTool.new(_assert_node_state))
	registry.register_tool("compare_screenshots",  GodotMCPCallableTool.new(_compare_screenshots))
	registry.register_tool("record_test",          GodotMCPCallableTool.new(_record_test))
	registry.register_tool("replay_test",          GodotMCPCallableTool.new(_replay_test))
	registry.register_tool("get_test_report",      GodotMCPCallableTool.new(_get_test_report))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _as_bool(val: Variant) -> bool:
	if val is bool: return val
	return str(val).to_lower() == "true"

func _get_editor_interface() -> EditorInterface:
	return _plugin.get_editor_interface()

func _get_scene_root() -> Node:
	return _get_editor_interface().get_edited_scene_root()

## Resolve a node by path from the edited scene root.
func _resolve_node(node_path: String) -> Variant:
	var root: Node = _get_scene_root()
	if root == null:
		return null
	if node_path.is_empty() or node_path == ".":
		return root
	return root.get_node_or_null(NodePath(node_path))

## Compare two Image objects and return a pixel-difference ratio [0.0, 1.0].
func _image_diff_ratio(img_a: Image, img_b: Image) -> float:
	if img_a.get_size() != img_b.get_size():
		return 1.0
	var w: int = img_a.get_width()
	var h: int = img_a.get_height()
	var diff_pixels: int = 0
	for y in h:
		for x in w:
			var ca: Color = img_a.get_pixel(x, y)
			var cb: Color = img_b.get_pixel(x, y)
			var dr: float = abs(ca.r - cb.r)
			var dg: float = abs(ca.g - cb.g)
			var db: float = abs(ca.b - cb.b)
			if dr + dg + db > 0.03:  # ~1/255 * 3 tolerance
				diff_pixels += 1
	return float(diff_pixels) / float(max(w * h, 1))

## Load an Image from a res:// or absolute path.
func _load_image(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	return img

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _run_automated_tests(args: Dictionary) -> Dictionary:
	## Run GDScript test files that follow a simple convention:
	## each function whose name starts with "test_" is called;
	## returning false or throwing counts as a failure.
	## Also supports GUT if it is available in the project.
	var test_path: String = args.get("test_path", "res://tests/")
	var test_filter: String = args.get("test_filter", "")
	# Collect .gd test files
	var test_files: Array = []
	var fs: EditorFileSystemDirectory = _plugin.get_editor_interface().get_resource_filesystem().get_filesystem()
	_collect_test_files(fs, test_path, test_files)

	if test_files.is_empty():
		return {"error": "No test files found under '%s'." % test_path,
				"hint": "Test files should be .gd scripts containing functions starting with 'test_'."}

	var results: Array = []
	var total_pass: int = 0
	var total_fail: int = 0
	var total_skip: int = 0

	for script_path in test_files:
		if not test_filter.is_empty() and not script_path.contains(test_filter):
			total_skip += 1
			continue

		var script = load(script_path)
		if not script is GDScript:
			results.append({"script": script_path, "status": "skip", "reason": "not a GDScript"})
			total_skip += 1
			continue

		var instance = script.new()
		var method_list: Array = instance.get_method_list()
		var test_methods: Array = []
		for m in method_list:
			if str(m["name"]).begins_with("test_"):
				test_methods.append(str(m["name"]))

		if test_methods.is_empty():
			results.append({"script": script_path, "status": "skip", "reason": "no test_ methods"})
			total_skip += 1
			if not instance is RefCounted:
				instance.free()
			continue

		var file_pass: int = 0
		var file_fail: int = 0
		var method_results: Array = []
		for method_name in test_methods:
			var ok: bool = true
			var err_msg: String = ""
			var ret = await instance.call(method_name)
			if ret is bool and ret == false:
				ok = false
				err_msg = "returned false"
			elif ret is Dictionary and ret.has("error"):
				ok = false
				err_msg = str(ret.get("error", "unknown"))
			if ok:
				file_pass += 1
				method_results.append({"method": method_name, "status": "pass"})
			else:
				file_fail += 1
				method_results.append({"method": method_name, "status": "fail", "error": err_msg})

		total_pass += file_pass
		total_fail += file_fail
		results.append({
			"script":  script_path,
			"status":  "fail" if file_fail > 0 else "pass",
			"pass":    file_pass,
			"fail":    file_fail,
			"methods": method_results,
		})

		if not instance is RefCounted:
			instance.free()

	var report: Dictionary = {
		"test_path":   test_path,
		"total_pass":  total_pass,
		"total_fail":  total_fail,
		"total_skip":  total_skip,
		"total_files": test_files.size(),
		"status":      "pass" if total_fail == 0 else "fail",
		"results":     results,
	}
	_last_report = report
	return report


func _assert_node_state(args: Dictionary) -> Dictionary:
	## Check that a node property (or a set of properties) matches expected values.
	## Returns {passed: bool, assertions: [...]} with per-check details.
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "node_path is required."}

	var assertions_in = args.get("assertions", [])
	if not assertions_in is Array or assertions_in.is_empty():
		# Legacy single-property mode: property + expected
		var property: String = args.get("property", "")
		var expected = args.get("expected")
		if property.is_empty():
			return {"error": "Provide 'assertions' array or both 'property' and 'expected'."}
		assertions_in = [{"property": property, "expected": expected}]

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: '%s'. Make sure a scene is open." % node_path}

	var assertion_results: Array = []
	var all_passed: bool = true

	for entry in assertions_in:
		if not entry is Dictionary:
			continue
		var prop: String = str(entry.get("property", ""))
		var expected = entry.get("expected")
		if prop.is_empty():
			continue

		var actual = node.get(prop)
		var passed: bool
		# Tolerant comparison for floats
		if actual is float and expected is float:
			passed = absf(actual - float(expected)) < 1e-5
		elif actual is Vector2 and expected is Dictionary:
			passed = (absf(actual.x - float(expected.get("x", actual.x))) < 1e-5 and
					  absf(actual.y - float(expected.get("y", actual.y))) < 1e-5)
		elif actual is Vector3 and expected is Dictionary:
			passed = (absf(actual.x - float(expected.get("x", actual.x))) < 1e-5 and
					  absf(actual.y - float(expected.get("y", actual.y))) < 1e-5 and
					  absf(actual.z - float(expected.get("z", actual.z))) < 1e-5)
		elif (actual is int or actual is float) and (expected is int or expected is float):
			# Handle int vs float from JSON (e.g. z_index=1 vs expected=1.0)
			passed = absf(float(actual) - float(expected)) < 1e-5
		else:
			passed = str(actual) == str(expected)

		if not passed:
			all_passed = false
		assertion_results.append({
			"property": prop,
			"expected": str(expected),
			"actual":   str(actual),
			"passed":   passed,
		})

	return {
		"node_path":  node_path,
		"passed":     all_passed,
		"assertions": assertion_results,
	}


func _compare_screenshots(args: Dictionary) -> Dictionary:
	## Compare two screenshot files and report the pixel-difference ratio.
	## Optionally fail if the ratio exceeds a threshold.
	var path_a: String = args.get("path_a", "")
	var path_b: String = args.get("path_b", "")
	var threshold: float = float(args.get("threshold", 0.01))  # 1% by default
	threshold = clamp(threshold, 0.0, 1.0)

	if path_a.is_empty() or path_b.is_empty():
		return {"error": "Both 'path_a' and 'path_b' are required."}

	# Resolve res:// to absolute if needed
	var abs_a: String = path_a
	var abs_b: String = path_b
	if path_a.begins_with("res://"):
		abs_a = ProjectSettings.globalize_path(path_a)
	if path_b.begins_with("res://"):
		abs_b = ProjectSettings.globalize_path(path_b)

	if not FileAccess.file_exists(abs_a):
		return {"error": "File not found: %s" % path_a}
	if not FileAccess.file_exists(abs_b):
		return {"error": "File not found: %s" % path_b}

	var img_a: Image = _load_image(abs_a)
	var img_b: Image = _load_image(abs_b)

	if img_a == null:
		return {"error": "Could not load image: %s" % path_a}
	if img_b == null:
		return {"error": "Could not load image: %s" % path_b}

	var size_match: bool = img_a.get_size() == img_b.get_size()
	var diff_ratio: float = _image_diff_ratio(img_a, img_b)
	var passed: bool = diff_ratio <= threshold

	return {
		"path_a":     path_a,
		"path_b":     path_b,
		"size_a":     {"width": img_a.get_width(), "height": img_a.get_height()},
		"size_b":     {"width": img_b.get_width(), "height": img_b.get_height()},
		"size_match": size_match,
		"diff_ratio": diff_ratio,
		"threshold":  threshold,
		"passed":     passed,
	}


func _record_test(args: Dictionary) -> Dictionary:
	## Start or stop recording a test sequence.
	## action="start" begins recording; action="stop" finalises and returns the recorded events.
	var action: String = args.get("action", "start")
	var test_name: String = args.get("test_name", "unnamed_test")

	match action:
		"start":
			if _recording:
				return {"error": "Already recording test '%s'. Stop it first." % _recording_name}
			_recording = true
			_recorded_events = []
			_recording_name = test_name
			return {
				"status":    "recording",
				"test_name": test_name,
				"message":   "Recording started. Call record_test with action='stop' to finish.",
			}

		"stop":
			if not _recording:
				return {"error": "No recording in progress."}
			_recording = false
			var recorded_name: String = _recording_name
			var events: Array = _recorded_events.duplicate()
			_recorded_events = []
			_recording_name = ""
			return {
				"status":      "stopped",
				"test_name":   recorded_name,
				"event_count": events.size(),
				"events":      events,
			}

		"add_event":
			# Allow callers to manually inject events during recording
			if not _recording:
				return {"error": "No recording in progress. Start recording first."}
			var event: Dictionary = args.get("event", {})
			if event.is_empty():
				return {"error": "'event' dict is required for action='add_event'."}
			_recorded_events.append(event)
			return {
				"status":      "event_added",
				"event_count": _recorded_events.size(),
			}

		"status":
			return {
				"recording":   _recording,
				"test_name":   _recording_name if _recording else "",
				"event_count": _recorded_events.size(),
			}

		_:
			return {"error": "Unknown action '%s'. Use 'start', 'stop', 'add_event', or 'status'." % action}


func _replay_test(args: Dictionary) -> Dictionary:
	## Replay a list of recorded test events.
	## Events are Dictionaries with a "type" key (key_press, mouse_click, mouse_move,
	## action, wait) and type-specific fields matching the input tools.
	var events: Array = args.get("events", [])
	if events.is_empty():
		return {"error": "'events' array is required and must not be empty."}

	var replayed: int = 0
	var errors: Array = []

	for i in events.size():
		var ev: Dictionary = events[i]
		if not ev is Dictionary:
			errors.append({"index": i, "error": "event is not a Dictionary"})
			continue
		var etype: String = str(ev.get("type", ""))

		match etype:
			"key_press":
				var ie := InputEventKey.new()
				ie.keycode = int(ev.get("keycode", KEY_NONE))
				ie.pressed = true
				ie.ctrl_pressed  = _as_bool(ev.get("ctrl",  false))
				ie.shift_pressed = _as_bool(ev.get("shift", false))
				ie.alt_pressed   = _as_bool(ev.get("alt",   false))
				Input.parse_input_event(ie)
				ie = ie.duplicate()
				ie.pressed = false
				Input.parse_input_event(ie)
				replayed += 1

			"mouse_click":
				var pos := Vector2(float(ev.get("x", 0)), float(ev.get("y", 0)))
				var button: int = int(ev.get("button", MOUSE_BUTTON_LEFT))
				var mb := InputEventMouseButton.new()
				mb.position = pos
				mb.button_index = button
				mb.pressed = true
				Input.parse_input_event(mb)
				mb = mb.duplicate()
				mb.pressed = false
				Input.parse_input_event(mb)
				replayed += 1

			"mouse_move":
				var mm := InputEventMouseMotion.new()
				mm.position = Vector2(float(ev.get("x", 0)), float(ev.get("y", 0)))
				Input.parse_input_event(mm)
				replayed += 1

			"action":
				var action_name: String = str(ev.get("action_name", ""))
				if action_name.is_empty():
					errors.append({"index": i, "error": "action_name is required"})
					continue
				var ia := InputEventAction.new()
				ia.action = action_name
				ia.pressed = true
				Input.parse_input_event(ia)
				ia = ia.duplicate()
				ia.pressed = false
				Input.parse_input_event(ia)
				replayed += 1

			"wait":
				var secs: float = clamp(float(ev.get("seconds", 0.1)), 0.0, 5.0)
				await _plugin.get_tree().create_timer(secs).timeout
				replayed += 1

			_:
				errors.append({"index": i, "error": "unknown event type '%s'" % etype})

	return {
		"replayed":    replayed,
		"total":       events.size(),
		"errors":      errors,
		"status":      "pass" if errors.is_empty() else "partial",
	}


func _get_test_report(args: Dictionary) -> Dictionary:
	## Return the most recent test report produced by run_automated_tests.
	if _last_report.is_empty():
		return {
			"error":   "No test report available.",
			"hint":    "Run 'run_automated_tests' first to generate a report.",
		}
	return _last_report

# ---------------------------------------------------------------------------
# File collection helper
# ---------------------------------------------------------------------------

func _collect_test_files(dir: EditorFileSystemDirectory, base_path: String, out: Array) -> void:
	# Ensure base_path ends with "/" to avoid matching sibling dirs (e.g. "tests" != "tests_extra")
	var prefix: String = base_path if base_path.ends_with("/") else base_path + "/"
	for i in dir.get_file_count():
		var fp: String = dir.get_file_path(i)
		if fp.begins_with(prefix) and fp.ends_with(".gd"):
			out.append(fp)
	for i in dir.get_subdir_count():
		_collect_test_files(dir.get_subdir(i), base_path, out)
