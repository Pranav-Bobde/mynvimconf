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
  })

  vim.cmd.colorscheme("catppuccin-mocha")
  vim.cmd [[
    hi @tag.attribute gui=NONE
    hi @tag.attribute.tsx gui=NONE
    hi @keyword.conditional.python gui=NONE
    hi @comment.python gui=NONE
    hi Conditional gui=NONE
    hi @module gui=NONE
  ]]
end

return M
