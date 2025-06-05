local config = {
  auto_close_terminals = false,
  auto_close_delay = 5000,
}

local M = {}

function M.setup(user_config)
  user_config = user_config or {}
  for k, v in pairs(user_config) do
    config[k] = v
  end
  vim.g.dotnet_utils = vim.g.dotnet_utils or {}
end

function M.get()
  return config
end

return M
