-- https://github.com/williamboman/mason.nvim?tab=readme-ov-file
local M = {
  "williamboman/mason.nvim",
  lazy = false,
}

function M.config()
  require("mason").setup({
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗"
      }
    }
  })

  -- Set transparency for Mason
  vim.api.nvim_set_hl(0, 'MasonHeader', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHeaderSecondary', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHighlight', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHighlightBlock', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHighlightBlockBold', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHighlightSecondary', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHighlightBlockSecondary', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHighlightBlockBoldSecondary', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonNormal', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonNormalFloat', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHighlightBlockBoldSecondary', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonError', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'MasonHeading', { bg = 'none' })
end

return M
