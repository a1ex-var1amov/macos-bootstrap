-- Shared highlight setter for custom (non-catppuccin) themes.
-- Installed to ~/.config/nvim/lua/theme_base.lua by install.sh.
-- Usage: require('theme_base').apply(colors)

local M = {}

function M.apply(c)
  local hl = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

  vim.o.background = c.dark and "dark" or "light"
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
  vim.g.colors_name = c.name or "custom"

  -- ── Base UI ──────────────────────────────────────────────────────────────
  hl("Normal",          { fg = c.text,    bg = c.bg })
  hl("NormalNC",        { fg = c.subtle,  bg = c.bg })
  hl("NormalFloat",     { fg = c.text,    bg = c.bg_raised })
  hl("FloatBorder",     { fg = c.border,  bg = c.bg_raised })
  hl("FloatTitle",      { fg = c.bright,  bg = c.bg_raised, bold = true })

  -- ── Cursor & line ─────────────────────────────────────────────────────────
  hl("Cursor",          { fg = c.bg,      bg = c.accent })
  hl("CursorLine",      { bg = c.bg_raised })
  hl("CursorLineNr",    { fg = c.orange,  bg = c.bg_raised, bold = true })
  hl("LineNr",          { fg = c.muted })
  hl("LineNrAbove",     { fg = c.muted })
  hl("LineNrBelow",     { fg = c.muted })
  hl("ColorColumn",     { bg = c.bg_raised })
  hl("CursorColumn",    { bg = c.bg_raised })

  -- ── Selection & search ───────────────────────────────────────────────────
  hl("Visual",          { bg = c.surface })
  hl("VisualNOS",       { bg = c.surface })
  hl("Search",          { fg = c.bg,      bg = c.yellow })
  hl("CurSearch",       { fg = c.bg,      bg = c.orange, bold = true })
  hl("IncSearch",       { fg = c.bg,      bg = c.orange })
  hl("Substitute",      { fg = c.bg,      bg = c.red })
  hl("MatchParen",      { fg = c.orange,  bold = true, underline = true })

  -- ── Folds & signs ────────────────────────────────────────────────────────
  hl("FoldColumn",      { fg = c.muted,   bg = c.bg })
  hl("Folded",          { fg = c.subtle,  bg = c.bg_raised })
  hl("SignColumn",      { fg = c.muted,   bg = c.bg })
  hl("Conceal",         { fg = c.muted })

  -- ── Status & tabs ────────────────────────────────────────────────────────
  hl("StatusLine",      { fg = c.bright,  bg = c.accent })
  hl("StatusLineNC",    { fg = c.muted,   bg = c.bg_raised })
  hl("TabLine",         { fg = c.muted,   bg = c.bg_raised })
  hl("TabLineFill",     { bg = c.bg_raised })
  hl("TabLineSel",      { fg = c.bright,  bg = c.accent, bold = true })

  -- ── Splits & borders ─────────────────────────────────────────────────────
  hl("VertSplit",       { fg = c.border })
  hl("WinSeparator",    { fg = c.border })

  -- ── Non-text chars ───────────────────────────────────────────────────────
  hl("NonText",         { fg = c.border })
  hl("EndOfBuffer",     { fg = c.border })
  hl("Whitespace",      { fg = c.border })
  hl("SpecialKey",      { fg = c.muted })

  -- ── Popup menu ───────────────────────────────────────────────────────────
  hl("Pmenu",           { fg = c.text,    bg = c.bg_raised })
  hl("PmenuSel",        { fg = c.bright,  bg = c.surface, bold = true })
  hl("PmenuSbar",       { bg = c.bg_raised })
  hl("PmenuThumb",      { bg = c.overlay })
  hl("PmenuBorder",     { fg = c.border,  bg = c.bg_raised })

  -- ── Messages ─────────────────────────────────────────────────────────────
  hl("ModeMsg",         { fg = c.green,   bold = true })
  hl("MsgArea",         { fg = c.text })
  hl("MoreMsg",         { fg = c.blue })
  hl("Question",        { fg = c.blue })
  hl("ErrorMsg",        { fg = c.red,     bold = true })
  hl("WarningMsg",      { fg = c.orange })
  hl("Title",           { fg = c.bright,  bold = true })
  hl("Directory",       { fg = c.blue })
  hl("WildMenu",        { fg = c.bg,      bg = c.blue })

  -- ── Spelling ─────────────────────────────────────────────────────────────
  hl("SpellBad",        { sp = c.red,     undercurl = true })
  hl("SpellCap",        { sp = c.orange,  undercurl = true })
  hl("SpellLocal",      { sp = c.yellow,  undercurl = true })
  hl("SpellRare",       { sp = c.purple,  undercurl = true })

  -- ── Classic syntax groups ─────────────────────────────────────────────────
  hl("Comment",         { fg = c.comment, italic = true })
  hl("Constant",        { fg = c.orange })
  hl("String",          { fg = c.green })
  hl("Character",       { fg = c.green })
  hl("Number",          { fg = c.orange })
  hl("Boolean",         { fg = c.orange })
  hl("Float",           { fg = c.orange })
  hl("Identifier",      { fg = c.text })
  hl("Function",        { fg = c.blue })
  hl("Statement",       { fg = c.purple })
  hl("Conditional",     { fg = c.purple })
  hl("Repeat",          { fg = c.purple })
  hl("Label",           { fg = c.purple })
  hl("Operator",        { fg = c.rose })
  hl("Keyword",         { fg = c.purple })
  hl("Exception",       { fg = c.red })
  hl("PreProc",         { fg = c.teal })
  hl("Include",         { fg = c.teal })
  hl("Define",          { fg = c.teal })
  hl("Macro",           { fg = c.teal })
  hl("PreCondit",       { fg = c.teal })
  hl("Type",            { fg = c.teal })
  hl("StorageClass",    { fg = c.teal })
  hl("Structure",       { fg = c.teal })
  hl("Typedef",         { fg = c.teal })
  hl("Special",         { fg = c.rose })
  hl("SpecialChar",     { fg = c.rose })
  hl("Tag",             { fg = c.rose })
  hl("Delimiter",       { fg = c.subtle })
  hl("SpecialComment",  { fg = c.comment, bold = true })
  hl("Debug",           { fg = c.rose })
  hl("Underlined",      { underline = true })
  hl("Error",           { fg = c.red })
  hl("Todo",            { fg = c.bg,      bg = c.yellow, bold = true })

  -- ── Treesitter ────────────────────────────────────────────────────────────
  hl("@comment",                { link = "Comment" })
  hl("@comment.documentation",  { fg = c.comment })
  hl("@string",                 { link = "String" })
  hl("@string.escape",          { fg = c.rose })
  hl("@string.special",         { fg = c.rose })
  hl("@number",                 { link = "Number" })
  hl("@number.float",           { link = "Float" })
  hl("@boolean",                { link = "Boolean" })
  hl("@keyword",                { fg = c.purple })
  hl("@keyword.function",       { fg = c.purple })
  hl("@keyword.return",         { fg = c.purple })
  hl("@keyword.conditional",    { fg = c.purple })
  hl("@keyword.repeat",         { fg = c.purple })
  hl("@keyword.operator",       { fg = c.purple })
  hl("@keyword.import",         { fg = c.teal })
  hl("@keyword.exception",      { fg = c.red })
  hl("@function",               { fg = c.blue })
  hl("@function.call",          { fg = c.blue })
  hl("@function.builtin",       { fg = c.blue })
  hl("@function.macro",         { fg = c.teal })
  hl("@function.method",        { fg = c.blue })
  hl("@function.method.call",   { fg = c.blue })
  hl("@constructor",            { fg = c.teal })
  hl("@variable",               { fg = c.text })
  hl("@variable.builtin",       { fg = c.rose })
  hl("@variable.member",        { fg = c.text })
  hl("@variable.parameter",     { fg = c.text,   italic = true })
  hl("@type",                   { fg = c.teal })
  hl("@type.builtin",           { fg = c.teal })
  hl("@type.definition",        { fg = c.teal })
  hl("@namespace",              { fg = c.text })
  hl("@module",                 { fg = c.text })
  hl("@attribute",              { fg = c.rose })
  hl("@annotation",             { fg = c.rose })
  hl("@operator",               { fg = c.rose })
  hl("@punctuation.bracket",    { fg = c.subtle })
  hl("@punctuation.delimiter",  { fg = c.subtle })
  hl("@punctuation.special",    { fg = c.rose })
  hl("@constant",               { fg = c.orange })
  hl("@constant.builtin",       { fg = c.orange })
  hl("@constant.macro",         { fg = c.teal })
  hl("@label",                  { fg = c.blue })
  hl("@tag",                    { fg = c.rose })
  hl("@tag.attribute",          { fg = c.orange })
  hl("@tag.delimiter",          { fg = c.subtle })

  -- ── LSP Diagnostics ──────────────────────────────────────────────────────
  hl("DiagnosticError",            { fg = c.red })
  hl("DiagnosticWarn",             { fg = c.orange })
  hl("DiagnosticInfo",             { fg = c.blue })
  hl("DiagnosticHint",             { fg = c.teal })
  hl("DiagnosticOk",               { fg = c.green })
  hl("DiagnosticUnnecessary",      { fg = c.muted,   italic = true })
  hl("DiagnosticUnderlineError",   { sp = c.red,     undercurl = true })
  hl("DiagnosticUnderlineWarn",    { sp = c.orange,  undercurl = true })
  hl("DiagnosticUnderlineInfo",    { sp = c.blue,    undercurl = true })
  hl("DiagnosticUnderlineHint",    { sp = c.teal,    undercurl = true })
  hl("DiagnosticVirtualTextError", { fg = c.red,     bg = c.bg_raised, italic = true })
  hl("DiagnosticVirtualTextWarn",  { fg = c.orange,  bg = c.bg_raised, italic = true })
  hl("DiagnosticVirtualTextInfo",  { fg = c.blue,    bg = c.bg_raised, italic = true })
  hl("DiagnosticVirtualTextHint",  { fg = c.teal,    bg = c.bg_raised, italic = true })
  hl("DiagnosticSignError",        { fg = c.red })
  hl("DiagnosticSignWarn",         { fg = c.orange })
  hl("DiagnosticSignInfo",         { fg = c.blue })
  hl("DiagnosticSignHint",         { fg = c.teal })

  -- ── Diff ─────────────────────────────────────────────────────────────────
  hl("DiffAdd",         { fg = c.green,   bg = c.bg_raised })
  hl("DiffChange",      { fg = c.orange,  bg = c.bg_raised })
  hl("DiffDelete",      { fg = c.red,     bg = c.bg_raised })
  hl("DiffText",        { fg = c.orange,  bg = c.surface, bold = true })
  hl("diffAdded",       { fg = c.green })
  hl("diffRemoved",     { fg = c.red })
  hl("diffChanged",     { fg = c.orange })
  hl("diffOldFile",     { fg = c.subtle })
  hl("diffNewFile",     { fg = c.text })
  hl("diffFile",        { fg = c.blue })
  hl("diffLine",        { fg = c.purple })
  hl("diffIndexLine",   { fg = c.teal })

  -- ── GitSigns (if installed) ───────────────────────────────────────────────
  hl("GitSignsAdd",       { fg = c.green })
  hl("GitSignsChange",    { fg = c.orange })
  hl("GitSignsDelete",    { fg = c.red })
  hl("GitSignsUntracked", { fg = c.muted })

  -- ── indent-blankline (if installed) ──────────────────────────────────────
  hl("IblIndent",  { fg = c.border })
  hl("IblScope",   { fg = c.overlay })

  -- ── Telescope (if installed) ──────────────────────────────────────────────
  hl("TelescopeNormal",         { fg = c.text,    bg = c.bg_raised })
  hl("TelescopeBorder",         { fg = c.border,  bg = c.bg_raised })
  hl("TelescopePromptNormal",   { fg = c.text,    bg = c.surface })
  hl("TelescopePromptBorder",   { fg = c.surface, bg = c.surface })
  hl("TelescopePromptTitle",    { fg = c.bg,      bg = c.blue,  bold = true })
  hl("TelescopeResultsTitle",   { fg = c.border,  bg = c.bg_raised })
  hl("TelescopePreviewTitle",   { fg = c.bg,      bg = c.teal,  bold = true })
  hl("TelescopeSelection",      { fg = c.bright,  bg = c.surface })
  hl("TelescopeMatching",       { fg = c.orange,  bold = true })

  -- ── Which-key (if installed) ──────────────────────────────────────────────
  hl("WhichKey",        { fg = c.blue })
  hl("WhichKeyGroup",   { fg = c.purple })
  hl("WhichKeyDesc",    { fg = c.text })
  hl("WhichKeyBorder",  { fg = c.border })
  hl("WhichKeyNormal",  { bg = c.bg_raised })
end

return M
