local function set_dark()
  vim.o.background = "dark" -- NOTE: tokyonight-moon uses light background
  vim.cmd.colorscheme("tokyonight")
end

local function set_light()
  vim.o.background = "light"
  vim.cmd.colorscheme("dayfox")
end

local function tmux_is_running()
  local processes = vim.fn.systemlist("ps -e | grep tmux")
  local found = false
  for _, process in ipairs(processes) do
    if string.find(process, "grep") then
      -- do nothing, just skip
    elseif string.find(process, "tmux") then
      found = true
    end
  end
  return found
end

local function set_tmux(style)
  if not tmux_is_running() then
    return
  end

  local tmux_theme = ""
  if style == "dark" then
    tmux_theme = vim.fn.expand("~/.local/share/lazy/tokyonight.nvim/extra/tmux/tokyonight_night.tmux")
    -- tmux_theme = vim.fn.expand("~/.tmux/plugins/tokyo-night-tmux/tokyo-night.tmux")
  elseif style == "light" then
    tmux_theme = vim.fn.expand("~/.local/share/lazy/nightfox.nvim/extra/dayfox/dayfox.tmux")
  end

  if vim.fn.filereadable(tmux_theme) == 1 then
    os.execute("tmux source-file " .. tmux_theme)
  end
end

return {
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    enabled = true,
    priority = 1000,
    dependencies = {},
    init = function()
      set_dark() -- avoid flickering when starting nvim, default to dark mode
    end,
    opts = {
      update_interval = 3000, -- milliseconds
      set_dark_mode = function()
        set_dark()
        set_tmux("dark")
      end,
      set_light_mode = function()
        set_light()
        set_tmux("light")
      end,
    },
  },
  {
    "uga-rosa/ccc.nvim",
    enabled = false, -- NOTE: enable when needed
    opts = {
      highlighter = {
        auto_enable = true,
        lsp = true,
      },
    },
    config = function(_, opts)
      local ccc = require("ccc")
      ccc.setup(opts)
    end,
  },
  {
    "folke/tokyonight.nvim",
    enabled = true,
    lazy = true,
    ---@class tokyonight.Config
    opts = {
      transparent = false, -- Enable transparency
      style = "night",
      styles = {
        -- Background styles. Can be "dark", "transparent" or "normal"
        floats = { "transparent" },
      },
      lualine_bold = true,
      on_colors = function(colors)
        -- colors.bg_float = "#000000"
        colors.border_highlight = colors.blue
        colors.git.add = "green"
        colors.git.change = "yellow"
        colors.git.delete = "red"
        colors.bg = "#000000"
        colors.border = "green"
        -- colors.bg_statusline = "#001440"
      end,
      on_highlights = function(hl, c)
        -- Set cursor color, these will be called by the "guicursor" option in
        -- the options.lua file, which will be used by neovide

        -- highlights.CursorLine = { bg = "#2f334d" }
        -- hl.CursorLineNr = {
        --   bold = true,
        --   fg = "#ff966c",
        -- }
        if vim.o.background == "dark" then
          -- Use bg.dark from storm (not night) for the cursor line background to make it more subtle
          hl.CursorLine = { bg = "#1f2335" }
          hl.Cursor = { bg = "#F712ff" }
          hl.CursorIM = { bg = "#F712FF" }
          -- Diff colors
          -- Brighten changes within a line
          hl.DiffText = { bg = "#224e38" }
          -- Make changed lines more green instead of blue
          hl.DiffAdd = { bg = "#182f23" }

          -- More saturated DiffDelete
          hl.DiffDelete = { bg = "#4d1919" }

          -- clean up Neogit diff colors (when committing)
          hl.NeogitDiffAddHighlight = { fg = "#82a957", bg = hl.DiffAdd.bg }

          -- Visual should match visual mode
          hl.TelescopeSelection = hl.Visual
          hl.Visual = { bg = "#3f3256" }

          -- Make TS context dimmer and color line numbers
          hl.TreesitterContext = { bg = "#272d45" }
          hl.TreesitterContextLineNumber = { fg = c.fg_gutter, bg = "#272d45" }
        else
          -- Diff colors
          -- Brighten changes within a line
          hl.DiffText = { bg = "#a3dca9" }
          -- Make changed lines more green instead of blue
          hl.DiffAdd = { bg = "#cce5cf" }

          -- clean up Neogit diff colors (when committing)
          hl.NeogitDiffAddHighlight = { fg = "#4d6534", bg = hl.DiffAdd.bg }

          -- Visual should match visual mode
          hl.TelescopeSelection = hl.Visual
          hl.Visual = { bg = "#b69de2" }

          -- Make TS context color line numbers
          hl.TreesitterContextLineNumber = { fg = "#939aba", bg = "#b3b8d1" }

          -- Make yaml properties and strings more distinct
          hl["@property.yaml"] = { fg = "#006a83" }

          -- Make flash label legible in light mode
          -- hl.FlashLabel.fg = c.bg
        end

        hl.TelescopeMatching = { fg = hl.IncSearch.bg }

        -- cmp
        hl.CmpItemAbbrMatchFuzzy = { fg = hl.IncSearch.bg }
        hl.CmpItemAbbrMatch = { fg = hl.IncSearch.bg }
        -- Darken cmp menu (src for the completion)
        hl.CmpItemMenu = hl.CmpGhostText

        -- Blink
        hl.Pmenu.bg = c.bg
        hl.BlinkCmpLabelMatch = { fg = hl.IncSearch.bg }
        hl.BlinkCmpMenuBorder = hl.FloatBorder
        hl.BlinkCmpSource = { fg = c.terminal_black }

        -- FzfLua
        hl.FzfLuaDirPart = hl.NonText
        hl.FzfLuaPathLineNr = { fg = c.fg_dark }
        hl.FzfLuaFzfCursorLine = hl.NonText
        hl.FzfLuaFzfMatch = { fg = hl.IncSearch.bg }
        hl.FzfLuaBufNr = { fg = c.fg }

        -- Snacks
        hl.SnacksPickerBufNr = hl.NonText
        hl.SnacksPickerMatch = { fg = hl.IncSearch.bg }

        -- clean up Neogit diff colors (when committing)
        hl.NeogitDiffContextHighlight = { bg = hl.Normal.bg }
        hl.NeogitDiffContext = { bg = hl.Normal.bg }

        -- More subtle
        hl.IblScope = hl.LineNr
        -- hl.IblScope = { fg = '#283861' }
        hl.IblIndent = { fg = "#1f202e" }
        hl.SnacksIndent = { fg = "#1f202e" }
        hl.SnacksIndentScope = hl.LineNr

        -- Make folds less prominent (especially important for DiffView)
        hl.Folded = { fg = c.blue0 }

        -- Make the colors in the Lualine x section dimmer
        local lualine = require("lualine.themes.tokyonight-night")
        lualine.normal.x = { fg = hl.Comment.fg, bg = lualine.normal.c.bg }

        -- Make diagnostic text easier to read (and underlined)
        hl.DiagnosticUnnecessary = hl.DiagnosticUnderlineWarn

        -- Make lsp cursor word highlights dimmer
        hl.LspReferenceWrite = { bg = c.bg_highlight }
        hl.LspReferenceText = { bg = c.bg_highlight }
        hl.LspReferenceRead = { bg = c.bg_highlight }

        hl.TelescopePromptTitle = {
          fg = c.fg,
        }
        hl.TelescopePromptBorder = {
          fg = c.blue1,
        }
        hl.TelescopeResultsTitle = {
          fg = c.purple,
        }
        hl.TelescopePreviewTitle = {
          fg = c.orange,
        }

        hl.HighlightUndo = hl.CurSearch
        hl.HighlightRedo = hl.CurSearch

        hl.Marks = hl.DiagnosticHint
        -- Apply all highlight definitions at once
        -- for group, props in pairs(highlight_definitions) do
        --   highlights[group] = props
        -- end
      end,
      dim_inactive = false, -- dims inactive windows
    },
  },
  {
    "catppuccin/nvim",
    enabled = true,
    lazy = true,
    name = "catppuccin", -- or Lazy will show the plugin as "nvim"
    opts = {
      -- transparent_background = true,
    },
  },
  {
    "EdenEast/nightfox.nvim",
    enabled = true,
    lazy = true,
  },
}
