-- Nord — delegates to the nord.nvim plugin
local M = {}
M.setup = function()
  vim.o.background = "dark"
  vim.cmd.colorscheme("nord")
end
return M
