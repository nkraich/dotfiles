-- ── Options ────────────────────────────────────────────────────────────────────
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- Disable netrw (Telescope handles file navigation)
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt
opt.number         = true
opt.relativenumber = true
opt.cursorline     = true
opt.signcolumn     = "yes"      -- always show sign column (prevents layout shifts)
opt.scrolloff      = 8          -- keep 8 lines visible above/below cursor
opt.wrap           = false
opt.expandtab      = true
opt.tabstop        = 2
opt.shiftwidth     = 2
opt.smartindent    = true
opt.ignorecase     = true
opt.smartcase      = true
opt.splitright     = true       -- new vertical splits open on the right
opt.splitbelow     = true       -- new horizontal splits open below
opt.updatetime     = 250        -- faster diagnostic updates
opt.timeoutlen     = 300
opt.undofile       = true       -- persistent undo history
opt.clipboard      = "unnamedplus"  -- sync with system clipboard
opt.termguicolors  = true

-- ── Keymaps ────────────────────────────────────────────────────────────────────
local map = vim.keymap.set

-- Keep cursor centered when paging
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- Window navigation (works alongside tmux-vim navigator if added later)
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")

-- Diagnostic navigation
map("n", "[d", vim.diagnostic.goto_prev,  { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next,  { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- ── Bootstrap lazy.nvim ────────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ── Load plugins ───────────────────────────────────────────────────────────────
require("lazy").setup("plugins", {
  change_detection = { notify = false },
})
