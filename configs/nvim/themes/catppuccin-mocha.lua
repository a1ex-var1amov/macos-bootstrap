-- Catppuccin Mocha — delegates to the catppuccin plugin (loaded via lazy.nvim)
local M = {}
M.setup = function()
  require("catppuccin").setup({ flavour = "mocha", integrations = { treesitter = true } })
  vim.cmd.colorscheme("catppuccin")
end
return M
