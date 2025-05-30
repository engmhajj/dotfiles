local function getCurrentFileDirName()
  local fullPath = vim.fn.expand("%:p:h") -- Get full path of current file's directory
  local dirName = fullPath:match("([^/\\]+)$") -- Extract just the directory name
  return dirName
end

return {

  {
    "GustavEikaas/easy-dotnet.nvim",
    -- event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    config = function()
      local function get_secret_path(secret_guid)
        local home_dir = vim.fn.expand("~")
        if require("easy-dotnet.extensions").isWindows() then
          return home_dir .. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\" .. secret_guid .. "\\secrets.json"
        else
          return home_dir .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
        end
      end

      local dotnet = require("easy-dotnet")

      local function create_migration()
        local migration_name = vim.fn.input("Enter migration name: ")
        vim.cmd("Dotnet ef migrations add " .. migration_name)
      end

      dotnet.setup({
        get_sdk_path = "/usr/local/share/dotnet/sdk/9.0.200",
        test_runner = {
          viewmode = "float",
          enable_buffer_test_execution = true,
          noBuild = true,
          noRestore = true,
          icons = {
            passed = "",
            skipped = "",
            failed = "",
            success = "",
            reload = "",
            test = "",
            sln = "󰘐",
            project = "󰘐",
            dir = "",
            package = "",
          },
          mappings = {
            vim.keymap.set("n", "<leader>ro", ":Dotnet<CR>", { desc = "[Dot]Net Open", noremap = true, silent = true }),
            vim.keymap.set(
              "n",
              "<leader>rm",
              create_migration,
              { desc = "Add Migration", noremap = true, silent = true }
            ),
            vim.keymap.set(
              "n",
              "<leader>ra",
              ":Dotnet ef database update<CR>",
              { desc = "[U]pdate Database", noremap = true, silent = true }
            ),
            vim.keymap.set("n", "<leader>re", function()
              dotnet.get_environment_variables(getCurrentFileDirName(), vim.fn.getcwd(), true)
            end, { desc = "[G]et Environment Variable", noremap = true, silent = true }),
            debug_test_from_buffer = { lhs = "<leader>db", desc = "debug test from buffer" },
            run_test_from_buffer = { lhs = "<leader>r", desc = "run test from buffer" },
            filter_failed_tests = { lhs = "<leader>fe", desc = "filter failed tests" },
            debug_test = { lhs = "<leader>d", desc = "debug test" },
            go_to_file = { lhs = "g", desc = "go to file" },
            run_all = { lhs = "<leader>R", desc = "run all tests" },
            run = { lhs = "<leader>r", desc = "run test" },
            peek_stacktrace = { lhs = "<leader>p", desc = "peek stacktrace of failed test" },
            expand = { lhs = "o", desc = "expand" },
            expand_node = { lhs = "E", desc = "expand node" },
            expand_all = { lhs = "-", desc = "expand all" },
            collapse_all = { lhs = "W", desc = "collapse all" },
            close = { lhs = "q", desc = "close testrunner" },
            refresh_testrunner = { lhs = "<C-r>", desc = "refresh testrunner" },
          },
          additional_args = {},
        },
        new = {
          project = {
            prefix = "sln", -- "sln" | "none"
          },
        },
        terminal = function(path, action, args)
          local commands = {
            run = function()
              return string.format("dotnet run --project %s %s", path, args)
            end,
            test = function()
              return string.format("dotnet test %s %s", path, args)
            end,
            restore = function()
              return string.format("dotnet restore %s %s", path, args)
            end,
            build = function()
              return string.format("dotnet build %s %s", path, args)
            end,
            watch = function()
              return string.format("dotnet watch --project %s %s", path, args)
            end,
          }
          local command = commands[action]() .. "\r"
          vim.cmd("vsplit")
          vim.cmd("term " .. command)
        end,
        secrets = {
          path = get_secret_path,
        },
        csproj_mappings = true,
        fsproj_mappings = true,
        auto_bootstrap_namespace = {
          type = "block_scoped",
          enabled = true,
        },
        picker = "telescope",
        background_scanning = true,
      })

      vim.api.nvim_create_user_command("Secrets", function()
        dotnet.secrets()
      end, {})
    end,
  },
}
