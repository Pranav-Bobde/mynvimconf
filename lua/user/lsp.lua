-- https://github.com/williamboman/mason-lspconfig.nvim
local M = {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "williamboman/mason-lspconfig.nvim",
    { "antosha417/nvim-lsp-file-operations", config = true },
  }
}

function M.config()
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

  require("mason-lspconfig").setup({
    ensure_installed = servers,
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

      opts.desc = "Smart rename"
      keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

      opts.desc = "Show buffer diagnostics"
      keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

      opts.desc = "Show line diagnostics"
      keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

      opts.desc = "Go to previous diagnostic"
      keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts) -- jump to previous diagnostic in buffer

      opts.desc = "Go to next diagnostic"
      keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts) -- jump to next diagnostic in buffer

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

  -- vim.lsp.config merges, so the per-server calls below keep these capabilities.
  for _, server in ipairs(servers) do
    vim.lsp.config(server, {
      capabilities = capabilities,
    })
  end

  vim.lsp.config("vtsls", {
    settings = {
      vtsls = {
        autoUseWorkspaceTsdk = true,
      },
    },
  })

  -- TypeScript 7+ is the native Go compiler and ships no tsserver, so vtsls can't load it.
  -- Projects on it get its own language server (`tsc --lsp`, via the tsgo config) instead.
  local function native_ts_bin(root)
    if not root then return nil end
    local tsgo = root .. "/node_modules/.bin/tsgo"
    if vim.fn.executable(tsgo) == 1 then return tsgo end
    local ok, pkg = pcall(vim.fn.readfile, root .. "/node_modules/typescript/package.json")
    if not ok then return nil end
    local version = vim.json.decode(table.concat(pkg, "\n")).version or ""
    if (tonumber(version:match("^(%d+)")) or 0) >= 7 then
      return root .. "/node_modules/.bin/tsc"
    end
  end

  local function root_if(server, want_native)
    local root_dir = vim.lsp.config[server].root_dir
    return function(bufnr, on_dir)
      root_dir(bufnr, function(root)
        if (native_ts_bin(root) ~= nil) == want_native then on_dir(root) end
      end)
    end
  end

  vim.lsp.config("vtsls", { root_dir = root_if("vtsls", false) })

  vim.lsp.config("tsgo", {
    capabilities = capabilities,
    cmd = function(dispatchers, config)
      return vim.lsp.rpc.start({ native_ts_bin(config.root_dir), "--lsp", "--stdio" }, dispatchers)
    end,
    root_dir = root_if("tsgo", true),
  })

  vim.lsp.config("graphql", {
    filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
  })

  vim.lsp.config("emmet_ls", {
    filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
  })

  -- pyright only reads `python` from PATH; point it at the project's .venv (uv/venv projects)
  vim.lsp.config("pyright", {
    before_init = function(_, config)
      local venv_python = config.root_dir and (config.root_dir .. "/.venv/bin/python")
      if venv_python and vim.uv.fs_stat(venv_python) then
        -- mutate in place: the client already holds a reference to this settings table
        config.settings.python = config.settings.python or {}
        config.settings.python.pythonPath = venv_python
      end
    end,
  })

  vim.lsp.config("lua_ls", {
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
  -- not in `servers`: Mason doesn't install it, it runs from each project's node_modules
  vim.lsp.enable("tsgo")
end

return M
