-- Solarized Light — delegates to the solarized.nvim plugin
local M = {}
M.setup = function()
  vim.o.background = "light"
  local ok, sol = pcall(require, "solarized")
  if ok then sol.setup({ variant = "spring" }) end
  vim.cmd.colorscheme("solarized")
end
return M
