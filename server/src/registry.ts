/**
 * The tool registry, separated from index.ts so it can be built without starting
 * a server: index.ts calls main() at module scope, so importing it to inspect the
 * tool table would launch the process. Nothing here has side effects.
 *
 * 9.7.1 will want to filter this list (a lite/full profile), which is the other
 * reason it is a function over a named list rather than a loop inside main().
 */

import { projectTools } from "./tools/project.js";
import { sceneTools } from "./tools/scene.js";
import { nodeTools } from "./tools/node.js";
import { scriptTools } from "./tools/script.js";
import { editorTools } from "./tools/editor.js";
import { inputTools } from "./tools/input.js";
import { runtimeTools } from "./tools/runtime.js";
import { animationTools } from "./tools/animation.js";
import { animationTreeTools } from "./tools/animation-tree.js";
import { scene3dTools } from "./tools/scene-3d.js";
import { physicsTools } from "./tools/physics.js";
import { particleTools } from "./tools/particles.js";
import { navigationTools } from "./tools/navigation.js";
import { audioTools } from "./tools/audio.js";
import { tilemapTools } from "./tools/tilemap.js";
import { themeTools } from "./tools/theme.js";
import { shaderTools } from "./tools/shader.js";
import { resourceTools } from "./tools/resource.js";
import { batchTools } from "./tools/batch.js";
import { analysisTools } from "./tools/analysis.js";
import { testingTools } from "./tools/testing.js";
import { profilingTools } from "./tools/profiling.js";
import { exportTools } from "./tools/export.js";

import { ToolDefinition } from "./types/index.js";

/** The 23 categories, in the order they are registered. */
export const categoriesByName = {
  project: projectTools,
  scene: sceneTools,
  node: nodeTools,
  script: scriptTools,
  editor: editorTools,
  input: inputTools,
  runtime: runtimeTools,
  animation: animationTools,
  "animation-tree": animationTreeTools,
  "scene-3d": scene3dTools,
  physics: physicsTools,
  particles: particleTools,
  navigation: navigationTools,
  audio: audioTools,
  tilemap: tilemapTools,
  theme: themeTools,
  shader: shaderTools,
  resource: resourceTools,
  batch: batchTools,
  analysis: analysisTools,
  testing: testingTools,
  profiling: profilingTools,
  export: exportTools,
} as const;

export type CategoryName = keyof typeof categoriesByName;

export const toolCategories = Object.values(categoriesByName);

/**
 * The categories a `core` profile keeps: general scene and script work, plus the
 * 3D and physics tools a game project actually reaches for.
 *
 * Chosen by category rather than by naming 76 individual tools, because a
 * hand-listed subset rots the moment a tool is added — and because tool *count*
 * turns out to be a poor proxy for cost anyway: `runtime` is 19 tools in 5.8k
 * characters while `scene-3d` is 6 tools in 8.4k (9.7.1).
 */
export const CORE_CATEGORIES: CategoryName[] = [
  "project", "scene", "node", "script", "editor",
  "input", "runtime", "animation", "scene-3d", "physics",
  "shader", "resource", "batch", "analysis",
];

/**
 * Which categories to register, from the environment.
 *
 * `tools/list` is loaded into the model's context before the user has asked
 * anything, so what it costs is paid every session whether or not a single tool
 * is called. A client that never touches particles or tilemaps should not carry
 * their schemas (9.7.1).
 *
 * `GODOT_MCP_CATEGORIES` is an explicit comma-separated list and wins;
 * `GODOT_MCP_PROFILE=core` selects the curated set; anything else is everything.
 */
export function selectedCategories(env: NodeJS.ProcessEnv = process.env): {
  names: CategoryName[];
  unknown: string[];
} {
  const all = Object.keys(categoriesByName) as CategoryName[];
  const explicit = (env.GODOT_MCP_CATEGORIES ?? "").trim();

  if (explicit) {
    const asked = explicit.split(",").map((s) => s.trim()).filter(Boolean);
    const names = asked.filter((n): n is CategoryName => n in categoriesByName);
    const unknown = asked.filter((n) => !(n in categoriesByName));
    // An all-typo list would otherwise register nothing and look like a broken
    // build; fall back to everything and let the caller report the typos.
    return names.length > 0 ? { names, unknown } : { names: all, unknown };
  }

  if ((env.GODOT_MCP_PROFILE ?? "").trim().toLowerCase() === "core") {
    return { names: CORE_CATEGORIES, unknown: [] };
  }
  return { names: all, unknown: [] };
}

/**
 * Flatten the selected categories into the name → definition map the MCP
 * handlers use. A later category silently wins a name collision, which is why
 * the unit tests assert the flattened count matches the sum of the parts.
 */
export function buildToolRegistry(
  names: CategoryName[] = Object.keys(categoriesByName) as CategoryName[]
): Map<string, ToolDefinition> {
  const registry = new Map<string, ToolDefinition>();
  for (const name of names) {
    for (const [toolName, tool] of Object.entries(categoriesByName[name])) {
      if (typeof tool === "object" && tool !== null && "handler" in tool) {
        registry.set(toolName, tool as ToolDefinition);
      }
    }
  }
  return registry;
}
