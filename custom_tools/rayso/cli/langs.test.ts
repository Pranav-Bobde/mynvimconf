import { describe, expect, test } from "bun:test";
import { filetypeToLang } from "./langs";

describe("filetypeToLang", () => {
	test.each([
		["typescript", "tsx"],
		["typescriptreact", "tsx"],
		["javascript", "javascript"],
		["javascriptreact", "jsx"],
		["html", "html"],
		["python", "python"],
		["markdown", "markdown"],
		["css", "css"],
		["scss", "scss"],
		["json", "json"],
		["jsonc", "jsonc"],
		["csv", "csv"],
		["tsv", "tsv"],
		["lua", "lua"],
		["sh", "shellscript"],
		["bash", "shellscript"],
		["zsh", "shellscript"],
		["yaml", "yaml"],
		["toml", "toml"],
		["sql", "sql"],
		["vue", "vue"],
		["svelte", "svelte"],
		["graphql", "graphql"],
		["dockerfile", "dockerfile"],
		["diff", "diff"],
		["xml", "xml"],
		["text", "plaintext"],
		["txt", "plaintext"],
		["", "plaintext"],
	])("maps %s to %s", (filetype, language) => {
		expect(filetypeToLang(filetype)).toBe(language);
	});

	test("uses another bundled language id as fallback", () => {
		expect(filetypeToLang("typescript", { typescript: true })).toBe("tsx");
		expect(filetypeToLang("json5", { json5: true })).toBe("json5");
		expect(filetypeToLang("unknown", {})).toBe("plaintext");
	});

	test.each(["constructor", "toString", "hasOwnProperty"])("maps inherited key %s to plaintext", (filetype) => {
		expect(filetypeToLang(filetype)).toBe("plaintext");
	});

	test("rejects inherited keys in the bundled language table", () => {
		expect(filetypeToLang("constructor", {})).toBe("plaintext");
		expect(filetypeToLang("toString", {})).toBe("plaintext");
	});
});
