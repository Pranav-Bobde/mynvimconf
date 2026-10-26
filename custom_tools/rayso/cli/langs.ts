import { bundledLanguages } from "shiki";

const filetypeAliases: Record<string, string> = {
	typescript: "tsx",
	typescriptreact: "tsx",
	javascriptreact: "jsx",
	sh: "shellscript",
	bash: "shellscript",
	zsh: "shellscript",
	text: "plaintext",
	txt: "plaintext",
};

export function filetypeToLang(
	filetype: string,
	available: Record<string, unknown> = bundledLanguages,
): string {
	if (filetype === "") return "plaintext";
	if (Object.hasOwn(filetypeAliases, filetype)) return filetypeAliases[filetype]!;
	return Object.hasOwn(available, filetype) ? filetype : "plaintext";
}
