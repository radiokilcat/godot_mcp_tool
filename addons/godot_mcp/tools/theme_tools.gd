@tool
extends GodotMCPToolBase

class_name GodotMCPThemeTools

## Implements 6 Theme/UI tools: create_theme, set_theme_color, set_theme_font,
## set_theme_constant, set_stylebox, get_theme_info.
## All tools operate on .tres Theme files via ResourceLoader/ResourceSaver.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("create_theme",       GodotMCPCallableTool.new(_create_theme))
	registry.register_tool("set_theme_color",    GodotMCPCallableTool.new(_set_theme_color))
	registry.register_tool("set_theme_font",     GodotMCPCallableTool.new(_set_theme_font))
	registry.register_tool("set_theme_constant", GodotMCPCallableTool.new(_set_theme_constant))
	registry.register_tool("set_stylebox",       GodotMCPCallableTool.new(_set_stylebox))
	registry.register_tool("get_theme_info",     GodotMCPCallableTool.new(_get_theme_info))

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _parse_vec2(val: Variant) -> Vector2:
	if val is Vector2:
		return val
	if val is Array and val.size() >= 2:
		return Vector2(float(val[0]), float(val[1]))
	if val is Dictionary:
		return Vector2(float(val.get("x", 0.0)), float(val.get("y", 0.0)))
	return Vector2.ZERO

func _load_theme(theme_path: String) -> Variant:
	if theme_path.is_empty():
		return {"error": "'theme_path' is required (e.g. 'res://theme/my_theme.tres')"}
	if not ResourceLoader.exists(theme_path):
		return {"error": "Theme file not found: %s" % theme_path}
	var resource = ResourceLoader.load(theme_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		return {"error": "Failed to load resource: %s" % theme_path}
	if not resource is Theme:
		return {"error": "Resource at '%s' is not a Theme (got %s)" % [theme_path, resource.get_class()]}
	return resource

func _save_theme(theme: Theme, theme_path: String) -> String:
	var err := ResourceSaver.save(theme, theme_path)
	if err != OK:
		return "Failed to save theme to '%s' (error %d)" % [theme_path, err]
	return ""
# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _create_theme(args: Dictionary) -> Dictionary:
	var theme_path: String = args.get("theme_path", "")
	if theme_path.is_empty():
		return {"error": "'theme_path' is required (e.g. 'res://theme/my_theme.tres')"}
	if not theme_path.ends_with(".tres") and not theme_path.ends_with(".res"):
		return {"error": "'theme_path' must end with .tres or .res"}
	if ResourceLoader.exists(theme_path) and not bool(args.get("overwrite", false)):
		return {"error": "Theme already exists at '%s'. Pass overwrite: true to replace it." % theme_path}

	var theme := Theme.new()

	if args.has("default_font_size"):
		theme.default_font_size = int(args["default_font_size"])

	if args.has("default_font"):
		var font_path := str(args["default_font"])
		if not font_path.is_empty():
			if not ResourceLoader.exists(font_path):
				return {"error": "Default font file not found: %s" % font_path}
			var font = ResourceLoader.load(font_path)
			if not font is Font:
				return {"error": "Resource at '%s' is not a Font (got %s)" % [font_path, font.get_class() if font else "null"]}
			theme.default_font = font

	var err := ResourceSaver.save(theme, theme_path)
	if err != OK:
		return {"error": "Failed to save theme to '%s' (error %d)" % [theme_path, err]}

	return {
		"success":           true,
		"theme_path":        theme_path,
		"default_font_size": theme.default_font_size,
	}

func _set_theme_color(args: Dictionary) -> Dictionary:
	var theme_path: String = args.get("theme_path", "")
	var theme_type: String = args.get("theme_type", "")
	var color_name: String = args.get("color_name", "")

	if theme_path.is_empty():
		return {"error": "'theme_path' is required"}
	if theme_type.is_empty():
		return {"error": "'theme_type' is required (e.g. 'Button', 'Label')"}
	if color_name.is_empty():
		return {"error": "'color_name' is required (e.g. 'font_color', 'font_hover_color')"}
	if not args.has("color"):
		return {"error": "'color' is required (e.g. '#ff0000' or [r, g, b])"}

	var result = _load_theme(theme_path)
	if result is Dictionary:
		return result
	var theme := result as Theme

	var new_color := _parse_color(args["color"])
	theme.set_color(color_name, theme_type, new_color)

	var err_str := _save_theme(theme, theme_path)
	if not err_str.is_empty():
		return {"error": err_str}

	return {
		"success":    true,
		"theme_path": theme_path,
		"theme_type": theme_type,
		"color_name": color_name,
		"color":      "#%s" % new_color.to_html(true),
	}

func _set_theme_font(args: Dictionary) -> Dictionary:
	var theme_path: String = args.get("theme_path", "")
	var theme_type: String = args.get("theme_type", "")
	var font_name:  String = args.get("font_name", "")
	var font_path:  String = args.get("font_path", "")

	if theme_path.is_empty():
		return {"error": "'theme_path' is required"}
	if theme_type.is_empty():
		return {"error": "'theme_type' is required (e.g. 'Button', 'Label')"}
	if font_name.is_empty():
		return {"error": "'font_name' is required (e.g. 'font')"}
	if font_path.is_empty():
		return {"error": "'font_path' is required (e.g. 'res://fonts/MyFont.ttf')"}

	var result = _load_theme(theme_path)
	if result is Dictionary:
		return result
	var theme := result as Theme

	if not ResourceLoader.exists(font_path):
		return {"error": "Font file not found: %s" % font_path}
	var font = ResourceLoader.load(font_path)
	if font == null:
		return {"error": "Failed to load font: %s" % font_path}
	if not font is Font:
		return {"error": "Resource at '%s' is not a Font (got %s)" % [font_path, font.get_class()]}

	theme.set_font(font_name, theme_type, font)

	if args.has("font_size"):
		theme.set_font_size(font_name, theme_type, int(args["font_size"]))

	var err_str := _save_theme(theme, theme_path)
	if not err_str.is_empty():
		return {"error": err_str}

	return {
		"success":    true,
		"theme_path": theme_path,
		"theme_type": theme_type,
		"font_name":  font_name,
		"font_path":  font_path,
	}

func _set_theme_constant(args: Dictionary) -> Dictionary:
	var theme_path:    String = args.get("theme_path", "")
	var theme_type:    String = args.get("theme_type", "")
	var constant_name: String = args.get("constant_name", "")

	if theme_path.is_empty():
		return {"error": "'theme_path' is required"}
	if theme_type.is_empty():
		return {"error": "'theme_type' is required (e.g. 'Button', 'Label')"}
	if constant_name.is_empty():
		return {"error": "'constant_name' is required (e.g. 'outline_size', 'h_separation')"}
	if not args.has("value"):
		return {"error": "'value' is required (integer)"}

	var result = _load_theme(theme_path)
	if result is Dictionary:
		return result
	var theme := result as Theme

	var new_value: int = int(args["value"])
	theme.set_constant(constant_name, theme_type, new_value)

	var err_str := _save_theme(theme, theme_path)
	if not err_str.is_empty():
		return {"error": err_str}

	return {
		"success":       true,
		"theme_path":    theme_path,
		"theme_type":    theme_type,
		"constant_name": constant_name,
		"value":         new_value,
	}

func _set_stylebox(args: Dictionary) -> Dictionary:
	var theme_path:    String = args.get("theme_path", "")
	var theme_type:    String = args.get("theme_type", "")
	var stylebox_name: String = args.get("stylebox_name", "")
	var stylebox_type: String = args.get("stylebox_type", "flat")

	if theme_path.is_empty():
		return {"error": "'theme_path' is required"}
	if theme_type.is_empty():
		return {"error": "'theme_type' is required (e.g. 'Button', 'PanelContainer')"}
	if stylebox_name.is_empty():
		return {"error": "'stylebox_name' is required (e.g. 'normal', 'hover', 'pressed', 'panel')"}

	var result = _load_theme(theme_path)
	if result is Dictionary:
		return result
	var theme := result as Theme

	var sb: StyleBox
	match stylebox_type:
		"flat":    sb = StyleBoxFlat.new()
		"line":    sb = StyleBoxLine.new()
		"empty":   sb = StyleBoxEmpty.new()
		_:
			return {"error": "Unknown stylebox_type '%s'. Valid: flat, line, empty" % stylebox_type}

	var props: Dictionary = args.get("properties", {})

	if stylebox_type == "flat":
		var flat := sb as StyleBoxFlat
		if props.has("bg_color"):
			flat.bg_color = _parse_color(props["bg_color"])
		if props.has("border_color"):
			flat.border_color = _parse_color(props["border_color"])
		if props.has("border_width"):
			var bw := int(props["border_width"])
			flat.border_width_left = bw; flat.border_width_right  = bw
			flat.border_width_top  = bw; flat.border_width_bottom = bw
		if props.has("border_width_left"):   flat.border_width_left   = int(props["border_width_left"])
		if props.has("border_width_right"):  flat.border_width_right  = int(props["border_width_right"])
		if props.has("border_width_top"):    flat.border_width_top    = int(props["border_width_top"])
		if props.has("border_width_bottom"): flat.border_width_bottom = int(props["border_width_bottom"])
		if props.has("corner_radius"):
			var cr := int(props["corner_radius"])
			flat.corner_radius_top_left    = cr; flat.corner_radius_top_right    = cr
			flat.corner_radius_bottom_left = cr; flat.corner_radius_bottom_right = cr
		if props.has("corner_radius_top_left"):     flat.corner_radius_top_left     = int(props["corner_radius_top_left"])
		if props.has("corner_radius_top_right"):    flat.corner_radius_top_right    = int(props["corner_radius_top_right"])
		if props.has("corner_radius_bottom_left"):  flat.corner_radius_bottom_left  = int(props["corner_radius_bottom_left"])
		if props.has("corner_radius_bottom_right"): flat.corner_radius_bottom_right = int(props["corner_radius_bottom_right"])
		if props.has("draw_center"):   flat.draw_center   = _as_bool(props["draw_center"])
		if props.has("anti_aliased"):  flat.anti_aliased  = _as_bool(props["anti_aliased"])
		if props.has("shadow_color"):  flat.shadow_color  = _parse_color(props["shadow_color"])
		if props.has("shadow_size"):   flat.shadow_size   = int(props["shadow_size"])
		if props.has("shadow_offset"): flat.shadow_offset = _parse_vec2(props["shadow_offset"])
		if props.has("expand_margin"):
			var em := float(props["expand_margin"])
			flat.expand_margin_left = em; flat.expand_margin_right  = em
			flat.expand_margin_top  = em; flat.expand_margin_bottom = em
		if props.has("expand_margin_left"):   flat.expand_margin_left   = float(props["expand_margin_left"])
		if props.has("expand_margin_right"):  flat.expand_margin_right  = float(props["expand_margin_right"])
		if props.has("expand_margin_top"):    flat.expand_margin_top    = float(props["expand_margin_top"])
		if props.has("expand_margin_bottom"): flat.expand_margin_bottom = float(props["expand_margin_bottom"])

	elif stylebox_type == "line":
		var line := sb as StyleBoxLine
		if props.has("color"):     line.color     = _parse_color(props["color"])
		if props.has("thickness"): line.thickness = int(props["thickness"])
		if props.has("vertical"):  line.vertical  = _as_bool(props["vertical"])

	# StyleBoxEmpty has no unique properties beyond the base content_margin_*

	theme.set_stylebox(stylebox_name, theme_type, sb)

	var err_str := _save_theme(theme, theme_path)
	if not err_str.is_empty():
		return {"error": err_str}

	return {
		"success":       true,
		"theme_path":    theme_path,
		"theme_type":    theme_type,
		"stylebox_name": stylebox_name,
		"stylebox_type": stylebox_type,
	}

func _get_theme_info(args: Dictionary) -> Dictionary:
	var theme_path: String = args.get("theme_path", "")

	var result = _load_theme(theme_path)
	if result is Dictionary:
		return result
	var theme := result as Theme

	var types := theme.get_type_list()
	var type_data: Dictionary = {}

	for t in types:
		var t_str := str(t)
		var entry: Dictionary = {}

		var colors := theme.get_color_list(t_str)
		if colors.size() > 0:
			var c_dict: Dictionary = {}
			for c in colors:
				c_dict[str(c)] = "#%s" % theme.get_color(c, t_str).to_html(true)
			entry["colors"] = c_dict

		var fonts := theme.get_font_list(t_str)
		if fonts.size() > 0:
			var f_dict: Dictionary = {}
			for f in fonts:
				var font = theme.get_font(f, t_str)
				f_dict[str(f)] = font.resource_path if font != null and not font.resource_path.is_empty() else "(embedded)"
			entry["fonts"] = f_dict

		var font_sizes := theme.get_font_size_list(t_str)
		if font_sizes.size() > 0:
			var fs_dict: Dictionary = {}
			for fs in font_sizes:
				fs_dict[str(fs)] = theme.get_font_size(fs, t_str)
			entry["font_sizes"] = fs_dict

		var constants := theme.get_constant_list(t_str)
		if constants.size() > 0:
			var k_dict: Dictionary = {}
			for k in constants:
				k_dict[str(k)] = theme.get_constant(k, t_str)
			entry["constants"] = k_dict

		var styleboxes := theme.get_stylebox_list(t_str)
		if styleboxes.size() > 0:
			var s_list: Array = []
			for s in styleboxes:
				var sb = theme.get_stylebox(s, t_str)
				s_list.append({"name": str(s), "type": sb.get_class() if sb != null else "null"})
			entry["styleboxes"] = s_list

		if not entry.is_empty():
			type_data[t_str] = entry

	return {
		"theme_path":        theme_path,
		"type_count":        types.size(),
		"types":             type_data,
		"has_default_font":  theme.default_font != null,
		"default_font_size": theme.default_font_size,
	}
