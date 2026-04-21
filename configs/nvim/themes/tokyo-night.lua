-- Tokyo Night — delegates to the tokyonight plugin (loaded via lazy.nvim)
local M = {}
M.setup = function()
  vim.cmd.colorscheme("tokyonight-night")
end
return M
