@tool
extends RefCounted

class_name GodotMCPTypeUtils

## Shared coercion for values that arrive over JSON, where a vector can only be
## an object, an array or a string. The string form ("Vector3(0, 2, 5)") is the
## project's documented shorthand and what node_tools already accepts, so every
## tool that takes a vector has to understand it -- dropping it silently turned
## "put the camera at (0, 2, 5)" into a no-op that still reported success.

## Numbers inside a Godot type literal. Only the text between the parentheses
## is scanned, so digits in the type name ("Vector2", "Rect2") are not read as
## components.
static func floats_in(text: String) -> Array:
	var body := text
	var open := text.find("(")
	var close := text.rfind(")")
	if open != -1 and close > open:
		body = text.substr(open + 1, close - open - 1)
	var numbers: Array = []
	var re := RegEx.new()
	re.compile(r"-?\d+(\.\d+)?")
	for m in re.search_all(body):
		numbers.append(float(m.get_string()))
	return numbers

static func to_vector2(val: Variant, default_val: Vector2 = Vector2.ZERO) -> Vector2:
	if val is Vector2:
		return val
	if val is Vector2i:
		return Vector2(val.x, val.y)
	if val is Dictionary:
		return Vector2(float(val.get("x", 0.0)), float(val.get("y", 0.0)))
	if val is Array and val.size() >= 2:
		return Vector2(float(val[0]), float(val[1]))
	if val is String:
		var n := floats_in(val)
		if n.size() >= 2:
			return Vector2(n[0], n[1])
		if n.size() == 1:
			return Vector2(n[0], n[0])
	return default_val

static func to_vector3(val: Variant, default_val: Vector3 = Vector3.ZERO) -> Vector3:
	if val is Vector3:
		return val
	if val is Vector3i:
		return Vector3(val.x, val.y, val.z)
	if val is Dictionary:
		return Vector3(float(val.get("x", 0.0)), float(val.get("y", 0.0)), float(val.get("z", 0.0)))
	if val is Array and val.size() >= 3:
		return Vector3(float(val[0]), float(val[1]), float(val[2]))
	if val is String:
		var n := floats_in(val)
		if n.size() >= 3:
			return Vector3(n[0], n[1], n[2])
		if n.size() == 1:
			return Vector3(n[0], n[0], n[0])
	return default_val

## Colour from any of the forms a client sends. Union of the four copies that
## used to live in the node/particle/scene_3d/theme tools, each accepting a
## different subset: two of them passed a "Color(1, 0, 0)" string straight to
## Color(String), which expects HTML and pushes an engine error for anything
## else -- so the documented shorthand failed loudly in one tool and worked in
## another. Order matters: the structured forms are tried before the loose
## number scan, so "Color(1, 0, 0)" is not mistaken for a bare "1, 0, 0".
static func to_color(val: Variant, default_val: Color = Color.WHITE) -> Color:
	if val is Color:
		return val
	if val is Dictionary:
		return Color(
			float(val.get("r", 1.0)), float(val.get("g", 1.0)),
			float(val.get("b", 1.0)), float(val.get("a", 1.0)))
	if val is Array and val.size() >= 3:
		return Color(float(val[0]), float(val[1]), float(val[2]),
			float(val[3]) if val.size() >= 4 else 1.0)
	if val is String:
		var s: String = (val as String).strip_edges()
		if s.is_empty():
			return default_val
		if s.begins_with("Color("):
			var n := floats_in(s)
			if n.size() >= 3:
				return Color(n[0], n[1], n[2], n[3] if n.size() >= 4 else 1.0)
			return default_val
		# Godot's own validator: covers "#rrggbb", "#rrggbbaa", "#rgb" and bare hex
		if Color.html_is_valid(s):
			return Color.html(s)
		if Color.html_is_valid("#" + s):
			return Color.html("#" + s)
		# Bare component list, e.g. "1, 0, 0" -- what the node_tools copy accepted
		var loose := floats_in(s)
		if loose.size() >= 3:
			return Color(loose[0], loose[1], loose[2], loose[3] if loose.size() >= 4 else 1.0)
	return default_val
