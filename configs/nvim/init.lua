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
  -- Catppuccin Macchiato (matches Ghostty / tmux / starship / delta)
  -- -------------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,
    opts = {
      flavour    = "macchiato",
      background = { light = "latte", dark = "macchiato" },
      integrations = {
        treesitter = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- -------------------------------------------------------------------------
  -- Treesitter — proper syntax highlighting and indentation
  -- -------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
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
