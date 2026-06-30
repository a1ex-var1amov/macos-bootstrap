-- Gruvbox Light — delegates to the gruvbox.nvim plugin
local M = {}
M.setup = function()
  vim.o.background = "light"
  local ok, g = pcall(require, "gruvbox")
  if ok then g.setup({ contrast = "" }) end
  vim.cmd.colorscheme("gruvbox")
end
return M
