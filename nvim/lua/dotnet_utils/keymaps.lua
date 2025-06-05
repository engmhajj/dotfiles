local dotnet = require("dotnet_utils")
local M = {}

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = "[Dotnet] " .. desc, noremap = true, silent = true })
end

function M.setup()
  -- Core
  map("n", "<leader>hr", dotnet.run, "Run")
  map("n", "<leader>ha", function()
    dotnet.run_all("dotnet run")
  end, "Run All Project")
  vim.keymap.set("n", "<leader>hA", function()
    dotnet.run_all("dotnet watch run")
  end, { desc = "Dotnet Watch All Projects" })
  map("n", "<leader>hb", dotnet.build, "Build")
  map("n", "<leader>ht", dotnet.test, "Test")
  map("n", "<leader>hw", dotnet.watch, "Watch")

  -- Terminal
  map("n", "<leader>hx", dotnet.close_all_terminals, "Close All Terminals")
  map("n", "<leader>hl", dotnet.list_terminals, "List Terminals")
  map("n", "<leader>hn", function()
    dotnet.cycle_terminal(true)
  end, "Next Terminal")
  map("n", "<leader>dp", function()
    dotnet.cycle_terminal(false)
  end, "Previous Terminal")

  -- Tests
  map("n", "<leader>hT", dotnet.run_and_show_tests, "Run + Show Tests")
  map("n", "<leader>ho", dotnet.show_test_results, "Open Test Results")
  map("n", "<leader>hO", dotnet.open_test_results_in_telescope, "Telescope: Test Results")
  map("n", "<leader>hN", dotnet.run_tests_with_neotest, "Neotest: Run Tests")

  -- Misc
  map("n", "<leader>hS", dotnet.switch_solution, "Switch Solution")
  map("n", "<leader>hs", "<cmd>DotnetSelectSolution<CR>", "Select Solution (Manual)")
  -- Open floating terminal with project picker, run `dotnet run --project <csproj>`
  vim.keymap.set("n", "<leader>hF", function()
    dotnet.floating_terminal.pick_and_run("dotnet run --project")
  end, { desc = "Dotnet floating terminal: run project" })

  -- List and focus floating terminal
  vim.keymap.set("n", "<leader>hL", function()
    local terminals = dotnet.floating_terminal.list()
    if #terminals == 0 then
      vim.notify("No floating terminals open", vim.log.levels.INFO)
      return
    end

    vim.ui.select(terminals, {
      prompt = "Select floating terminal to focus",
      format_item = function(item)
        return vim.fn.fnamemodify(item, ":t")
      end,
    }, function(choice)
      if choice then
        dotnet.floating_terminal.focus(choice)
      end
    end)
  end, { desc = "Dotnet floating terminal: list and focus" })
end
vim.keymap.set("n", "<leader>hf", function()
  dotnet.floating_terminal.pick_project(function(project)
    vim.g.dotnet_utils_last_used_csproj = project
    dotnet.floating_terminal.open(project, "dotnet run --project " .. vim.fn.shellescape(project))
  end)
end, { desc = "Dotnet: Run floating terminal for selected project" })

return M
