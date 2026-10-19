local M = {
  "nvim-treesitter/nvim-treesitter",
  -- This config uses the master-branch API (nvim-treesitter.configs);
  -- main is a rewrite without it, so an update there would break setup.
  branch = "master",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
}

local opts = {
      ensure_installed = { 'bash', 'c', 'html', 'css', 'lua', 'luadoc', 'markdown', 'vim', 'vimdoc', 'python', 'typescript', 'javascript', 'tsx' },
      -- Autoinstall languages that are not installed
      auto_install = true,
      -- Avoid parser installs during git commit editor sessions.
      ignore_install = { 'gitcommit' },
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    }

function M.config()
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

      -- Prefer git instead of curl in order to improve connectivity in some environments
      require('nvim-treesitter.install').prefer_git = true
      ---@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup(opts)

      -- Avoid nvim-treesitter's markdown `set-lang-from-info-string!` directive,
      -- which crashes Neovim 0.12 while render-markdown parses fenced code blocks.
      vim.treesitter.query.set('markdown', 'injections', [[
(fenced_code_block
  (info_string
    (language) @injection.language)
  (code_fence_content) @injection.content)

((html_block) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined)
  (#set! injection.include-children))

((minus_metadata) @injection.content
  (#set! injection.language "yaml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

((plus_metadata) @injection.content
  (#set! injection.language "toml")
  (#offset! @injection.content 1 0 -1 0)
  (#set! injection.include-children))

([
  (inline)
  (pipe_table_cell)
] @injection.content
  (#set! injection.language "markdown_inline"))
      ]])
end

return M
