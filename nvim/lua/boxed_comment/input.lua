local config = require("boxed_comment.config")
local styles = config.styles
local box = require("boxed_comment.box")

local M = {}

local function open_style_picker(lines)
  vim.ui.select(vim.tbl_keys(styles), {
    prompt = "Choose Box Style:",
  }, function(choice)
    if not choice then
      vim.notify("No style selected", vim.log.levels.WARN)
      return
    end
    box.format_box(lines, choice, false)
  end)
end

function M.floating_box_selector()
  vim.ui.input({ prompt = "Enter Box Title (\\n for multi-line):" }, function(input)
    if not input or input == "" then
      vim.notify("Empty input - cancelled", vim.log.levels.WARN)
      return
    end
    local lines = vim.split(input, "\\n", { plain = true })
    open_style_picker(lines)
  end)
end

return M
