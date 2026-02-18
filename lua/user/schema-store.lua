-- https://github.com/b0o/SchemaStore.nvim
local M = {
  "b0o/schemastore.nvim"
}

function M.config()
  vim.lsp.config("yamlls", {
    settings = {
      yaml = {
        schemaStore = {
          -- You must disable built-in schemaStore support if you want to use
          -- this plugin and its advanced options like `ignore`.
          enable = false,
          -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
          url = "",
        },
        schemas = require("schemastore").yaml.schemas(),
      },
    },
  })
end

return M
