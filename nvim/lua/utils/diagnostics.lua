M = {}

---@param diagnostic table
local function prefix(diagnostic)
  local icons = require("utils.icons").icons.diagnostics
  for d, icon in pairs(icons) do
    if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
      return icon
    end
  end
end

function M.setup_diagnostics()
  ---@class vim.diagnostic.Opts?
  local opts = {
    enable = false,

    virtual_lines = false,
    -- virtual_lines = {
    --   -- Only show virtual line diagnostics for the current cursor line
    --   current_line = false,
    -- },
    -- virtual_text = false,
    virtual_text = function(_, _)
      --   ---@class vim.diagnostic.Opts.VirtualText
      return { spacing = 4, source = "if_many", prefix = prefix }
    end,

    underline = true,
    update_in_insert = false,
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = require("utils.icons").icons.diagnostics.Error,
        [vim.diagnostic.severity.WARN] = require("utils.icons").icons.diagnostics.Warn,
        [vim.diagnostic.severity.HINT] = require("utils.icons").icons.diagnostics.Hint,
        [vim.diagnostic.severity.INFO] = require("utils.icons").icons.diagnostics.Info,
      },
    },
  }

  -- set diagnostic icons
  for name, icon in pairs(require("utils.icons").icons.diagnostics) do
    name = "DiagnosticSign" .. name
    vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
  end

  vim.diagnostic.config(vim.deepcopy(opts))

  require("config.keymaps").setup_diagnostics_keymaps()
end

-- Open a floating window with diagnostics for the current line
function M.open_float_diagnostics()
  local opts = {
    focusable = false,
    close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
    border = "rounded",
    source = "always",
    prefix = " ",
    scope = "line",
  }

  vim.diagnostic.open_float(nil, opts)
end

function M.open_buffer_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)
  if #diagnostics == 0 then
    print("No diagnostics in current buffer")
    return
  end

  local lines = {}
  for _, diag in ipairs(diagnostics) do
    table.insert(
      lines,
      string.format("%s [%s] %s", diag.lnum + 1, vim.diagnostic.severity[diag.severity], diag.message)
    )
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = 50
  local height = #lines
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
  }

  vim.api.nvim_open_win(buf, true, opts)
end

return M
