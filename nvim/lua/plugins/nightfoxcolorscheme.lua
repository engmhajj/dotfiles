-- Plugins: Colorschemes
-- https://github.com/rafi/vim-config
if true then
  return {}
end

return {
  -- Lazy
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000, -- Ensure it loads first
    config = function()
      vim.cmd("colorscheme onedark_dark")
    end,
  },

  -- -- Use last-used colorscheme
  -- {
  --   "rafi/theme-loader.nvim",
  --   lazy = false,
  --   priority = 99,
  --   opts = { initial_colorscheme = "neohybrid" },
  -- },
  --
  -- { "rafi/neo-hybrid.vim", priority = 100, lazy = false },
  -- { "rafi/awesome-vim-colorschemes", lazy = false },
}
