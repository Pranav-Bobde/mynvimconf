local M = {
  "mistricky/codesnap.nvim",
  build = "make build_generator",
  keys = {
    { "<leader>cc", "<cmd>CodeSnap<cr>",     mode = "x", desc = "Save selected code snapshot into clipboard" },
    { "<leader>cf", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Pictures/ScreenShots" },
  },
  opts = {
    save_path = "~/Pictures/ScreenShots",
    has_breadcrumbs = true,
    bg_theme = "grape",
  },
}

return M
