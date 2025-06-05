local M = {}

local commands = require("dotnet_utils.commands")
local config = require("dotnet_utils.config")
local integration = require("dotnet_utils.integration")
local terminal = require("dotnet_utils.terminal")
M.floating_terminal = require("dotnet_utils.floating_terminal")
M.setup = config.setup
M.run = commands.run
M.test = commands.test
M.build = commands.build
M.watch = commands.watch
M.run_all = commands.run_all
M.close_all_terminals = terminal.close_all
M.list_terminals = terminal.list
M.cycle_terminal = terminal.cycle
M.run_and_show_tests = commands.run_and_show_tests
M.show_test_results = commands.show_test_results
M.open_test_results_in_telescope = commands.open_test_results_in_telescope
M.run_tests_with_neotest = commands.run_tests_with_neotest
M.switch_solution = commands.switch_solution
integration.register_user_commands()
return M
