@tool
extends RefCounted

class_name GodotMCPVersionUtils

## Shared helpers for feature-detecting the running Godot engine version.
##
## GDScript resolves class names and singleton constants at parse time, so a
## script that statically references a class/constant introduced in a later
## Godot version (e.g. "TileMapLayer", "Performance.MEMORY_DYNAMIC") will fail
## to *load* on an engine build that predates it — an `if` guard around the
## reference does not help, because parsing happens before the guard runs.
##
## Two different problems need two different tools:
## - "Does the engine support X" where X is a class/constant that may not
##   exist at all on some versions -> use the ClassDB.* lookups below, which
##   take names as Strings and never touch the missing symbol directly.
## - "Which code path should I take" where both paths reference only symbols
##   that exist on every supported version -> use at_least()/before().

static func info() -> Dictionary:
	return Engine.get_version_info()

static func major() -> int:
	return Engine.get_version_info().get("major", 0)

static func minor() -> int:
	return Engine.get_version_info().get("minor", 0)

static func patch() -> int:
	return Engine.get_version_info().get("patch", 0)

static func version_string() -> String:
	return Engine.get_version_info().get("string", "")

## True if the running engine is >= major.minor.patch
static func at_least(req_major: int, req_minor: int = 0, req_patch: int = 0) -> bool:
	var v := Engine.get_version_info()
	var maj: int = v.get("major", 0)
	var min_: int = v.get("minor", 0)
	var pat: int = v.get("patch", 0)
	if maj != req_major:
		return maj > req_major
	if min_ != req_minor:
		return min_ > req_minor
	return pat >= req_patch

## True if the running engine is < major.minor.patch
static func before(req_major: int, req_minor: int = 0, req_patch: int = 0) -> bool:
	return not at_least(req_major, req_minor, req_patch)

## Does a class with this name exist on the running engine build?
## Safe to call with class names that don't exist on this version (e.g.
## "TileMapLayer" on Godot 4.0-4.2) — never causes a parse error since the
## name is passed as a String, not referenced as a type.
static func has_class(class_name_str: String) -> bool:
	return ClassDB.class_exists(class_name_str)

## Does `class_name_str` currently expose an integer constant named
## `constant_name`? Use this before reading engine constants that were added
## or removed between versions (e.g. Performance.MEMORY_DYNAMIC, removed in
## Godot 4.4).
static func has_constant(class_name_str: String, constant_name: String) -> bool:
	return ClassDB.class_has_integer_constant(class_name_str, constant_name)

## Look up an integer constant dynamically by name, returning `default_value`
## if the class or constant doesn't exist on this engine build. Pairs with
## has_constant() to read version-sensitive singleton constants without a
## static reference that would fail to parse on engines lacking them.
static func get_constant(class_name_str: String, constant_name: String, default_value: int = -1) -> int:
	if not ClassDB.class_has_integer_constant(class_name_str, constant_name):
		return default_value
	return ClassDB.class_get_integer_constant(class_name_str, constant_name)
