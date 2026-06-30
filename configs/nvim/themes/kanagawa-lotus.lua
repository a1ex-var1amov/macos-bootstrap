-- Kanagawa Lotus — delegates to the kanagawa.nvim plugin
local M = {}
M.setup = function()
  vim.o.background = "light"
  local ok, k = pcall(require, "kanagawa")
  if ok then k.setup({ theme = "lotus", background = { dark = "wave", light = "lotus" } }) end
  vim.cmd.colorscheme("kanagawa-lotus")
end
return M
