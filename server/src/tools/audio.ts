/**
 * Audio tools - 6 tools
 * Tools for creating audio players, loading streams, controlling playback,
 * and configuring the audio bus layout and effects.
 */

import { ToolCategory } from "../types/index.js";
import { godotConnection } from "../godot-connection.js";

export const audioTools: ToolCategory = {
  add_audio_player: {
    name: "add_audio_player",
    description:
      "Add an AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node to the scene. The node plays audio on the specified bus. Call load_audio_file to assign a stream afterward.",
    inputSchema: {
      type: "object",
      properties: {
        parent_path: {
          type: "string",
          description: "Path to parent node (default: scene root)",
        },
        node_name: {
          type: "string",
          description:
            "Name for the new node (default: 'AudioStreamPlayer', 'AudioStreamPlayer2D', or 'AudioStreamPlayer3D')",
        },
        type: {
          type: "string",
          enum: ["flat", "2d", "3d"],
          description:
            "'flat' (default) — no spatial audio. '2d' — attenuates with distance in 2D. '3d' — full 3D spatial audio.",
        },
        bus: {
          type: "string",
          description: "Name of the audio bus to play on (default: 'Master')",
        },
        volume_db: {
          type: "number",
          description: "Volume in decibels (default: 0.0). Negative values are quieter, 0 is original.",
        },
        pitch_scale: {
          type: "number",
          description: "Pitch multiplier (default: 1.0). 2.0 = one octave up, 0.5 = one octave down.",
        },
        autoplay: {
          type: "boolean",
          description: "Start playing automatically when the scene starts (default: false)",
        },
      },
      required: [],
    },
    handler: async (args) => {
      return await godotConnection.callTool("add_audio_player", args);
    },
  },

  load_audio_file: {
    name: "load_audio_file",
    description:
      "Assign an audio stream resource to an AudioStreamPlayer node. The file must already exist in the Godot project. Supports .ogg, .wav, and .mp3 files.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AudioStreamPlayer, AudioStreamPlayer2D, or AudioStreamPlayer3D node",
        },
        file_path: {
          type: "string",
          description: "Project-relative path to the audio file, e.g. 'res://audio/music.ogg'",
        },
      },
      required: ["node_path", "file_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("load_audio_file", args);
    },
  },

  play_audio: {
    name: "play_audio",
    description:
      "Start playback on an AudioStreamPlayer node. Works in the editor — audio will be audible if the node has a stream assigned. Fully undoable.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AudioStreamPlayer node",
        },
        from_position: {
          type: "number",
          description: "Position in the stream to start from, in seconds (default: 0.0)",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("play_audio", args);
    },
  },

  stop_audio: {
    name: "stop_audio",
    description:
      "Stop playback on an AudioStreamPlayer node. If the node was playing, undo will restart playback from the beginning. Fully undoable.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description: "Path to the AudioStreamPlayer node",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("stop_audio", args);
    },
  },

  configure_bus: {
    name: "configure_bus",
    description:
      "Set volume, mute, solo, or send routing on an audio bus. At least one of volume_db, mute, solo, or send must be provided. Changes apply to the AudioServer immediately and are undoable. The 'Master' bus always exists and cannot have its send rerouted; other buses must be created in the Audio panel first.",
    inputSchema: {
      type: "object",
      properties: {
        bus_name: {
          type: "string",
          description: "Name of the audio bus to configure (e.g. 'Master', 'Music', 'SFX')",
        },
        volume_db: {
          type: "number",
          description: "New volume in decibels for this bus (0.0 = unity gain, -80 = silent)",
        },
        mute: {
          type: "boolean",
          description: "Mute or unmute this bus",
        },
        solo: {
          type: "boolean",
          description: "Solo this bus (silences all other non-soloed buses)",
        },
        send: {
          type: "string",
          description:
            "Name of the bus to route this bus's output to (e.g. 'Master'). Only valid for non-Master buses.",
        },
      },
      required: ["bus_name"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("configure_bus", args);
    },
  },

  add_audio_effect: {
    name: "add_audio_effect",
    description:
      "Add an audio effect (reverb, compressor, EQ, etc.) to an audio bus. Effects are applied in order. Fully undoable.",
    inputSchema: {
      type: "object",
      properties: {
        bus_name: {
          type: "string",
          description: "Name of the audio bus to add the effect to (e.g. 'Master', 'Music')",
        },
        effect_type: {
          type: "string",
          enum: [
            "reverb",
            "distortion",
            "eq6",
            "eq10",
            "chorus",
            "delay",
            "compressor",
            "limiter",
            "amplify",
            "panner",
            "highpass",
            "lowpass",
          ],
          description:
            "Type of effect to add. 'reverb' — room echo. 'compressor' — dynamic range compression. 'eq6'/'eq10' — equalizer. 'limiter' — peak prevention. 'amplify' — volume boost/cut. 'panner' — stereo pan. 'highpass'/'lowpass' — frequency filters.",
        },
        effect_name: {
          type: "string",
          description: "Optional display name for the effect in the AudioServer panel",
        },
      },
      required: ["bus_name", "effect_type"],
    },
    handler: async (args) => {
      return await godotConnection.callTool("add_audio_effect", args);
    },
  },
};
