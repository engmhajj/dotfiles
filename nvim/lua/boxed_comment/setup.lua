local commands = require("boxed_comment.commands")
local config = require("boxed_comment.config")

local M = {}
function M.setup(user_config)
  config.setup(user_config or {})

  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      local ft = vim.bo.filetype
      local filetype_style = config.default_config.filetype_styles[ft]
      if filetype_style and config.default_config.style ~= filetype_style then
        config.default_config.style = filetype_style
      end
    end,
  })

  commands.setup_commands()
  commands.setup_keymaps()
end

return M
