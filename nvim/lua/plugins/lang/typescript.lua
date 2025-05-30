return {
  {
    "yioneko/nvim-vtsls",
    lazy = true,
    opts = {},
    config = function(_, opts)
      require("vtsls").config(opts)
    end,
  },
  {
    "CRAG666/code_runner.nvim",
    lazy = true,
    opts = {
      filetype = {
        typescript = {
          "bun",
        },
      },
    },
  },

  {
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
}
