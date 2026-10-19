local M = {
  'stevearc/conform.nvim',
  lazy = false,
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = "fallback" }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  }
}

function M.config()
  require("conform").setup({
    notify_on_error = false,
    formatters_by_ft = {
      lua = { 'stylua' },
      json = { 'prettierd', 'prettier', stop_after_first = true },
      jsonc = { 'prettierd', 'prettier', stop_after_first = true },
      typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
      typescript = { 'prettierd', 'prettier', stop_after_first = true },
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
    },
  })
end

return M
