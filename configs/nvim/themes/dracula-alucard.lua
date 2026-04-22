-- Dracula Alucard (light) — uses theme_base with official Alucard palette
local M = {}
M.setup = function()
  require("theme_base").apply({
    name     = "dracula-alucard",
    dark     = false,
    bg       = "#fffbeb",
    bg_raised = "#e8e3d8",
    surface  = "#cfcfde",
    overlay  = "#b8b3c8",
    border   = "#cfcfde",
    text     = "#1f1f1f",
    subtle   = "#6c664b",
    muted    = "#9e9a8e",
    bright   = "#1f1f1f",
    comment  = "#6c664b",
    accent   = "#644ac9",
    red      = "#cb3a2a",
    orange   = "#a34d14",
    yellow   = "#846e15",
    green    = "#14710a",
    teal     = "#036a96",
    blue     = "#644ac9",
    purple   = "#644ac9",
    pink     = "#a3144d",
    cyan     = "#036a96",
    rose     = "#a3144d",
  })
end
return M
