vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Replace doesn't overwrite the last yanked text in the register
vim.keymap.set("x", "p", [["_dP]])
-- Yank to system clipboard by default
vim.keymap.set({"n", "v"}, "y", '"+y', { noremap = true, silent = true })
vim.keymap.set("n", "yy", '"+yy', { noremap = true, silent = true })

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
vim.api.nvim_create_user_command("E", function(opts)
  local target = opts.args ~= "" and (" " .. opts.args) or ""
  vim.cmd("Oil" .. target)
end, { nargs = "?", complete = "dir", desc = "Open Oil explorer" })
vim.keymap.set("n", "<leader>so", ":source ~/.config/nvim/init.lua", { desc = "Source init.lua" })

-- Function to maximize the current buffer
function _G.toggle_maximize_buffer()
  local is_maximized = vim.t.maximized or false

  if is_maximized then
    -- Restore previous window layout
    vim.cmd('wincmd =')
    vim.t.maximized = false
  else
    -- Maximize current window
    vim.cmd('resize | vertical resize')
    vim.t.maximized = true
  end
end

-- Map Space + f to maximize the focused buffer
vim.api.nvim_set_keymap('n', '<Space>ff', ':lua toggle_maximize_buffer()<CR>', { noremap = true, silent = true })

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
-- vim.keymap.set("n", "<leader>d", function()
-- 	vim.diagnostic.enable(true, nil)
-- end, { desc = "Enable diagnostic" })

--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-w>,", ":vertical resize -10<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-w>.", ":vertical resize +10<CR>", { noremap = true, silent = true })


-- Reset highlighted search keyword
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- V-split & focus on the new buffer
vim.api.nvim_set_keymap("n", "<leader>v", ":vsplit<CR>", { noremap = true, silent = true })
-- H-split & focus on the new buffer
vim.api.nvim_set_keymap("n", "<leader>s", ":split<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<leader>>", "<C-w>>", { noremap = true, silent = true })

-- move to start & end of line
vim.keymap.set({ "n", "o", "x" }, "<s-h>", "^", { noremap = true, silent = true })
vim.keymap.set({ "n", "o", "x" }, "<s-l>", "g_", { noremap = true, silent = true })

-- tailwind bearable to work with
vim.keymap.set({ "n", "x" }, "j", "gj", { noremap = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "gk", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>w", ":lua vim.wo.wrap = not vim.wo.wrap<CR>", { noremap = true, silent = true })

-- Move lines up
-- vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
-- vim.keymap.set("n", "<A-k>", ":m -2<CR>", { noremap = true, silent = true })

-- Move lines up
-- vim.keymap.set("n", "<A-j>", ":m +1<CR>", { noremap = true, silent = true })
-- vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })

vim.keymap.set("n", "<C-_>", "10<C-w>>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-=>", "10<C-w><", { noremap = true, silent = true })

vim.api.nvim_create_augroup("custom_buffer", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = "custom_buffer",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Create an augroup for auto-saving
vim.api.nvim_create_augroup("autosave", { clear = true })

-- Define the autocmd for CursorHold event
vim.api.nvim_create_autocmd("CursorHold", {
  group = "autosave",
  pattern = "*",
  callback = function()
    -- Get the current file name and file type
    local file_name = vim.fn.expand("%:t")
    local file_type = vim.bo.filetype

    -- Define the list of excluded file types and file names
    local excluded_filetypes = { "lua" }
    local excluded_files = { "scope.lua" }

    -- Check if the buffer is modifiable and not a special buffer
    if vim.bo.modified and vim.bo.buftype == "" then
      -- Check if the current file type or file name is excluded
      if
          not vim.tbl_contains(excluded_filetypes, file_type) and not vim.tbl_contains(excluded_files, file_name)
      then
        vim.cmd("write")
      end
    end
  end,
})

vim.keymap.set("n", "<leader>l", ":lua vim.cmd('e'..vim.lsp.get_log_path())", { noremap = true, silent = true })

vim.g.session_start_cwd = vim.g.session_start_cwd or vim.loop.cwd()

vim.keymap.set("n", "<leader>tt", function()
  vim.cmd("botright 14new")
  vim.fn.termopen(vim.o.shell, { cwd = vim.g.session_start_cwd })
  vim.cmd("startinsert")
end, { desc = "Open terminal (start cwd)", noremap = true, silent = true })

local term_tmux_nav = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

for key, direction in pairs(term_tmux_nav) do
  vim.keymap.set("t", "<M-" .. key .. ">", "<C-\\><C-n><cmd>TmuxNavigate" .. direction .. "<CR>", {
    noremap = true,
    silent = true,
  })
end
