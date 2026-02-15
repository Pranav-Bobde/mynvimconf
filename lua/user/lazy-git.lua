local M = {
  "kdheepak/lazygit.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim"
  },
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  keys = {
    { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
  }
}

function M.config()
  vim.g.lazygit_floating_window_scaling_factor = 1 -- scaling factor for floating window
  vim.g.lazygit_use_custom_config_file_path = 1
  vim.g.lazygit_config_file_path = vim.fn.stdpath("config") .. "/lazygit/config.yml"
end

return M
