-- https://github.com/williamboman/mason-lspconfig.nvim
local M = {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "williamboman/mason-lspconfig.nvim",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim",                   opts = {} }
  }
}

function M.config()
  local mason_lspconfig = require("mason-lspconfig")

  mason_lspconfig.setup({
    ensure_installed = { "vtsls", "html", "cssls", "tailwindcss", "lua_ls", "graphql", "emmet_ls", "yamlls", "jsonls", "prismals", "pyright" },
    -- ts_ls is still installed from before the vtsls switch; keep it from
    -- auto-enabling alongside vtsls (duplicate diagnostics/completions)
    automatic_enable = { exclude = { "ts_ls" } },
  })

  local cmp_nvim_lsp = require("cmp_nvim_lsp")
  local keymap = vim.keymap

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
      -- Buffer local mappings.
      -- See `:help vim.lsp.*` for documentation on any of the below functions
      local opts = {
        buffer = ev.buf,
        silent = true
      }

      -- set keybinds
      opts.desc = "Show LSP references"
      keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

      opts.desc = "Go to declaration"
      keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

      opts.desc = "Show LSP definitions"
      keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

      opts.desc = "Show LSP implementations"
      keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

      opts.desc = "Show LSP type definitions"
      keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

      -- opts.desc = "See available code actions"
      -- keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

      opts.desc = "Smart rename"
      keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

      opts.desc = "Show buffer diagnostics"
      keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

      opts.desc = "Show line diagnostics"
      keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

      opts.desc = "Go to previous diagnostic"
      keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

      opts.desc = "Go to next diagnostic"
      keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

      opts.desc = "Show documentation for what is under cursor"
      keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

      opts.desc = "Restart LSP"
      keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
    end
  })

  -- used to enable autocompletion (assign to every lsp server config)
  local capabilities = cmp_nvim_lsp.default_capabilities()

  local signs = {
    Error = " ",
    Warn = " ",
    Hint = "󰠠 ",
    Info = " "
  }

  vim.diagnostic.config({
    virtual_text = {
      severity = { min = vim.diagnostic.severity.WARN },
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = signs.Error,
        [vim.diagnostic.severity.WARN] = signs.Warn,
        [vim.diagnostic.severity.INFO] = signs.Info,
        [vim.diagnostic.severity.HINT] = signs.Hint,
      },
    },
    underline = {
      severity = { min = vim.diagnostic.severity.WARN },
    },
    update_in_insert = false,
  })

  local servers = {
    "vtsls",
    "html",
    "cssls",
    "tailwindcss",
    "lua_ls",
    "graphql",
    "emmet_ls",
    "yamlls",
    "jsonls",
    "prismals",
    "pyright",
  }

  for _, server in ipairs(servers) do
    vim.lsp.config(server, {
      capabilities = capabilities,
    })
  end

  vim.lsp.config("vtsls", {
    capabilities = capabilities,
    settings = {
      vtsls = {
        autoUseWorkspaceTsdk = true,
      },
    },
  })

  vim.lsp.config("graphql", {
    capabilities = capabilities,
    filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
  })

  vim.lsp.config("emmet_ls", {
    capabilities = capabilities,
    filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
  })

  vim.lsp.config("lua_ls", {
    capabilities = capabilities,
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
        completion = {
          callSnippet = "Replace",
        },
      },
    },
  })

  vim.lsp.enable(servers)
end

return M
