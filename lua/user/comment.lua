local M = {
  "terrortylor/nvim-comment",
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring"
  }
}

function M.config()
  require('ts_context_commentstring').setup {
    enable_autocmd = false,
  }

  require("nvim_comment").setup({
    line_mapping = "<leader>cl",
    operator_mapping = "<leader>c",
    comment_chunk_text_object = "ic",
    hook = function()
      require('ts_context_commentstring').update_commentstring()
    end,
  })
end

return M
