-- https://github.com/voldikss/vim-floaterm?tab=readme-ov-file

local M = {
  "voldikss/vim-floaterm",
}

function M.config()
  map("n", "<leader>ff", ":FloatermToggle --height=0.9 --width=0.9 --wintype=float --name=term --autoclose=2<CR>")
  map("t", "<leader>ff", "<C-\\><C-n>:FloatermToggle<CR>")
end

return M
