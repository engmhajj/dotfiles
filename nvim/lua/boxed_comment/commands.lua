-- commands.lua
local M = {}

local box = require("boxed_comment.box")
local config = require("boxed_comment.config")
local input = require("boxed_comment.input")

-- Command for inserting boxed comment with arguments
function M.box_comment_command(opts)
  local args = opts.fargs
  local at_top = false
  local style_name = config.default_config.style

  if args[1] == "top" then
    at_top = true
    table.remove(args, 1)
  elseif style_name and config.styles[args[1]] then
    style_name = args[1]
    table.remove(args, 1)
  end

  local title = table.concat(args, " ")
  if title == "" then
    vim.notify("No title provided", vim.log.levels.ERROR)
    return
  end

  local lines = vim.split(title, "\\n", { plain = true })
  box.format_box(lines, style_name, at_top)
end

-- Command for visual selection boxing
function M.box_comment_visual()
  local start_pos = vim.fn.getpos("'<")[2]
  local end_pos = vim.fn.getpos("'>")[2]
  local lines = vim.api.nvim_buf_get_lines(0, start_pos - 1, end_pos, false)
  if #lines == 0 then
    vim.notify("No text selected", vim.log.levels.ERROR)
    return
  end

  local style_name = config.default_config.style
  local ft = vim.bo.filetype
  if config.default_config.filetype_styles[ft] then
    style_name = config.default_config.filetype_styles[ft]
  end

  box.format_box(lines, style_name, false)
end

function M.setup_commands()
  vim.api.nvim_create_user_command("BoxComment", M.box_comment_command, {
    nargs = "+",
    desc = "Insert boxed comment. Usage: BoxComment [top] [style] <text>",
  })

  vim.api.nvim_create_user_command("BoxCommentVisual", M.box_comment_visual, {
    range = true,
    desc = "Box visual selection",
  })
end

function M.setup_keymaps()
  vim.keymap.set("n", "<leader>ca", input.floating_box_selector, { desc = "Insert styled boxed comment" })
  vim.keymap.set("v", "cc", ":BoxCommentVisual<CR>", { desc = "Box visual selection" })
  vim.keymap.set("n", "cc", function()
    vim.ui.input({ prompt = "Comment Title (\\n for multi-line):" }, function(input)
      if input and input ~= "" then
        vim.cmd("BoxComment " .. input)
      end
    end)
  end, { desc = "Insert boxed comment" })
end

return M
