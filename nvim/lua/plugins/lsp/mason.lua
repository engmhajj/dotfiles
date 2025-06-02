return {
  {
    "williamboman/mason.nvim",
    dependencies = {

      {
        "zapling/mason-lock.nvim",
        opts = {
          lockfile_path = require("utils.environ").getenv("DOTFILES") .. "/nvim/mason-lock.json",
        },
      },
      {
        "nvim-lualine/lualine.nvim",
        opts = {
          extensions = { "mason" },
        },
      },
    },

    -- version = "v2.0.0", -- Pin to a specific version
    -- commit = "5477d67", -- Or pin to a specific commit hash
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
      PATH = "append",
      ensure_installed = {
        -- Your list of tools
        -- LSPs
        "lua_ls",
        "dockerls",
        "superhtml",
        "jsonls",
        "basedpyright",
        "ruff",
        "bashls",
        "yamlls",
        "vtsls",
        "ruby_lsp",
        "gopls",
        "zls",
        "markdownlint",
        "omnisharp",
        "netcoredbg",
        -- Formatters / Linters
        "stylua",
        "biome",
        "buf",
        "rubocop",
        "taplo",
        "hadolint",
        "eslint_d",
        "pylint",
        "mypy",
        "markdownlint",
        "rustfmt",
        "gofmt",
        "shellcheck",
        "luacheck", -- This will use Mason's internal version
        "prettier",
        "mdformat",
        "markdown-toc",
        "tectonic",
        "shfmt",
        "yamlfmt",
      },
    },
  },
  -- {
  --   "williamboman/mason-lspconfig.nvim",
  --   version = "v2.0.0",
  --   commit = "5477d67",
  --   opts = {
  --     ensure_installed = {
  --       -- Your list of LSP servers
  --       "lua_ls",
  --       "dockerls",
  --       "superhtml",
  --       "jsonls",
  --       "basedpyright",
  --       "ruff",
  --       "bashls",
  --       "yamlls",
  --       "vtsls",
  --       "ruby_lsp",
  --       "gopls",
  --       "zls",
  --     },
  --   },
  -- },
}
