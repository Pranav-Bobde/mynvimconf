import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import { describe, expect, test } from "bun:test";
import { Resvg } from "@resvg/resvg-js";
import { filetypeToLang } from "./langs";
import { CELL_ADVANCE, FRAME_PADDING, cellWidth, frameSize, glyphX, graphemes, maxColumns, prepareCode } from "./layout";
import { codeToSvg, escapeXml, readFontMetrics, renderCode, renderSvg, requiresSystemFonts } from "./render";

const effect = `import { Effect } from "effect"

const program = Effect.gen(function* () {
  const n = yield* Effect.succeed(42)
  return n * 2
})`;

const leftpad = `module.exports = leftpad;

function leftpad(str, len, ch) {
  str = String(str);
  var i = -1;

  if (!ch && ch !== 0) ch = ' ';

  len = len - str.length;

  while (i++ < len) {
    str = ch + str;
  }
  return str;
}`;

const samples = [
	{ name: "effect", lang: "typescript", code: effect },
	{ name: "leftpad", lang: "javascript", code: leftpad },
	{ name: "html", lang: "html", code: `<main class="demo">Hi &amp; bye</main>` },
	{ name: "python", lang: "python", code: `def twice(value):\n    return value * 2` },
	{ name: "markdown", lang: "markdown", code: `# Snapshot\n\n**bold** and *italic*` },
	{ name: "markdown-bold", lang: "markdown", code: `**Bold** regular` },
	{ name: "cjk-emoji", lang: "plaintext", code: `A界B\n// 🚀 🙂 ✅ ❤️ 👨‍👩‍👧` },
	{ name: "css", lang: "css", code: `body { color: #fff; }` },
	{ name: "json", lang: "json", code: `{"ok": true, "count": 2}` },
	{ name: "txt", lang: "txt", code: `<script>&"'` },
	{ name: "csv", lang: "csv", code: `name,count\nAda,2` },
	{ name: "tsv", lang: "tsv", code: `name\tcount\nAda\t2` },
];

const outDir = new URL("./__out__/", import.meta.url).pathname;

function pixel(image: ReturnType<typeof renderSvg>, x: number, y: number): number[] {
	const offset = (y * image.width + x) * 4;
	return [...image.pixels.subarray(offset, offset + 3)];
}

function hasTokenColor(svg: string, text: string, color: string): boolean {
	return [...svg.matchAll(/<text\b([^>]*)>([\s\S]*?)<\/text>/g)].some(([, attrs, content]) => {
		const decoded = content
			?.replaceAll("&lt;", "<")
			.replaceAll("&gt;", ">")
			.replaceAll("&quot;", "\"")
			.replaceAll("&apos;", "'")
			.replaceAll("&amp;", "&");
		const matches = decoded === text || (text === "Effect" && decoded?.includes(text));
		return matches && attrs?.includes(`fill="${color}"`);
	});
}

function openPng(png: Buffer) {
	const width = png.readUInt32BE(16);
	const height = png.readUInt32BE(20);
	const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><image width="${width}" height="${height}" href="data:image/png;base64,${png.toString("base64")}"/></svg>`;
	return new Resvg(svg).render();
}

function imageRegion(image: ReturnType<typeof renderSvg>, x0: number, y0: number, x1: number, y1: number): number[] {
	const pixels: number[] = [];
	for (let y = y0; y < y1; y++) {
		const start = (y * image.width + x0) * 4;
		const end = (y * image.width + x1) * 4;
		pixels.push(...image.pixels.subarray(start, end));
	}
	return pixels;
}

describe("rendering", () => {
	test("reads only the Geist Mono metrics used by layout", async () => {
		const font = await Bun.file(new URL("../fonts/GeistMono-Regular.ttf", import.meta.url)).arrayBuffer();
		expect(readFontMetrics(font)).toEqual({
			unitsPerEm: 1000,
			ascender: 1005,
			descender: -295,
		});
	});

	test.each(samples.map((sample) => [sample.name, sample] as const))("writes a 2x %s PNG", async (_name, sample) => {
		await mkdir(outDir, { recursive: true });
		const svg = await codeToSvg(sample.code, filetypeToLang(sample.lang));
		const image = renderSvg(svg);
		const png = image.asPng();
		const lines = prepareCode(sample.code);
		const size = frameSize(lines.length, maxColumns(lines));
		const output = join(outDir, `${sample.name}.png`);
		await Bun.write(output, png);

		expect(image.width).toBe(size.pngWidth);
		expect(image.height).toBe(size.pngHeight);
		expect(png.readUInt32BE(16)).toBe(size.pngWidth);
		expect(png.readUInt32BE(20)).toBe(size.pngHeight);
		expect(pixel(image, 0, 0)).toEqual([0, 0, 0]);
		expect(pixel(image, 10, FRAME_PADDING * 2 + 1)).toEqual([26, 26, 26]);
		expect(pixel(image, FRAME_PADDING * 2 + 1, FRAME_PADDING * 2 + 1)).toEqual([81, 83, 86]);
	});

	test("matches pinned Effect and leftpad image sizes", async () => {
		const effectImage = renderSvg(await codeToSvg(effect, "tsx"));
		const leftpadImage = renderSvg(await codeToSvg(leftpad, "javascript"));
		expect([effectImage.width, effectImage.height]).toEqual([1066, 590]);
		expect([leftpadImage.width, leftpadImage.height]).toEqual([1040, 994]);
	});

	test("escapes XML metacharacters in code", () => {
		expect(escapeXml(`<script>&"'`)).toBe("&lt;script&gt;&amp;&quot;&apos;");
	});

	test("uses the requested Vercel token colors", async () => {
		const svg = await codeToSvg(effect, "tsx");
		for (const [token, color] of [
			["import", "#FF4D8D"],
			["Effect", "#EDEDED"],
			["\"effect\"", "#00CA50"],
			["program", "#47A8FF"],
			[".gen", "#C472FB"],
			["n", "#47A8FF"],
			[".succeed", "#C472FB"],
			["42", "#FFFFFF"],
			["return", "#FF4D8D"],
			["2", "#FFFFFF"],
		] as const) {
			expect(hasTokenColor(svg, token, color)).toBe(true);
		}
		expect(hasTokenColor(svg, "Effect", "#47A8FF")).toBe(true);
	});

	test("keeps TSV tabs for tokenization, then expands them at visual tab stops", async () => {
		const svg = await codeToSvg("name\tcount\nAda\t2", "tsv");
		expect(hasTokenColor(svg, "count", "#FF4D8D")).toBe(true);
		expect(hasTokenColor(svg, "2", "#FF4D8D")).toBe(true);
	});

	test("positions text after a wide grapheme and tab at visual column four", async () => {
		for (const grapheme of ["界", "🙂"]) {
			const svg = await codeToSvg(`A${grapheme}\tB`, "plaintext");
			const bRun = svg.match(/<text[^>]*x="([\d.]+)"[^>]*> B<\/text>/);
			expect(Number(bRun?.[1]) + CELL_ADVANCE).toBeCloseTo(FRAME_PADDING + glyphX(4));
		}
	});

	test("renders CJK with a system fallback font", async () => {
		const cjkSvg = await codeToSvg("A界B", "plaintext");
		const cjkImage = openPng(await renderCode("A界B", "plaintext"));
		const cjkWithoutFallback = renderSvg(cjkSvg);
		const cjkPixels = imageRegion(cjkImage, 178, 160, 215, 210);
		const cjkTofuPixels = imageRegion(cjkWithoutFallback, 178, 160, 215, 210);
		expect(cjkPixels.some((channel, index) => channel !== cjkTofuPixels[index])).toBe(true);

	});

	test("renders each emoji in two centered cells with its token color", async () => {
		const code = "// 🚀 🙂 ✅ ❤️ 👨‍👩‍👧";
		const emoji = ["🚀", "🙂", "✅", "❤️", "👨‍👩‍👧"];
		const svg = await codeToSvg(code, "typescript");
		const emojiRuns = [...svg.matchAll(/<text\b([^>]*)>([\s\S]*?)<\/text>/g)]
			.filter(([, attrs]) => attrs?.includes('font-family="Noto Emoji"'));
		const commentColor = svg.match(/<text\b([^>]*)>\/\/ /)?.[1]?.match(/fill="([^"]+)"/)?.[1];

		expect(requiresSystemFonts(code)).toBe(false);
		expect(emojiRuns).toHaveLength(emoji.length);

		let column = 0;
		const image = openPng(await renderCode(code, "typescript"));
		for (const grapheme of graphemes(code)) {
			const width = cellWidth(grapheme);
			if (emoji.includes(grapheme)) {
				const run = emojiRuns.find(([, , content]) => content === grapheme);
				const attributes = run?.[1] ?? "";
				const x = Number(attributes.match(/\bx="([\d.]+)"/)?.[1]);
				const x0 = Math.floor((FRAME_PADDING + glyphX(column)) * 2);
				const x1 = Math.ceil((FRAME_PADDING + glyphX(column + width)) * 2);
				const region = imageRegion(image, x0, 150, x1, 220);
				const tofu = renderSvg(await codeToSvg(
					`// ${"A".repeat(column - 3)}\u{10FFFD}`,
					"typescript",
				));
				const tofuRegion = imageRegion(tofu, x0, 150, x1, 220);

				expect(attributes).toContain('text-anchor="middle"');
				expect(attributes).toContain(`fill="${commentColor}"`);
				expect(x).toBeCloseTo(FRAME_PADDING + (glyphX(column) + glyphX(column + width)) / 2, 3);
				expect(region.some((channel) => channel !== 0)).toBe(true);
				expect(region).not.toEqual(tofuRegion);
			}
			column += width;
		}
	});

	test("loads system fonts only for glyphs without the bundled emoji fallback", () => {
		expect(requiresSystemFonts?.("ASCII ‘quote’ — ──")).toBe(false);
		expect(requiresSystemFonts?.("A界B")).toBe(true);
		expect(requiresSystemFonts?.("A🙂B")).toBe(false);
	});

	test("uses static Geist weights for distinct bold rendering", () => {
		const base = `<svg xmlns="http://www.w3.org/2000/svg" width="180" height="60"><rect width="100%" height="100%" fill="#000"/><text x="4" y="42" fill="#fff" font-family="Geist Mono" font-size="32" font-weight="`;
		const regular = renderSvg(`${base}400">MMMM</text></svg>`);
		const bold = renderSvg(`${base}700">MMMM</text></svg>`);
		expect(bold.pixels).not.toEqual(regular.pixels);
	});

	test("draws each corner cross across 50 device pixels", async () => {
		const image = renderSvg(await codeToSvg("x", "plaintext"));
		const size = frameSize(1, 1);
		const centers: [number, number][] = [
			[FRAME_PADDING * 2 + 1, FRAME_PADDING * 2 + 1],
			[Math.round((FRAME_PADDING + size.windowWidth - 0.5) * 2), Math.round((FRAME_PADDING + size.windowHeight - 0.5) * 2)],
		];
		for (const [centerX, centerY] of centers) {
			const span = Array.from({ length: image.width }, (_, x) => x).filter((x) =>
				pixel(image, x, centerY).join(",") === "81,83,86",
			);
			const vertical = Array.from({ length: image.height }, (_, y) => y).filter((y) =>
				pixel(image, centerX, y).join(",") === "81,83,86",
			);
			expect(span).toHaveLength(50);
			expect(vertical).toHaveLength(50);
			expect(pixel(image, centerX, centerY)).toEqual([81, 83, 86]);
		}
	});
});
