-- Catppuccin Frappé — delegates to the catppuccin plugin (loaded via lazy.nvim)
local M = {}
M.setup = function()
  vim.cmd.colorscheme("catppuccin")
end
return M
