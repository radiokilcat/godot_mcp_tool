@tool
extends GodotMCPToolBase

class_name GodotMCPTileMapTools

## Implements 6 TileMap tools: set_tile_cell, fill_tiles, query_tile_cell,
## get_tileset_info, erase_tile_cell, get_tilemap_info.
##
## node_path may point at either a TileMap or a TileMapLayer node (the latter
## introduced in Godot 4.3 as TileMap's eventual replacement). A TileMapLayer
## has no `layer` argument on its cell methods and represents a single layer;
## pass layer 0 (default) or omit it. See _is_layer_node() and version_utils.gd.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("set_tile_cell",    GodotMCPCallableTool.new(_set_tile_cell))
	registry.register_tool("fill_tiles",       GodotMCPCallableTool.new(_fill_tiles))
	registry.register_tool("query_tile_cell",  GodotMCPCallableTool.new(_query_tile_cell))
	registry.register_tool("get_tileset_info", GodotMCPCallableTool.new(_get_tileset_info))
	registry.register_tool("erase_tile_cell",  GodotMCPCallableTool.new(_erase_tile_cell))
	registry.register_tool("get_tilemap_info", GodotMCPCallableTool.new(_get_tilemap_info))
func _parse_vec2i(val: Variant, default_val: Vector2i = Vector2i.ZERO) -> Vector2i:
	if val is Vector2i:
		return val
	if val is Array and val.size() >= 2:
		return Vector2i(int(val[0]), int(val[1]))
	if val is Dictionary:
		return Vector2i(int(val.get("x", 0)), int(val.get("y", 0)))
	return default_val

## TileMapLayer (Godot 4.3+) is checked via is_class(), a String-based lookup,
## rather than `node is TileMapLayer` — a static type reference to a class
## introduced in 4.3 would fail to parse at all on Godot 4.0-4.2. See
## version_utils.gd for background on this constraint.
func _is_layer_node(node: Node) -> bool:
	return node.is_class("TileMapLayer")

func _validate_tilemap(node_path: String) -> Variant:
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not (node is TileMap or _is_layer_node(node)):
		return {"error": "Node '%s' is not a TileMap or TileMapLayer (got %s)" % [node_path, node.get_class()]}
	return node

## `tilemap` is intentionally left dynamically typed (not cast to TileMap) so
## the same call sites work for both TileMap and TileMapLayer nodes, whose
## cell methods take a different argument list (TileMapLayer has no `layer`).
func _validate_layer(tilemap, is_layer: bool, layer: int) -> String:
	if is_layer:
		if layer != 0:
			return "TileMapLayer nodes represent a single layer (layer must be 0). Use sibling TileMapLayer nodes for additional layers, or target a TileMap node instead."
		return ""
	if layer < 0 or layer >= tilemap.get_layers_count():
		return "Layer %d out of range (TileMap has %d layer(s))" % [layer, tilemap.get_layers_count()]
	return ""

## Read helpers: dynamically dispatched (no static TileMap/TileMapLayer cast)
## so the correct overload — with or without the `layer` argument — is
## resolved at runtime based on the node's actual class.
func _cell_source_id(tilemap, is_layer: bool, layer: int, coords: Vector2i) -> int:
	if is_layer:
		return tilemap.get_cell_source_id(coords)
	return tilemap.get_cell_source_id(layer, coords)

func _cell_atlas_coords(tilemap, is_layer: bool, layer: int, coords: Vector2i) -> Vector2i:
	if is_layer:
		return tilemap.get_cell_atlas_coords(coords)
	return tilemap.get_cell_atlas_coords(layer, coords)

func _cell_alternative_tile(tilemap, is_layer: bool, layer: int, coords: Vector2i) -> int:
	if is_layer:
		return tilemap.get_cell_alternative_tile(coords)
	return tilemap.get_cell_alternative_tile(layer, coords)

# ---------------------------------------------------------------------------
# Tool implementations
# ---------------------------------------------------------------------------

func _set_tile_cell(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if not args.has("coords"):
		return {"error": "'coords' is required (e.g. [0, 0])"}
	if not args.has("source_id"):
		return {"error": "'source_id' is required. Use get_tileset_info to find valid source IDs."}

	var result = _validate_tilemap(node_path)
	if result is Dictionary:
		return result
	var tilemap = result
	var is_layer := _is_layer_node(tilemap)

	var layer: int = int(args.get("layer", 0))
	var err := _validate_layer(tilemap, is_layer, layer)
	if not err.is_empty():
		return {"error": err}

	var coords       := _parse_vec2i(args["coords"])
	var source_id: int = int(args["source_id"])
	var atlas_coords := _parse_vec2i(args.get("atlas_coords", Vector2i.ZERO))
	var alt: int       = int(args.get("alternative_tile", 0))

	var ts_check = tilemap.tile_set
	if ts_check == null:
		return {"error": "%s '%s' has no TileSet assigned" % [tilemap.get_class(), node_path]}
	if not ts_check.has_source(source_id):
		var ids: Array = []
		for i in ts_check.get_source_count():
			ids.append(ts_check.get_source_id(i))
		return {"error": "Source ID %d not found in TileSet. Available IDs: %s" % [source_id, str(ids)]}

	var old_src: int = _cell_source_id(tilemap, is_layer, layer, coords)
	var old_ac       = _cell_atlas_coords(tilemap, is_layer, layer, coords)
	var old_alt: int = _cell_alternative_tile(tilemap, is_layer, layer, coords)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Set tile at (%d, %d)" % [coords.x, coords.y])
	if is_layer:
		ur.add_do_method(tilemap, "set_cell", coords, source_id, atlas_coords, alt)
		ur.add_undo_method(tilemap, "set_cell", coords, old_src, old_ac, old_alt)
	else:
		ur.add_do_method(tilemap, "set_cell", layer, coords, source_id, atlas_coords, alt)
		ur.add_undo_method(tilemap, "set_cell", layer, coords, old_src, old_ac, old_alt)
	ur.commit_action()

	return {
		"success":      true,
		"node_path":    node_path,
		"layer":        layer,
		"coords":       {"x": coords.x, "y": coords.y},
		"source_id":    source_id,
		"atlas_coords": {"x": atlas_coords.x, "y": atlas_coords.y},
		"alternative":  alt,
	}

func _fill_tiles(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if not args.has("from_coords"):
		return {"error": "'from_coords' is required"}
	if not args.has("to_coords"):
		return {"error": "'to_coords' is required"}
	if not args.has("source_id"):
		return {"error": "'source_id' is required"}

	var result = _validate_tilemap(node_path)
	if result is Dictionary:
		return result
	var tilemap = result
	var is_layer := _is_layer_node(tilemap)

	var layer: int = int(args.get("layer", 0))
	var err := _validate_layer(tilemap, is_layer, layer)
	if not err.is_empty():
		return {"error": err}

	var from := _parse_vec2i(args["from_coords"])
	var to   := _parse_vec2i(args["to_coords"])
	var source_id: int = int(args["source_id"])
	var atlas_coords   := _parse_vec2i(args.get("atlas_coords", Vector2i.ZERO))
	var alt: int        = int(args.get("alternative_tile", 0))

	var ts_fill = tilemap.tile_set
	if ts_fill == null:
		return {"error": "%s '%s' has no TileSet assigned" % [tilemap.get_class(), node_path]}
	if not ts_fill.has_source(source_id):
		var ids: Array = []
		for i in ts_fill.get_source_count():
			ids.append(ts_fill.get_source_id(i))
		return {"error": "Source ID %d not found in TileSet. Available IDs: %s" % [source_id, str(ids)]}

	var min_x := mini(from.x, to.x)
	var min_y := mini(from.y, to.y)
	var max_x := maxi(from.x, to.x)
	var max_y := maxi(from.y, to.y)
	var cell_count := (max_x - min_x + 1) * (max_y - min_y + 1)

	if cell_count > 10000:
		return {"error": "Fill area too large (%d cells). Maximum is 10,000 cells per call." % cell_count}

	var ur := _plugin.get_undo_redo()
	ur.create_action("Fill %d tiles on layer %d" % [cell_count, layer])

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var c := Vector2i(x, y)
			var old_src: int = _cell_source_id(tilemap, is_layer, layer, c)
			var old_ac       = _cell_atlas_coords(tilemap, is_layer, layer, c)
			var old_alt: int = _cell_alternative_tile(tilemap, is_layer, layer, c)
			if is_layer:
				ur.add_do_method(tilemap, "set_cell", c, source_id, atlas_coords, alt)
				ur.add_undo_method(tilemap, "set_cell", c, old_src, old_ac, old_alt)
			else:
				ur.add_do_method(tilemap, "set_cell", layer, c, source_id, atlas_coords, alt)
				ur.add_undo_method(tilemap, "set_cell", layer, c, old_src, old_ac, old_alt)

	ur.commit_action()

	return {
		"success":      true,
		"node_path":    node_path,
		"layer":        layer,
		"cells_filled": cell_count,
		"from_coords":  {"x": min_x, "y": min_y},
		"to_coords":    {"x": max_x, "y": max_y},
	}

func _query_tile_cell(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if not args.has("coords"):
		return {"error": "'coords' is required (e.g. [0, 0])"}

	var result = _validate_tilemap(node_path)
	if result is Dictionary:
		return result
	var tilemap = result
	var is_layer := _is_layer_node(tilemap)

	var layer: int = int(args.get("layer", 0))
	var err := _validate_layer(tilemap, is_layer, layer)
	if not err.is_empty():
		return {"error": err}

	var coords := _parse_vec2i(args["coords"])
	var source_id: int = _cell_source_id(tilemap, is_layer, layer, coords)
	var is_empty: bool = (source_id == -1)

	var info: Dictionary = {
		"node_path": node_path,
		"layer":     layer,
		"coords":    {"x": coords.x, "y": coords.y},
		"is_empty":  is_empty,
	}

	if not is_empty:
		var ac       = _cell_atlas_coords(tilemap, is_layer, layer, coords)
		var alt: int = _cell_alternative_tile(tilemap, is_layer, layer, coords)
		info["source_id"]    = source_id
		info["atlas_coords"] = {"x": ac.x, "y": ac.y}
		info["alternative"]  = alt
		var ts = tilemap.tile_set
		if ts != null and ts.has_source(source_id):
			var src = ts.get_source(source_id)
			if not src.resource_name.is_empty():
				info["source_name"] = src.resource_name

	return info

func _get_tileset_info(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var result = _validate_tilemap(node_path)
	if result is Dictionary:
		return result
	var tilemap = result

	var ts = tilemap.tile_set
	if ts == null:
		return {"node_path": node_path, "has_tileset": false}

	var sources: Array = []
	for i in ts.get_source_count():
		var src_id: int = ts.get_source_id(i)
		var src = ts.get_source(src_id)
		var info: Dictionary = {"source_id": src_id, "class": src.get_class(), "name": src.resource_name}
		if src is TileSetAtlasSource:
			var atlas := src as TileSetAtlasSource
			info["tile_count"] = atlas.get_tiles_count()
			info["texture"]    = atlas.texture.resource_path if atlas.texture else ""
			if atlas.has_method("get_atlas_grid_size"):
				var grid := atlas.get_atlas_grid_size()
				info["grid_size"] = {"x": grid.x, "y": grid.y}
			elif atlas.texture and atlas.texture_region_size.x > 0 and atlas.texture_region_size.y > 0:
				var sz := atlas.texture.get_size()
				info["grid_size"] = {
					"x": int(sz.x / atlas.texture_region_size.x),
					"y": int(sz.y / atlas.texture_region_size.y),
				}
		sources.append(info)

	return {
		"node_path":    node_path,
		"has_tileset":  true,
		"tileset_path": ts.resource_path if not ts.resource_path.is_empty() else "(embedded)",
		"tile_size":    {"x": ts.tile_size.x, "y": ts.tile_size.y},
		"tile_shape":   int(ts.tile_shape),
		"source_count": ts.get_source_count(),
		"sources":      sources,
	}

func _erase_tile_cell(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if not args.has("coords"):
		return {"error": "'coords' is required (e.g. [0, 0])"}

	var result = _validate_tilemap(node_path)
	if result is Dictionary:
		return result
	var tilemap = result
	var is_layer := _is_layer_node(tilemap)

	var layer: int = int(args.get("layer", 0))
	var err := _validate_layer(tilemap, is_layer, layer)
	if not err.is_empty():
		return {"error": err}

	var coords := _parse_vec2i(args["coords"])
	var old_src: int = _cell_source_id(tilemap, is_layer, layer, coords)
	if old_src == -1:
		return {"success": true, "node_path": node_path, "layer": layer, "coords": {"x": coords.x, "y": coords.y}, "was_empty": true}

	var old_ac       = _cell_atlas_coords(tilemap, is_layer, layer, coords)
	var old_alt: int = _cell_alternative_tile(tilemap, is_layer, layer, coords)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Erase tile at (%d, %d)" % [coords.x, coords.y])
	if is_layer:
		ur.add_do_method(tilemap, "erase_cell", coords)
		ur.add_undo_method(tilemap, "set_cell", coords, old_src, old_ac, old_alt)
	else:
		ur.add_do_method(tilemap, "erase_cell", layer, coords)
		ur.add_undo_method(tilemap, "set_cell", layer, coords, old_src, old_ac, old_alt)
	ur.commit_action()

	return {
		"success":   true,
		"node_path": node_path,
		"layer":     layer,
		"coords":    {"x": coords.x, "y": coords.y},
		"was_empty": old_src == -1,
	}

func _get_tilemap_info(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var result = _validate_tilemap(node_path)
	if result is Dictionary:
		return result
	var tilemap = result
	var is_layer := _is_layer_node(tilemap)

	var layers: Array = []
	if is_layer:
		# A TileMapLayer node is itself a single layer; use sibling
		# TileMapLayer nodes for additional layers (there is no built-in
		# multi-layer container the way TileMap has one).
		layers.append({
			"index":      0,
			"name":       tilemap.name,
			"enabled":    tilemap.visible,
			"cell_count": tilemap.get_used_cells().size(),
		})
	else:
		for i in tilemap.get_layers_count():
			layers.append({
				"index":      i,
				"name":       tilemap.get_layer_name(i),
				"enabled":    tilemap.is_layer_enabled(i),
				"cell_count": tilemap.get_used_cells(i).size(),
			})

	var used_rect = tilemap.get_used_rect()
	var ts = tilemap.tile_set
	var total_cells: int = 0
	for layer_info in layers:
		total_cells += int(layer_info["cell_count"])

	return {
		"node_path":    node_path,
		"node_type":    tilemap.get_class(),
		"layer_count":  layers.size(),
		"layers":       layers,
		"has_tiles":    total_cells > 0,
		"used_rect":    {
			"x":      used_rect.position.x,
			"y":      used_rect.position.y,
			"width":  used_rect.size.x,
			"height": used_rect.size.y,
		},
		"has_tileset":  ts != null,
		"tileset_path": ts.resource_path if ts != null and not ts.resource_path.is_empty() else "",
		"tile_size":    {"x": ts.tile_size.x, "y": ts.tile_size.y} if ts != null else {"x": 16, "y": 16},
	}
