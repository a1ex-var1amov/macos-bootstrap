-- GitHub Light — delegates to the github-nvim-theme plugin
local M = {}
M.setup = function()
  vim.o.background = "light"
  vim.cmd.colorscheme("github_light_default")
end
return M
