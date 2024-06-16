local M = {
	"catppuccin/nvim",
	lazy = false,
	priority = 1000,
	name = "catppuccin",
}

function M.config()
	require("catppuccin").setup({
		flavour = "mocha",
		transparent_background = true,
		integrations = {
			cmp = true,
			gitsigns = true,
			nvimtree = true,
			treesitter = true,
		},
	})

	vim.cmd.colorscheme("catppuccin-mocha")
	-- vim.cmd([[highlight NormalFloat guibg=#1E1E2E]])
	-- vim.cmd([[highlight FloatBorder guibg=#1E1E2E guifg=#C0CAF5]])
	vim.cmd([[highlight NormalFloat guibg=#1E1E2E guifg=#C0CAF5]])
	vim.cmd([[highlight FloatBorder guibg=#1E1E2E guifg=#C0CAF5]])
	vim.cmd([[highlight Pmenu guibg=#1E1E2E guifg=#C0CAF5]])
	vim.cmd([[highlight PmenuSel guibg=#565F89 guifg=#C0CAF5]])
	vim.cmd([[highlight PmenuSbar guibg=#1E1E2E]])
	vim.cmd([[highlight PmenuThumb guibg=#565F89]])

	-- Optional: Add rounded borders for the floating windows (requires Neovim 0.5+)
	vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#C0CAF5", bg = "#1E1E2E" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1E1E2E" })
end

return M
