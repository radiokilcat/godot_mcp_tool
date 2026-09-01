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

static func _cache_file(suffix: String) -> String:
	return OS.get_cache_dir().path_join("godot_mcp_syntax_check_%d%s" % [OS.get_process_id(), suffix])

## Parse errors for a script file, as [{line, message}]. line_offset is
## subtracted from every line, for sources that were wrapped in a header before
## compiling. Returns an empty array if the check could not be run at all.
static func check_path(script_path: String, line_offset: int = 0) -> Array:
	var exe := OS.get_executable_path()
	if exe.is_empty() or not FileAccess.file_exists(script_path):
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
	OS.execute(exe, args, output, true)
	var text := ""
	for chunk in output:
		text += str(chunk) + "\n"

	if "Unknown command line argument" in text:
		# --log-file is newer than the engine in use. Run without it and accept
		# that this rotates the project's log.
		args.erase("--log-file")
		args.erase(log_path)
		output.clear()
		OS.execute(exe, args, output, true)
		text = ""
		for chunk in output:
			text += str(chunk) + "\n"

	DirAccess.remove_absolute(log_path)
	return parse_diagnostics(text, line_offset)

## Same, for source that is not on disk yet.
static func check_source(source: String, line_offset: int = 0) -> Array:
	var probe_path := _cache_file(".gd")
	var file := FileAccess.open(probe_path, FileAccess.WRITE)
	if file == null:
		return []
	file.store_string(source)
	file.close()
	var diagnostics := check_path(probe_path, line_offset)
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
static func describe(diagnostics: Array, fallback: String) -> String:
	if diagnostics.is_empty():
		return fallback
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
