vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = { "*.rb", "Vagrantfile" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.colorcolumn = "88"
    vim.opt_local.expandtab = true

    vim.opt_local.colorcolumn = "120"
  end,
})

return {

  {
    "mfussenegger/nvim-lint",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "rubocop", "ruby-lsp", "rufo" })
          opts.formatters_by_ft = {
            ruby = { "rubocop" },
          }
        end,
      },
    },
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters = opts.linters or {}

      opts.linters_by_ft["ruby"] = { "rubocop" }
    end,
  },

  {
    "virtual-lsp-config",
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
          {
            "williamboman/mason.nvim",
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "ruby_lsp" })
        end,
      },
    },
    opts = {
      servers = {
        ruby_lsp = {
          cmd = { "rubocop" },
          filetypes = { "ruby", "vagrantfile" },
          root_markers = {
            "Vagrantfile",
            ".git",
          },
          log_level = vim.lsp.protocol.MessageType.Warning,
          capabilities = {
            general = {
              -- positionEncodings = { "utf-8", "utf-16", "utf-32" }  <--- this is the default
              positionEncodings = { "utf-16" },
            },
          },
          init_options = {
            settings = {
              -- https://docs.astral.sh/ruff/editors/settings/
              configurationPreference = "filesystemFirst",
              lineLength = 88,
            },
          },
          settings = {
            rubocop = {},
          },
        },
      },
    },
  },
}
