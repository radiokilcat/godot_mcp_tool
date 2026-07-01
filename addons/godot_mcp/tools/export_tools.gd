@tool
extends RefCounted

class_name GodotMCPExportTools

## Implements 3 Export tools:
## list_export_presets, export_project, get_template_info

var _plugin: EditorPlugin

func _init(plugin: EditorPlugin) -> void:
	_plugin = plugin

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("list_export_presets", GodotMCPCallableTool.new(_list_export_presets))
	registry.register_tool("export_project",      GodotMCPCallableTool.new(_export_project))
	registry.register_tool("get_template_info",   GodotMCPCallableTool.new(_get_template_info))

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _list_export_presets(_args: Dictionary) -> Dictionary:
	## Return all export presets defined in export_presets.cfg.
	var config: ConfigFile = ConfigFile.new()
	var cfg_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(cfg_path):
		return {"presets": [], "note": "No export_presets.cfg found in project root."}

	var err: int = config.load(cfg_path)
	if err != OK:
		return {"error": "Failed to read export_presets.cfg (error %d)." % err}

	var presets: Array = []
	var idx: int = 0
	while config.has_section("preset.%d" % idx):
		var section: String = "preset.%d" % idx
		var preset: Dictionary = {
			"index":    idx,
			"name":     config.get_value(section, "name", ""),
			"platform": config.get_value(section, "platform", ""),
			"runnable": config.get_value(section, "runnable", false),
			"export_path": config.get_value(section, "export_path", ""),
			"dedicated_server": config.get_value(section, "dedicated_server", false),
			"custom_features": config.get_value(section, "custom_features", ""),
		}
		var options_section: String = "preset.%d.options" % idx
		if config.has_section(options_section):
			var options: Dictionary = {}
			for key in config.get_section_keys(options_section):
				options[key] = config.get_value(options_section, key)
			preset["options"] = options
		presets.append(preset)
		idx += 1

	return {"presets": presets, "count": presets.size()}


func _export_project(args: Dictionary) -> Dictionary:
	## Export the project using godot --headless --export-release/debug.
	## Note: OS.execute() is synchronous — the editor main thread is blocked
	## for the duration of the export. Large projects may take several minutes.
	var preset_name: String = str(args.get("preset_name", ""))
	var output_path: String = str(args.get("output_path", ""))
	var debug: bool = _as_bool(args.get("debug", false))

	if preset_name.is_empty():
		return {"error": "preset_name is required."}

	var config: ConfigFile = ConfigFile.new()
	var cfg_path: String = "res://export_presets.cfg"
	if not FileAccess.file_exists(cfg_path):
		return {"error": "No export_presets.cfg found — create at least one export preset first."}

	var err: int = config.load(cfg_path)
	if err != OK:
		return {"error": "Failed to read export_presets.cfg (error %d)." % err}

	var preset_export_path: String = ""
	var found: bool = false
	var idx: int = 0
	while config.has_section("preset.%d" % idx):
		var section: String = "preset.%d" % idx
		if config.get_value(section, "name", "") == preset_name:
			preset_export_path = config.get_value(section, "export_path", "")
			found = true
			break
		idx += 1

	if not found:
		return {"error": "Export preset '%s' not found." % preset_name}

	# Resolve output path: use explicit arg or preset's configured path.
	var resolved_path: String = output_path if not output_path.is_empty() else preset_export_path
	if resolved_path.is_empty():
		return {"error": "No output_path provided and preset has no export_path configured."}

	return _run_export(preset_name, resolved_path, debug)


func _get_template_info(_args: Dictionary) -> Dictionary:
	## Return information about installed export templates.
	var version_info: Dictionary = Engine.get_version_info()
	# version_string is e.g. "4.2.2.stable" — used directly as template dir name.
	var version_string: String = version_info.get("string", "")

	var templates_base: String = "user://export_templates"
	# Godot stores templates in <base>/<version_string>/ (e.g. "4.2.2.stable"),
	# not just the numeric part — use version_string directly.
	var version_dir: String = templates_base + "/" + version_string

	var result: Dictionary = {
		"engine_version": version_string,
		"templates_base_dir": ProjectSettings.globalize_path(templates_base),
		"version_dir": ProjectSettings.globalize_path(version_dir),
	}

	# Check if templates directory exists for this version.
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(version_dir)):
		result["templates_installed"] = true
		# List available platform directories.
		var dir: DirAccess = DirAccess.open(version_dir)
		if dir != null:
			var platforms: Array = []
			dir.list_dir_begin()
			var entry: String = dir.get_next()
			while entry != "":
				if not entry.begins_with("."):
					platforms.append(entry)
				entry = dir.get_next()
			dir.list_dir_end()
			platforms.sort()
			result["platform_entries"] = platforms
	else:
		result["templates_installed"] = false
		result["note"] = (
			"Export templates for v%s are not installed. " % version_string +
			"Download them via Editor > Export > Manage Export Templates, or " +
			"place them in: %s" % ProjectSettings.globalize_path(version_dir)
		)

	return result

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _run_export(preset_name: String, output_path: String, debug: bool) -> Dictionary:
	## Invoke godot --export-release/--export-debug via OS.execute.
	## Caution: this call blocks the editor main thread until export completes.
	var godot_exe: String = OS.get_executable_path()
	if godot_exe.is_empty():
		return {"error": "Could not determine Godot executable path."}

	var project_path: String = ProjectSettings.globalize_path("res://")
	var flag: String = "--export-debug" if debug else "--export-release"

	# Resolve output_path: keep absolute paths as-is, prefix relative with project dir.
	var abs_output: String = output_path
	if not abs_output.is_absolute_path():
		abs_output = project_path.path_join(output_path)

	# Ensure output directory exists.
	# Use instance-based make_dir_recursive for Godot 4.0 compatibility.
	# (DirAccess.make_dir_recursive_absolute is Godot 4.1+)
	var out_dir: String = abs_output.get_base_dir()
	if not DirAccess.dir_exists_absolute(out_dir):
		var da: DirAccess = DirAccess.open("user://")
		var mk_err: int = FAILED if da == null else da.make_dir_recursive(out_dir)
		if mk_err != OK:
			return {"error": "Could not create output directory '%s' (error %d)." % [out_dir, mk_err]}

	var args_list: PackedStringArray = PackedStringArray([
		"--headless",
		"--path", project_path,
		flag, preset_name, abs_output,
	])

	# OS.execute() 4th param is read_stderr: bool. Pass true to capture stderr
	# into the same output array (there is no separate stderr capture in Godot 4).
	var output: Array = []
	var exit_code: int = OS.execute(godot_exe, args_list, output, true)

	var output_text: String = "\n".join(output) if output.size() > 0 else ""

	if exit_code == -1:
		return {
			"error":  "Failed to launch export subprocess (executable not found or permission denied).",
			"exe":    godot_exe,
			"output": output_text,
			"preset": preset_name,
		}

	if exit_code != 0:
		return {
			"error":     "Export failed with exit code %d." % exit_code,
			"output":    output_text,
			"preset":    preset_name,
			"output_path": abs_output,
		}

	return {
		"success":     true,
		"preset":      preset_name,
		"output_path": abs_output,
		"debug":       debug,
		"output":      output_text,
	}

func _as_bool(val: Variant) -> bool:
	if val is bool: return val
	return str(val).to_lower() == "true"
