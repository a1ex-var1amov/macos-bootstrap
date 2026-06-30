-- Kanagawa Wave — delegates to the kanagawa.nvim plugin
local M = {}
M.setup = function()
  vim.o.background = "dark"
  local ok, k = pcall(require, "kanagawa")
  if ok then k.setup({ theme = "wave", background = { dark = "wave", light = "lotus" } }) end
  vim.cmd.colorscheme("kanagawa-wave")
end
return M
