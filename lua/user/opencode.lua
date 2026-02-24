local M = {
  "nickjvandyke/opencode.nvim",
  version = "*",
  keys = {
    {
      "<leader>oa",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "Ask opencode",
    },
    {
      "<leader>oo",
      function()
        require("opencode").select()
      end,
      mode = { "n", "x" },
      desc = "Opencode actions",
    },
    {
      "<leader>ot",
      function()
        require("opencode").toggle()
      end,
      mode = { "n", "t" },
      desc = "Toggle opencode",
    },
    {
      "<leader>oc",
      function()
        return require("opencode").operator("@this ")
      end,
      mode = "x",
      expr = true,
      desc = "Send selection to opencode",
    },
  },
}

function M.config()
  vim.g.opencode_opts = {
    provider = {
      enabled = "terminal",
    },
  }
  vim.o.autoread = true

  local opencode_group = vim.api.nvim_create_augroup("opencode_terminal_keys", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = opencode_group,
    pattern = "opencode_terminal",
    callback = function(args)
      local opts = { buffer = args.buf, silent = true }
      vim.keymap.set({ "n", "t" }, "<C-u>", function()
        require("opencode").command("session.half.page.up")
      end, opts)
      vim.keymap.set({ "n", "t" }, "<C-d>", function()
        require("opencode").command("session.half.page.down")
      end, opts)
    end,
  })
end

return M
