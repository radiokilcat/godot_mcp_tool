/**
 * Unit tests for type parser
 */

import { describe, it, expect } from "vitest";
import {
  parseGodotType,
  godotTypeToString,
  GodotVector2,
  GodotVector3,
  GodotColor,
} from "../server/src/utils/type-parser.js";

describe("Type Parser", () => {
  describe("Vector2 parsing", () => {
    it("should parse Vector2(100, 200)", () => {
      const result = parseGodotType("Vector2(100, 200)");
      expect(result).toEqual({ type: "Vector2", x: 100, y: 200 });
    });

    it("should parse Vector2 with decimals", () => {
      const result = parseGodotType("Vector2(1.5, 2.3)");
      expect(result).toEqual({ type: "Vector2", x: 1.5, y: 2.3 });
    });

    it("should parse Vector2 with negative values", () => {
      const result = parseGodotType("Vector2(-10, -20)");
      expect(result).toEqual({ type: "Vector2", x: -10, y: -20 });
    });

    it("should parse Vector2 with spaces", () => {
      const result = parseGodotType("Vector2( 100 , 200 )");
      expect(result).toEqual({ type: "Vector2", x: 100, y: 200 });
    });
  });

  describe("Vector3 parsing", () => {
    it("should parse Vector3(100, 200, 300)", () => {
      const result = parseGodotType("Vector3(100, 200, 300)");
      expect(result).toEqual({ type: "Vector3", x: 100, y: 200, z: 300 });
    });

    it("should parse Vector3 with decimals", () => {
      const result = parseGodotType("Vector3(1.5, 2.3, 3.7)");
      expect(result).toEqual({ type: "Vector3", x: 1.5, y: 2.3, z: 3.7 });
    });
  });

  describe("Color parsing", () => {
    it("should parse Color(r, g, b, a)", () => {
      const result = parseGodotType("Color(1, 0, 0, 1)");
      expect(result).toEqual({
        type: "Color",
        r: 1,
        g: 0,
        b: 0,
        a: 1,
      });
    });

    it("should parse Color without alpha", () => {
      const result = parseGodotType("Color(1, 0, 0)");
      expect(result).toEqual({
        type: "Color",
        r: 1,
        g: 0,
        b: 0,
        a: 1,
      });
    });

    it("should clamp color values", () => {
      const result = parseGodotType("Color(2, -1, 0.5)");
      expect(result).toEqual({
        type: "Color",
        r: 1,
        g: 0,
        b: 0.5,
        a: 1,
      });
    });
  });

  describe("Hex color parsing", () => {
    it("should parse #ff0000", () => {
      const result = parseGodotType("#ff0000");
      expect(result).toEqual({
        type: "Color",
        r: 1,
        g: 0,
        b: 0,
        a: 1,
        hex: "#ff0000",
      });
    });

    it("should parse #ff0000ff", () => {
      const result = parseGodotType("#ff0000ff");
      expect(result).toEqual({
        type: "Color",
        r: 1,
        g: 0,
        b: 0,
        a: 1,
        hex: "#ff0000ff",
      });
    });

    it("should parse #00ff00", () => {
      const result = parseGodotType("#00ff00");
      expect(result).toEqual({
        type: "Color",
        r: 0,
        g: 1,
        b: 0,
        a: 1,
        hex: "#00ff00",
      });
    });
  });

  describe("Number parsing", () => {
    it("should parse integers", () => {
      expect(parseGodotType("42")).toBe(42);
    });

    it("should parse decimals", () => {
      expect(parseGodotType("3.14")).toBe(3.14);
    });

    it("should parse negative numbers", () => {
      expect(parseGodotType("-100")).toBe(-100);
    });

    it("should parse scientific notation", () => {
      expect(parseGodotType("1.5e-3")).toBe(0.0015);
    });
  });

  describe("Boolean parsing", () => {
    it("should parse true", () => {
      expect(parseGodotType("true")).toBe(true);
    });

    it("should parse false", () => {
      expect(parseGodotType("false")).toBe(false);
    });

    it("should parse TRUE", () => {
      expect(parseGodotType("TRUE")).toBe(true);
    });
  });

  describe("Null parsing", () => {
    it("should parse null", () => {
      expect(parseGodotType("null")).toBe(null);
    });
  });

  describe("String fallback", () => {
    it("should return string for non-matching input", () => {
      expect(parseGodotType("hello")).toBe("hello");
    });

    it("should return string for node paths", () => {
      expect(parseGodotType("/root/Main/Player")).toBe("/root/Main/Player");
    });
  });

  describe("Type to string conversion", () => {
    it("should convert Vector2 back to string", () => {
      const vector: GodotVector2 = { type: "Vector2", x: 100, y: 200 };
      const result = godotTypeToString(vector);
      expect(result).toBe("Vector2(100, 200)");
    });

    it("should convert Vector3 back to string", () => {
      const vector: GodotVector3 = {
        type: "Vector3",
        x: 100,
        y: 200,
        z: 300,
      };
      const result = godotTypeToString(vector);
      expect(result).toBe("Vector3(100, 200, 300)");
    });

    it("should convert Color back to string", () => {
      const color: GodotColor = {
        type: "Color",
        r: 1,
        g: 0,
        b: 0,
        a: 1,
      };
      const result = godotTypeToString(color);
      expect(result).toBe("Color(1, 0, 0, 1)");
    });
  });

  describe("Round trip parsing", () => {
    it("should parse and convert back to same value", () => {
      const original = "Vector2(100.5, 200.3)";
      const parsed = parseGodotType(original);
      const converted = godotTypeToString(parsed);
      const reparsed = parseGodotType(converted);
      expect(parsed).toEqual(reparsed);
    });
  });
});
