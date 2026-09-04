/**
 * TileMap tools - 6 tools
 * Tools for reading and modifying TileMap nodes: setting cells, filling regions,
 * querying tile data, and inspecting TileSet sources.
 *
 * Also accepts TileMapLayer nodes (Godot 4.3+), which have a single implicit
 * layer instead of TileMap's indexed layers.
 */

import { ToolCategory } from "../types/index.js";
import { callTool } from "../godot-connection.js";

const coordsSchema = {
  type: "array" as const,
  items: { type: "integer" as const },
  minItems: 2,
  maxItems: 2,
};

export const tilemapTools: ToolCategory = {
  set_tile_cell: {
    name: "set_tile_cell",
    description:
      "Set a tile at a specific cell position in a TileMap layer. Use get_tileset_info first to discover valid source_id and atlas_coords values. Fully undoable.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to the TileMap or TileMapLayer node. TileMapLayer (Godot 4.3+) has a single implicit layer — omit 'layer' or pass 0.",
        },
        layer: {
          type: "integer",
          description: "TileMap layer index (default: 0)",
        },
        coords: {
          ...coordsSchema,
          description: "Cell coordinates as [column, row]",
        },
        source_id: {
          type: "integer",
          description:
            "TileSet source ID to use. Get valid IDs from get_tileset_info.",
        },
        atlas_coords: {
          ...coordsSchema,
          description:
            "Atlas tile position as [x, y] within the source texture (default: [0, 0])",
        },
        alternative_tile: {
          type: "integer",
          description:
            "Alternative tile ID for rotated/flipped variants (default: 0)",
        },
      },
      required: ["node_path", "coords", "source_id"],
    },
    handler: async (args) => {
      return await callTool("set_tile_cell", args);
    },
  },

  fill_tiles: {
    name: "fill_tiles",
    description:
      "Fill a rectangular region of a TileMap with the same tile. All cells from from_coords to to_coords (inclusive) are set to the given tile. Maximum 10,000 cells per call. Fully undoable.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to the TileMap or TileMapLayer node. TileMapLayer (Godot 4.3+) has a single implicit layer — omit 'layer' or pass 0.",
        },
        layer: {
          type: "integer",
          description: "TileMap layer index (default: 0)",
        },
        from_coords: {
          ...coordsSchema,
          description: "Top-left corner of the fill region as [column, row]",
        },
        to_coords: {
          ...coordsSchema,
          description:
            "Bottom-right corner of the fill region as [column, row]",
        },
        source_id: {
          type: "integer",
          description: "TileSet source ID to use",
        },
        atlas_coords: {
          ...coordsSchema,
          description:
            "Atlas tile position within the source (default: [0, 0])",
        },
        alternative_tile: {
          type: "integer",
          description: "Alternative tile ID (default: 0)",
        },
      },
      required: ["node_path", "from_coords", "to_coords", "source_id"],
    },
    handler: async (args) => {
      return await callTool("fill_tiles", args);
    },
  },

  query_tile_cell: {
    name: "query_tile_cell",
    description:
      "Get the tile data at a specific cell position. Returns source_id, atlas_coords, and alternative ID. Returns is_empty: true for cells with no tile placed.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to the TileMap or TileMapLayer node. TileMapLayer (Godot 4.3+) has a single implicit layer — omit 'layer' or pass 0.",
        },
        layer: {
          type: "integer",
          description: "TileMap layer index (default: 0)",
        },
        coords: {
          ...coordsSchema,
          description: "Cell coordinates as [column, row]",
        },
      },
      required: ["node_path", "coords"],
    },
    handler: async (args) => {
      return await callTool("query_tile_cell", args);
    },
  },

  get_tileset_info: {
    name: "get_tileset_info",
    description:
      "Get information about the TileSet assigned to a TileMap: tile size, tile shape (square/isometric/hex), and all sources with their atlas textures and tile counts. Use this to discover valid source_id and atlas_coords values before placing tiles.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to the TileMap or TileMapLayer node. TileMapLayer (Godot 4.3+) has a single implicit layer — omit 'layer' or pass 0.",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_tileset_info", args);
    },
  },

  erase_tile_cell: {
    name: "erase_tile_cell",
    description:
      "Remove the tile at a specific cell position, leaving it empty. Fully undoable.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to the TileMap or TileMapLayer node. TileMapLayer (Godot 4.3+) has a single implicit layer — omit 'layer' or pass 0.",
        },
        layer: {
          type: "integer",
          description: "TileMap layer index (default: 0)",
        },
        coords: {
          ...coordsSchema,
          description: "Cell coordinates as [column, row]",
        },
      },
      required: ["node_path", "coords"],
    },
    handler: async (args) => {
      return await callTool("erase_tile_cell", args);
    },
  },

  get_tilemap_info: {
    name: "get_tilemap_info",
    description:
      "Get overview information about a TileMap node: layer count and names, used cell counts per layer, bounding rectangle of all placed tiles, and TileSet assignment.",
    inputSchema: {
      type: "object",
      properties: {
        node_path: {
          type: "string",
          description:
            "Path to the TileMap or TileMapLayer node. TileMapLayer (Godot 4.3+) has a single implicit layer — omit 'layer' or pass 0.",
        },
      },
      required: ["node_path"],
    },
    handler: async (args) => {
      return await callTool("get_tilemap_info", args);
    },
  },
};
