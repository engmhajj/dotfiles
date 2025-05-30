vim.api.nvim_create_autocmd("FileType", {
  pattern = { "lua" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
    vim.opt_local.colorcolumn = "120"
  end,
})

return {

  {
    "folke/lazydev.nvim",
    opts = {
      library = {

        -- Library paths can be absolute
        -- "~/projects/my-awesome-lib",

        -- Or relative, which means they will be resolved from the plugin dir.
        "lazy.nvim",
        "neotest",
        "plenary",

        -- It can also be a table with trigger words / mods
        -- Only load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },

        -- always load the LazyVim library
        -- "LazyVim",

        -- Only load the lazyvim library when the `LazyVim` global is found
        { path = "LazyVim", words = { "LazyVim" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
  -- lua_ls LSP config using lspconfig
  {
    "nvim-neotest/neotest",
    lazy = true,
    ft = { "lua" },
    dependencies = { "nvim-neotest/neotest-plenary" },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-plenary"] = {}
    end,
  },

  {
    "mfussenegger/nvim-dap",
    lazy = true,
    ft = { "lua" },
    dependencies = {
      {
        "jbyuki/one-small-step-for-vimkind",
        keys = require("config.keymaps").setup_osv_keymaps(),
      },
    },
    opts = function(_, opts)
      opts.configurations = opts.configurations or {}
      opts.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance",
        },
      }
      local dap = require("dap")
      dap.adapters.nlua = function(callback, config)
        callback({
          type = "server",
          host = config.host or "127.0.0.1",
          port = config.port or 8086,
        })
      end
    end,
  },
}
