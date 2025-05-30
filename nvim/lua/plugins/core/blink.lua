return {
  {
    "saghen/blink.cmp",
    enabled = vim.g.cmp_engine ~= "cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    version = "*",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "Kaiser-Yang/blink-cmp-avante",
      {
        "folke/lazydev.nvim",
        config = function()
          require("lazydev").setup({
            library = {
              "lazy.nvim",
              "neotest",
              "plenary",
              { path = "${3rd}/luv/library", words = { "vim%.uv" } },
              { path = "LazyVim", words = { "LazyVim" } },
            },
          })
        end,
      },
    },

    opts = {
      keymap = require("config.keymaps").setup_blink_cmp_keymaps(),

      cmdline = {
        enabled = true,
        completion = {
          menu = { auto_show = true },
          ghost_text = { enabled = true },
        },
        keymap = require("config.keymaps").setup_blink_cmdline_keymaps(),
      },

      completion = {
        list = {
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
        menu = {
          border = "rounded",
          max_height = 12,
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", "source_name", gap = 1 },
            },
            components = {
              kind_icon = {
                text = function(ctx)
                  if ctx.source_id ~= "cmdline" then
                    return ctx.kind_icon .. ctx.icon_gap
                  end
                end,
              },
              label = { width = { fill = false } },
              label_description = { width = { fill = true } },
              source_name = {
                text = function(ctx)
                  if ctx.source_id ~= "cmdline" then
                    return ctx.source_name and ctx.source_name:sub(1, 4) or ""
                  end
                end,
              },
            },
            treesitter = { "lsp" },
          },
        },
        documentation = {
          auto_show = true,
          window = { border = "rounded" },
        },
      },

      signature = {
        enabled = true,
        window = {
          show_documentation = true,
          border = "rounded",
        },
      },

      appearance = {
        nerd_font_variant = "normal",
        kind_icons = require("utils.icons").icons.kinds,
      },

      fuzzy = {
        implementation = "prefer_rust_with_warning",
      },

      sources = {
        default = {
          "lsp",
          "path",
          "snippets",
          "buffer",
          "easy-dotnet",
          "lazydev",
          "git",
        },
        providers = {
          ["easy-dotnet"] = {
            name = "easy-dotnet",
            enabled = true,
            module = "easy-dotnet.completion.blink",
            score_offset = 10000,
            async = true,
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
          git = {
            module = "blink-cmp-git",
            name = "Git",
            should_show_items = function()
              return vim.bo.filetype == "gitcommit" or vim.bo.filetype == "markdown"
            end,
            opts = {
              use_items_pre_cache = false,
            },
          },
          path = {
            enabled = function()
              return not vim.tbl_contains({ "AvanteInput", "codecompanion" }, vim.bo.filetype)
            end,
          },
          buffer = {
            enabled = function()
              return not vim.tbl_contains({ "AvanteInput", "codecompanion" }, vim.bo.filetype)
            end,
          },
          snippets = {
            opts = {
              friendly_snippets = true,
              search_paths = {
                require("utils.environ").getenv("DOTFILES") .. "/nvim/snippets",
              },
            },
          },
        },
      },
    },

    opts_extend = {
      "sources.default",
    },

    config = function(_, opts)
      require("blink.cmp").setup(opts)
    end,
  },

  {
    "Kaiser-Yang/blink-cmp-git",
    lazy = true,
    enabled = vim.g.cmp_engine ~= "cmp",
  },
}
