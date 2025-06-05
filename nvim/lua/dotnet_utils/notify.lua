local M = {}

function M.error(msg)
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.ERROR)
  end)
end

function M.info(msg)
  vim.schedule(function()
    vim.notify(msg, vim.log.levels.INFO)
  end)
end

return M
