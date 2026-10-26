import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { filetypeToLang } from "./langs";
import { renderCode } from "./render";

type Options = {
	lang: string;
	out?: string;
	noClipboard: boolean;
};

function parseOptions(args: string[]): Options {
	let lang = "";
	let out: string | undefined;
	let noClipboard = false;
	for (let i = 0; i < args.length; i++) {
		const arg = args[i];
		if (arg === "--lang") {
			const value = args[i + 1];
			if (value?.startsWith("--")) throw new Error(`--lang value must not start with --: ${value}`);
			if (value !== undefined) i++;
			lang = value ?? "";
		} else if (arg === "--out") {
			const value = args[i + 1];
			if (value?.startsWith("--")) throw new Error(`--out value must not start with --: ${value}`);
			if (value === undefined || value === "") throw new Error("missing --out path");
			out = value;
			i++;
		}
		else if (arg === "--no-clipboard") noClipboard = true;
		else throw new Error(`unknown option ${arg}`);
	}
	return { lang, out, noClipboard };
}

function oneLine(error: unknown): string {
	return (error instanceof Error ? error.message : String(error)).replace(/[\r\n]+/g, " ").trim();
}

async function copyPng(path: string): Promise<void> {
	const appleScriptPath = resolve(path).replaceAll("\\", "\\\\").replaceAll('"', '\\"');
	const script = `set the clipboard to (read (POSIX file "${appleScriptPath}") as «class PNGf»)`;
	const process = Bun.spawn(["osascript", "-e", script], { stderr: "pipe", stdout: "ignore" });
	const stderr = await new Response(process.stderr).text();
	const exitCode = await process.exited;
	if (exitCode !== 0) throw new Error(oneLine(stderr || `osascript exited ${exitCode}`));
}

async function main(): Promise<void> {
	let options: Options;
	try {
		options = parseOptions(Bun.argv.slice(2));
	} catch (error) {
		process.stderr.write(`usage error: ${oneLine(error)}\n`);
		process.exitCode = 1;
		return;
	}

	let code: string;
	try {
		code = await Bun.stdin.text();
	} catch (error) {
		process.stderr.write(`input error: ${oneLine(error)}\n`);
		process.exitCode = 1;
		return;
	}
	if (!code.trim()) {
		process.stderr.write("empty input\n");
		process.exitCode = 1;
		return;
	}

	let output: string;
	let temporaryOutputDirectory: string | undefined;
	try {
		const png = await renderCode(code, filetypeToLang(options.lang));
		if (options.out) output = options.out;
		else {
			temporaryOutputDirectory = await mkdtemp(join(tmpdir(), "rayso-snap-"));
			output = join(temporaryOutputDirectory, "rayso-snap.png");
		}
		await mkdir(dirname(output), { recursive: true });
		await Bun.write(output, png);
	} catch (error) {
		process.stderr.write(`render error: ${oneLine(error)}\n`);
		process.exitCode = 1;
		return;
	}

	if (!options.noClipboard) {
		try {
			await copyPng(output);
		} catch (error) {
			process.stderr.write(`clipboard error: ${oneLine(error)}\n`);
			process.exitCode = 1;
			return;
		}
		if (temporaryOutputDirectory) {
			try {
				await rm(temporaryOutputDirectory, { recursive: true, force: true });
			} catch (error) {
				process.stderr.write(`cleanup error: ${oneLine(error)}\n`);
				process.exitCode = 1;
				return;
			}
		}
	}
	process.stdout.write(`${output}\n`);
}

if (import.meta.main) await main();
