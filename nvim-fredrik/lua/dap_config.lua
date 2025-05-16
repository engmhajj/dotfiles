local function getCurrentFileDirName()
  local fullPath = vim.fn.expand("%:p:h") -- Get the full path of the directory containing the current file
  local dirName = fullPath:match("([^/\\]+)$") -- Extract the directory name
  return dirName
end

vim.g.dotnet_build_project = function()
  local default_path = vim.fn.getcwd() .. "/" .. getCurrentFileDirName() .. ".csproj"
  if vim.g["dotnet_last_proj_path"] ~= nil then
    default_path = vim.g["dotnet_last_proj_path"]
  end
  local path = vim.fn.input("Path to your *proj file", default_path, "file")
  vim.g["dotnet_last_proj_path"] = path
  local cmd = "dotnet build " .. path .. " > /dev/null"
  print("")
  print("Cmd to execute: " .. cmd)
  local f = os.execute(cmd)
  if f == 0 then
    print("\nBuild: ✔️ ")
  else
    print("\nBuild: ❌ (code: " .. f .. ")")
  end
end

vim.g.dotnet_get_dll_path = function()
  local request = function()
    return vim.fn.input(
      "Path to dll",
      vim.fn.getcwd() .. "/bin/Debug/net9.0/" .. getCurrentFileDirName() .. ".dll",
      "file"
    )
  end

  if vim.g["dotnet_last_dll_path"] == nil then
    vim.g["dotnet_last_dll_path"] = request()
  else
    if
      vim.fn.confirm("Do you want to change the path to dll?\n" .. vim.g["dotnet_last_dll_path"], "&yes\n&no", 2) == 1
    then
      vim.g["dotnet_last_dll_path"] = request()
    end
  end

  return vim.g["dotnet_last_dll_path"]
end
local function get_plugin_directory()
  local str = debug.getinfo(1, "S").source:sub(2)
  str = str:match("(.*/)") -- Get the directory of the current file
  return str:gsub("/[^/]+/[^/]+/$", "/") -- Go up two directories
end

local plugin_directory = get_plugin_directory()
local netcoredbg_path = plugin_directory .. "netcoredbg/build/src/netcoredbg"

local config = {
  {
    request = "launch",
    type = "cs",
    name = "launch",
    command = netcoredbg_path,
    args = { "--interpreter=vscode", "--engineLogging", "--consoleLogging" },
    cwd = "${fileDirname}" .. getCurrentFileDirName(),
    env = {
      ASPNETCORE_ENVIRONMENT = function()
        return vim.fn.input("ASPNETCORE_ENVIRONMENT: ", "Development")
      end,
      ASPNETCORE_URL = function()
        return vim.fn.input("ASPNETCORE_URL: ", "http://localhost:7500")
      end,
    },
    program = function()
      if vim.fn.confirm("Should I recompile first?", "&yes\n&no", 2) == 1 then
        vim.g.dotnet_build_project()
      end
      return vim.g.dotnet_get_dll_path()
    end,
  },
}
local dap = require("dap")
dap.configurations.cs = config
dap.configurations.fsharp = config
