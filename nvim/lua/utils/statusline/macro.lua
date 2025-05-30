-- utils/statusline/macro.lua
local M = {}

function M.recording()
  local reg = vim.fn.reg_recording()
  return reg ~= "" and ("Recording @" .. reg) or ""
end

return M
