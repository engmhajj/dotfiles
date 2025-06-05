-- https://github.com/eldritch-theme/eldritch.nvim
--
-- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/colorschemes/eldritch.lua
-- ~/github/dotfiles-latest/neovim/neobean/lua/plugins/colorschemes/eldritch.lua

-- Require the colors.lua module and access the colors directly without
-- additional file reads
local colors = require("config.colors")

local tmux_theme = vim.fn.expand("~/.local/share/nvim/lazy/tokyonight.nvim/extra/tmux/tokyonight_night.tmux")

if vim.fn.filereadable(tmux_theme) == 1 then
  os.execute("tmux source-file " .. tmux_theme)
end

return {
  {
    "eldritch-theme/eldritch.nvim",
    lazy = true,
    priority = 1000,
    name = "eldritch",
    opts = {
      styles = {
        -- Background styles. Can be "dark", "transparent" or "normal"
        floats = { "transparent" },
      },
      dim_inactive = false, -- dims inactive windows
      -- Overriding colors globally using a definitions table
      on_colors = function(global_colors)
        -- Define all color overrides in a single table
        local color_definitions = {
          -- https://github.com/eldritch-theme/eldritch.nvim/blob/master/lua/eldritch/colors.lua
          bg = colors["color10"],
          fg = colors["color14"],
          border = "green",
          -- border_highlight = "blue",
          selection = colors["color16"],
          comment = colors["color09"],
          red = colors["color08"], -- default #f16c75
          orange = colors["color06"], -- default #f7c67f
          yellow = colors["color05"], -- default #f1fc79
          green = colors["color02"],
          purple = colors["color04"], -- default #a48cf2
          cyan = colors["color03"],
          pink = colors["color01"], -- default #f265b5
          bright_red = colors["color08"],
          bright_green = colors["color02"],
          bright_yellow = colors["color05"],
          bright_blue = colors["color04"],
          bright_magenta = colors["color01"],
          bright_cyan = colors["color03"],
          bright_white = colors["color14"],
          menu = colors["color10"],
          visual = colors["color16"],
          gutter_fg = colors["color16"],
          nontext = colors["color16"],
          white = colors["color14"],
          black = colors["color10"],
          git = {
            change = "yellow",
            add = "green",
            delete = colors["color11"],
          },
          gitSigns = {
            change = colors["color03"],
            add = colors["color02"],
            delete = colors["color11"],
          },
          bg_dark = colors["color13"],
          -- Lualine line across
          bg_highlight = colors["color17"],
          terminal_black = colors["color13"],
          fg_dark = colors["color14"],
          fg_gutter = colors["color13"],
          dark3 = colors["color13"],
          dark5 = colors["color13"],
          bg_visual = colors["color16"],
          dark_cyan = colors["color03"],
          magenta = colors["color01"],
          magenta2 = colors["color01"],
          magenta3 = colors["color01"],
          dark_yellow = colors["color05"],
          dark_green = colors["color02"],
        }

        -- Apply each color definition to global_colors
        for key, value in pairs(color_definitions) do
          global_colors[key] = value
        end
      end,

      -- This function is found in the documentation
      on_highlights = function(highlights)
        local highlight_definitions = {
          -- comments
          TitleFancy = { fg = "#f6c177", bold = true },
          TitleDouble = { fg = "#9ccfd8", bold = true },
          TitleWave = { fg = "#f0a0a0", bold = true },

          -- nvim-spectre or grug-far.nvim highlight colors
          DiffChange = { bg = colors["color03"], fg = "black" },
          DiffDelete = { bg = colors["color11"], fg = "black" },
          DiffAdd = { bg = colors["color02"], fg = "black" },
          TelescopeResultsDiffDelete = { bg = colors["color01"], fg = "black" },

          -- horizontal line that goes across where cursor is
          CursorLine = { bg = colors["color13"] },

          -- Set cursor color, these will be called by the "guicursor" option in
          -- the options.lua file, which will be used by neovide
          Cursor = { bg = colors["color24"] },
          lCursor = { bg = colors["color24"] },
          CursorIM = { bg = colors["color24"] },

          -- I do the line below to change the color of bold text
          ["@markup.strong"] = { fg = colors["color24"], bold = true },

          -- Inline code in markdown
          ["@markup.raw.markdown_inline"] = { fg = colors["color02"] },

          -- Change the spell underline color
          SpellBad = { sp = colors["color11"], undercurl = true, bold = true, italic = true },
          SpellCap = { sp = colors["color12"], undercurl = true, bold = true, italic = true },
          SpellLocal = { sp = colors["color12"], undercurl = true, bold = true, italic = true },
          SpellRare = { sp = colors["color04"], undercurl = true, bold = true, italic = true },

          MiniDiffSignAdd = { fg = colors["color05"], bold = true },
          MiniDiffSignChange = { fg = colors["color02"], bold = true },

          -- Codeblocks for the render-markdown plugin
          RenderMarkdownCode = { bg = colors["color07"] },
          -- Visual should match visual mode

          -- This is the plugin that shows you where you are at the top
          TreesitterContext = { bg = "#272d45" },
          TreesitterContextLineNumber = { fg = highlights.fg_gutter, bg = "#272d45" },
          -- TreesitterContext = { sp = colors["color10"] },
          -- MiniFilesNormal = { sp = colors["color10"] },
          -- MiniFilesBorder = { sp = colors["color10"] },
          -- MiniFilesTitle = { sp = colors["color10"] },
          -- MiniFilesTitleFocused = { sp = colors["color10"] },
          -- Make yaml properties and strings more distinct
          -- NormalFloat = { bg = colors["color26"] },
          -- FloatBorder = { bg = colors["color11"] },
          -- FloatTitle = { bg = colors["color15"] },
          NotifyBackground = { bg = colors["color17"] },
          NeoTreeNormalNC = { bg = colors["color17"] },
          NeoTreeNormal = { bg = colors["color17"] }, -- change neotree color
          NvimTreeWinSeparator = { fg = colors["color01"], bg = colors["color10"] },
          NvimTreeNormalNC = { bg = colors["color10"] },
          NvimTreeNormal = { bg = colors["color10"] },
          TroubleNormal = { bg = colors["color10"] },

          NoiceCmdlinePopupBorder = { fg = colors["color11"] },
          NoiceCmdlinePopupTitle = { fg = colors["color11"] },
          NoiceCmdlinePopupBorderFilter = { fg = colors["color11"] },
          NoiceCmdlineIconFilter = { fg = colors["color10"] },
          NoiceCmdlinePopupTitleFilter = { fg = colors["color10"] },
          NoiceCmdlineIcon = { fg = colors["color10"] },
          NoiceCmdlineIconCmdline = { fg = colors["color03"] },
          NoiceCmdlinePopupBorderCmdline = { fg = colors["color02"] },
          NoiceCmdlinePopupTitleCmdline = { fg = colors["color03"] },
          NoiceCmdlineIconSearch = { fg = colors["color04"] },
          NoiceCmdlinePopupBorderSearch = { fg = colors["color03"] },
          NoiceCmdlinePopupTitleSearch = { fg = colors["color04"] },
          NoiceCmdlineIconLua = { fg = colors["color05"] },
          NoiceCmdlinePopupBorderLua = { fg = colors["color01"] },
          NoiceCmdlinePopupTitleLua = { fg = colors["color05"] },
          NoiceCmdlineIconHelp = { fg = colors["color12"] },
          NoiceCmdlinePopupBorderHelp = { fg = colors["color08"] },
          NoiceCmdlinePopupTitleHelp = { fg = colors["color12"] },
          NoiceCmdlineIconInput = { fg = colors["color10"] },
          NoiceCmdlinePopupBorderInput = { fg = colors["color10"] },
          NoiceCmdlinePopupTitleInput = { fg = colors["color10"] },
          NoiceCmdlineIconCalculator = { fg = colors["color10"] },
          NoiceCmdlinePopupBorderCalculator = { fg = colors["color10"] },
          NoiceCmdlinePopupTitleCalculator = { fg = colors["color10"] },
          NoiceCompletionItemKindDefault = { fg = colors["color10"] },

          NoiceMini = { bg = colors["color10"] },
          StatusLine = { bg = colors["color10"] },
          Folded = { bg = colors["color10"] },

          DiagnosticInfo = { fg = colors["color03"] },
          DiagnosticHint = { fg = colors["color02"] },
          DiagnosticWarn = { fg = colors["color12"] },
          DiagnosticOk = { fg = colors["color04"] },
          DiagnosticError = { fg = colors["color11"] },
          RenderMarkdownQuote = { fg = colors["color12"] },

          -- visual mode selection
          Visual = { bg = colors["color16"], fg = colors["color10"] },
          PreProc = { fg = colors["color06"] },
          ["@operator"] = { fg = colors["color02"] },

          KubectlHeader = { fg = colors["color04"] },
          KubectlWarning = { fg = colors["color03"] },
          KubectlError = { fg = colors["color01"] },
          KubectlInfo = { fg = colors["color02"] },
          KubectlDebug = { fg = colors["color05"] },
          KubectlSuccess = { fg = colors["color02"] },
          KubectlPending = { fg = colors["color03"] },
          KubectlDeprecated = { fg = colors["color08"] },
          KubectlExperimental = { fg = colors["color09"] },
          KubectlNote = { fg = colors["color03"] },
          KubectlGray = { fg = colors["color10"] },

          -- Colorcolumn that helps me with markdown guidelines
          ColorColumn = { bg = colors["color13"] }, -- this change the color of the line shown on the right

          FzfLuaFzfPrompt = { fg = colors["color04"], bg = colors["color10"] },
          FzfLuaCursorLine = { fg = colors["color02"], bg = colors["color10"] },
          FzfLuaTitle = { fg = colors["color03"], bg = colors["color10"] },
          FzfLuaSearch = { fg = colors["color14"], bg = colors["color10"] },
          FzfLuaBorder = { fg = colors["color02"], bg = colors["color10"] },
          FzfLuaNormal = { fg = colors["color14"], bg = colors["color10"] },

          TelescopeNormal = { fg = colors["color14"], bg = colors["color10"] },
          TelescopeMultiSelection = { fg = colors["color02"], bg = colors["color10"] },
          TelescopeSelection = { fg = colors["color14"], bg = colors["color13"] },
        }

        -- Apply all highlight definitions at once
        for group, props in pairs(highlight_definitions) do
          highlights[group] = props
        end
      end,
    },
  },
}
