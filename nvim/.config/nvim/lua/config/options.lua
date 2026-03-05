-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

--  Define the 'Anti-Freeze' Paste Function
local function paste()
  return {
    vim.fn.split(vim.fn.getreg('"'), "\n"),
    vim.fn.getregtype('"'),
  }
end

-- FORCE the OSC 52 provider (No "if" checks)
-- This uses the internal Neovim v0.10+ module
vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = paste,
    ['*'] = paste,
  },
}

-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "basedpyright"
