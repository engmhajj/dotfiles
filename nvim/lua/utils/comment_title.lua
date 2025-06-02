-- comment_title.lua
-- Boxed comment generator with floating input and telescope picker

local M = {}

-- =========================
-- DEFAULT CONFIGURATION
-- =========================
local config = {
  style = "fancy",
  max_width = 80,
  padding = 1,
  filetype_styles = {}, -- e.g. { lua = "double", python = "ascii" }
}

-- ╔═════════════════╗
-- ║  -- BOX STYLES  ║
-- ╚═════════════════╝
local styles = {
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

  -- Flames Style (fiery)
  flames = {
    tl = "🔥",
    tr = "🔥",
    bl = "🔥",
    br = "🔥",
    hor = "🔥",
    ver = "🔥",
    hl = "TitleFlames",
  },
  -- Japanese style Kawaii Boxes
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

-- =========================
-- UTILITIES
-- =========================

-- (*^▽^*)∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽(^▽^*)
-- ❖          -- Get comment prefix for current buffer          ❖
-- (^▽^*)∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽∽(*^▽^*)
local function get_comment_prefix()
  local cs = vim.bo.commentstring or ""
  local prefix = cs:match("^(.-)%%s") or "//"
  return prefix:gsub("%s+$", "")
end

-- (*^▽^*)══════════════════════════════════════════════════════════════════════════(^▽^*)
-- ❖          -- Wrap a single line into multiple lines by max width          ❖
-- (^▽^*)══════════════════════════════════════════════════════════════════════════(*^▽^*)
local function wrap_line(line, max_width)
  local words, current, wrapped = {}, "", {}
  for word in line:gmatch("%S+") do
    if #current + #word + 1 > max_width then
      table.insert(wrapped, current)
      current = word
    else
      current = current ~= "" and current .. " " .. word or word
    end
  end
  if current ~= "" then
    table.insert(wrapped, current)
  end
  return wrapped
end

local function wrap_lines(lines, max_width)
  local result = {}
  for _, line in ipairs(lines) do
    vim.list_extend(result, wrap_line(line, max_width))
  end
  return result
end

-- ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
-- ┃          -- Center lines inside width with spaces          ┃
-- ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢
local function center_lines(lines, width)
  local centered = {}
  for _, line in ipairs(lines) do
    local pad = math.floor((width - #line) / 2)
    local padded = string.rep(" ", pad) .. line
    table.insert(centered, padded .. string.rep(" ", width - #padded))
  end
  return centered
end

-- =========================
-- CORE BOX FORMATTING
-- =========================
local function format_box(lines, style_name, at_top)
  local prefix = get_comment_prefix()
  local style = styles[style_name] or styles[config.style] or styles.unicode

  local max_width = config.max_width
  local padding = config.padding or 1

  local wrapped = wrap_lines(lines, max_width)
  local max_len = 0
  for _, l in ipairs(wrapped) do
    max_len = math.max(max_len, #l)
  end

  max_len = max_len + padding * 2

  local centered = center_lines(wrapped, max_len)

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

-- =========================
-- FLOATING INPUT + TELESCOPE SELECTOR
-- =========================
local has_picker, pickers = pcall(require, "telescope.pickers")
if not has_picker then
  vim.notify("Telescope is not installed", vim.log.levels.ERROR)
  return
end
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
function M.floating_box_selector()
  local ok_floating, floating_input = pcall(require, "floating-input")
  local ok_telescope, telescope = pcall(require, "telescope")
  if not (ok_floating and ok_telescope) then
    vim.notify("Requires both 'floating-input' and 'telescope.nvim' plugins", vim.log.levels.ERROR)
    return
  end

  local input_opts = {
    prompt = "Enter Box Title (use \\n for multi-line):",
    default = "",
    on_confirm = function(title)
      if not title or title == "" then
        vim.notify("Empty input - cancelled", vim.log.levels.WARN)
        return
      end

      pickers
        .new({}, {
          prompt_title = "Choose Box Style",
          finder = finders.new_table({ results = vim.tbl_keys(styles) }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local entry = action_state.get_selected_entry()
              local style = entry and entry.value or config.style
              local lines = vim.split(title, "\\n", { plain = true })
              format_box(lines, style, false)
            end)
            return true
          end,
        })
        :find()
    end,
  }

  local ok, err = pcall(function()
    floating_input.input(input_opts)
  end)
  if not ok then
    vim.notify("floating-input failed: " .. tostring(err) .. "\nFalling back to vim.ui.input", vim.log.levels.WARN)

    -- fallback to native vim.ui.input
    vim.ui.input({ prompt = input_opts.prompt }, function(title)
      if not title or title == "" then
        vim.notify("Empty input - cancelled", vim.log.levels.WARN)
        return
      end

      pickers
        .new({}, {
          prompt_title = "Choose Box Style",
          finder = finders.new_table({ results = vim.tbl_keys(styles) }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local entry = action_state.get_selected_entry()
              local style = entry and entry.value or config.style
              local lines = vim.split(title, "\\n", { plain = true })
              format_box(lines, style, false)
            end)
            return true
          end,
        })
        :find()
    end)
  end
end

-- =========================
-- TELESCOPE PROMPT FOR MULTILINE INPUT
-- =========================
function M.telescope_box_prompt()
  local input_lines = {}

  local function on_done(prompt_bufnr)
    if #input_lines == 0 then
      vim.notify("No input provided", vim.log.levels.ERROR)
      return
    end
    actions.close(prompt_bufnr)
    format_box(input_lines, { at_top = false })
  end

  pickers
    .new({}, {
      prompt_title = "Box Comment Input (Enter adds line, <Esc> finishes)",
      finder = finders.new_table({ results = input_lines }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        local function safe_set_cursor(win, pos)
          if vim.api.nvim_win_is_valid(win) then
            pcall(vim.api.nvim_win_set_cursor, win, pos)
          end
        end

        map("i", "<CR>", function()
          local line = action_state.get_current_line()
          if line ~= "" then
            table.insert(input_lines, line)
            -- Update buffer with current lines
            vim.api.nvim_buf_set_lines(prompt_bufnr, 0, -1, false, input_lines)
            -- Set cursor safely to the new line at col 0
            safe_set_cursor(prompt_bufnr, { #input_lines + 1, 0 })
            -- Clear the prompt input line below (if any)
            vim.api.nvim_buf_set_lines(prompt_bufnr, #input_lines, #input_lines, false, { "" })
          end
        end)

        map("i", "<Esc>", function()
          on_done(prompt_bufnr)
        end)
        return true
      end,
    })
    :find()
end

-- =========================
-- COMMANDS & KEYMAPS
-- =========================

function M.setup(user_config)
  config = vim.tbl_deep_extend("force", config, user_config or {})

  -- Autodetect style per filetype if provided
  vim.api.nvim_create_autocmd("FileType", {
    callback = function()
      local ft = vim.bo.filetype
      if config.filetype_styles[ft] then
        config.style = config.filetype_styles[ft]
      end
    end,
  })

  -- ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
  -- ┃  -- Create user commands  ┃
  -- ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━◢
  vim.api.nvim_create_user_command("BoxComment", function(opts)
    local args = opts.fargs
    local at_top = false
    local style_name = config.style
    local title

    -- Check if first arg is "top" or a style
    if args[1] == "top" then
      at_top = true
      table.remove(args, 1)
    elseif styles[args[1]] then
      style_name = args[1]
      table.remove(args, 1)
    end

    title = table.concat(args, " ")
    if title == "" then
      vim.notify("No title provided", vim.log.levels.ERROR)
      return
    end

    local lines = vim.split(title, "\\n", { plain = true })
    format_box(lines, style_name, at_top)
  end, {
    nargs = "+",
    desc = "Insert boxed comment. Usage: BoxComment [top] [style] <text>",
  })

  -- ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
  -- ┃  -- Insert with prompt (multi-line allowed using \n)  ┃
  -- ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢

  vim.api.nvim_create_user_command("BoxCommentVisual", function()
    local start_pos = vim.fn.getpos("'<")[2]
    local end_pos = vim.fn.getpos("'>")[2]
    local lines = vim.api.nvim_buf_get_lines(0, start_pos - 1, end_pos, false)
    if #lines == 0 then
      vim.notify("No text selected", vim.log.levels.ERROR)
      return
    end

    local style_name = config.style
    local ft = vim.bo.filetype
    if config.filetype_styles[ft] then
      style_name = config.filetype_styles[ft]
    end

    format_box(lines, style_name, false)
  end, { range = true })

  -- ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
  -- ┃          -- Keymaps          ┃
  -- ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢
  vim.keymap.set("n", "<leader>bb", M.floating_box_selector, { desc = "Insert styled boxed comment" })
  vim.keymap.set("v", "<leader>bc", ":BoxCommentVisual<CR>", { desc = "Box visual selection" })
  vim.keymap.set("n", "<leader>bt", M.telescope_box_prompt, { desc = "Box Comment Telescope Prompt" })
  vim.keymap.set("n", "<leader>bc", function()
    vim.ui.input({ prompt = "Comment Title (\\n for multi-line):" }, function(input)
      if input and input ~= "" then
        vim.cmd("BoxComment " .. input)
      end
    end)
  end, { desc = "Insert boxed comment" })
end

-- =========================
-- Return module
-- =========================
return M
