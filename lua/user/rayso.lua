return {
  dir = vim.fn.stdpath("config") .. "/custom_tools/rayso",
  name = "rayso",
  keys = {
    { "<leader>cc", function() require("rayso").snap() end, mode = "x", desc = "Snapshot selection (ray.so Vercel) into clipboard" },
  },
}
