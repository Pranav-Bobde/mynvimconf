import { describe, expect, test } from "bun:test";
import {
	baselineY,
	cellWidth,
	expandTabs,
	frameSize,
	glyphX,
	prepareCode,
} from "./layout";

describe("prepareCode", () => {
	test("strips common leading indentation", () => {
		expect(prepareCode("    alpha\n      beta\n\n    gamma\n")).toEqual([
			"alpha",
			"  beta",
			"",
			"gamma",
		]);
	});

	test("keeps tabs intact until after tokenization", () => {
		expect(prepareCode("\talpha\n  \tbeta\n")).toEqual([
			"alpha",
			"\tbeta",
		]);
	});

	test("drops trailing blank lines", () => {
		expect(prepareCode("one\n\n  \n")).toEqual(["one"]);
	});
});

describe("cell widths and positions", () => {
	test("counts CJK and emoji as two cells", () => {
		expect(cellWidth("界🙂x")).toBe(5);
	});

	test("counts a variation-selector emoji as one two-cell grapheme", () => {
		expect(cellWidth("A❤️B")).toBe(4);
	});

	test("expands tabs after an emoji grapheme from its visual column", () => {
		expect(expandTabs("A❤️\tB")).toEqual({ text: "A❤️ B", columns: 5 });
	});

	test("places glyphs on fixed 9.1px cell columns", () => {
		expect(glyphX(0)).toBe(16);
		expect(glyphX(3)).toBeCloseTo(43.3);
	});

	test("uses font metrics to center the line box baseline", () => {
		const metrics = { unitsPerEm: 1000, ascender: 1005, descender: -295 };
		expect(baselineY(0, metrics)).toBe(32.5);
		expect(baselineY(1, metrics)).toBe(55);
	});
});

describe("frameSize", () => {
	test("matches the pinned 15-line leftpad image", () => {
		expect(frameSize(15, 31)).toMatchObject({
			windowWidth: 392,
			frameWidth: 520,
			pngWidth: 1040,
			pngHeight: 994,
		});
	});

	test("matches the pinned six-line Effect image", () => {
		expect(frameSize(6, 41)).toMatchObject({
			frameWidth: 41 * 9.1 + 160,
			pngWidth: 1066,
			pngHeight: 590,
		});
	});

	test("widens beyond 920px for a 140-column line", () => {
		expect(frameSize(1, 140).pngWidth).toBeGreaterThan(920);
	});
});
