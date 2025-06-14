local M = {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "folke/trouble.nvim",
    "nvim-telescope/telescope.nvim"
  }
}

function M.config()
  require("chatgpt").setup({
    api_host_cmd = 'echo -n https://api.groq.com/openai/',
    api_base_cmd = 'echo -n https://api.groq.com',
    openai_params = {
      model = 'llama-3.1-8b-instant'
    },
    openai_edit_params = {
      model = 'llama-3.1-8b-instant'
    }
  })
end

return M
