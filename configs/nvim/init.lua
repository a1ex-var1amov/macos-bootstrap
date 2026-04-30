-- Neovim configuration
-- Location: ~/.config/nvim/init.lua

-- =============================================================================
-- BOOTSTRAP lazy.nvim
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- OPTIONS  (set before plugins so colorscheme priority works)
-- =============================================================================
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Appearance
opt.number         = true
opt.relativenumber = false
opt.cursorline     = true
opt.signcolumn     = "yes"
opt.colorcolumn    = "80"
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.laststatus     = 2
opt.showcmd        = true
opt.showmode       = true
opt.termguicolors  = true
opt.showmatch      = true
opt.wildmode       = "longest:full,full"

-- Indentation
opt.expandtab   = true
opt.tabstop     = 2
opt.shiftwidth  = 2
opt.softtabstop = 2
opt.autoindent  = true
opt.smartindent = true
opt.shiftround  = true

-- Search
opt.incsearch  = true
opt.hlsearch   = true
opt.ignorecase = true
opt.smartcase  = true

-- Files & buffers
opt.encoding     = "utf-8"
opt.fileencoding = "utf-8"
opt.hidden       = true
opt.autoread     = true
opt.backup       = false
opt.writebackup  = false
opt.swapfile     = false
opt.undofile     = true

local undodir = vim.fn.stdpath("data") .. "/undo"
vim.fn.mkdir(undodir, "p")
opt.undodir = undodir

-- Editing
opt.backspace  = "indent,eol,start"
opt.mouse      = "a"
opt.clipboard  = "unnamedplus"   -- system clipboard (macOS: pbcopy/pbpaste)
opt.splitbelow = true
opt.splitright = true
opt.wrap       = true
opt.linebreak  = true

-- Performance
opt.updatetime  = 250
opt.timeoutlen  = 500
opt.ttimeoutlen = 10
opt.lazyredraw  = true

-- =============================================================================
-- PLUGINS
-- =============================================================================
require("lazy").setup({

  -- -------------------------------------------------------------------------
  -- Catppuccin — all flavours (frappe, macchiato, mocha, latte).
  -- active_theme.lua picks the flavour and calls colorscheme.
  -- -------------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,
  },

  -- -------------------------------------------------------------------------
  -- Tokyo Night — supports night / storm / moon / day variants.
  -- active_theme.lua picks the variant via colorscheme("tokyonight-<variant>").
  -- -------------------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    priority = 1000,
  },

  -- -------------------------------------------------------------------------
  -- Rosé Pine — supports main / moon / dawn variants.
  -- active_theme.lua picks the variant via colorscheme("rose-pine[-moon|-dawn]").
  -- -------------------------------------------------------------------------
  {
    "rose-pine/neovim",
    name     = "rose-pine",
    priority = 1000,
  },

  -- -------------------------------------------------------------------------
  -- Dracula — classic dark purple theme.
  -- active_theme.lua calls colorscheme("dracula").
  -- -------------------------------------------------------------------------
  {
    "Mofiqul/dracula.nvim",
    priority = 1000,
  },

  -- -------------------------------------------------------------------------
  -- Treesitter — proper syntax highlighting and indentation
  -- -------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      highlight        = { enable = true },
      indent           = { enable = true },
      ensure_installed = {
        "bash", "dockerfile", "go", "json", "lua",
        "markdown", "python", "toml", "yaml", "vim", "vimdoc",
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- -------------------------------------------------------------------------
  -- Mason — automatic LSP server installer (UI: :Mason)
  -- -------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts  = { ui = { border = "rounded" } },
  },

  -- -------------------------------------------------------------------------
  -- mason-lspconfig — bridges Mason ↔ nvim-lspconfig
  -- -------------------------------------------------------------------------
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "lua_ls",    -- Lua
        "gopls",     -- Go
        "pyright",   -- Python
        "bashls",    -- Bash / Shell
        "yamlls",    -- YAML
        "jsonls",    -- JSON
      },
      automatic_enable = true,
    },
  },

  -- -------------------------------------------------------------------------
  -- nvim-lspconfig — LSP server configs (uses nvim 0.11+ vim.lsp.config API)
  -- -------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local o = { buffer = args.buf, silent = true }
          vim.keymap.set("n", "gd",         vim.lsp.buf.definition,   o)
          vim.keymap.set("n", "gr",         vim.lsp.buf.references,   o)
          vim.keymap.set("n", "gi",         vim.lsp.buf.implementation, o)
          vim.keymap.set("n", "K",          vim.lsp.buf.hover,        o)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,       o)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,  o)
          vim.keymap.set("n", "<leader>d",  vim.diagnostic.open_float, o)
          vim.keymap.set("n", "[d",         vim.diagnostic.goto_prev, o)
          vim.keymap.set("n", "]d",         vim.diagnostic.goto_next, o)
          vim.keymap.set("n", "<leader>f",
            function() vim.lsp.buf.format({ async = true }) end, o)
        end,
      })

      vim.lsp.config("*", { capabilities = capabilities })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime   = { version = "LuaJIT" },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            validate    = true,
            schemaStore = { enable = true, url = "" },
          },
        },
      })

      vim.diagnostic.config({
        virtual_text  = { prefix = "●" },
        severity_sort = true,
        float         = { border = "rounded", source = true },
      })
    end,
  },

  -- -------------------------------------------------------------------------
  -- nvim-cmp — completion engine (LSP + snippets + buffer + path)
  -- -------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]     = cmp.mapping.select_next_item(),
          ["<C-p>"]     = cmp.mapping.select_prev_item(),
          ["<C-d>"]     = cmp.mapping.scroll_docs(4),
          ["<C-u>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  },

}, {
  ui = { border = "rounded" },
})

-- =============================================================================
-- KEY MAPPINGS
-- =============================================================================
local map = vim.keymap.set

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { silent = true })

-- Quick save / quit
map("n", "<leader>w", "<cmd>w<CR>")
map("n", "<leader>q", "<cmd>q<CR>")

-- Window navigation (Ctrl+hjkl)
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Move lines up/down
map("n", "<A-j>", "<cmd>m .+1<CR>==")
map("n", "<A-k>", "<cmd>m .-2<CR>==")
map("v", "<A-j>", ":m '>+1<CR>gv=gv")
map("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Stay in visual mode after indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Buffer navigation
map("n", "<leader>bn", "<cmd>bnext<CR>")
map("n", "<leader>bp", "<cmd>bprevious<CR>")
map("n", "<leader>bd", "<cmd>bdelete<CR>")

-- Toggle line numbers
map("n", "<leader>n", "<cmd>set nu!<CR>")

-- Copy mode (disable numbers + mouse for clean terminal copy/paste)
map("n", "<leader>c", function()
  opt.number = false
  opt.mouse  = ""
  print("Copy mode ON")
end)
map("n", "<leader>C", function()
  opt.number = true
  opt.mouse  = "a"
  print("Copy mode OFF")
end)

-- Quick splits
map("n", "<leader>v", "<cmd>vsplit<CR>")
map("n", "<leader>s", "<cmd>split<CR>")

-- Insert-mode escape shortcuts
map("i", "jk", "<Esc>")
map("i", "jj", "<Esc>")

-- =============================================================================
-- AUTOCOMMANDS
-- =============================================================================
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Filetype-specific indentation (mirrors vimrc)
local ft = augroup("filetypes", { clear = true })
autocmd("FileType", { group = ft, pattern = { "yaml", "json", "sh" },
  command = "setlocal ts=2 sts=2 sw=2 expandtab" })
autocmd("FileType", { group = ft, pattern = { "python" },
  command = "setlocal ts=4 sts=4 sw=4 expandtab" })
autocmd("FileType", { group = ft, pattern = { "go", "make" },
  command = "setlocal ts=4 sts=4 sw=4 noexpandtab" })
autocmd("FileType", { group = ft, pattern = "markdown",
  command = "setlocal wrap linebreak" })

-- Flash highlight on yank
autocmd("TextYankPost", {
  group    = augroup("highlight_yank", { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})

-- Restore cursor position when reopening a file
autocmd("BufReadPost", {
  group    = augroup("restore_cursor", { clear = true }),
  callback = function()
    local mark  = vim.api.nvim_buf_get_mark(0, '"')
    local lines = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lines then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- =============================================================================
-- COLOR THEME
-- Apply active theme (set by install.sh → ~/.config/nvim/lua/active_theme.lua).
-- Falls back to catppuccin if no theme file is installed.
-- =============================================================================
local ok, theme = pcall(require, "active_theme")
if ok and type(theme) == "table" and theme.setup then
  theme.setup()
else
  require("catppuccin").setup({ flavour = "frappe", integrations = { treesitter = true } })
  vim.cmd.colorscheme("catppuccin")
end
