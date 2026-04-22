-- Dracula — delegates to the Mofiqul/dracula.nvim plugin (loaded via lazy.nvim)
local M = {}
M.setup = function()
  vim.cmd.colorscheme("dracula")
end
return M
