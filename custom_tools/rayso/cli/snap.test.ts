import { afterAll, describe, expect, test } from "bun:test";
import { access, chmod, mkdir, mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const cli = fileURLToPath(new URL("./snap.ts", import.meta.url));
const pluginRoot = fileURLToPath(new URL("../", import.meta.url));
const scratchDirs: string[] = [];

async function scratchDir(): Promise<string> {
	const path = await mkdtemp(join(tmpdir(), "rayso-test-"));
	scratchDirs.push(path);
	return path;
}

async function runCli(args: string[], input: string, env: Record<string, string> = {}) {
	const child = Bun.spawn([process.execPath, cli, ...args], {
		stdin: "pipe",
		stdout: "pipe",
		stderr: "pipe",
		env: { ...process.env, ...env },
	});
	child.stdin.write(input);
	child.stdin.end();
	const [stdout, stderr, code] = await Promise.all([
		new Response(child.stdout).text(),
		new Response(child.stderr).text(),
		child.exited,
	]);
	return { stdout: stdout.trim(), stderr: stderr.trim(), code };
}

async function successfulClipboardEnv(directory: string): Promise<Record<string, string>> {
	const bin = join(directory, "bin");
	const osascript = join(bin, "osascript");
	const marker = join(directory, "clipboard-copied");
	await mkdir(bin, { recursive: true });
	await Bun.write(osascript, "#!/bin/sh\n: > \"$RAYSO_CLIPBOARD_MARKER\"\n");
	await chmod(osascript, 0o755);
	return {
		TMPDIR: directory,
		PATH: `${bin}:${process.env.PATH ?? ""}`,
		RAYSO_CLIPBOARD_MARKER: marker,
	};
}

async function pathExists(path: string): Promise<boolean> {
	try {
		await access(path);
		return true;
	} catch {
		return false;
	}
}

afterAll(async () => {
	await Promise.all(scratchDirs.map((path) => rm(path, { recursive: true, force: true })));
});

describe("snap CLI", () => {
	test("uses a distinct default output path for concurrent invocations", async () => {
		const directory = await scratchDir();
		const env = { TMPDIR: directory };
		const [first, second] = await Promise.all([
			runCli(["--lang", "text", "--no-clipboard"], "AAA", env),
			runCli(["--lang", "text", "--no-clipboard"], "B\nB", env),
		]);
		expect([first.code, second.code]).toEqual([0, 0]);
		expect(first.stdout).not.toBe(second.stdout);
		expect((await readFile(first.stdout)).subarray(0, 8)).toEqual(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
		expect((await readFile(second.stdout)).subarray(0, 8)).toEqual(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
	});

	test("removes default output directory after successful clipboard copy", async () => {
		const directory = await scratchDir();
		const result = await runCli(["--lang", "text"], "copied", await successfulClipboardEnv(directory));

		expect(result.code).toBe(0);
		expect(result.stderr).toBe("");
		expect(await pathExists(join(directory, "clipboard-copied"))).toBe(true);
		const outputDirectory = dirname(result.stdout);
		expect(basename(outputDirectory).startsWith("rayso-snap-")).toBe(true);
		expect(await pathExists(outputDirectory)).toBe(false);
	});

	test("keeps a user-supplied output after successful clipboard copy", async () => {
		const directory = await scratchDir();
		const output = join(directory, "saved.png");
		const result = await runCli(
			["--lang", "text", "--out", output],
			"copied",
			await successfulClipboardEnv(directory),
		);

		expect(result.code).toBe(0);
		expect(result.stdout).toBe(output);
		expect((await readFile(output)).subarray(0, 8)).toEqual(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
		expect(await pathExists(join(directory, "clipboard-copied"))).toBe(true);
	});

	test.each([
		["empty string", ["--lang", ""]],
		["missing value", ["--lang"]],
	])("treats %s as plaintext", async (_name, langArgs) => {
		const directory = await scratchDir();
		const output = join(directory, "plain.png");
		const result = await runCli(["--out", output, "--no-clipboard", ...langArgs], "plain text");
		expect(result.code).toBe(0);
		expect(result.stdout).toBe(output);
	});

	test("rejects an option where --lang expects a value", async () => {
		const directory = await scratchDir();
		const result = await runCli([
			"--lang", "--no-clipboard", "--out", join(directory, "plain.png"), "--no-clipboard",
		], "plain text");
		expect(result.code).toBe(1);
		expect(result.stderr).toContain("--lang value must not start with --");
		expect(result.stderr.split("\n")).toHaveLength(1);
	});

	test("rejects an option where --out expects a path", async () => {
		const directory = await scratchDir();
		const result = await runCli([
			"--out", "--no-clipboard", "--out", join(directory, "plain.png"), "--no-clipboard",
		], "plain text");
		expect(result.code).toBe(1);
		expect(result.stderr).toContain("--out value must not start with --");
	});

	test("reports stdin read failures as one stderr line", async () => {
		const directory = await scratchDir();
		const child = Bun.spawn([
			"/bin/sh",
			"-c",
			'exec "$1" "$2" --lang text --no-clipboard < "$3"',
			"rayso-test",
			process.execPath,
			cli,
			directory,
		], { stdout: "pipe", stderr: "pipe" });
		const [stdout, stderr, code] = await Promise.all([
			new Response(child.stdout).text(),
			new Response(child.stderr).text(),
			child.exited,
		]);
		expect(code).toBe(1);
		expect(stdout).toBe("");
		expect(stderr.trim().split("\n")).toHaveLength(1);
		expect(stderr).toContain("input error:");
	});

	test("notifies at ERROR level when Neovim cannot spawn Bun", async () => {
		const directory = await scratchDir();
		const script = join(directory, "missing-bun.lua");
		const luaRoot = JSON.stringify(pluginRoot.replaceAll("\\", "/"));
		await Bun.write(script, `
vim.opt.rtp:prepend(${luaRoot})
vim.env.PATH = "/missing-bun"
local notices = {}
vim.notify = function(message, level) notices[#notices + 1] = { message, level } end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "x" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd("normal! v")
require("rayso").snap()
vim.wait(500, function() return #notices > 0 end)
assert(notices[1] and notices[1][2] == vim.log.levels.ERROR, "missing Bun must notify at ERROR level")
assert(notices[1][1]:find("bun", 1, true), "notification must name bun")
`);
		const nvim = Bun.which("nvim");
		expect(nvim).not.toBeNull();
		const result = Bun.spawnSync([nvim!, "--headless", "--clean", "-u", "NONE", "-l", script]);
		expect(result.exitCode).toBe(0);
	});
});
