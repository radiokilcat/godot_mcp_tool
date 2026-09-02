@tool
extends GodotMCPToolBase

class_name GodotMCPAudioTools

## Implements 6 Audio tools: add_audio_player, load_audio_file, play_audio,
## stop_audio, configure_bus, add_audio_effect.

func register(registry: GodotMCPToolRegistry) -> void:
	registry.register_tool("add_audio_player", GodotMCPCallableTool.new(_add_audio_player))
	registry.register_tool("load_audio_file",  GodotMCPCallableTool.new(_load_audio_file))
	registry.register_tool("play_audio",       GodotMCPCallableTool.new(_play_audio))
	registry.register_tool("stop_audio",       GodotMCPCallableTool.new(_stop_audio))
	registry.register_tool("configure_bus",    GodotMCPCallableTool.new(_configure_bus))
	registry.register_tool("add_audio_effect", GodotMCPCallableTool.new(_add_audio_effect))
func _is_audio_player(node: Node) -> bool:
	return node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D
func _add_audio_player(args: Dictionary) -> Dictionary:
	var root := _scene_root()
	if root == null:
		return {"error": "No scene is currently open"}

	var parent_path:  String = args.get("parent_path", "")
	var node_name:    String = args.get("node_name", "")
	var player_type:  String = args.get("type", "flat")
	var bus:          String = args.get("bus", "Master")
	var volume_db:    float  = float(args.get("volume_db", 0.0))
	var pitch_scale:  float  = float(args.get("pitch_scale", 1.0))
	var autoplay:     bool   = bool(args.get("autoplay", false))

	var parent := _resolve_parent(root, parent_path)
	if parent == null:
		return {"error": "Parent node not found: %s" % parent_path}

	var player: Node
	match player_type:
		"2d":
			var p := AudioStreamPlayer2D.new()
			p.bus = bus; p.volume_db = volume_db; p.pitch_scale = pitch_scale; p.autoplay = autoplay
			if node_name.is_empty(): node_name = "AudioStreamPlayer2D"
			player = p
		"3d":
			var p := AudioStreamPlayer3D.new()
			p.bus = bus; p.volume_db = volume_db; p.pitch_scale = pitch_scale; p.autoplay = autoplay
			if node_name.is_empty(): node_name = "AudioStreamPlayer3D"
			player = p
		_:
			var p := AudioStreamPlayer.new()
			p.bus = bus; p.volume_db = volume_db; p.pitch_scale = pitch_scale; p.autoplay = autoplay
			if node_name.is_empty(): node_name = "AudioStreamPlayer"
			player = p
			player_type = "flat"

	var result := _add_to_scene(player, parent, node_name, "Add AudioStreamPlayer '%s'" % node_name)
	result["player_type"] = player_type
	result["bus"]         = bus
	result["volume_db"]   = volume_db
	return result

func _load_audio_file(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	var file_path: String = args.get("file_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}
	if file_path.is_empty():
		return {"error": "'file_path' is required (e.g. 'res://audio/music.ogg')"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not _is_audio_player(node):
		return {"error": "Node '%s' is not an AudioStreamPlayer (got %s)" % [node_path, node.get_class()]}
	if not ResourceLoader.exists(file_path):
		return {"error": "Audio file not found in project: %s" % file_path}

	var stream = ResourceLoader.load(file_path)
	if stream == null:
		return {"error": "Failed to load audio resource: %s" % file_path}
	if not stream is AudioStream:
		return {"error": "Resource '%s' is not an AudioStream (got %s)" % [file_path, stream.get_class()]}

	var old_stream = node.get("stream")
	var ur := _plugin.get_undo_redo()
	ur.create_action("Load audio stream on '%s'" % node_path)
	ur.add_do_property(node, "stream", stream)
	ur.add_undo_property(node, "stream", old_stream)
	ur.commit_action()

	return {
		"success":     true,
		"node_path":   node_path,
		"file_path":   file_path,
		"stream_type": stream.get_class(),
	}

func _play_audio(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not _is_audio_player(node):
		return {"error": "Node '%s' is not an AudioStreamPlayer (got %s)" % [node_path, node.get_class()]}

	var from_pos:   float = float(args.get("from_position", 0.0))
	var was_playing: bool = bool(node.get("playing"))

	var ur := _plugin.get_undo_redo()
	ur.create_action("Play audio '%s'" % node_path)
	ur.add_do_method(node, "play", from_pos)
	if was_playing:
		ur.add_undo_method(node, "play", 0.0)
	else:
		ur.add_undo_method(node, "stop")
	ur.commit_action()

	return {"success": true, "node_path": node_path, "playing": true}

func _stop_audio(args: Dictionary) -> Dictionary:
	var node_path: String = args.get("node_path", "")
	if node_path.is_empty():
		return {"error": "'node_path' is required"}

	var node = _resolve_node(node_path)
	if node == null:
		return {"error": "Node not found: %s" % node_path}
	if not _is_audio_player(node):
		return {"error": "Node '%s' is not an AudioStreamPlayer (got %s)" % [node_path, node.get_class()]}

	var was_playing: bool = bool(node.get("playing"))

	var ur := _plugin.get_undo_redo()
	ur.create_action("Stop audio '%s'" % node_path)
	ur.add_do_method(node, "stop")
	if was_playing:
		ur.add_undo_method(node, "play", 0.0)
	else:
		ur.add_undo_method(node, "stop")
	ur.commit_action()

	return {"success": true, "node_path": node_path, "was_playing": was_playing}

func _configure_bus(args: Dictionary) -> Dictionary:
	var bus_name: String = args.get("bus_name", "")
	if bus_name.is_empty():
		return {"error": "'bus_name' is required (e.g. 'Master', 'Music', 'SFX')"}

	var has_changes: bool = args.has("volume_db") or args.has("mute") or args.has("solo") or args.has("send")
	if not has_changes:
		return {"error": "At least one property must be specified: volume_db, mute, solo, send"}

	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		var buses: Array = []
		for i in AudioServer.get_bus_count():
			buses.append(AudioServer.get_bus_name(i))
		return {"error": "Audio bus not found: '%s'. Available buses: %s" % [bus_name, ", ".join(buses)]}

	if args.has("send"):
		if bus_idx == 0:
			return {"error": "Cannot set send routing on the Master bus (it is the root audio sink)"}
		var send_target := str(args["send"])
		if AudioServer.get_bus_index(send_target) == -1:
			var buses: Array = []
			for i in AudioServer.get_bus_count():
				buses.append(AudioServer.get_bus_name(i))
			return {"error": "Send target bus '%s' not found. Available buses: %s" % [send_target, ", ".join(buses)]}

	var old_volume_db: float      = AudioServer.get_bus_volume_db(bus_idx)
	var old_mute:      bool       = AudioServer.is_bus_mute(bus_idx)
	var old_solo:      bool       = AudioServer.is_bus_solo(bus_idx)
	var old_send:      StringName = AudioServer.get_bus_send(bus_idx)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Configure audio bus '%s'" % bus_name)

	if args.has("volume_db"):
		var new_vol := float(args["volume_db"])
		ur.add_do_method(AudioServer, "set_bus_volume_db", bus_idx, new_vol)
		ur.add_undo_method(AudioServer, "set_bus_volume_db", bus_idx, old_volume_db)
	if args.has("mute"):
		var new_mute := bool(args["mute"])
		ur.add_do_method(AudioServer, "set_bus_mute", bus_idx, new_mute)
		ur.add_undo_method(AudioServer, "set_bus_mute", bus_idx, old_mute)
	if args.has("solo"):
		var new_solo := bool(args["solo"])
		ur.add_do_method(AudioServer, "set_bus_solo", bus_idx, new_solo)
		ur.add_undo_method(AudioServer, "set_bus_solo", bus_idx, old_solo)
	if args.has("send"):
		var new_send := StringName(str(args["send"]))
		ur.add_do_method(AudioServer, "set_bus_send", bus_idx, new_send)
		ur.add_undo_method(AudioServer, "set_bus_send", bus_idx, old_send)

	ur.commit_action()

	return {
		"success":   true,
		"bus_name":  bus_name,
		"bus_index": bus_idx,
		"volume_db": AudioServer.get_bus_volume_db(bus_idx),
		"mute":      AudioServer.is_bus_mute(bus_idx),
		"solo":      AudioServer.is_bus_solo(bus_idx),
		"send":      str(AudioServer.get_bus_send(bus_idx)),
	}

func _add_audio_effect(args: Dictionary) -> Dictionary:
	var bus_name:    String = args.get("bus_name", "")
	var effect_type: String = args.get("effect_type", "")
	if bus_name.is_empty():
		return {"error": "'bus_name' is required"}
	if effect_type.is_empty():
		return {"error": "'effect_type' is required. Valid: reverb, distortion, eq6, eq10, chorus, delay, compressor, limiter, amplify, panner, highpass, lowpass"}

	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return {"error": "Audio bus not found: '%s'" % bus_name}

	var effect: AudioEffect
	match effect_type:
		"reverb":     effect = AudioEffectReverb.new()
		"distortion": effect = AudioEffectDistortion.new()
		"eq6":        effect = AudioEffectEQ6.new()
		"eq10":       effect = AudioEffectEQ10.new()
		"chorus":     effect = AudioEffectChorus.new()
		"delay":      effect = AudioEffectDelay.new()
		"compressor": effect = AudioEffectCompressor.new()
		"limiter":    effect = AudioEffectLimiter.new()
		"amplify":    effect = AudioEffectAmplify.new()
		"panner":     effect = AudioEffectPanner.new()
		"highpass":   effect = AudioEffectHighPassFilter.new()
		"lowpass":    effect = AudioEffectLowPassFilter.new()
		_:
			return {"error": "Unknown effect_type '%s'. Valid: reverb, distortion, eq6, eq10, chorus, delay, compressor, limiter, amplify, panner, highpass, lowpass" % effect_type}

	if args.has("effect_name"):
		effect.resource_name = str(args["effect_name"])

	# Capture insert position before adding so undo can remove the correct index.
	var effect_idx: int = AudioServer.get_bus_effect_count(bus_idx)

	var ur := _plugin.get_undo_redo()
	ur.create_action("Add %s effect to bus '%s'" % [effect_type, bus_name])
	ur.add_do_method(AudioServer, "add_bus_effect", bus_idx, effect, effect_idx)
	ur.add_undo_method(AudioServer, "remove_bus_effect", bus_idx, effect_idx)
	ur.commit_action()

	return {
		"success":      true,
		"bus_name":     bus_name,
		"effect_type":  effect_type,
		"effect_index": effect_idx,
		"effect_count": AudioServer.get_bus_effect_count(bus_idx),
	}
