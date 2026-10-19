local M = {
  "windwp/nvim-ts-autotag"
}

function M.config()
  require('nvim-ts-autotag').setup({
    -- enable_close and enable_rename are on by default.
    opts = {
      enable_close_on_slash = true -- Auto close on trailing </ (off by default)
    },
    -- Also override individual filetype configs, these take priority.
    -- Empty by default, useful if one of the "opts" global settings
    -- doesn't work well in a specific filetype
    per_filetype = {
      ["html"] = {
        enable_close = false
      }
    }
  })
end

return M
