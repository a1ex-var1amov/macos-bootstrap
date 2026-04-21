-- Rosé Pine Dawn — delegates to the rose-pine plugin (light)
local M = {}
M.setup = function()
  vim.o.background = "light"
  vim.cmd.colorscheme("rose-pine-dawn")
end
return M
