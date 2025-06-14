local M = {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true },
  },
}

function M.config()
  require("telescope").load_extension("git_worktree")

  local actions = require("telescope.actions")
  require("telescope").setup({
    pickers = {
      find_files = {
        hidden = true
      }
    },
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },
    },
    defaults = {
      file_ignore_patterns = {
        "node_modules",
        ".git",
        ".svn",
        ".hg",
        ".tar",
        ".zip",
        ".gz",
        ".bz2",
        ".xz",
        ".bak",
        ".swp",
      },
      mappings = {
        i = {
          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,
          ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        },
        n = {
          -- Other mappings can go here
          ["<C-k>"] = actions.preview_scrolling_up,
          ["<C-j>"] = actions.preview_scrolling_down,
        },
      },
    },
  })
  require("telescope").load_extension("fzf")

  local builtin = require("telescope.builtin")
  vim.keymap.set("n", "<leader>fh", builtin.help_tags, { noremap = true, silent = true, desc = "[S]earch [H]elp" })
  vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
  vim.keymap.set("n", "<leader>fo", builtin.find_files, { noremap = true, silent = true, desc = "[S]earch [F]iles" })
  vim.keymap.set(
    "n",
    "<leader>bo",
    builtin.buffers,
    { noremap = true, silent = true, desc = "[ ] Find existing buffers" }
  )
  vim.keymap.set("n", "<leader>fb", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
  vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
  vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
  vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
  vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[S]earch [R]esume" })
  vim.keymap.set("n", "<leader>f.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })

  -- Slightly advanced example of overriding default behavior and theme
  -- vim.keymap.set("n", "<leader>/", function()
  --   -- You can pass additional configuration to Telescope to change the theme, layout, etc.
  --   builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
  --     winblend = 10,
  --     previewer = false,
  --   }))
  -- end, { desc = "[/] Fuzzily search in current buffer" })

  -- It's also possible to pass additional configuration options.
  --  See `:help telescope.builtin.live_grep()` for information about particular keys
  vim.keymap.set("n", "<leader>s/", function()
    builtin.live_grep({
      grep_open_files = true,
      prompt_title = "Live Grep in Open Files",
    })
  end, { desc = "[S]earch [/] in Open Files" })

  -- Shortcut for searching your Neovim configuration files
  vim.keymap.set("n", "<leader>sn", function()
    builtin.find_files({ cwd = vim.fn.stdpath("config") })
  end, { desc = "[S]earch [N]eovim files" })
end

return M
