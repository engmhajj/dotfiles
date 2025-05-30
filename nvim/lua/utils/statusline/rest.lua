local M = {}

function M.status()
  return vim.g.rest_status or "" -- Adapt if using a plugin
end

return M
