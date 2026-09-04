@tool
extends RefCounted

class_name GodotMCPDiscovery

## How an MCP server process finds the editor to talk to (progress.md 6.5.6).
##
## The plan called for a file under `res://.godot/`, and that does not work: the
## server has no idea where the project is. `.mcp.json` carries an absolute path to
## the *server*, never to the Godot project, and the client's working directory is
## whatever it happened to be launched from. A project-local file is only findable
## by someone who already knows the answer.
##
## So the registry is machine-wide — one small JSON file per running editor under
## ~/.godot-mcp/instances/ — and the server picks from it (see server/src/discovery.ts
## for the selection rules). This also gives the multi-project story for free: two
## editors write two files on two ports and never collide.
##
## The file holds a credential, so it is created 0600 where the OS has a notion of
## that. On Windows the per-user profile is the boundary instead.

const FORMAT_VERSION := 1
const DIR_NAME := ".godot-mcp"
const INSTANCES_DIR := "instances"

static func _home_dir() -> String:
	var home := OS.get_environment("USERPROFILE") if OS.has_feature("windows") else OS.get_environment("HOME")
	if home.is_empty():
		# Last resort: keep the editor working even somewhere without a home
		# directory. The server can still be pointed at the port explicitly.
		home = OS.get_user_data_dir()
	return home

static func instances_dir() -> String:
	return _home_dir().path_join(DIR_NAME).path_join(INSTANCES_DIR)

## A stable per-project file name, so re-opening the same project replaces its own
## entry instead of accumulating one per launch.
static func instance_id(project_path: String) -> String:
	return project_path.to_lower().sha256_text().substr(0, 16)

## 256 bits from the platform CSPRNG. Not `randi()`: the token is the only thing
## between `execute_script` and any web page the developer has open, since
## WebSocket ignores same-origin and a page may connect to ws://127.0.0.1:<port>.
static func generate_token() -> String:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(32).hex_encode()

## Write (or replace) this editor's entry. Returns the file path, or "" on failure.
static func publish(port: int, token: String, plugin_version: String) -> String:
	var dir_path := instances_dir()
	var dir := DirAccess.open(_home_dir())
	if dir == null:
		return ""
	if dir.make_dir_recursive(DIR_NAME.path_join(INSTANCES_DIR)) != OK \
			and not DirAccess.dir_exists_absolute(dir_path):
		return ""

	var project_path := ProjectSettings.globalize_path("res://")
	var file_path := dir_path.path_join(instance_id(project_path) + ".json")

	var entry := {
		"format": FORMAT_VERSION,
		"port": port,
		"token": token,
		"project_path": project_path,
		"project_name": ProjectSettings.get_setting("application/config/name", ""),
		"pid": OS.get_process_id(),
		"godot_version": Engine.get_version_info().get("string", ""),
		"plugin_version": plugin_version,
		"started_at": Time.get_datetime_string_from_system(true),
	}

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(entry))
	file.close()
	_restrict_permissions(file_path)
	return file_path

static func withdraw(file_path: String) -> void:
	if file_path.is_empty():
		return
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

## GDScript has no chmod, and the default 0644 would leave the token readable by
## every local account. Shelling out is unlovely but it is the only route, and it
## is a no-op on Windows where the profile directory is already the boundary.
static func _restrict_permissions(file_path: String) -> void:
	if OS.has_feature("windows"):
		return
	OS.execute("chmod", ["600", file_path])
