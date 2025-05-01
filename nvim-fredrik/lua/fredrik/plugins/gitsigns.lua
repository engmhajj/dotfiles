local icons = require("fredrik.utils.icons")
return {
  {
    "lewis6991/gitsigns.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {

      signs = {
        add = { text = icons.icons.git.added },
        change = { text = icons.icons.git.modified },
        delete = { text = icons.icons.git.removed },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(bufnr)
        require("fredrik.config.keymaps").setup_gitsigns_keymaps(bufnr)
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
    end,
  },
}
