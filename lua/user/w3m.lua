local M = {
  "yuratomo/w3m.vim",
  event = "VeryLazy",
  cond = function()
    return vim.fn.executable("w3m") == 1
  end,
}

return M
