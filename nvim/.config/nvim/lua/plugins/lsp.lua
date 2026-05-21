return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- This diagnostic table is automatically passed into
      -- vim.diagnostic.config() by LazyVim during setup.
      diagnostics = {
        virtual_text = false,
        virtual_lines = { current_line = true },
      },
    },
  },
}
