-- Tokyo Night Day — delegates to the tokyonight plugin (light)
local M = {}
M.setup = function()
  vim.o.background = "light"
  vim.cmd.colorscheme("tokyonight-day")
end
return M
