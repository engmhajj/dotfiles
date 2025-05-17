return {
  {
    "folke/snacks.nvim",
    dependencies = {
      --  "folke/persistence.nvim",
      {
        "nvim-lualine/lualine.nvim",
        opts = {
          options = {
            disabled_filetypes = { "snacks_dashboard" },
          },
        },
        opts_extend = {
          "options.disabled_filetypes",
        },
      },
      { "folke/trouble.nvim" },
      { "folke/todo-comments.nvim" },
      {
        "folke/edgy.nvim",
        ---@module 'edgy'
        ---@param opts Edgy.Config
        opts = function(_, opts)
          for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
            opts[pos] = opts[pos] or {}
            table.insert(opts[pos], {
              ft = "snacks_terminal",
              size = { height = 0.3 },
              title = "%{b:snacks_terminal.id}: %{b:term_title}",
              filter = function(_buf, win)
                return vim.w[win].snacks_win
                  and vim.w[win].snacks_win.position == pos
                  and vim.w[win].snacks_win.relative == "editor"
                  and not vim.w[win].trouble_preview
              end,
            })
          end
        end,
      },
    },
    priority = 1000,
    lazy = false,

    ---@type snacks.Config
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
          duration = {
            step = 20, -- ms per step
            total = 500, -- maximum duration
          },
        },
      },

      lazygit = {
        enabled = true,
        -- automatically configure lazygit to use the current colorscheme
        -- and integrate edit with the current neovim instance
        configure = true,

        config = {
          os = { editPreset = "nvim-remote" },
          gui = {
            -- set to an empty string "" to disable icons
            nerdFontsVersion = "3",
          },
          git = {
            overrideGpg = true,
          },
        },
      },

      ---@class snacks.notifier.Config
      ---@field enabled? boolean
      ---@field keep? fun(notif: snacks.notifier.Notif): boolean # global keep function
      ---@field filter? fun(notif: snacks.notifier.Notif): boolean # filter our unwanted notifications (return false to hide)
      notifier = {
        enabled = true,
        timeout = 500, -- default timeout in ms
        width = { min = 30, max = 0.4 },
        height = { min = 1, max = 0.6 },
        -- editor margin to keep free. tabline and statusline are taken into account automatically
        margin = { top = 0, right = 1, bottom = 0 },
        padding = true, -- add 1 cell of left/right padding to the notification window
        sort = { "level", "added" }, -- sort by level and time
        -- minimum log level to display. TRACE is the lowest
        -- all notifications are stored in history
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
        ---@type snacks.notifier.style
        style = "compact",
        top_down = true, -- place notifications from top to bottom
        date_format = "%R", -- time format for notifications
        -- format for footer when more lines are available
        -- `%d` is replaced with the number of lines.
        -- only works for styles with a border
        ---@type string|boolean
        more_format = " ↓ %d lines ",
        refresh = 2000, -- refresh at most every 50ms
      },
      -- This keeps the image on the top right corner, basically leaving your
      -- text area free, suggestion found in reddit by user `Redox_ahmii`
      -- https://www.reddit.com/r/neovim/comments/1irk9mg/comment/mdfvk8b/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
      image = {
        enabled = true,
        doc = {
          -- Personally I set this to false, I don't want to render all the
          -- images in the file, only when I hover over them
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = vim.g.neovim_mode == "skitty" and true or false,
          -- only_render_image_at_cursor = vim.g.neovim_mode == "skitty" and false or true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = true,
          -- Sets the size of the image
          -- max_width = 60,
          -- max_width = vim.g.neovim_mode == "skitty" and 20 or 60,
          -- max_height = vim.g.neovim_mode == "skitty" and 10 or 30,
          max_width = vim.g.neovim_mode == "skitty" and 5 or 60,
          max_height = vim.g.neovim_mode == "skitty" and 2.5 or 30,
          -- max_height = 30,
          -- Apparently, all the images that you preview in neovim are converted
          -- to .png and they're cached, original image remains the same, but
          -- the preview you see is a png converted version of that image
          --
          -- Where are the cached images stored?
          -- This path is found in the docs
          -- :lua print(vim.fn.stdpath("cache") .. "/snacks/image")
          -- For me returns `~/.cache/neobean/snacks/image`
          -- Go 1 dir above and check `sudo du -sh ./* | sort -hr | head -n 5`
        },
      },

      picker = {
        enabled = true,
        actions = require("trouble.sources.snacks").actions,
        sources = {
          files = {
            hidden = true, -- NOTE: toggle with alt+h
            ignored = false, -- NOTE: toggle with alt+h
          },
        },
        win = {
          input = {
            keys = {
              ["<c-t>"] = {
                "trouble_open",
                mode = { "n", "i" },
              },
            },
          },
        },
      },

      quickfile = { enabled = true },

      statuscolumn = { enabled = true },

      terminal = { enabled = true },

      zen = {
        enabled = true,
        -- You can add any `Snacks.toggle` id here.
        -- Toggle state is restored when the window is closed.
        -- Toggle config options are NOT merged.
        ---@type table<string, boolean>
        toggles = {
          dim = false,
          git_signs = false,
          mini_diff_signs = false,
          diagnostics = true,
          -- inlay_hints = false,
        },
        win = {
          backdrop = {
            transparent = false,
          },
        },
      },
    },
    keys = function()
      ---@type table[table]
      local snacks_keymaps = require("fredrik.config.keymaps").setup_snacks_keymaps()
      ---@type table[table]
      local terminal_keymaps = require("fredrik.config.keymaps").setup_terminal_keymaps()

      local merged_keymaps = {}
      for _, keymap in ipairs(snacks_keymaps) do
        table.insert(merged_keymaps, keymap)
      end
      for _, keymap in ipairs(terminal_keymaps) do
        table.insert(merged_keymaps, keymap)
      end
      return merged_keymaps
    end,
  },
}
