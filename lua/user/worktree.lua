local M = {
  "ThePrimeagen/git-worktree.nvim"
}

function M.config()
  map("n", "<leader>vw", ":lua require('telescope').extensions.git_worktree.git_worktrees()<CR>")
  map("n", "<leader>cw", ":lua require('telescope').extensions.git_worktree.create_git_worktree()<CR>")
end

return M
