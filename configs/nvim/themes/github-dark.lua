-- GitHub Dark — delegates to the github-nvim-theme plugin
local M = {}
M.setup = function()
  vim.o.background = "dark"
  vim.cmd.colorscheme("github_dark_default")
end
return M
