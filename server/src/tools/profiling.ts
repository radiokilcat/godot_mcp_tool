import { callTool } from "../godot-connection.js";

export const profilingTools = {
  get_performance_monitors: {
    name: "get_performance_monitors",
    description:
      "Return current values for all Godot Performance monitors grouped by category: " +
      "time (FPS, frame/physics/navigation ms), memory (static bytes/peak), " +
      "render (objects, primitives, draw calls, VRAM), " +
      "physics_2d/3d (active objects, collision pairs, islands), " +
      "audio (output latency), navigation (maps, regions, agents, polygons). " +
      "Use 'category' to request a single group.",
    inputSchema: {
      type: "object",
      properties: {
        category: {
          type: "string",
          enum: ["time", "memory", "render", "physics_2d", "physics_3d", "audio", "navigation"],
          description:
            "Optional category filter. Omit to return all categories at once.",
        },
      },
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("get_performance_monitors", args),
  },

  get_memory_usage: {
    name: "get_memory_usage",
    description:
      "Return a breakdown of Godot's memory consumption: " +
      "static allocator (used/peak in bytes and MB), " +
      "render memory (VRAM, textures, buffers), " +
      "and optionally a sample of currently cached resource paths. " +
      "Useful for spotting memory leaks or unexpected resource retention.",
    inputSchema: {
      type: "object",
      properties: {
        include_resources: {
          type: "boolean",
          description:
            "If true (default), include a sample of paths from the resource cache " +
            "showing which assets are currently loaded.",
        },
        max_resources: {
          type: "integer",
          description:
            "Maximum number of cached resource paths to return in the sample (default 50, max 500).",
        },
      },
      required: [],
    },
    handler: async (args: Record<string, unknown>) =>
      callTool("get_memory_usage", args),
  },
};
