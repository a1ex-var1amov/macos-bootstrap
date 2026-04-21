-- Catppuccin Latte — delegates to the catppuccin plugin (loaded via lazy.nvim)
local M = {}
M.setup = function()
  require("catppuccin").setup({ flavour = "latte", integrations = { treesitter = true } })
  vim.o.background = "light"
  vim.cmd.colorscheme("catppuccin")
end
return M
