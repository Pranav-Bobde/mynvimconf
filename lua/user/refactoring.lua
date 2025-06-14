local M = {
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
}

function M.config()
  require("refactoring").setup({})
  vim.keymap.set(
    { "n", "x" },
    "<leader>r",
    function() require('refactoring').select_refactor() end
  )
end

return M
