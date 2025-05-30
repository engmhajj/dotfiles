-- utils/statusline/lsp.lua
local M = {}

function M.status()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return "No LSP"
  end
  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return "LSP: " .. table.concat(names, ", ")
end

return M
