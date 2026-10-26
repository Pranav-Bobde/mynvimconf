import stringWidth from "string-width";

export type FontMetrics = {
	unitsPerEm: number;
	ascender: number;
	descender: number;
};

export const FONT_SIZE = 15;
export const LINE_HEIGHT = 22.5;
export const CELL_ADVANCE = 9.1;
export const TEXT_INSET = 16;
export const FRAME_PADDING = 64;
const segmenter = new Intl.Segmenter(undefined, { granularity: "grapheme" });

export function graphemes(text: string): string[] {
	return Array.from(segmenter.segment(text), ({ segment }) => segment);
}

export function prepareCode(code: string): string[] {
	const inputLines = code.replace(/\r\n?/g, "\n").split("\n");
	const nonBlank = inputLines.filter((line) => line.trim() !== "");
	const indent = nonBlank.length
		? Math.min(...nonBlank.map(indentationColumns))
		: 0;
	const lines = inputLines.map((line) => line.trim() === "" ? "" : removeIndent(line, indent));

	while (lines.length > 0 && lines.at(-1)?.trim() === "") lines.pop();
	return lines.length > 0 ? lines : [""];
}

function indentationColumns(line: string): number {
	let column = 0;
	for (const character of line) {
		if (character === " ") column++;
		else if (character === "\t") column += 2 - (column % 2);
		else break;
	}
	return column;
}

function removeIndent(line: string, indent: number): string {
	let column = 0;
	let index = 0;
	let remainder = "";
	while (index < line.length) {
		const character = line[index];
		if (character !== " " && character !== "\t") break;
		const nextColumn = character === "\t" ? column + 2 - (column % 2) : column + 1;
		if (nextColumn > indent) {
			if (column < indent) {
				remainder = " ".repeat(nextColumn - indent);
				index++;
			}
			break;
		}
		column = nextColumn;
		index++;
	}
	return remainder + line.slice(index);
}

export function expandTabs(text: string, column = 0): { text: string; columns: number } {
	let output = "";
	for (const grapheme of graphemes(text)) {
		if (grapheme === "\t") {
			const spaces = 2 - (column % 2);
			output += " ".repeat(spaces);
			column += spaces;
		} else {
			output += grapheme;
			column += cellWidth(grapheme);
		}
	}
	return { text: output, columns: column };
}

export function cellWidth(text: string): number {
	return graphemes(text).reduce((width, grapheme) => width + stringWidth(grapheme), 0);
}

export function maxColumns(lines: string[]): number {
	return Math.max(0, ...lines.map((line) => expandTabs(line).columns));
}

export function glyphX(column: number): number {
	return TEXT_INSET + column * CELL_ADVANCE;
}

export function baselineY(lineIndex: number, metrics: FontMetrics): number {
	const glyphHeight = ((metrics.ascender - metrics.descender) * FONT_SIZE) / metrics.unitsPerEm;
	const baselineInLine = (LINE_HEIGHT - glyphHeight) / 2 + (metrics.ascender * FONT_SIZE) / metrics.unitsPerEm;
	return Math.round((TEXT_INSET + lineIndex * LINE_HEIGHT + baselineInLine) * 2) / 2;
}

export function frameSize(lineCount: number, maxCols: number) {
	const windowWidth = Math.max(392, maxCols * CELL_ADVANCE + 32);
	const windowHeight = lineCount * LINE_HEIGHT + 32;
	const frameWidth = windowWidth + FRAME_PADDING * 2;
	// The pinned 15-line reference is 994px tall, so snap CSS height before 2x rasterization.
	const frameHeight = Math.floor(windowHeight + FRAME_PADDING * 2);
	return {
		windowWidth,
		windowHeight,
		frameWidth,
		frameHeight,
		pngWidth: Math.round(frameWidth * 2),
		pngHeight: Math.round(frameHeight * 2),
	};
}
