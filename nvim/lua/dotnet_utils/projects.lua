local notify = require("dotnet_utils.notify")
local utils = require("dotnet_utils.utils")

local M = {}

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

function M.pick_csproj(csproj_files, callback)
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
    if utils.is_valid_csproj(choice) then
      vim.g.dotnet_utils.last_used_csproj = choice
      callback(choice)
    else
      notify.error("Invalid .csproj selection")
    end
  end)
end

function M.pick_sln_file(sln_files, callback)
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
      notify.error("Invalid solution selection")
    end
  end)
end

function M.parse_sln_projects(sln_path)
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

function M.get_projects_from_solution(callback)
  local last = vim.g.dotnet_utils.last_used_sln
  local sln_files = vim.fn.glob("*.sln", false, true)

  if last and vim.fn.filereadable(last) == 1 then
    callback(M.parse_sln_projects(last))
  elseif #sln_files == 0 then
    callback(M.get_all_csproj())
  elseif #sln_files == 1 then
    vim.g.dotnet_utils.last_used_sln = sln_files[1]
    callback(M.parse_sln_projects(sln_files[1]))
  else
    M.pick_sln_file(sln_files, function(selected)
      if selected then
        vim.g.dotnet_utils.last_used_sln = selected
        callback(M.parse_sln_projects(selected))
      else
        notify.error("No solution selected")
      end
    end)
  end
end

return M
