local M = {
  "xiyaowong/transparent.nvim",
}

function M.config()
  -- The plugin's default group list is what we want cleared.
  require("transparent").setup({})
end

return M
