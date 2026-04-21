-- Catppuccin Macchiato — delegates to the catppuccin plugin (loaded via lazy.nvim)
local M = {}
M.setup = function()
  require("catppuccin").setup({ flavour = "macchiato", integrations = { treesitter = true } })
  vim.cmd.colorscheme("catppuccin")
end
return M
