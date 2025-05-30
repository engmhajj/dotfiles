-- Fix conceallevel for markdown files
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = vim.api.nvim_create_augroup("markdown_conceal", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.conceallevel = 2
  end,
})

return {

  {
    "iamcco/markdown-preview.nvim",
    lazy = true,
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = true,
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.icons",
      {
        "saghen/blink.cmp",
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
          sources = {
            default = { "markdown" },
            providers = {
              markdown = { name = "RenderMarkdown", module = "render-markdown.integ.blink" },
            },
          },
        },
        opts_extend = {
          "sources.default",
        },
      },
      {
        -- "epwalsh/obsidian.nvim",
        "obsidian-nvim/obsidian.nvim",
        opts = {
          ui = { enable = false },
        },
      },
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      heading = {
        enabled = false,
        -- width = "block",
        -- sign = false,
        -- icons = {},
      },
    },
    keys = require("config.keymaps").setup_markdown_keymaps(),
  },
}
