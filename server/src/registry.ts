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
export const toolCategories = [
  projectTools,
  sceneTools,
  nodeTools,
  scriptTools,
  editorTools,
  inputTools,
  runtimeTools,
  animationTools,
  animationTreeTools,
  scene3dTools,
  physicsTools,
  particleTools,
  navigationTools,
  audioTools,
  tilemapTools,
  themeTools,
  shaderTools,
  resourceTools,
  batchTools,
  analysisTools,
  testingTools,
  profilingTools,
  exportTools,
];

/**
 * Flatten the categories into the name → definition map the MCP handlers use.
 * A later category silently wins a name collision, which is why the unit tests
 * assert the flattened count matches the sum of the parts.
 */
export function buildToolRegistry(): Map<string, ToolDefinition> {
  const registry = new Map<string, ToolDefinition>();
  for (const category of toolCategories) {
    for (const [name, tool] of Object.entries(category)) {
      if (typeof tool === "object" && tool !== null && "handler" in tool) {
        registry.set(name, tool as ToolDefinition);
      }
    }
  }
  return registry;
}
