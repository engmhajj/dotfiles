return {
  {
    "stevearc/conform.nvim",
    -- dependencies = {
    --   {
    --     "williamboman/mason.nvim",
    --     opts = function(_, opts)
    --       local extend = vim.fn and vim.list_extend
    --         or function(t1, t2)
    --           for _, v in ipairs(t2) do
    --             table.insert(t1, v)
    --           end
    --           return t1
    --         end
    --
    --       opts.ensure_installed = opts.ensure_installed or {}
    --       extend(opts.ensure_installed, {
    --         "stylua",
    --         "prettier",
    --         "mdformat",
    --         "markdown-toc",
    --         "tectonic",
    --         "shfmt",
    --         "yamlfmt",
    --       })
    --     end,
    --   },
    -- },
    lazy = true,
    event = "BufWritePre",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        json = { "biome" },
        jsonc = { "biome" },
        json5 = { "biome" },
        markdown = { "prettier" },
        sh = { "shfmt" },
        typescript = { "prettier" },
        yaml = { "yamlfmt" },
        gha = { "yamlfmt" },
        dependabot = { "yamlfmt" },
      },
      formatters = {
        yamlfmt = {
          prepend_args = {
            "-formatter",
            "retain_line_breaks_single=true",
          },
        },
        biome = {
          args = { "format", "--indent-style", "space", "--stdin-file-path", "$FILENAME" },
        },
        prettier = {
          prepend_args = { "--prose-wrap", "always", "--print-width", "80", "--tab-width", "2" },
        },
        mdformat = {
          prepend_args = { "--number", "--wrap", "80" },
        },
      },
    },
    config = function(_, opts)
      vim.g.auto_format = true
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        callback = function(args)
          if vim.g.auto_format then
            require("conform").format({
              bufnr = args.buf,
              timeout_ms = 5000,
              lsp_format = "fallback",
            })
          end
        end,
      })

      require("conform").setup(opts)
      require("config.keymaps").setup_conform_keymaps()
    end,
  },
}
