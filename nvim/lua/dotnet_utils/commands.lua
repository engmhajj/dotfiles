local notify = require("dotnet_utils.notify")
local projects = require("dotnet_utils.projects")
local terminal = require("dotnet_utils.terminal")

local M = {}

local function execute(cmd)
  local last = vim.g.dotnet_utils.last_used_csproj
  if last and last ~= "" then
    terminal.open(cmd, last)
    return
  end

  local csproj_files = projects.get_all_csproj()
  if #csproj_files == 0 then
    notify.error("No .csproj files found")
    return
  end

  projects.pick_csproj(csproj_files, function(choice)
    if choice then
      vim.g.dotnet_utils.last_used_csproj = choice
      terminal.open(cmd, choice)
    else
      notify.error("Invalid .csproj selection")
    end
  end)
end

M.run = function()
  execute("dotnet run --project")
end

M.test = function()
  execute("dotnet test")
end

M.build = function()
  execute("dotnet build")
end

M.watch = function()
  execute("dotnet watch run --project")
end

M.run_all = function(cmd)
  projects.get_projects_from_solution(function(csproj_files)
    if not csproj_files or #csproj_files == 0 then
      notify.error("No .csproj files found")
      return
    end
    for _, file in ipairs(csproj_files) do
      local full_cmd = cmd .. ' --project "' .. file .. '"'
      local state = terminal.state()
      if state[file] and state[file].job_id then
        terminal.close(file)
      else
        terminal.open(full_cmd, file)
      end
    end
  end)
end

-- === Test Commands === --

M.run_and_show_tests = function()
  local last = vim.g.dotnet_utils.last_used_csproj
  local function run_tests(csproj)
    local cmd = 'dotnet test --logger "trx;LogFileName=Results.trx" --results-directory ./TestResults'
    terminal.open(cmd, csproj)
  end

  if last and vim.fn.filereadable(last) == 1 then
    run_tests(last)
  else
    local csproj_files = projects.get_all_csproj()
    if #csproj_files > 0 then
      projects.pick_csproj(csproj_files, run_tests)
    else
      notify.error("No .csproj files found")
    end
  end
end

M.show_test_results = function()
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
    notify.error("Test results not found")
  end
end

M.open_test_results_in_telescope = function()
  local ok, telescope = pcall(require, "telescope.builtin")
  if not ok then
    notify.error("Telescope not installed")
    return
  end

  local results_dir = "./TestResults"
  if vim.fn.isdirectory(results_dir) == 1 then
    telescope.find_files({ cwd = results_dir, prompt_title = "Test Results" })
  else
    notify.error("Test results directory not found")
  end
end

M.run_tests_with_neotest = function()
  local ok, neotest = pcall(require, "neotest")
  if not ok then
    notify.error("Neotest not installed")
    return
  end
  neotest.run.run()
end

M.switch_solution = function()
  local ok, telescope = pcall(require, "telescope.builtin")
  if not ok then
    notify.error("Telescope is not installed")
    return
  end

  local sln_files = vim.fn.glob("**/*.sln", true, true)
  if #sln_files == 0 then
    notify.error("No solution files found")
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
          notify.info("Switched to solution: " .. filepath)
        else
          notify.error("Invalid selection")
        end
      end)

      return true
    end,
  })
end

return M
