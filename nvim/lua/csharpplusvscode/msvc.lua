local dap = require("dap")
require("local_utils.configs")

local uv = vim.loop

local utils = require("dap.utils")

local rpc = require("dap.rpc")

local function send_payload(client, payload)
  local msg = rpc.msg_with_content_length(vim.json.encode(payload))
  client.write(msg)
end

DebugAdapterLocation = PathJoin({ "C:", "debugadapter" })
-- UserHome = PathJoin({"C:", "Users", "tsior"})
UserHome = vim.env.HOME

DebugPaths = {}

function SetDefaultLocation()
  local is_windows = vim.fn.has("win32") or vim.fn.has("win64")
  if vim.env.VIM_DEBUG_ADAPTERS then
    DebugAdapterLocation = vim.env.VIM_DEBUG_ADAPTERS
  end
  local cppdbg_debugger = {
    UserHome,
    ".vscode",
    "extensions",
    "ms-vscode.cpptools-1.18.5-win32-x64",
    "ms-vscode.cpptools-1.18.5-win32-x64",
    "debugAdapters",
    "bin",
  }
  if is_windows then
    table.insert(cppdbg_debugger, #cppdbg_debugger + 1, "OpenDebugAD7.exe")
  else
    table.insert(cppdbg_debugger, #cppdbg_debugger + 1, "OpenDebugAD7")
  end
  DebugPaths["cppdbg"] = PathJoin(cppdbg_debugger)
  DebugPaths["vsdbg"] = PathJoin({
    UserHome,
    ".vscode",
    "extensions",
    "ms-vscode.cpptools-1.18.5-win32-x64",
    "debugAdapters",
    "vsdbg",
    "bin",
    "vsdbg.exe",
  })
  DebugPaths["firefox"] = PathJoin({ DebugAdapterLocation, "vscode-firefox-debug", "dist", "adapter.bundle.js" })
  DebugPaths["chrome"] = PathJoin({ DebugAdapterLocation, "vscode-chrome-debug", "out", "src", "chromeDebug.js" })
  DebugPaths["node"] = PathJoin({ DebugAdapterLocation, "vscode-node-debug2", "out", "src", "nodeDebug.js" })
end

function RunHandshake(self, request_payload)
  local sign_file_location = PathJoin({ DebugAdapterLocation, "vsdbgsignature", "sign.js" })
  local signResult = io.popen("node " .. sign_file_location .. " " .. request_payload.arguments.value)
  if signResult == nil then
    utils.notify("error while signing handshake", vim.log.levels.ERROR)
    return
  end
  local signature = signResult:read("*a")
  signature = string.gsub(signature, "\n", "")
  local response = {
    type = "response",
    seq = 0,
    command = "handshake",
    request_seq = request_payload.seq,
    success = true,
    body = {
      signature = signature,
    },
  }
  send_payload(self.client, response)
end

--NOTE::DAp Config
local function LoadDapAdapters()
  local file = io.open(".dap-adapters.json", "r")
  local content = nil
  if file then
    local c = file:read("*a")
    content = vim.json.decode(c)
  end
  return content
end

function GetConfigs(dap)
  local configs = LoadDapAdapters()
  if not configs then
    return
  end
  for i, config in ipairs(configs) do
    local adapter = config.adapter
    local configuration = config.configuration
    local name = config.name
    configuration.name = name
    if not dap.configurations[config.language] then
      dap.configurations[config.language] = {}
    end
    if adapter then
      local adapter_name = "custom_adapter" .. i
      dap.adapters[adapter_name] = adapter
      configuration.type = adapter_name
    end
    table.insert(dap.configurations[config.language], 1, configuration)
  end
end

--Repel
local repl = require("dap.repl")

local ReplLog = {}

function ReplLog:write(chunk)
  if chunk then
    vim.schedule(function()
      repl.append(chunk)
    end)
  end
end

function ReplLog:close() end

function ReplLog:remove() end

function MakeReplLogger()
  local l = {}
  local logger = setmetatable(l, { __index = ReplLog })
  return logger
end

dap.adapters.coreclr = {
  id = "coreclr",
  type = "executable",
  command = "C:\\Users\\tsior\\.vscode\\extensions\\ms-dotnettools.csharp-2.39.29-win32-x64\\.debugger\\x86_64\\vsdbg-ui.exe",
  args = { "--interpreter=vscode" },
  options = {
    externalTerminal = true,
  },
  runInTerminal = true,
  reverse_request_handlers = {
    handshake = RunHandshake,
  },
}

dap.configurations.cs = {
  {
    name = "Try coreclr",
    type = "coreclr",
    request = "launch",
    program = function()
      -- return vim.fn.input('Path: ', vim.fn.getcwd() .. '\\bin\\Debug\\net7.0\\test.exe', 'file')
      return vim.fn.input(
        "Path: ",
        vim.fn.getcwd() .. "src\\MvcSample\\bin\\Debug\\netcoreapp2.2\\MvcSample.dll",
        "file"
      )
    end,
    cwd = vim.fn.getcwd(),
    clientID = "vscode",
    clientName = "Visual Studio Code",
    externalTerminal = true,
    columnsStartAt1 = true,
    linesStartAt1 = true,
    locale = "en",
    pathFormat = "path",
    externalConsole = true,
  },
}
