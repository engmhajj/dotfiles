local config = require("dotnet_utils.config").get()
local notify = require("dotnet_utils.notify")
local utils = require("dotnet_utils.utils")

local M = {}
local terminal_windows = {}

function M.close(key)
  local term = terminal_windows[key]
  if not term then
    return
  end

  if vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_close(term.win, true)
  end

  if utils.is_job_alive(term.job_id) then
    vim.fn.jobstop(term.job_id)
  end

  terminal_windows[key] = nil
  notify.info("[dotnet] Terminal closed: " .. key)
end

function M.open(cmd, csproj_path)
  local key = csproj_path
  local existing = terminal_windows[key]

  if existing and utils.is_job_alive(existing.job_id) and vim.api.nvim_win_is_valid(existing.win) then
    M.close(key)
    return
  elseif existing then
    terminal_windows[key] = nil
  end

  local first_term_win
  for _, term in pairs(terminal_windows) do
    if vim.api.nvim_win_is_valid(term.win) then
      first_term_win = term.win
      break
    end
  end

  if not first_term_win then
    vim.cmd("botright split | resize 15 | setlocal winfixheight")
    first_term_win = vim.api.nvim_get_current_win()
  else
    vim.api.nvim_set_current_win(first_term_win)
    vim.cmd("vsplit | vertical resize 80 | setlocal winfixwidth")
  end

  local project_name = vim.fn.fnamemodify(csproj_path, ":t:r")
  local buf_name = "[dotnet] " .. project_name
  local term_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(term_buf, buf_name)
  vim.api.nvim_buf_set_option(term_buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(term_buf, "filetype", "terminal")
  vim.api.nvim_buf_set_option(term_buf, "scrollback", 10000)

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, term_buf)

  local job_id = vim.fn.termopen(cmd .. " " .. csproj_path, {
    on_exit = function(_, code)
      vim.schedule(function()
        if config.auto_close_terminals then
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(term_buf) then
              vim.api.nvim_buf_delete(term_buf, { force = true })
            end
            terminal_windows[key] = nil
            notify.info("[dotnet] Terminal buffer auto-closed after exit.")
          end, config.auto_close_delay)
        else
          notify.info("[dotnet] Terminal exited with code " .. code .. ". Buffer kept open.")
        end

        if code ~= 0 then
          notify.error("[dotnet] Terminal exited with error code " .. code)
        end
      end)
    end,
  })

  terminal_windows[key] = { buf = term_buf, win = win, job_id = job_id }

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    buffer = term_buf,
    once = true,
    callback = function()
      if utils.is_job_alive(job_id) then
        vim.fn.jobstop(job_id)
      end
      terminal_windows[key] = nil
      notify.info("[dotnet] Terminal manually closed: " .. key)
    end,
  })

  vim.cmd("startinsert")
end

function M.close_all()
  for key in pairs(terminal_windows) do
    M.close(key)
  end
  notify.info("Closed all dotnet terminals")
end

function M.list()
  local keys = vim.tbl_keys(terminal_windows)
  if #keys == 0 then
    notify.info("No active dotnet terminals")
    return
  end
  vim.ui.select(keys, {
    prompt = "Select active dotnet terminal",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":t")
    end,
  }, function(choice)
    local term = terminal_windows[choice]
    if term and vim.api.nvim_win_is_valid(term.win) then
      vim.api.nvim_set_current_win(term.win)
      vim.cmd("startinsert")
    else
      notify.error("Terminal window not valid")
      terminal_windows[choice] = nil
    end
  end)
end

function M.cycle(next)
  local keys = vim.tbl_keys(terminal_windows)
  if #keys == 0 then
    notify.info("No active dotnet terminals")
    return
  end
  table.sort(keys)
  local current_win = vim.api.nvim_get_current_win()
  local idx = 1
  for i, k in ipairs(keys) do
    if terminal_windows[k].win == current_win then
      idx = i
      break
    end
  end
  local new_idx = (next and idx + 1 or idx - 1) % #keys
  if new_idx == 0 then
    new_idx = #keys
  end

  local term = terminal_windows[keys[new_idx]]
  if term and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_set_current_win(term.win)
    vim.cmd("startinsert")
  else
    notify.error("Terminal window not valid")
  end
end

function M.state()
  return terminal_windows
end

return M
