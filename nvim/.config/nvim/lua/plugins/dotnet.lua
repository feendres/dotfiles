return {
  {
    "GustavEikaas/easy-dotnet.nvim",
    cond = vim.fn.executable("dotnet") == 1,
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    ft = { "cs" },
    config = function()
      require("easy-dotnet").setup()
    end,
  },
}
