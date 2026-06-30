-- Nord Light — uses theme_base with community Snow-Storm light palette
local M = {}
M.setup = function()
  require("theme_base").apply({
    name      = "nord-light",
    dark      = false,
    bg        = "#eceff4",
    bg_raised = "#e5e9f0",
    surface   = "#d8dee9",
    overlay   = "#c8d0db",
    border    = "#d8dee9",
    text      = "#2e3440",
    subtle    = "#3b4252",
    muted     = "#4c566a",
    bright    = "#2e3440",
    comment   = "#4c566a",
    accent    = "#5e81ac",
    red       = "#bf616a",
    orange    = "#d08770",
    yellow    = "#b58900",
    green     = "#a3be8c",
    teal      = "#8fbcbb",
    blue      = "#5e81ac",
    purple    = "#b48ead",
    pink      = "#b48ead",
    cyan      = "#88c0d0",
    rose      = "#bf616a",
  })
end
return M
