local M = {}

-- ┌─────────────────┐
-- │ Configuration │
-- └─────────────────┘

local config = {
  auto_close_terminals = false,
  auto_close_delay = 5000,
}

--  ┌─────────────────┐
--  │ Notifications │
--  └─────────────────┘
local function notify_error(msg)
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.ERROR)
  end)
end

local function notify_info(msg)
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.INFO)
  end)
end

--  ┌────────────────────────┐
--  │ -- === Utilities ===   │
--  └────────────────────────┘
local function is_valid_csproj(path)
  return path and path:match("%.csproj$")
end

local function is_job_alive(job_id)
  if not job_id then
    return false
  end
  return vim.fn.jobwait({ job_id }, 0)[1] == -1
end

--  ╔════════════════════════════════╗
--  ║ -- === Terminal Management === ║
--  ╚════════════════════════════════╝
local terminal_windows = {}

local function close_terminal(key)
  local term = terminal_windows[key]
  if not term then
    return
  end

  if vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_close(term.win, true)
  end

  if is_job_alive(term.job_id) then
    vim.fn.jobstop(term.job_id)
  end

  terminal_windows[key] = nil
  notify_info("[dotnet] Terminal closed: " .. key)
end

local function open_terminal(cmd, csproj_path)
  local key = csproj_path
  local existing = terminal_windows[key]

  if existing and is_job_alive(existing.job_id) and vim.api.nvim_win_is_valid(existing.win) then
    close_terminal(key)
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
            notify_info("[dotnet] Terminal buffer auto-closed after exit.")
          end, config.auto_close_delay)
        else
          notify_info("[dotnet] Terminal exited with code " .. code .. ". Buffer kept open.")
        end

        if code ~= 0 then
          notify_error("[dotnet] Terminal exited with error code " .. code)
        end
      end)
    end,
  })

  terminal_windows[key] = { buf = term_buf, win = win, job_id = job_id }

  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    buffer = term_buf,
    once = true,
    callback = function()
      if is_job_alive(job_id) then
        vim.fn.jobstop(job_id)
      end
      terminal_windows[key] = nil
      notify_info("[dotnet] Terminal manually closed: " .. key)
    end,
  })

  vim.cmd("startinsert")
end

--  ╔════════════════════════════════════════╗
--  ║ -- === File Scanning and Selection === ║
--  ╚════════════════════════════════════════╝
local function get_all_csproj()
  local ok, scandir = pcall(require, "plenary.scandir")
  if not ok then
    notify_error("plenary.scandir not installed")
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
    notify_error("No .csproj files found in workspace")
  end

  return vim.tbl_map(function(path)
    return path:gsub("\\", "/")
  end, files)
end

local function pick_csproj(csproj_files, callback)
  vim.ui.select(csproj_files, {
    prompt = "Select a .csproj file",
    format_item = function(item)
      local name = vim.fn.fnamemodify(item, ":t")
      local icon = "󰈙 "
      pcall(function()
        icon = require("mini.icons").get("file", name)
      end)
      return icon .. " " .. name:gsub("%.csproj$", "")
    end,
  }, function(choice)
    if is_valid_csproj(choice) then
      vim.g.dotnet_utils.last_used_csproj = choice
      callback(choice)
    else
      notify_error("Invalid .csproj selection")
    end
  end)
end

local function pick_sln_file(sln_files, callback)
  vim.ui.select(sln_files, {
    prompt = "Select a .sln file",
    format_item = function(item)
      return "📦 " .. vim.fn.fnamemodify(item, ":t")
    end,
  }, function(choice)
    if choice and vim.fn.filereadable(choice) == 1 then
      vim.g.dotnet_utils.last_used_sln = choice
      callback(choice)
    else
      notify_error("Invalid solution selection")
    end
  end)
end

local function parse_sln_projects(sln_path)
  local projects = {}
  for line in io.lines(sln_path) do
    local rel_path = line:match('Project%(.+%) = ".-", "(.-%.csproj)"')
    if rel_path then
      local full_path = vim.fn.resolve(vim.fn.fnamemodify(sln_path, ":p:h") .. "/" .. rel_path):gsub("\\", "/")
      if vim.fn.filereadable(full_path) == 1 then
        table.insert(projects, full_path)
      end
    end
  end
  return projects
end

local function get_projects_from_solution(callback)
  local last = vim.g.dotnet_utils.last_used_sln
  local sln_files = vim.fn.glob("*.sln", false, true)

  if last and vim.fn.filereadable(last) == 1 then
    callback(parse_sln_projects(last))
  elseif #sln_files == 0 then
    callback(get_all_csproj())
  elseif #sln_files == 1 then
    vim.g.dotnet_utils.last_used_sln = sln_files[1]
    callback(parse_sln_projects(sln_files[1]))
  else
    pick_sln_file(sln_files, function(selected)
      if selected then
        vim.g.dotnet_utils.last_used_sln = selected
        callback(parse_sln_projects(selected))
      else
        notify_error("No solution selected")
      end
    end)
  end
end

--  ╔══════════════════════════╗
--  ║ -- === Core Commands === ║
--  ╚══════════════════════════╝
local function execute(cmd)
  local last = vim.g.dotnet_utils.last_used_csproj
  if last and last ~= "" then
    open_terminal(cmd, last)
    return
  end

  local csproj_files = get_all_csproj()
  if #csproj_files == 0 then
    notify_error("No .csproj files found")
    return
  end

  pick_csproj(csproj_files, function(choice)
    if choice then
      vim.g.dotnet_utils.last_used_csproj = choice
      open_terminal(cmd, choice)
    else
      notify_error("Invalid .csproj selection")
    end
  end)
end

--  ╔═══════════════════════╗
--  ║ -- === Public API === ║
--  ╚═══════════════════════╝
function M.setup(user_config)
  user_config = user_config or {}
  for k, v in pairs(user_config) do
    config[k] = v
  end
  vim.g.dotnet_utils = vim.g.dotnet_utils or {}
end

function M.run()
  execute("dotnet run --project")
end
function M.test()
  execute("dotnet test")
end
function M.build()
  execute("dotnet build")
end
function M.watch()
  execute("dotnet watch run --project")
end

function M.run_all(cmd)
  get_projects_from_solution(function(csproj_files)
    if not csproj_files or #csproj_files == 0 then
      notify_error("No .csproj files found")
      return
    end
    for _, file in ipairs(csproj_files) do
      local full_cmd = cmd .. ' --project "' .. file .. '"'
      if terminal_windows[file] and is_job_alive(terminal_windows[file].job_id) then
        close_terminal(file)
      else
        open_terminal(full_cmd, file)
      end
    end
  end)
end

function M.close_all_terminals()
  for key in pairs(terminal_windows) do
    close_terminal(key)
  end
  notify_info("Closed all dotnet terminals")
end

function M.list_terminals()
  local keys = vim.tbl_keys(terminal_windows)
  if #keys == 0 then
    notify_info("No active dotnet terminals")
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
      notify_error("Terminal window not valid")
      terminal_windows[choice] = nil
    end
  end)
end

function M.cycle_terminal(next)
  local keys = vim.tbl_keys(terminal_windows)
  if #keys == 0 then
    notify_info("No active dotnet terminals")
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
    notify_error("Terminal window not valid")
  end
end

--  ╔══════════════════════════╗
--  ║ -- === Test Commands === ║
--  ╚══════════════════════════╝

function M.run_and_show_tests()
  local last = vim.g.dotnet_utils.last_used_csproj
  local function run_tests(csproj)
    local cmd = 'dotnet test --logger "trx;LogFileName=Results.trx" --results-directory ./TestResults'
    open_terminal(cmd, csproj)
  end

  if last and vim.fn.filereadable(last) == 1 then
    run_tests(last)
  else
    local csproj_files = get_all_csproj()
    if #csproj_files > 0 then
      pick_csproj(csproj_files, run_tests)
    else
      notify_error("No .csproj files found")
    end
  end
end

function M.show_test_results()
  local results_path = "./TestResults/Results.trx"
  if vim.fn.filereadable(results_path) == 1 then
    if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
      vim.cmd("silent !start " .. results_path)
    elseif vim.fn.has("macunix") == 1 then
      vim.cmd("silent !open " .. results_path)
    else
      vim.cmd("silent !xdg-open " .. results_path)
    end
  else
    notify_error("Test results not found")
  end
end

function M.open_test_results_in_telescope()
  local ok, telescope = pcall(require, "telescope.builtin")
  if not ok then
    notify_error("Telescope not installed")
    return
  end

  local results_dir = "./TestResults"
  if vim.fn.isdirectory(results_dir) == 1 then
    telescope.find_files({ cwd = results_dir, prompt_title = "Test Results" })
  else
    notify_error("Test results directory not found")
  end
end

--  ╔════════════════════════════════╗
--  ║ -- === Neotest Integration === ║
--  ╚════════════════════════════════╝

function M.run_tests_with_neotest()
  local ok, neotest = pcall(require, "neotest")
  if not ok then
    notify_error("Neotest not installed")
    return
  end
  neotest.run.run()
end

-- ╔══════════════════════════════════════════════╗
-- ║ -- === Solution Switching with Telescope === ║
-- ╚══════════════════════════════════════════════╝

function M.switch_solution()
  local ok, telescope = pcall(require, "telescope.builtin")
  if not ok then
    notify_error("Telescope is not installed")
    return
  end

  local sln_files = vim.fn.glob("**/*.sln", true, true)
  if #sln_files == 0 then
    notify_error("No solution files found")
    return
  end

  telescope.find_files({
    prompt_title = "Select a .sln file",
    cwd = vim.fn.getcwd(),
    find_command = { "fd", "--type", "f", "--extension", "sln" },
    attach_mappings = function(_, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      map("i", "<CR>", function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local filepath = entry and (entry.path or entry.value or entry[1])
        if filepath then
          filepath = vim.fn.fnamemodify(filepath, ":p")
          vim.g.dotnet_utils.last_used_sln = filepath
          notify_info("Switched to solution: " .. filepath)
        else
          notify_error("Invalid selection")
        end
      end)

      return true
    end,
  })
end

-- ╔═════════════════════════╗
-- ║ -- === User Command === ║
-- ╚═════════════════════════╝

vim.api.nvim_create_user_command("DotnetSelectSolution", function()
  local sln_files = vim.fn.glob("*.sln", false, true)
  if #sln_files == 0 then
    notify_error("No solution files found")
    return
  end
  pick_sln_file(sln_files, function(selected)
    if selected then
      vim.g.dotnet_utils.last_used_sln = selected
      notify_info("Selected solution: " .. selected)
    end
  end)
end, {})

return M
