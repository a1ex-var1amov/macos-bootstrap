-- Everforest Dark — delegates to the everforest plugin
local M = {}
M.setup = function()
  vim.o.background = "dark"
  vim.g.everforest_background = "medium"
  vim.g.everforest_better_performance = 1
  vim.cmd.colorscheme("everforest")
end
return M
