local M = {}

function M.name()
  local ok, lib = pcall(require, "auto-session.lib")
  if not ok then
    return ""
  end
  return lib.current_session_name(true) or ""
end

return M
