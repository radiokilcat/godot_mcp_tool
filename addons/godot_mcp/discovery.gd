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
## `is_private` marks an editor that was told which port to listen on, which in
## practice means a harness launched it. The entry is still written — the harness
## reads the token straight out of it — but a session doing ordinary discovery
## skips it. Without that, a throwaway e2e editor is the only one running, so any
## idle MCP session on the machine picks it up and starts issuing calls into a
## project that is about to be deleted.
static func publish(port: int, token: String, plugin_version: String, is_private: bool = false) -> String:
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
		"private": is_private,
	}

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(entry))
	file.close()
	_restrict_permissions(file_path)
	return file_path

## Remove this editor's entry, but only while it is still this editor's. The file
## is named per project, not per process, so any second engine opened on the same
## project writes to the same path, and deleting blindly on exit erased whatever
## entry was there by then: a live editor's, if it had re-published in between.
## The token is the ownership test because it is unique per launch; the pid is not
## (a reused pid would match). Anything unreadable is left alone: the server drops
## entries whose pid is dead, so a stray file costs nothing and a wrong delete
## costs the user their connection.
static func withdraw(file_path: String, token: String) -> void:
	if file_path.is_empty() or token.is_empty():
		return
	if not FileAccess.file_exists(file_path):
		return
	if _read_token(file_path) != token:
		return
	DirAccess.remove_absolute(file_path)

## JSON.new().parse() rather than JSON.parse_string(): a half-written or foreign
## file is an expected case here, and it should not put an error in the Output panel.
static func _read_token(file_path: String) -> String:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return ""
	var data: Variant = json.data
	if data is Dictionary:
		return str(data.get("token", ""))
	return ""

## Flags under which the engine opens the project as an editor, runs one export and
## exits. Only these: `--import`, `--quit`, `--quit-after`, `--headless` and `--path`
## are consumed while the engine parses its arguments and never reach
## OS.get_cmdline_args() (an import run reports just ["--editor"], measured on
## 4.4.1), so the headless rule below is what catches an import.
const ONE_SHOT_FLAGS := ["--export-release", "--export-debug", "--export-pack", "--export-patch"]

## Why this engine should not start the bridge, or "" if it should.
##
## `godot --headless --import` loads the plugin like any editor, and because the
## discovery file is named after the project it overwrote the entry of the editor
## the user had open, then deleted it on exit. Every session after that got "No
## running Godot editor found" while the editor sat there listening. The plugin's
## own export_project spawns exactly such an engine, so this was self-inflicted too.
##
## A one-shot run never needs the bridge: nobody can attach before it quits. The
## flag list cannot name every tool that drives a headless editor, though, and a
## headless editor has no user in front of it, so by default it stays off discovery
## as well. The e2e harness runs real headless editors that must listen; it always
## sets GODOT_MCP_PORT, so for headless that variable is the opt-in. `0` counts: it
## opts in while still letting the OS pick the port.
static func bridge_skip_reason(cmdline_args: PackedStringArray, display_server: String, port_env: String) -> String:
	for arg in cmdline_args:
		if arg in ONE_SHOT_FLAGS:
			return "the engine was started with %s and will exit when done" % arg
	if display_server == "headless" and port_env.is_empty():
		return "the engine is headless and GODOT_MCP_PORT is not set (set it, 0 included, to run the bridge headless)"
	return ""

## GDScript has no chmod, and the default 0644 would leave the token readable by
## every local account. Shelling out is unlovely but it is the only route, and it
## is a no-op on Windows where the profile directory is already the boundary.
static func _restrict_permissions(file_path: String) -> void:
	if OS.has_feature("windows"):
		return
	OS.execute("chmod", ["600", file_path])
