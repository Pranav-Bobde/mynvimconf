-- Automatic per-directory nvim sessions.
--
-- vim-obsession keeps a session file continuously up to date (every buffer and
-- window change), so it survives a hard kill — unlike session managers that
-- only write on a clean :quit, which a reboot never gives you.
--
-- Two departures from stock vim-obsession, both so this needs zero ceremony:
--   1. Session files live in a central store keyed by cwd, not as a Session.vim
--      littering every project you happen to open.
--   2. Tracking arms itself on entry, and an existing session for the cwd loads
--      itself. No :Obsession to remember.
--
-- Pairs with tmux-resurrect: a restored pane re-runs `nvim` in its saved
-- directory, which lands here and reopens that directory's buffers and layout.

local M = {
	"tpope/vim-obsession",
	lazy = false,
	priority = 100,
	keys = {
		{ "<leader>O", "<cmd>Obsession<cr>", desc = "Toggle session tracking for this directory" },
	},
}

local store = vim.fn.stdpath("data") .. "/sessions"

local function session_file()
	-- percent-encode the cwd so it survives as a single flat filename
	local cwd = vim.fn.getcwd()
	return store .. "/" .. cwd:gsub("%%", "%%25"):gsub("/", "%%") .. ".vim"
end

-- Sessions are for "I am working in this project", not for one-off edits,
-- git commit messages, pager use, or a stray nvim in $HOME.
local function should_track()
	if vim.fn.argc() > 0 then return false end            -- opened with file args
	if vim.g.obsession_disable then return false end
	if vim.o.diff then return false end
	if vim.bo.filetype == "gitcommit" or vim.bo.filetype == "gitrebase" then return false end
	if vim.fn.exists("v:this_session") == 1 and vim.v.this_session ~= "" then return false end
	local cwd = vim.fn.getcwd()
	if cwd == vim.env.HOME or cwd == "/" then return false end
	if vim.g.read_from_stdin then return false end        -- started as a pager / piped stdin
	return true
end

function M.config()
	vim.fn.mkdir(store, "p")

	vim.api.nvim_create_autocmd("StdinReadPre", {
		callback = function() vim.g.read_from_stdin = true end,
	})

	local function arm()
		if not should_track() then return end
		local f = session_file()
		if vim.fn.filereadable(f) == 1 then
			-- the session file ends with `let g:this_obsession = v:this_session`,
			-- so sourcing it re-arms tracking on its own
			local ok, err = pcall(vim.cmd, "silent source " .. vim.fn.fnameescape(f))
			if ok then return end
			vim.notify("session restore failed: " .. tostring(err), vim.log.levels.WARN)
			vim.fn.delete(f)
		end
		vim.cmd("silent Obsession " .. vim.fn.fnameescape(f))
	end

	-- Not a VimEnter autocmd: lazy.nvim loads plugins from inside its own
	-- VimEnter handler, and autocmds registered while an event is firing are
	-- skipped for that event. Scheduling runs arm() on the next loop tick, once
	-- startup has fully settled, regardless of when lazy got around to us.
	vim.schedule(arm)
end

return M
