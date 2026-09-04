extends SceneTree

## Unit tests for the plugin's pure coercion rules (progress.md 6.1.3).
##
## These are the rules an agent's input meets first, they have no editor
## dependency, and 9.3 showed they are where the copies drifted: `_as_bool`
## answered false for a numeric 1 in eight of nine files, and two copies of
## `_parse_color` pushed an engine error for the project's own documented
## "Color(1, 0, 0)" shorthand. The e2e suite reaches them only indirectly,
## through a live editor, four minutes at a time; this runs headless in ~2s.
##
## Run via `node e2e/unit.mjs`. Exits 0 when everything passes, 1 otherwise.

var _passed := 0
var _failures: Array[String] = []

func _initialize() -> void:
	_test_floats_in()
	_test_to_vector2()
	_test_to_vector3()
	_test_to_color()
	_test_as_bool()
	_test_value_to_json()

	print("[gdunit] %d passed / %d failed" % [_passed, _failures.size()])
	for f in _failures:
		printerr("[gdunit] FAIL %s" % f)
	quit(1 if _failures.size() > 0 else 0)

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

## Compares floats and float-bearing types approximately: these values come out
## of a parse, and 1.8 does not survive a float32 round trip exactly.
func _same(a: Variant, b: Variant) -> bool:
	if a is float and b is float:
		return is_equal_approx(a, b)
	if a is Vector2 and b is Vector2:
		return (a as Vector2).is_equal_approx(b)
	if a is Vector3 and b is Vector3:
		return (a as Vector3).is_equal_approx(b)
	if a is Color and b is Color:
		return (a as Color).is_equal_approx(b)
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _same(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for k in b:
			if not a.has(k) or not _same(a[k], b[k]):
				return false
		return true
	return a == b

func check(label: String, actual: Variant, expected: Variant) -> void:
	if _same(actual, expected):
		_passed += 1
	else:
		_failures.append("%s\n    expected: %s\n    actual:   %s" % [label, str(expected), str(actual)])

# ---------------------------------------------------------------------------
# GodotMCPTypeUtils.floats_in
# ---------------------------------------------------------------------------

func _test_floats_in() -> void:
	var f := func(s): return GodotMCPTypeUtils.floats_in(s)

	check("floats_in reads the components", f.call("Vector2(1, 2)"), [1.0, 2.0])
	# The load-bearing case: only the text between the parentheses is scanned, or
	# the 2 in "Vector2" and the 3 in "Vector3" would be read as a component.
	check("floats_in ignores digits in the type name", f.call("Vector3(7, 8, 9)"), [7.0, 8.0, 9.0])
	check("floats_in handles Rect2", f.call("Rect2(1, 2, 3, 4)"), [1.0, 2.0, 3.0, 4.0])
	check("floats_in keeps negatives", f.call("Vector3(-1.5, 0, 2)"), [-1.5, 0.0, 2.0])
	check("floats_in reads a bare list", f.call("1, 0, 0"), [1.0, 0.0, 0.0])
	check("floats_in on text without numbers", f.call("nonsense"), [])

# ---------------------------------------------------------------------------
# GodotMCPTypeUtils.to_vector2 / to_vector3
# ---------------------------------------------------------------------------

func _test_to_vector2() -> void:
	var f := func(v): return GodotMCPTypeUtils.to_vector2(v)

	check("to_vector2 passes a Vector2 through", f.call(Vector2(1, 2)), Vector2(1, 2))
	check("to_vector2 widens a Vector2i", f.call(Vector2i(3, 4)), Vector2(3, 4))
	check("to_vector2 from a dictionary", f.call({"x": 5, "y": 6}), Vector2(5, 6))
	check("to_vector2 from an array", f.call([7, 8]), Vector2(7, 8))
	check("to_vector2 from the string shorthand", f.call("Vector2(9, 10)"), Vector2(9, 10))
	check("to_vector2 spreads a single number", f.call("4"), Vector2(4, 4))
	check("to_vector2 missing keys default to zero", f.call({"x": 5}), Vector2(5, 0))
	check("to_vector2 falls back on garbage", f.call("nonsense"), Vector2.ZERO)
	check("to_vector2 falls back on a short array", f.call([1]), Vector2.ZERO)
	check("to_vector2 falls back on null", f.call(null), Vector2.ZERO)
	check("to_vector2 honours an explicit default",
		GodotMCPTypeUtils.to_vector2(null, Vector2.ONE), Vector2.ONE)

func _test_to_vector3() -> void:
	var f := func(v): return GodotMCPTypeUtils.to_vector3(v)

	check("to_vector3 passes a Vector3 through", f.call(Vector3(1, 2, 3)), Vector3(1, 2, 3))
	check("to_vector3 widens a Vector3i", f.call(Vector3i(4, 5, 6)), Vector3(4, 5, 6))
	check("to_vector3 from a dictionary", f.call({"x": 1, "y": 2, "z": 3}), Vector3(1, 2, 3))
	check("to_vector3 from an array", f.call([1, 2, 3]), Vector3(1, 2, 3))
	# 6.6.14: this exact form reached add_camera and was dropped, so the camera
	# went to the origin while the tool reported success.
	check("to_vector3 from the string shorthand", f.call("Vector3(0, 2, 5)"), Vector3(0, 2, 5))
	check("to_vector3 keeps fractional components", f.call("Vector3(0.35, 1.8, -2.25)"), Vector3(0.35, 1.8, -2.25))
	check("to_vector3 spreads a single number", f.call("2"), Vector3(2, 2, 2))
	check("to_vector3 falls back on a short array", f.call([1, 2]), Vector3.ZERO)
	check("to_vector3 falls back on garbage", f.call("nonsense"), Vector3.ZERO)
	check("to_vector3 honours an explicit default",
		GodotMCPTypeUtils.to_vector3(null, Vector3.ONE), Vector3.ONE)

# ---------------------------------------------------------------------------
# GodotMCPTypeUtils.to_color
# ---------------------------------------------------------------------------

func _test_to_color() -> void:
	var f := func(v): return GodotMCPTypeUtils.to_color(v)

	check("to_color passes a Color through", f.call(Color(0.1, 0.2, 0.3, 0.4)), Color(0.1, 0.2, 0.3, 0.4))
	check("to_color from a dictionary", f.call({"r": 1, "g": 0, "b": 0, "a": 1}), Color(1, 0, 0, 1))
	check("to_color from a dictionary defaults alpha", f.call({"r": 0, "g": 1, "b": 0}), Color(0, 1, 0, 1))
	check("to_color from a 3-array", f.call([1, 0, 0]), Color(1, 0, 0, 1))
	check("to_color from a 4-array", f.call([1, 0, 0, 0.5]), Color(1, 0, 0, 0.5))
	check("to_color from #rrggbb", f.call("#ff0000"), Color(1, 0, 0, 1))
	check("to_color from bare hex", f.call("ff0000"), Color(1, 0, 0, 1))
	check("to_color from #rrggbbaa", f.call("#ff000080"), Color(1, 0, 0, 128.0 / 255.0))
	# Two of the four copies passed this straight to Color(String), which expects
	# HTML and pushes an engine error for anything else — so the project's own
	# documented shorthand failed loudly in one tool and worked in another.
	check("to_color from the Color() shorthand", f.call("Color(1, 0, 0)"), Color(1, 0, 0, 1))
	check("to_color from Color() with alpha", f.call("Color(0.5, 0.25, 0.125, 0.75)"), Color(0.5, 0.25, 0.125, 0.75))
	check("to_color from a bare component list", f.call("1, 0, 0"), Color(1, 0, 0, 1))
	check("to_color falls back on an empty string", f.call(""), Color.WHITE)
	check("to_color falls back on garbage", f.call("nonsense"), Color.WHITE)
	check("to_color honours an explicit default",
		GodotMCPTypeUtils.to_color("nonsense", Color.BLACK), Color.BLACK)

# ---------------------------------------------------------------------------
# GodotMCPToolBase._as_bool / _value_to_json
# ---------------------------------------------------------------------------

func _test_as_bool() -> void:
	var base := GodotMCPToolBase.new()

	check("_as_bool of true", base._as_bool(true), true)
	check("_as_bool of false", base._as_bool(false), false)
	check("_as_bool of \"true\"", base._as_bool("true"), true)
	check("_as_bool is case-insensitive", base._as_bool("TRUE"), true)
	# The reason this helper exists (3.16b): bool("false") is true in GDScript,
	# because every non-empty string is.
	check("_as_bool of \"false\"", base._as_bool("false"), false)
	check("_as_bool of \"1\"", base._as_bool("1"), true)
	check("_as_bool of \"0\"", base._as_bool("0"), false)
	check("_as_bool of \"yes\"", base._as_bool("yes"), true)
	# 9.3 found eight of the nine copies answering false here, for clients that
	# send numbers rather than JSON booleans.
	check("_as_bool of numeric 1", base._as_bool(1), true)
	check("_as_bool of numeric 0", base._as_bool(0), false)
	check("_as_bool of an empty string", base._as_bool(""), false)
	check("_as_bool of null", base._as_bool(null), false)

func _test_value_to_json() -> void:
	var base := GodotMCPToolBase.new()

	check("_value_to_json passes an int through", base._value_to_json(7), 7)
	check("_value_to_json passes a string through", base._value_to_json("hi"), "hi")
	check("_value_to_json of Vector2", base._value_to_json(Vector2(1, 2)), {"x": 1.0, "y": 2.0})
	check("_value_to_json of Vector2i", base._value_to_json(Vector2i(1, 2)), {"x": 1, "y": 2})
	check("_value_to_json of Vector3", base._value_to_json(Vector3(1, 2, 3)), {"x": 1.0, "y": 2.0, "z": 3.0})
	check("_value_to_json of Color", base._value_to_json(Color(1, 0, 0, 1)), {"r": 1.0, "g": 0.0, "b": 0.0, "a": 1.0})
	check("_value_to_json of Rect2", base._value_to_json(Rect2(1, 2, 3, 4)), {"x": 1.0, "y": 2.0, "w": 3.0, "h": 4.0})
	check("_value_to_json of Quaternion",
		base._value_to_json(Quaternion(0, 0, 0, 1)), {"x": 0.0, "y": 0.0, "z": 0.0, "w": 1.0})

	# The node_tools copy rendered this as str(v) — "[X: (1, 0), Y: (0, 1), O: (0, 0)]",
	# which a client can display but not read back. The structured form is the point.
	# Explicitly Variant: `:=` on a Variant-returning call is a warning, and the
	# addon's project settings promote warnings to errors.
	var t2: Variant = base._value_to_json(Transform2D.IDENTITY)
	check("_value_to_json of Transform2D is structured, not a string", t2 is Dictionary, true)
	check("_value_to_json of Transform2D origin", t2.get("origin"), {"x": 0.0, "y": 0.0})
	check("_value_to_json of Transform2D x axis", t2.get("x"), {"x": 1.0, "y": 0.0})

	var t3: Variant = base._value_to_json(Transform3D.IDENTITY)
	check("_value_to_json of Transform3D is structured", t3 is Dictionary, true)
	check("_value_to_json of Transform3D origin", t3.get("origin"), {"x": 0.0, "y": 0.0, "z": 0.0})
	check("_value_to_json of Transform3D basis x", t3.get("basis").get("x"), {"x": 1.0, "y": 0.0, "z": 0.0})

	# A Resource comes back as the path a client can act on; anything else as text.
	var res := Resource.new()
	check("_value_to_json of a pathless Resource is a string", base._value_to_json(res) is String, true)
