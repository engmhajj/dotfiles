-- box.lua
local config = require("boxed_comment.config")
local utils = require("boxed_comment.utils")

local M = {}

function M.format_box(lines, style_name, at_top)
  local prefix = utils.get_comment_prefix()
  local cfg = config.default_config
  local style = config.styles[style_name] or config.styles[cfg.style] or config.styles.unicode

  if cfg.strip_existing_comments then
    lines = utils.strip_comment_prefix(lines, prefix)
  end

  local max_width = cfg.max_width
  local padding = cfg.padding or 1

  local wrapped = utils.wrap_lines(lines, max_width)
  local max_len = 0
  for _, l in ipairs(wrapped) do
    max_len = math.max(max_len, #l)
  end
  max_len = max_len + padding * 2

  local centered = utils.center_lines(wrapped, max_len)

  local top = prefix .. " " .. style.tl .. style.hor:rep(max_len) .. style.tr
  local bot = prefix .. " " .. style.bl .. style.hor:rep(max_len) .. style.br

  local content = { top }
  for _, line in ipairs(centered) do
    table.insert(content, prefix .. " " .. style.ver .. line .. style.ver)
  end
  table.insert(content, bot)

  if at_top then
    vim.api.nvim_buf_set_lines(0, 0, 0, false, content)
  else
    vim.api.nvim_put(content, "l", true, true)
  end
end

return M
