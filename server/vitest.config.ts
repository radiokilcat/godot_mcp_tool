import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // The old "../tests/**" entry pointed at a repo-root tests/ directory that
    // 9.2 deleted along with the one test it held.
    include: ["tests/**/*.test.ts", "src/**/*.test.ts"],
    globals: true,
  },
});
