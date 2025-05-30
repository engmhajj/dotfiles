local M = {}

local notify_error = function(msg)
  vim.notify(msg, vim.log.levels.ERROR)
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

local is_valid_csproj = function(path)
  return path and path:match("%.csproj$")
end

local pick_csproj = function(csproj_files, callback)
  vim.ui.select(csproj_files, {
    prompt = "Select a .csproj file",
    format_item = function(item)
      local filename = vim.fs.basename(item)
      local icon = "󰈙 " -- fallback if mini.icons not available
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

local execute = function(cmd)
  local terminal_opts = {}
  local last = vim.g.dotnet_utils.last_used_csproj

  if last and is_valid_csproj(last) then
    require("snacks.terminal").toggle(cmd .. last, terminal_opts)
  else
    local csproj_files = get_all_csproj()
    if #csproj_files > 0 then
      pick_csproj(csproj_files, function(choice)
        require("snacks.terminal").toggle(cmd .. choice, terminal_opts)
      end)
    end
  end
end

function M.build()
  execute("dotnet build ")
end

function M.watch()
  execute("dotnet watch --project ")
end

function M.reset()
  vim.g.dotnet_utils.last_used_csproj = nil
  vim.notify("Cleared last selected .csproj", vim.log.levels.INFO)
end

function M.setup()
  vim.g.dotnet_utils = {
    last_used_csproj = nil,
  }

  vim.keymap.set("n", "<leader>rb", M.build, { desc = "Build project", noremap = true })
  vim.keymap.set("n", "<leader>rc", M.watch, { desc = "Watch project", noremap = true })
  vim.keymap.set("n", "<leader>rr", M.reset, { desc = "Reset selected project", noremap = true })
end

return M
