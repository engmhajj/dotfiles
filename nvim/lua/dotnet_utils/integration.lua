local notify = require("dotnet_utils.notify")
local projects = require("dotnet_utils.projects")

local M = {}

function M.register_user_commands()
  vim.api.nvim_create_user_command("DotnetSelectSolution", function()
    local sln_files = vim.fn.glob("*.sln", false, true)
    if #sln_files == 0 then
      notify.error("No solution files found")
      return
    end
    projects.pick_sln_file(sln_files, function(selected)
      if selected then
        vim.g.dotnet_utils.last_used_sln = selected
        notify.info("Selected solution: " .. selected)
      end
    end)
  end, {})
end

return M
