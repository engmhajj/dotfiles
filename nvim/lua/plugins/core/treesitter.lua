return {
  {
    "nvim-treesitter/playground",
    cmd = {
      "TSPlaygroundToggle",
      "TSHighlightCapturesUnderCursor",
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        playground = {
          enable = true,
        },
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = "BufRead",
    build = ":TSUpdate",
    opts = function(_, opts)
      local defaults = {

        auto_install = true,
        ensure_installed = {
          "diff",
          "regex",
          "markdown_inline",
          "http",
          "zig",
          "markdown",
          "latex",
          "ruby",
          "python",
          "javascript",
          "typescript",
          "lua",
          "c",
          "cpp",
          "bash",
          "css",
          "html",
          "norg",
          "scss",
          "svelte",
          "tsx",
          "typst",
          "vue",
          "yaml",
          "yaml",
          "dockerfile",
          "toml",
          "rust",
          -- "go",
          -- "sh",
          -- "actionlint",
          -- "cs",
          "razor",
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = { "ruby" },
        },
        indent = { enable = true },
        playground = {
          enable = true,
          disable = {},
          updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
          persist_queries = false, -- Whether the query persists across vim sessions
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },
        multiwindow = true,
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- Whether to set jumps in the jumplist
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
        },
      }
      return require("utils.table").deep_merge(defaults, opts or {})
    end,
    config = function(_, opts)
      vim.treesitter.language.register("c_sharp", "csharp")
      local configs = require("nvim-treesitter.configs")
      configs.setup(opts)
      require("config.options").treesitter_foldexpr()
    end,
  },
}
