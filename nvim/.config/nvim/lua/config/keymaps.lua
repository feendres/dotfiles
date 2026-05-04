-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Delete single character without copying into register
vim.keymap.set("n", "x", '"_x')

-- Leader+d to delete without copying
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d')
