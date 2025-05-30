-- Utility: Delete all hidden, listed buffers to clean up session saves
local function delete_hidden_buffers()
  local visible = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.buflisted(buf) == 1 and not visible[buf] then
      local ok = pcall(vim.api.nvim_buf_delete, buf, { force = true })
      if not ok then
        vim.notify("Failed to delete buffer " .. buf, vim.log.levels.WARN)
      end
    end
  end
end

-- Toggle Copilot when a session is loaded
vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceLoadPost",
  callback = function()
    local ok, private = pcall(require, "utils.private")
    if ok and private.toggle_copilot then
      private.toggle_copilot()
    end
  end,
})

-- Clean up buffers before saving session
vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceSavePre",
  callback = function()
    delete_hidden_buffers()
  end,
})

return {
  {
    "folke/persistence.nvim",
    dependencies = { "folke/snacks.nvim" },
    event = "VimEnter",
    init = function()
      -- Set session options. See `:help sessionoptions`
      vim.opt.sessionoptions = {
        "buffers", "curdir", "folds", "help",
        "localoptions", "winpos", "winsize"
      }
    end,
    config = function(_, opts)
      require("persistence").setup(opts)
      -- Optional: Uncomment to auto-load the last session on startup
      -- vim.schedule(function()
      --   require("persistence").load()
      -- end)
    end,
    -- Snacks session picker is used for manual selection
  },
}
