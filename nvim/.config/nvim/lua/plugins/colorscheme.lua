return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    opts = {
      style = "night",
      transparent = true, -- The correct key is 'transparent'
      styles = {
        sidebars = "transparent", -- ensures file tree/etc are also clear
        floats = "transparent", -- ensures popups are clear
      },
    },
  },
}
