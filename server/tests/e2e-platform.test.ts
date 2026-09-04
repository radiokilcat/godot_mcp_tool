import { describe, it, expect } from "vitest";
// @ts-expect-error - plain .mjs harness module, no type declarations
import { platformFor, allPlatforms } from "../../e2e/lib/platform/index.mjs";

/**
 * Tests for the e2e harness's platform layer (progress.md 9.6). They live in the
 * server's vitest suite because that is the repo's only JS test runner, and they
 * are pure functions with nothing to spawn.
 *
 * These matter more than most: the harness runs on exactly one host at a time, so
 * two of the three modules are always untested by simply running the suite. The
 * shape check below is the real guard — it fails if a platform is added or the
 * interface changes and one module is left behind.
 */

const INTERFACE = [
  "name",
  "archiveName",
  "distName",
  "binaryPath",
  "selfContainedDir",
  "extract",
  "afterExtract",
  "spawnOptions",
  "killTree",
];

describe("platform selection", () => {
  it("covers the three hosts the README promises", () => {
    expect(Object.keys(allPlatforms).sort()).toEqual(["darwin", "linux", "win32"]);
  });

  it("names the missing module when the host is unsupported", () => {
    expect(() => platformFor("freebsd")).toThrow(/e2e\/lib\/platform\/freebsd\.mjs/);
  });

  it.each(Object.entries(allPlatforms))("%s implements the whole interface", (id, platform) => {
    for (const member of INTERFACE) {
      expect(platform, `${id} is missing ${member}`).toHaveProperty(member);
    }
    expect(platform.name).toBe(id);
  });
});

describe("release archive names", () => {
  it("matches the assets Godot actually publishes", () => {
    // Checked against the 4.4.1-stable release page; a typo here fails as a 404
    // after the download has already started.
    expect(allPlatforms.win32.archiveName("4.4.1", "x64")).toBe("Godot_v4.4.1-stable_win64.exe.zip");
    expect(allPlatforms.linux.archiveName("4.4.1", "x64")).toBe("Godot_v4.4.1-stable_linux.x86_64.zip");
    expect(allPlatforms.linux.archiveName("4.4.1", "arm64")).toBe("Godot_v4.4.1-stable_linux.arm64.zip");
    expect(allPlatforms.darwin.archiveName("4.4.1")).toBe("Godot_v4.4.1-stable_macos.universal.zip");
  });

  it("keeps the cache directory name stable on Windows", () => {
    // The pre-9.6 harness cached under exactly this name. Changing it would
    // silently re-download 66 MB on every existing checkout.
    expect(allPlatforms.win32.distName("4.4.1", "x64")).toBe("Godot_v4.4.1-stable_win64");
  });
});

describe("binary and marker locations", () => {
  const norm = (p: string) => p.replace(/\\/g, "/");

  it("uses the console executable on Windows", () => {
    // The plain .exe detaches from the console and writes nothing the harness
    // can capture — no editor log, and no way to see a parse error.
    expect(norm(allPlatforms.win32.binaryPath("/c", "4.4.1", "x64")))
      .toBe("/c/Godot_v4.4.1-stable_win64_console.exe");
  });

  it("uses the single binary elsewhere", () => {
    expect(norm(allPlatforms.linux.binaryPath("/c", "4.4.1", "x64")))
      .toBe("/c/Godot_v4.4.1-stable_linux.x86_64");
  });

  it("reaches inside the .app bundle on macOS", () => {
    expect(norm(allPlatforms.darwin.binaryPath("/c"))).toBe("/c/Godot.app/Contents/MacOS/Godot");
  });

  it("puts the self-contained marker beside the binary, not beside the bundle", () => {
    // The load-bearing macOS detail: Godot looks for _sc_ next to the executable.
    // Writing it to the unpack directory would silently leave self-contained mode
    // off, and the run would then read and write the developer's real editor
    // settings instead of a throwaway copy.
    expect(norm(allPlatforms.darwin.selfContainedDir("/c"))).toBe("/c/Godot.app/Contents/MacOS");
    expect(norm(allPlatforms.win32.selfContainedDir("/c"))).toBe("/c");
    expect(norm(allPlatforms.linux.selfContainedDir("/c"))).toBe("/c");
  });
});

describe("process handling", () => {
  it("spawns into a process group only where one exists", () => {
    // POSIX needs the editor to lead its own group so the whole tree can be
    // signalled; Windows has taskkill /T instead and must not pass detached.
    expect(allPlatforms.linux.spawnOptions).toEqual({ detached: true });
    expect(allPlatforms.darwin.spawnOptions).toEqual({ detached: true });
    expect(allPlatforms.win32.spawnOptions).toEqual({});
  });

  it("treats an already-dead process group as success", () => {
    // killTree runs in teardown, including after a run that already crashed the
    // editor. ESRCH means the thing we wanted gone is gone.
    const dead = 0x7ffffff0;
    expect(() => allPlatforms.linux.killTree(dead)).not.toThrow();
    expect(() => allPlatforms.darwin.killTree(dead)).not.toThrow();
  });
});
