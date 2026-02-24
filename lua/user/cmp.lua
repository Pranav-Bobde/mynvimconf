local M = {
  -- Autocompletion
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer",
    "saadparwaiz1/cmp_luasnip",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-path",
    {
      "L3MON4D3/LuaSnip",
      build = (function()
        -- Build Step is needed for regex support in snippets.
        -- This step is not supported in many windows environments.
        -- Remove the below condition to re-enable on windows.
        if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
          return
        end
        return "make install_jsregexp"
      end)(),
      dependencies = {
        -- See the README about individual language/framework/plugin snippets:
        -- https://github.com/rafamadriz/friendly-snippets
        {
          "rafamadriz/friendly-snippets",
          config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
          end,
        },
      },
    },
  },
}

function M.config()
  -- See `:help cmp`
  local cmp = require("cmp")
  local luasnip = require("luasnip")
  luasnip.config.setup({})

  cmp.setup({
    debug = true,
    completion = { completeopt = "menu,menuone,preview,noselect" },
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ["<S-Tab>"] = cmp.mapping.select_prev_item(), -- previous suggestion
      ["<Tab>"] = cmp.mapping.select_next_item(),   -- next suggestion
      ["<C-k>"] = cmp.mapping.scroll_docs(-4),
      ["<C-j>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),  -- show completion suggestions
      ["<C-e>"] = cmp.mapping.abort(),         -- close completion window
      ["<CR>"] = cmp.mapping.confirm({ select = false }),
    }),
    sources = {
      { name = "codeium" },
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "buffer" },
      { name = "path" },
    },
  })
end

return M
