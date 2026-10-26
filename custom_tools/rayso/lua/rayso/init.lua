local M = {}

local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
local cli = root .. "/cli/snap.ts"

function M.snap()
  local anchor = vim.fn.getpos("v")[2]
  local cursor = vim.fn.getpos(".")[2]
  local first = math.min(anchor, cursor)
  local last = math.max(anchor, cursor)
  local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
  local code = table.concat(lines, "\n")
  local filetype = vim.bo.filetype

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  local ok, err = pcall(vim.system, { "bun", cli, "--lang", filetype }, { stdin = code }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        vim.notify("Snapshot copied to clipboard")
      else
        local message = vim.trim(result.stderr or "Snapshot failed"):gsub("[\r\n]+", " ")
        if message == "" then message = "Snapshot failed" end
        vim.notify(message, vim.log.levels.ERROR)
      end
    end)
  end)
  if not ok then
    local message = tostring(err):gsub("[\r\n]+", " ")
    vim.schedule(function()
      vim.notify(message, vim.log.levels.ERROR)
    end)
  end
end

return M
