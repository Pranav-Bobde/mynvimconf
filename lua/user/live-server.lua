return {
  "barrett-ruth/live-server.nvim",
  build = "pnpm add -g live-server",
  cmd = { "LiveServerStart", "LiveServerStop" },
  -- Defaults are fine; options would go in vim.g.live_server (setup() is deprecated).
}
