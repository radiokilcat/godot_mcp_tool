import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["../tests/**/*.test.ts", "**/*.test.ts"],
    globals: true,
    // There are no unit tests right now: the only one covered type-parser.ts,
    // which nothing imported (deleted in 9.2). Without this, `npm test` fails on
    // an empty suite and looks like a broken build. Drop this line as soon as
    // 6.1.3 lands real tests for the modules that are actually wired in.
    passWithNoTests: true,
  },
});
