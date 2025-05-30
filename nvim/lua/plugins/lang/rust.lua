return {

  {
    "mrcjkb/rustaceanvim",
    lazy = true,
    ft = { "rust" },
    version = "*",
  },

  {
    "nvim-neotest/neotest",
    lazy = true,
    ft = { "rust" },
    dependencies = {
      "mrcjkb/rustaceanvim",
    },
    optional = true,
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      vim.list_extend(opts.adapters, {
        require("rustaceanvim.neotest"),
      })
    end,
  },
}
