return {

  {
    "saghen/blink.cmp",
    enabled = vim.g.cmp_engine ~= "cmp",
    -- lazy = false, -- lazy loading handled internally
    event = { "InsertEnter", "CmdlineEnter" },
    version = "*",
    dependencies = {
      -- NOTE: https://github.com/Saghen/blink.compat is also available
      "rafamadriz/friendly-snippets",
      "Kaiser-Yang/blink-cmp-avante",
    },

    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    --  build = "cargo build --release",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = require("fredrik.config.keymaps").setup_blink_cmp_keymaps(),
      cmdline = {
        enabled = true,
        completion = {
          menu = { auto_show = true },
          ghost_text = { enabled = true },
        },
        keymap = require("fredrik.config.keymaps").setup_blink_cmdline_keymaps(),
        -- keymap = { preset = "cmdline" },
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
                  if ctx.source_id == "cmdline" then
                    return
                  end
                  return ctx.kind_icon .. ctx.icon_gap
                end,
              },
              label = { width = { fill = false } }, -- default is true
              label_description = {
                width = { fill = true },
              },
              source_name = {
                text = function(ctx)
                  if ctx.source_id == "cmdline" then
                    return
                  end
                  return ctx.source_name:sub(1, 4)
                end,
              },
            },

            treesitter = { "lsp" },
          },
        },
        documentation = {
          auto_show = true,
          window = {
            border = "rounded",
          },
        },
      },
      signature = {
        enabled = true, -- experimental, can also be provided by noice
        window = {
          show_documentation = true,
          border = "rounded",
        },
      },
      appearance = {
        nerd_font_variant = "normal",
        kind_icons = require("fredrik.utils.icons").icons.kinds,
      },
      -- default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, via `opts_extend`
      fuzzy = { implementation = "prefer_rust_with_warning" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "easy-dotnet" },
        providers = {
          ["easy-dotnet"] = {
            name = "easy-dotnet",
            enabled = true,
            module = "easy-dotnet.completion.blink",
            score_offset = 10000,
            async = true,
          },
          path = {
            -- TODO: use custom field and move to respective plugin
            enabled = function()
              return not vim.tbl_contains({ "AvanteInput", "codecompanion" }, vim.bo.filetype)
            end,
          },
          -- TODO: use custom field and move to respective plugin
          buffer = {
            enabled = function()
              return not vim.tbl_contains({ "AvanteInput", "codecompanion" }, vim.bo.filetype)
            end,
          },
          snippets = {
            opts = {
              friendly_snippets = true,
              search_paths = { require("fredrik.utils.environ").getenv("DOTFILES") .. "/nvim-fredrik/snippets" },
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
  -- lazydev
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "lazydev" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- show at a higher priority than lsp
          },
        },
      },
    },
  },
  {
    "Kaiser-Yang/blink-cmp-git",
    lazy = true,
    enabled = vim.g.cmp_engine ~= "cmp",
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        -- add lazydev to your completion providers
        default = { "git" },
        providers = {
          git = {
            module = "blink-cmp-git",
            name = "Git",
            should_show_items = function()
              return vim.o.filetype == "gitcommit" or vim.o.filetype == "markdown"
            end,
            opts = {
              use_items_pre_cache = false,
              -- options for the blink-cmp-git
            },
          },
        },
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = {
      fuzzy = { implementation = "prefer_rust_with_warning" },
      sources = {
        default = { "lsp", "easy-dotnet", "path" },
        providers = {
          ["easy-dotnet"] = {
            name = "easy-dotnet",
            enabled = true,
            module = "easy-dotnet.completion.blink",
            score_offset = 10000,
            async = true,
          },
        },
      },
    },
  },
}
