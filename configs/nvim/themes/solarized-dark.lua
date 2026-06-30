-- Solarized Dark — delegates to the solarized.nvim plugin
local M = {}
M.setup = function()
  local ok, sol = pcall(require, "solarized")
  if ok then sol.setup({ variant = "winter" }) end
  vim.cmd.colorscheme("solarized")
end
return M
