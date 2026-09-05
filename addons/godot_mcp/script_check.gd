@tool
extends RefCounted

class_name GodotMCPScriptCheck

## Recovers the parser's actual complaint about a piece of GDScript.
##
## GDScript.reload() hands back an error code and nothing else -- the message
## and the line it happened on are printed to the process's stderr, where no
## caller can reach them, so a typo could only be found by eye. Running the
## editor's own binary again with --check-only prints both. It costs ~0.3-1.2s
## and only happens on a path where the script has already failed to compile.
##
## The probe file goes in the OS cache dir, not user://, so it does not depend
## on the editor and the subprocess resolving user:// to the same place (they
## do not in self-contained mode), and --log-file keeps the subprocess from
## rotating the project's own log, which get_error_log reads.

## Scratch path for the probe and the subprocess log. The cache dir is not
## guaranteed to exist — it is $XDG_CACHE_HOME or ~/.cache on Linux and the
## engine does not create it — and FileAccess will not create intermediate
## directories, so a missing one turns into a silent "no diagnostics".
static func _cache_file(suffix: String) -> String:
	var dir := OS.get_cache_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	if not DirAccess.dir_exists_absolute(dir):
		# Nowhere to scratch in the cache dir; user:// always exists.
		dir = ProjectSettings.globalize_path("user://")
	return dir.path_join("godot_mcp_syntax_check_%d%s" % [OS.get_process_id(), suffix])

## Record why a check produced nothing, when the caller offered somewhere to put
## it. Without this the tool falls back to the pre-6.6.5 message, which names an
## error code and no reason — and the reason is the whole point of this file.
static func _note(status: Variant, reason: String) -> void:
	if status is Dictionary:
		status["reason"] = reason

## Parse errors for a script file, as [{line, message}]. line_offset is
## subtracted from every line, for sources that were wrapped in a header before
## compiling. Returns an empty array if the check could not be run at all.
static func check_path(script_path: String, line_offset: int = 0, status: Variant = null) -> Array:
	var exe := OS.get_executable_path()
	if exe.is_empty():
		_note(status, "the engine did not report its own executable path")
		return []
	if not FileAccess.file_exists(script_path):
		_note(status, "the script to check was not readable at %s" % script_path)
		return []

	var log_path := _cache_file(".log")
	var args: Array = [
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--log-file", log_path,
		"--check-only",
		"--script", script_path,
	]
	var output: Array = []
	var exit_code := OS.execute(exe, args, output, true)
	var text := ""
	for chunk in output:
		text += str(chunk) + "\n"

	if "Unknown command line argument" in text:
		# --log-file is newer than the engine in use. Run without it and accept
		# that this rotates the project's log.
		args.erase("--log-file")
		args.erase(log_path)
		output.clear()
		exit_code = OS.execute(exe, args, output, true)
		text = ""
		for chunk in output:
			text += str(chunk) + "\n"

	DirAccess.remove_absolute(log_path)
	var diagnostics := parse_diagnostics(text, line_offset)
	if diagnostics.is_empty():
		# The subprocess ran but said nothing this parser recognises. Keep the
		# tail: whatever it did say is the only lead, and losing it is how this
		# ends up as an unexplained "no diagnostics" on someone else's platform.
		if exit_code == -1:
			_note(status, "could not run %s to re-check the script" % exe)
		else:
			var tail := text.strip_edges()
			if tail.length() > 400:
				tail = tail.substr(tail.length() - 400)
			_note(status, "the re-check exited %d without a recognised parse error%s"
				% [exit_code, "" if tail.is_empty() else "; it printed: " + tail])
	return diagnostics

## Same, for source that is not on disk yet.
static func check_source(source: String, line_offset: int = 0, status: Variant = null) -> Array:
	var probe_path := _cache_file(".gd")
	var file := FileAccess.open(probe_path, FileAccess.WRITE)
	if file == null:
		_note(status, "could not write the probe file to %s (%s)"
			% [probe_path, error_string(FileAccess.get_open_error())])
		return []
	file.store_string(source)
	file.close()
	var diagnostics := check_path(probe_path, line_offset, status)
	DirAccess.remove_absolute(probe_path)
	return diagnostics

## Godot reports a parse error as a message line followed by a location line:
##   SCRIPT ERROR: Parse Error: Identifier "foo" not declared in the current scope.
##      at: GDScript::reload (C:/path/probe.gd:6)
static func parse_diagnostics(text: String, line_offset: int = 0) -> Array:
	var diagnostics: Array = []
	var pending := ""
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		var message := ""
		if line.begins_with("SCRIPT ERROR: Parse Error: "):
			message = line.substr("SCRIPT ERROR: Parse Error: ".length())
		elif line.begins_with("SCRIPT ERROR: Compile Error: "):
			message = line.substr("SCRIPT ERROR: Compile Error: ".length())
		if not message.is_empty():
			if not pending.is_empty():
				diagnostics.append({"message": pending})
			pending = message
			continue
		if not pending.is_empty() and line.begins_with("at: "):
			var reported := _line_number(line)
			if reported > 0:
				diagnostics.append({"line": max(1, reported - line_offset), "message": pending})
			else:
				diagnostics.append({"message": pending})
			pending = ""
	if not pending.is_empty():
		diagnostics.append({"message": pending})
	return diagnostics

## Line number out of "at: GDScript::reload (C:/path/probe.gd:6)". Both the
## drive letter and the C++ scope operator contain colons, so the search runs
## backwards from the closing parenthesis.
static func _line_number(at_line: String) -> int:
	var close := at_line.rfind(")")
	if close == -1:
		return 0
	var colon := at_line.rfind(":", close)
	if colon == -1 or close <= colon + 1:
		return 0
	return int(at_line.substr(colon + 1, close - colon - 1))

## Human-readable summary for an error response. Several entries are folded
## into the one string because a tool that fails answers over the error channel,
## which carries no structured payload -- the 'diagnostics' array only reaches
## callers of tools that report a failure as an ordinary result.
static func describe(diagnostics: Array, fallback: String, status: Variant = null) -> String:
	if diagnostics.is_empty():
		var reason := ""
		if status is Dictionary:
			reason = str((status as Dictionary).get("reason", ""))
		return fallback if reason.is_empty() else "%s (could not recover the parser's message: %s)" % [fallback, reason]
	var shown: Array = []
	for entry in diagnostics.slice(0, 3):
		var one: Dictionary = entry
		var text: String = str(one.get("message", ""))
		if one.has("line"):
			text = "line %d: %s" % [int(one["line"]), text]
		shown.append(text)
	var summary: String = "; ".join(PackedStringArray(shown))
	if diagnostics.size() > shown.size():
		summary += " (+%d more)" % (diagnostics.size() - shown.size())
	return summary
