import { fileURLToPath } from "node:url";
import { Resvg, type RenderedImage } from "@resvg/resvg-js";
import { createHighlighter, type BundledLanguage, type ThemeRegistrationAny, type ThemedToken } from "shiki";
import theme from "./theme.json" with { type: "json" };
import {
	baselineY,
	CELL_ADVANCE,
	cellWidth,
	expandTabs,
	FRAME_PADDING,
	frameSize,
	graphemes,
	glyphX,
	maxColumns,
	prepareCode,
	type FontMetrics,
} from "./layout";

const regularFont = fileURLToPath(new URL("../fonts/GeistMono-Regular.ttf", import.meta.url));
const emojiFont = fileURLToPath(new URL("../fonts/NotoEmoji-VF.ttf", import.meta.url));
const fontFiles = [
	regularFont,
	fileURLToPath(new URL("../fonts/GeistMono-Bold.ttf", import.meta.url)),
	fileURLToPath(new URL("../fonts/GeistMono-Italic.ttf", import.meta.url)),
	fileURLToPath(new URL("../fonts/GeistMono-BoldItalic.ttf", import.meta.url)),
	emojiFont,
];
const shikiTheme = theme as unknown as ThemeRegistrationAny;
let fontMetricsPromise: Promise<FontMetrics> | undefined;

export function escapeXml(text: string): string {
	return text
		.replaceAll("&", "&amp;")
		.replaceAll("<", "&lt;")
		.replaceAll(">", "&gt;")
		.replaceAll('"', "&quot;")
		.replaceAll("'", "&apos;");
}

export function readFontMetrics(buffer: ArrayBuffer): FontMetrics {
	const view = new DataView(buffer);
	const tableCount = view.getUint16(4);
	const tables = new Map<string, number>();
	for (let i = 0; i < tableCount; i++) {
		const entry = 12 + i * 16;
		const tag = String.fromCharCode(...new Uint8Array(buffer, entry, 4));
		tables.set(tag, view.getUint32(entry + 8));
	}

	const offset = (tag: string) => {
		const value = tables.get(tag);
		if (value === undefined) throw new Error(`font is missing ${tag} table`);
		return value;
	};
	const head = offset("head");
	const hhea = offset("hhea");
	const unitsPerEm = view.getUint16(head + 18);
	const ascender = view.getInt16(hhea + 4);
	const descender = view.getInt16(hhea + 6);
	return { unitsPerEm, ascender, descender };
}

async function getFontMetrics(): Promise<FontMetrics> {
	fontMetricsPromise ??= Bun.file(regularFont).arrayBuffer().then(readFontMetrics);
	return fontMetricsPromise;
}

function needsSystemFont(grapheme: string): boolean {
	if (isEmojiGrapheme(grapheme)) return false;
	return [...grapheme].some((character) => {
		const point = character.codePointAt(0)!;
		// Geist Mono covers common punctuation and box drawing; other extended glyphs use system fonts.
		return point > 0x024f
			&& !(point >= 0x2000 && point <= 0x206f)
			&& !(point >= 0x2500 && point <= 0x257f)
			&& !(point >= 0xfe00 && point <= 0xfe0f)
			&& point !== 0x200c
			&& point !== 0x200d;
	});
}

export function requiresSystemFonts(code: string): boolean {
	return graphemes(code).some(needsSystemFont);
}

function isEmojiGrapheme(grapheme: string): boolean {
	return [...grapheme].some((character) => {
		const point = character.codePointAt(0)!;
		return (point >= 0x1f000 && point <= 0x1faff)
			|| (point >= 0x2600 && point <= 0x27ff)
			|| point === 0x20e3
			|| point === 0xfe0f;
	});
}

function xmlNumber(value: number): string {
	return Number(value.toFixed(3)).toString();
}

function renderTokenRun(token: ThemedToken, content: string, column: number, y: number, emoji = false): string {
	const style = token.fontStyle ?? 0;
	const decorations = [
		style & 4 ? "underline" : "",
		style & 8 ? "line-through" : "",
	].filter(Boolean);
	const x = FRAME_PADDING + glyphX(column) + (emoji ? cellWidth(content) * CELL_ADVANCE / 2 : 0);
	const family = emoji ? ' font-family="Noto Emoji" text-anchor="middle"' : "";
	return `<text xml:space="preserve" x="${xmlNumber(x)}" y="${xmlNumber(y)}" fill="${token.color ?? "#EDEDED"}"${family} font-size="15" font-weight="${style & 2 ? 700 : 400}" letter-spacing="0.1"${style & 1 ? ' font-style="italic"' : ""}${decorations.length ? ` text-decoration="${decorations.join(" ")}"` : ""}>${escapeXml(content)}</text>`;
}

function renderToken(token: ThemedToken, startColumn: number, y: number): string {
	let output = "";
	let column = startColumn;
	let runColumn = column;
	let run = "";
	let runNeedsSystemFont = false;
	const flush = () => {
		if (run) output += renderTokenRun(token, run, runColumn, y);
		run = "";
	};
	for (const grapheme of graphemes(token.content)) {
		if (isEmojiGrapheme(grapheme)) {
			flush();
			output += renderTokenRun(token, grapheme, column, y, true);
		} else {
			const needsSystem = needsSystemFont(grapheme);
			if (run && needsSystem !== runNeedsSystemFont) flush();
			if (!run) {
				runColumn = column;
				runNeedsSystemFont = needsSystem;
			}
			run += grapheme;
		}
		column += cellWidth(grapheme);
	}
	flush();
	return output;
}

function expandTokenTabs(lines: ThemedToken[][]): ThemedToken[][] {
	return lines.map((tokens) => {
		let column = 0;
		return tokens.map((token) => {
			const expanded = expandTabs(token.content, column);
			column = expanded.columns;
			return { ...token, content: expanded.text };
		});
	});
}

function snapToDevicePixel(value: number): number {
	return Math.round(value * 2) / 2;
}

function gridAndCrosses(frameWidth: number, frameHeight: number, windowWidth: number, windowHeight: number): string {
	// Half-pixel CSS centers align one-pixel strokes on the reference's 2x raster.
	const left = FRAME_PADDING + 0.5;
	const top = FRAME_PADDING + 0.5;
	const right = snapToDevicePixel(left + windowWidth - 1);
	const bottom = snapToDevicePixel(top + windowHeight - 1);
	const grid = [
		`<line x1="0" y1="${top}" x2="${frameWidth}" y2="${top}"/>`,
		`<line x1="0" y1="${bottom}" x2="${frameWidth}" y2="${bottom}"/>`,
		`<line x1="${left}" y1="0" x2="${left}" y2="${frameHeight}"/>`,
		`<line x1="${right}" y1="0" x2="${right}" y2="${frameHeight}"/>`,
	].join("");
	const crosses = ([
		[left, top],
		[right, bottom],
	] satisfies [number, number][]).map(([x, y]) =>
			`<line x1="${x - 12}" y1="${y}" x2="${x + 13}" y2="${y}"/><line x1="${x}" y1="${y - 12}" x2="${x}" y2="${y + 13}"/>`,
	).join("");
	return `<g fill="none" stroke="#1A1A1A" stroke-width="1" shape-rendering="crispEdges">${grid}</g><g fill="none" stroke="#515356" stroke-width="1" shape-rendering="crispEdges">${crosses}</g>`;
}

export async function codeToSvg(code: string, lang: string): Promise<string> {
	const lines = prepareCode(code);
	const prepared = lines.join("\n");
	let tokenLines: ThemedToken[][];
	if (lang === "plaintext") {
		tokenLines = lines.map((content) => content ? [{ content, offset: 0, color: "#EDEDED" }] : []);
	} else {
		const highlighter = await createHighlighter({
			themes: [shikiTheme],
			langs: [lang as BundledLanguage],
		});
		try {
			tokenLines = highlighter.codeToTokens(prepared, {
				lang: lang as BundledLanguage,
				theme: shikiTheme,
			}).tokens;
		} finally {
			highlighter.dispose();
		}
	}
	tokenLines = expandTokenTabs(tokenLines);

	const metrics = await getFontMetrics();
	const size = frameSize(lines.length, maxColumns(lines));
	const text = tokenLines.map((tokens, lineIndex) => {
		let column = 0;
		const y = FRAME_PADDING + baselineY(lineIndex, metrics);
		return tokens.map((token) => {
			const svg = renderToken(token, column, y);
			column += cellWidth(token.content);
			return svg;
		}).join("");
	}).join("");
	const grid = gridAndCrosses(size.frameWidth, size.frameHeight, size.windowWidth, size.windowHeight);
	return `<svg xmlns="http://www.w3.org/2000/svg" width="${xmlNumber(size.frameWidth)}" height="${size.frameHeight}" viewBox="0 0 ${xmlNumber(size.frameWidth)} ${size.frameHeight}"><rect width="100%" height="100%" fill="#000000"/><g>${text}</g>${grid}</svg>`;
}

export function renderSvg(svg: string, options: { loadSystemFonts?: boolean } = {}): RenderedImage {
	return new Resvg(svg, {
		fitTo: { mode: "zoom", value: 2 },
		font: {
			fontFiles,
			loadSystemFonts: options.loadSystemFonts ?? false,
			defaultFontFamily: "Geist Mono",
		},
	}).render();
}

export async function renderCode(code: string, lang: string): Promise<Buffer> {
	return renderSvg(await codeToSvg(code, lang), { loadSystemFonts: requiresSystemFonts(code) }).asPng();
}
