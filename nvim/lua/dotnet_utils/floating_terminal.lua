local notify = require("dotnet_utils.notify")

local M = {}

-- Store terminals indexed by key (e.g. csproj path)
local terminals = {}

local floating_terminals = {}

-- add naming to terminal
function M.get_project_display_name(path)
  if not path then
    return "[dotnet]"
  end
  local project_name = vim.fn.fnamemodify(path, ":t:r")
  return "[dotnet] " .. project_name
end

-- open multiple terminal stach
function M.open(key, cmd)
  if floating_terminals[key] then
    M.focus(key)
    return
  end

  local width = math.floor(vim.o.columns * 0.3)
  local height = 15
  local x = vim.o.columns - width - 2

  -- Stack vertically: calculate Y offset based on open terminals
  local count = vim.tbl_count(floating_terminals)
  local spacing = 1
  local y = 1 + count * (height + spacing)

  -- Prevent overflow
  if y + height > vim.o.lines - 2 then
    y = 2
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = x,
    row = y,
    border = "rounded",
    style = "minimal",
  })

  local job_id = vim.fn.termopen(cmd or ("dotnet run --project " .. vim.fn.shellescape(key)), {
    on_exit = function(_, code)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        floating_terminals[key] = nil
        vim.notify("[dotnet] Floating terminal exited (key: " .. key .. ", code: " .. code .. ")")
      end)
    end,
  })

  vim.api.nvim_buf_set_name(buf, "[dotnet-floating-terminal] " .. key)
  floating_terminals[key] = { win = win, buf = buf, job_id = job_id }
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload", "BufDelete" }, {
    buffer = buf,
    once = true,
    callback = function()
      if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end

      if job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1 then
        vim.fn.jobstop(job_id)
      end

      terminals[key] = nil

      notify.info("Terminal [" .. key .. "] closed manually.")
    end,
  })

  vim.cmd("startinsert")
end

-- Floating window config (top-right)
local function get_floating_window_config()
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.3)
  local height = math.floor(ui.height * 0.3)
  return {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = 1,
    col = ui.width - width - 1,
  }
end

local function is_job_alive(job_id)
  if not job_id then
    return false
  end
  return vim.fn.jobwait({ job_id }, 0)[1] == -1
end
function M.pick_project(callback)
  local get_projects_from_solution = require("dotnet_utils.projects").get_projects_from_solution
  local pick_csproj = require("dotnet_utils.projects").pick_csproj

  get_projects_from_solution(function(projects)
    if not projects or #projects == 0 then
      vim.schedule(function()
        vim.notify("No projects found", vim.log.levels.ERROR)
      end)
      return
    end

    if #projects == 1 then
      callback(projects[1])
    else
      pick_csproj(projects, callback)
    end
  end)
end
function M.get_all_csproj()
  local ok, scandir = pcall(require, "plenary.scandir")
  if not ok then
    notify.error("plenary.scandir not installed")
    return {}
  end

  local cwd = vim.fn.getcwd():gsub("\\", "/")
  local files = scandir.scan_dir(cwd, {
    hidden = false,
    only_dirs = false,
    depth = 5,
    search_pattern = "%.csproj$",
  })

  if #files == 0 then
    notify.error("No .csproj files found in workspace")
  end

  return vim.tbl_map(function(path)
    return path:gsub("\\", "/")
  end, files)
end

local function is_valid_csproj(path)
  return path and path:match("%.csproj$")
end

--- Open or reuse floating terminal by key, run cmd
function M.run(key, cmd)
  local term = terminals[key]

  if term and vim.api.nvim_win_is_valid(term.win) and is_job_alive(term.job_id) then
    vim.api.nvim_set_current_win(term.win)
    vim.cmd("startinsert")
    vim.fn.chansend(term.buf, cmd .. "\n")
    return
  end

  if term then
    if vim.api.nvim_win_is_valid(term.win) then
      vim.api.nvim_win_close(term.win, true)
    end
    if is_job_alive(term.job_id) then
      vim.fn.jobstop(term.job_id)
    end
    terminals[key] = nil
  end

  local buf = vim.api.nvim_create_buf(false, true)
  if not buf then
    notify.error("Failed to create terminal buffer")
    return
  end

  local win_opts = get_floating_window_config()
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(buf, "filetype", "terminal")
  vim.api.nvim_buf_set_name(buf, M.get_project_display_name(key))

  local job_id = vim.fn.termopen(cmd, {
    on_exit = function(_, code)
      if code ~= 0 then
        notify.error("Terminal [" .. key .. "] exited with code: " .. code)
      else
        notify.info("Terminal [" .. key .. "] completed.")
      end
    end,
  })

  terminals[key] = {
    buf = buf,
    win = win,
    job_id = job_id,
  }

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    buffer = buf,
    once = true,
    callback = function()
      if is_job_alive(job_id) then
        vim.fn.jobstop(job_id)
      end
      terminals[key] = nil
      notify.info("Terminal [" .. key .. "] closed manually.")
    end,
  })

  vim.cmd("startinsert")
end

function M.close(key)
  local term = floating_terminals[key]
  if not term then
    return
  end

  if vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_close(term.win, true)
  end

  if term.job_id and vim.fn.jobwait({ term.job_id }, 0)[1] == -1 then
    vim.fn.jobstop(term.job_id)
  end

  floating_terminals[key] = nil
  vim.notify("[dotnet] Closed floating terminal: " .. key)
end

function M.close_all()
  for key, _ in pairs(floating_terminals) do
    M.close(key)
  end
end

function M.list()
  return vim.tbl_keys(terminals)
end

function M.focus(key)
  local term = terminals[key]
  if term and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_set_current_win(term.win)
    vim.cmd("startinsert")
  else
    notify.error("Terminal [" .. key .. "] is not valid or closed")
  end
end

-- New: pick a project and open floating terminal running a given cmd prefix
function M.pick_and_run(cmd_prefix)
  local csproj_files = M.get_all_csproj()
  if #csproj_files == 0 then
    notify.error("No .csproj files found")
    return
  end

  vim.ui.select(csproj_files, {
    prompt = "Select a .csproj file for floating terminal",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":t")
    end,
  }, function(choice)
    if is_valid_csproj(choice) then
      local full_cmd = cmd_prefix .. " " .. vim.fn.shellescape(choice)
      M.run(choice, full_cmd)
    else
      notify.error("Invalid .csproj selection")
    end
  end)
end

return M
