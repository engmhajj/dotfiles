-- utils/statusline/hostname.lua
local M = {}

local cached_hostname = nil

function M.get()
  if cached_hostname then
    return cached_hostname
  end

  if vim.loop.os_uname().sysname == "Windows_NT" then
    cached_hostname = os.getenv("COMPUTERNAME") or "unknown"
  else
    local handle = io.popen("uname -n")
    if handle then
      cached_hostname = handle:read("*l") or "unknown"
      handle:close()
    else
      cached_hostname = "unknown"
    end
  end

  return cached_hostname
end

return M
