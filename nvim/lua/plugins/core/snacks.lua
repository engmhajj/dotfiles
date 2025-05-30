return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    dependencies = {
      -- "folke/persistence.nvim", -- currently commented out
      {
        {
          "nvim-lualine/lualine.nvim",
          opts = function(_, opts)
            opts.options = opts.options or {}
            opts.options.disabled_filetypes = opts.options.disabled_filetypes or {}
            table.insert(opts.options.disabled_filetypes, "snacks_dashboard")
          end,
        },
      },
      "folke/trouble.nvim",
      "folke/todo-comments.nvim",
      {
        "folke/edgy.nvim",
        opts = function(_, opts)
          for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
            opts[pos] = opts[pos] or {}
            table.insert(opts[pos], {
              ft = "snacks_terminal",
              size = { height = 0.3 },
              title = "%{b:snacks_terminal.id}: %{b:term_title}",
              filter = function(_buf, win)
                local w = vim.w[win]
                return w.snacks_win
                  and w.snacks_win.position == pos
                  and w.snacks_win.relative == "editor"
                  and not w.trouble_preview
              end,
            })
          end
        end,
      },
    },

    opts = {
      styles = {
        notification_history = {
          relative = "editor",
          width = 0.9,
          height = 0.9,
        },
        snacks_image = {
          relative = "editor",
          col = -1,
        },
      },

      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },

      indent = {
        enabled = true,
        priority = 1,
        animate = {
          enabled = false,
          style = "out",
          easing = "linear",
          duration = { step = 20, total = 500 },
        },
      },

      lazygit = {
        enabled = true,
        configure = true,
        config = {
          os = { editPreset = "nvim-remote" },
          gui = { nerdFontsVersion = "3" },
          git = { overrideGpg = true },
        },
      },

      notifier = {
        enabled = true,
        timeout = 500,
        width = { min = 30, max = 0.4 },
        height = { min = 1, max = 0.6 },
        margin = { top = 0, right = 1, bottom = 0 },
        padding = true,
        sort = { "level", "added" },
        level = vim.log.levels.TRACE,
        icons = {
          error = " ",
          warn = " ",
          info = " ",
          debug = " ",
          trace = " ",
        },
        keep = function(notif)
          return vim.fn.getcmdpos() > 0
        end,
        style = "compact",
        top_down = true,
        date_format = "%R",
        more_format = " ↓ %d lines ",
        refresh = 2000,
      },

      image = {
        enabled = true,
        doc = {
          inline = vim.g.neovim_mode == "skitty",
          float = true,
          max_width = vim.g.neovim_mode == "skitty" and 5 or 60,
          max_height = vim.g.neovim_mode == "skitty" and 2.5 or 30,
        },
      },

      picker = {
        enabled = true,
        -- actions = require("trouble.sources.snacks").actions,
        sources = {
          files = {
            hidden = true,
            ignored = false,
          },
        },
        win = {
          input = {
            keys = {
              ["<c-t>"] = { "trouble_open", mode = { "n", "i" } },
            },
          },
        },
      },

      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      terminal = { enabled = true },

      zen = {
        enabled = true,
        toggles = {
          dim = false,
          git_signs = false,
          mini_diff_signs = false,
          diagnostics = true,
        },
        win = {
          backdrop = { transparent = false },
        },
      },
    },

    keys = function()
      local snacks_keymaps = require("config.keymaps").setup_snacks_keymaps()
      local terminal_keymaps = require("config.keymaps").setup_terminal_keymaps()
      local merged = {}
      for _, km in ipairs(snacks_keymaps or {}) do
        table.insert(merged, km)
      end
      for _, km in ipairs(terminal_keymaps or {}) do
        table.insert(merged, km)
      end
      return merged
    end,
  },
}
