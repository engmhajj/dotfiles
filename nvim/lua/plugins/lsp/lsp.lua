-- plugins.lua or lspconfig.lua (your main plugin spec)
-- lua/plugins/lspconfig.lua (or wherever you register LSP servers)

return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = {
      "williamboman/mason.nvim",
      -- "williamboman/mason-lspconfig.nvim",
      "b0o/SchemaStore.nvim",
      "folke/lazydev.nvim", -- optional dev helper for completions
      "Bilal2453/luvit-meta", -- optional typings
      -- "artemave/workspace-diagnostics.nvim",
    },
    config = function()
      local servers = require("plugins.lsp.lsp_servers")

      -- Setup Mason and Mason-LSPconfig to ensure servers installed
      require("mason").setup()
      -- require("mason-lspconfig").setup({
      --   ensure_installed = vim.tbl_keys(servers),
      -- })
      -- init.lua or plugin config file
      local lsp_utils = require("plugins.lsp.utils")

      -- Setup servers
      -- Validate and prepare
      lsp_utils.validate_servers(servers)
      lsp_utils.extend_capabilities(servers)
      -- lsp_utils.ensure_servers_installed(servers)
      lsp_utils.register_lsp_servers(servers)
      lsp_utils.register_lspattach_autocmd()
      -- lsp_utils.register_csharp_lsp(servers)

      -- Setup keymaps for LSP
      require("config.keymaps").setup_lsp_keymaps()
    end,
  },

  -- Copilot config
}
