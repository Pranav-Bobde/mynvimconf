-- Quit nvim and hand the current dir to the parent shell.
-- The `vh` zsh function sets NVIM_CWD_FILE and cds into whatever we write there.
local M = {}

local function current_dir()
  local ok, oil = pcall(require, "oil")
  if ok and vim.bo.filetype == "oil" then
    local dir = oil.get_current_dir()
    if dir then
      return dir
    end
  end
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and vim.bo.buftype == "" then
    return vim.fn.fnamemodify(name, ":p:h")
  end
  return vim.fn.getcwd()
end

-- Written on VimLeavePre so a cancelled "save changes?" prompt doesn't leave a stale dir.
local target

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local file = vim.env.NVIM_CWD_FILE
    if target and file and file ~= "" then
      vim.fn.writefile({ target }, file)
    end
  end,
})

function M.quit()
  target = current_dir()
  pcall(vim.cmd, "confirm qa")
  target = nil
end

vim.api.nvim_create_user_command("Qcd", M.quit, { desc = "Quit and cd shell to current dir" })

return M
