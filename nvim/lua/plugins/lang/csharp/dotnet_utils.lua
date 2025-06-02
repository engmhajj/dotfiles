local M = {}
local pick_csproj = function(csproj_files, callback)
  vim.ui.select(csproj_files, {
    prompt = "Select a .csproj file",
    format_item = function(item)
      local filename = vim.fn.fnamemodify(item, ":t")
      local icon = "󰈙 "
      pcall(function()
        icon = require("mini.icons").get("file", filename)
      end)
      return icon .. " " .. filename:gsub("%.csproj$", "")
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
local has_telescope, telescope = pcall(require, "telescope.builtin")
local notify_error = function(msg)
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.ERROR)
  end)
end
local pick_csproj = function(csproj_files, callback)
  local has_telescope, telescope = pcall(require, "telescope.builtin")
  if not has_telescope then
    notify_error("Telescope is not installed")
    return
  end

  local entry_maker = function(entry)
    local filename = vim.fn.fnamemodify(entry, ":t")
    return {
      value = entry,
      display = filename:gsub("%.csproj$", ""),
      ordinal = filename,
      path = entry,
    }
  end

  telescope.find_files({
    prompt_title = "Select a .csproj file",
    cwd = vim.fn.getcwd(),
    find_command = { "fd", "--type", "f", "--extension", "csproj" },
    attach_mappings = function(_, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      map("i", "<CR>", function(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry and entry.path then
          callback(entry.path)
        else
          notify_error("Invalid project selected")
        end
      end)

      return true
    end,
    entry_maker = entry_maker,
  })
end

local pick_sln_file = function(sln_files, callback)
  vim.ui.select(sln_files, {
    prompt = "Select a .sln file",
    format_item = function(item)
      return "📦 " .. vim.fn.fnamemodify(item, ":t")
    end,
  }, function(choice)
    if choice and vim.fn.filereadable(choice) == 1 then
      callback(choice)
    else
      notify_error("Invalid solution selection")
    end
  end)
end
local parse_sln_projects = function(sln_path)
  local projects = {}
  for line in io.lines(sln_path) do
    local rel_path = line:match('Project%(.+%) = ".-", "(.-%.csproj)"')
    if rel_path then
      local full_path = vim.fn.fnamemodify(sln_path, ":p:h") .. "/" .. rel_path
      full_path = vim.fn.resolve(full_path):gsub("\\", "/")
      if vim.fn.filereadable(full_path) == 1 then
        table.insert(projects, full_path)
      end
    end
  end
  return projects
end
local get_projects_from_solution = function(callback)
  local sln_files = vim.fn.glob("*.sln", false, true)

  if #sln_files == 0 then
    callback(get_all_csproj()) -- fallback to raw scan
    return
  elseif #sln_files == 1 then
    callback(parse_sln_projects(sln_files[1]))
  else
    pick_sln_file(sln_files, function(selected)
      if selected then
        callback(parse_sln_projects(selected))
      else
        notify_error("No solution selected")
      end
    end)
  end
end

local is_job_alive = function(job_id)
  if not job_id then
    return false
  end
  local status = vim.fn.jobwait({ job_id }, 0)[1]
  return status == -1
end

local terminal_windows = {}

local function open_terminal(cmd, csproj_path)
  local key = csproj_path
  local existing = terminal_windows[key]

  -- Toggle: if terminal exists and job alive, close terminal and kill job
  if existing then
    if is_job_alive(existing.job_id) and vim.api.nvim_win_is_valid(existing.win) then
      vim.api.nvim_win_close(existing.win, true)
      vim.fn.jobstop(existing.job_id)
      terminal_windows[key] = nil
      return
    else
      terminal_windows[key] = nil
    end
  end

  -- Find first valid terminal window (for splitting)
  local first_term_win = nil
  for _, v in pairs(terminal_windows) do
    if vim.api.nvim_win_is_valid(v.win) then
      first_term_win = v.win
      break
    end
  end

  if not first_term_win then
    -- No terminal yet: open horizontal split bottom with fixed height 15
    vim.cmd("botright split")
    vim.cmd("resize 15")
    first_term_win = vim.api.nvim_get_current_win()
    vim.cmd("setlocal winfixheight")
  else
    -- Terminals exist: split first terminal vertically (side-by-side)
    vim.api.nvim_set_current_win(first_term_win)
    vim.cmd("vsplit")
    vim.cmd("vertical resize 80")
    vim.cmd("setlocal winfixwidth")
  end

  local project_name = vim.fn.fnamemodify(csproj_path, ":t:r") -- Extract filename without extension
  local buf_name = "[dotnet] " .. project_name

  local term_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(term_buf, buf_name)

  vim.api.nvim_buf_set_option(term_buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(term_buf, "filetype", "terminal")
  vim.api.nvim_buf_set_option(term_buf, "scrollback", 10000)

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, term_buf)

  local job_id = vim.fn.termopen(cmd .. " " .. csproj_path, {
    on_exit = function(_, code, _)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(term_buf) then
          vim.api.nvim_buf_delete(term_buf, { force = true })
        end
        terminal_windows[key] = nil
        if code ~= 0 then
          notify_error("Terminal exited with error code " .. code)
        end
      end)
    end,
  })

  terminal_windows[key] = { buf = term_buf, win = win, job_id = job_id }

  -- Autocmd to kill job if buffer is wiped/closed manually by user
  vim.api.nvim_create_autocmd({ "BufWipeout", "BufUnload" }, {
    buffer = term_buf,
    once = true,
    callback = function()
      if is_job_alive(job_id) then
        vim.fn.jobstop(job_id)
      end
      terminal_windows[key] = nil
    end,
  })

  vim.api.nvim_set_current_win(win)
  vim.cmd("startinsert")
end

local is_valid_csproj = function(path)
  return path and path:match("%.csproj$")
end

local get_all_csproj = function()
  local ok, scandir = pcall(require, "plenary.scandir")
  if not ok then
    notify_error("plenary not installed")
    return {}
  end

  local cwd = vim.fn.getcwd():gsub("\\", "/")
  local csproj_files = scandir.scan_dir(cwd, {
    hidden = false,
    only_dirs = false,
    depth = 5,
    search_pattern = "%.csproj$",
  })

  if #csproj_files == 0 then
    notify_error("No .csproj files found in workspace")
    return {}
  end

  return vim.tbl_map(function(path)
    return path:gsub("\\", "/")
  end, csproj_files)
end

local execute = function(cmd)
  local last = vim.g.dotnet_utils.last_used_csproj
  if last and last ~= "" then
    open_terminal(cmd, last)
  else
    local csproj_files = get_all_csproj()
    if #csproj_files > 0 then
      pick_csproj(csproj_files, function(choice)
        if choice then
          vim.g.dotnet_utils.last_used_csproj = choice
          open_terminal(cmd, choice)
        else
          notify_error("Invalid .csproj selection")
        end
      end)
    else
      notify_error("No .csproj files found")
    end
  end
end
function M.close_all_terminals()
  for _, v in pairs(terminal_windows) do
    if vim.api.nvim_win_is_valid(v.win) then
      vim.api.nvim_win_close(v.win, true)
    end
    if is_job_alive(v.job_id) then
      vim.fn.jobstop(v.job_id)
    end
  end
  terminal_windows = {}
  vim.notify("Closed all dotnet terminals", vim.log.levels.INFO)
end

function M.run_all(cmd)
  get_projects_from_solution(function(csproj_files)
    if not csproj_files or #csproj_files == 0 then
      notify_error("No .csproj files found")
      return
    end

    for _, csproj_path in ipairs(csproj_files) do
      local existing = terminal_windows[csproj_path]
      if existing and is_job_alive(existing.job_id) then
        vim.api.nvim_win_close(existing.win, true)
        vim.fn.jobstop(existing.job_id)
        terminal_windows[csproj_path] = nil
      else
        open_terminal(cmd, csproj_path)
      end
    end
  end)
end
-- used to toggle

-- ========================================
-- Testing
-- ========================================

local trouble_open = false

function M.run_and_show_tests()
  local cmd = 'dotnet test --logger "trx;LogFileName=Results.trx" --results-directory ./TestResults'

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      for _, line in ipairs(data or {}) do
        if line ~= "" then
          vim.schedule(function()
            vim.api.nvim_echo({ { line, "Normal" } }, false, {})
          end)
        end
      end
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify("✔ Tests completed", vim.log.levels.INFO)
        else
          vim.notify("❌ Test run failed", vim.log.levels.ERROR)
        end
        M.show_test_results()
      end)
    end,
  })
end

function M.show_test_results()
  local xml2lua = require("utils.xml2lua")
  local handler = require("utils.xmlhandler.tree")

  local file = io.open("TestResults/Results.trx", "r")
  if not file then
    vim.notify("Test result file not found", vim.log.levels.ERROR)
    return
  end

  local content = file:read("*all")
  file:close()

  local start = content:find("<%?xml")
  if not start then
    vim.notify("Invalid .trx file: no XML declaration", vim.log.levels.ERROR)
    return
  end
  content = content:sub(start)

  local h = handler:new()
  local parser = xml2lua.parser(h)

  local ok, err = pcall(function()
    parser:parse(content)
  end)
  if not ok then
    vim.notify("Failed to parse XML: " .. err, vim.log.levels.ERROR)
    return
  end

  local root = h.root
  if not root then
    vim.notify("Failed to parse root node", vim.log.levels.ERROR)
    return
  end

  -- ⛏️ Extract the only key, which should be TestRun
  local test_run_node = nil
  for k, v in pairs(root) do
    if type(k) == "table" and k.name == "TestRun" then
      test_run_node = v
      break
    elseif type(k) == "string" and k:match("TestRun") then
      test_run_node = v
      break
    end
  end

  if not test_run_node then
    vim.notify("⚠️ Could not locate <TestRun> node", vim.log.levels.ERROR)
    print("Root keys:", vim.inspect(root)) -- log keys for inspection
    return
  end

  -- Continue parsing ResultSummary -> RunInfos -> RunInfo
  local result_summary = nil
  for k, v in pairs(test_run_node) do
    if type(k) == "table" and k.name == "ResultSummary" then
      result_summary = v
      break
    end
  end

  if not result_summary then
    vim.notify("No ResultSummary found", vim.log.levels.WARN)
    return
  end

  local run_infos = nil
  for k, v in pairs(result_summary) do
    if type(k) == "table" and k.name == "RunInfos" then
      run_infos = v
      break
    end
  end

  if not run_infos or not run_infos.RunInfo then
    vim.notify("No RunInfo found in test results", vim.log.levels.WARN)
    return
  end

  local infos = run_infos.RunInfo
  if infos._attr then
    infos = { infos }
  end

  local diagnostics = {}
  for _, info in ipairs(infos) do
    local msg = info.Text and info.Text._text or "Unknown failure"
    table.insert(diagnostics, {
      bufnr = 0,
      lnum = 0,
      col = 0,
      severity = vim.diagnostic.severity.ERROR,
      message = msg,
      source = "dotnet-test",
    })
  end

  vim.diagnostic.set(vim.api.nvim_create_namespace("dotnet_test"), 0, diagnostics, {})

  local ok_trouble, trouble = pcall(require, "trouble")
  if ok_trouble then
    trouble.open()
    trouble_open = true
  end
end

function M.toggle_test_results()
  local ok, trouble = pcall(require, "trouble")
  if not ok then
    notify_error("Trouble.nvim not installed")
    return
  end

  if trouble_open then
    trouble.close()
  else
    trouble.open()
  end
  trouble_open = not trouble_open
end

function M.open_test_results_in_telescope()
  local ok, telescope = pcall(require, "telescope.builtin")
  if not ok then
    notify_error("Telescope not installed")
    return
  end

  telescope.diagnostics()
end

function M.build()
  execute("dotnet build --project")
end

function M.watch()
  execute("dotnet watch --project")
end

function M.reset()
  vim.g.dotnet_utils.last_used_csproj = nil
  vim.notify("Cleared last selected .csproj", vim.log.levels.INFO)
end

function M.setup()
  vim.g.dotnet_utils = {
    last_used_csproj = nil,
  }
  vim.api.nvim_create_user_command("DotnetSelectSolution", function()
    local sln_files = vim.fn.glob("*.sln", false, true)
    if #sln_files == 0 then
      notify_error("No solution files found")
      return
    end
    pick_sln_file(sln_files, function(selected)
      if selected then
        vim.g.dotnet_utils.last_used_sln = selected
        vim.notify("Selected solution: " .. selected, vim.log.levels.INFO)
      end
    end)
  end, {})

  function M.watch_all()
    M.run_all("dotnet watch --project")
  end

  -- Bind to a key

  vim.keymap.set("n", "<leader>rb", M.build, { desc = "Build project", noremap = true })
  vim.keymap.set("n", "<leader>rt", M.watch, { desc = "Watch project", noremap = true })
  vim.keymap.set("n", "<leader>rS", M.reset, { desc = "Reset selected project", noremap = true })
  vim.keymap.set("n", "<leader>rc", M.close_all_terminals, { desc = "Close all dotnet terminals" })
  vim.keymap.set("n", "<leader>ra", M.watch_all, { desc = "Watch all projects", noremap = true })
  vim.keymap.set("n", "<leader>rs", "<cmd>DotnetSelectSolution<CR>", { desc = "Watch all projects", noremap = true })
  vim.keymap.set("n", "<leader>rq", M.show_test_results, { desc = "Run Test", noremap = true, silent = true })
  vim.keymap.set("n", "<leader>rT", M.run_and_show_tests, { desc = "Run tests and show results", noremap = true })
  -- vim.keymap.set("n", "<leader>rT", M.toggle_test_results, { desc = "Toggle Test Results (Trouble)" })
  vim.keymap.set("n", "<leader>rR", M.open_test_results_in_telescope, { desc = "Open Test Results (Telescope)" })

  -- for the dotnet plugin
  --Dotnet key maps
  -- --
  -- vim.keymap.set("n", "<leader>rR", "<cmd>!dotnet run<CR>", { desc = "[D]otnet Run" })
  -- vim.keymap.set("n", "<leader>rb", "<cmd>!dotnet build<CR>", { desc = "[D]otnet [B]uild" })
  vim.keymap.set("n", "<leader>rA", "<cmd>DotnetUI project reference add<CR>", { desc = "[D]otnet [A]dd reference" })
  -- vim.keymap.set(
  --   "n",
  --   "<leader>rD",
  --   "<cmd>DotnetUI project reference remove<CR>",
  --   { desc = "[D]otnet [R]emove reference" }
  -- )
  vim.keymap.set("n", "<leader>rp", "<cmd>DotnetUI project package add<CR>", { desc = "[D]otnet [A]dd package" })
  vim.keymap.set("n", "<leader>rP", "<cmd>DotnetUI project package remove<CR>", { desc = "[D]otnet [R]emove package" })
  vim.keymap.set("n", "<leader>rf", "<cmd>DotnetUI file bootstrap<CR>", { desc = "[D]otnet [N]ew cs file" })
  vim.keymap.set("n", "<leader>rn", "<cmd>:DotnetUI new_item<CR>", { desc = "[D]otnet [N]ew item or project template" })
  -- vim.keymap.set("n", "<C-b>", ":lua vim.g.dotnet_build_project()<CR>", { noremap = true, silent = true })
  vim.keymap.set(
    "n",
    "<space>rW",
    "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",
    { desc = "[A]dd workspace folder" }
  )
  vim.keymap.set(
    "n",
    "<space>rx",
    "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
    { desc = "Remove workspace folder" }
  )

  vim.keymap.set(
    "n",
    "<space>rl",
    "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
    { desc = "List workspace folders" }
  )
  --
  -- Then bind keymap:
end

return M
