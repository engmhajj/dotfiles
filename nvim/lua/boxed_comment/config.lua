-- config.lua
local M = {}

M.default_config = {
  style = "fancy",
  max_width = 80,
  padding = 1,
  strip_existing_comments = true,
  filetype_styles = {}, -- e.g. { lua = "double", python = "ascii" }
}

M.styles = {
  unicode = {
    tl = "┌",
    tr = "┐",
    bl = "└",
    br = "┘",
    hor = "─",
    ver = "│",
    hl = nil,
  },
  ascii = {
    tl = "+",
    tr = "+",
    bl = "+",
    br = "+",
    hor = "-",
    ver = "|",
    hl = nil,
  },
  double = {
    tl = "╔",
    tr = "╗",
    bl = "╚",
    br = "╝",
    hor = "═",
    ver = "║",
    hl = "TitleDouble",
  },
  markdown = {
    tl = "```",
    tr = "",
    bl = "```",
    br = "",
    hor = "",
    ver = "",
    hl = "Comment",
  },
  fancy = {
    tl = "◤",
    tr = "◥",
    bl = "◣",
    br = "◢",
    hor = "━",
    ver = "┃",
    hl = "TitleFancy",
  },
  diamond = {
    tl = "◇",
    tr = "◇",
    bl = "◇",
    br = "◇",
    hor = "◆",
    ver = "◆",
    hl = "TitleDiamond",
  },
  wave = {
    tl = "~",
    tr = "~",
    bl = "~",
    br = "~",
    hor = "~",
    ver = "~",
    hl = "TitleWave",
  },
  flames = {
    tl = "🔥",
    tr = "🔥",
    bl = "🔥",
    br = "🔥",
    hor = "🔥",
    ver = "🔥",
    hl = "TitleFlames",
  },
  kawaii = {
    tl = "(*^▽^*)",
    tr = "(^▽^*)",
    bl = "(^▽^*)",
    br = "(*^▽^*)",
    hor = "═",
    ver = "❖",
    hl = "TitleKawaii",
  },
}
M.highlight_groups = {
  TitleDouble = "Title",
  TitleFancy = "Title",
  -- users can override in setup
}

function M.setup(user_config)
  user_config = user_config or {}
  if type(user_config) ~= "table" then
    error("boxed_comment config.setup expects a table, got " .. type(user_config))
  end

  M.default_config = vim.tbl_deep_extend("force", M.default_config or {}, user_config)
end

return M
