if not require("fredrik.config").pde.csharp then
  return {}
end
return {

  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "netcoredbg" })
    end,
  },

  {
    "GustavEikaas/easy-dotnet.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    config = function()
      local function get_secret_path(secret_guid)
        local path = ""
        local home_dir = vim.fn.expand("~")
        if require("easy-dotnet.extensions").isWindows() then
          local secret_path = home_dir
            .. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\"
            .. secret_guid
            .. "\\secrets.json"
          path = secret_path
        else
          local secret_path = home_dir .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
          path = secret_path
        end
        return path
      end

      local dotnet = require("easy-dotnet")
      -- Options are not required
      dotnet.setup({
        --Optional function to return the path for the dotnet sdk (e.g C:/ProgramFiles/dotnet/sdk/8.0.0)
        -- easy-dotnet will resolve the path automatically if this argument is omitted, for a performance improvement you can add a function that returns a hardcoded string
        -- You should define this function to return a hardcoded path for a performance improvement 🚀
        get_sdk_path = "/usr/local/share/dotnet/sdk/9.0.200",
        ---@type TestRunnerOptions
        test_runner = {
          ---@type "split" | "float" | "buf"
          viewmode = "float",
          enable_buffer_test_execution = true, --Experimental, run tests directly from buffer
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
            debug_test_from_buffer = { lhs = "<leader>db", desc = "debug test from buffer" },
            run_test_from_buffer = { lhs = "<leader>r", desc = "run test from buffer" },
            filter_failed_tests = { lhs = "<leader>fe", desc = "filter failed tests" },
            debug_test = { lhs = "<leader>d", desc = "debug test" },
            go_to_file = { lhs = "g", desc = "got to file" },
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
          --- Optional table of extra args e.g "--blame crash"
          additional_args = {},
        },
        new = {
          project = {
            prefix = "sln", -- "sln" | "none"
          },
        },
        ---@param action "test" | "restore" | "build" | "run"
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
          --block_scoped, file_scoped
          type = "block_scoped",
          enabled = true,
        },
        -- choose which picker to use with the plugin
        -- possible values are "telescope" | "fzf" | "snacks" | "basic"
        -- if no picker is specified, the plugin will determine
        -- the available one automatically with this priority:
        -- telescope -> fzf -> snacks ->  basic
        picker = "telescope",
        background_scanning = true,
      })

      -- Example command
      vim.api.nvim_create_user_command("Secrets", function()
        dotnet.secrets()
      end, {})

      -- Example keybinding
      vim.keymap.set("n", "<C-p>", function()
        dotnet.run_project()
      end)
    end,
  },
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      config = {
        settings = {
          ["csharp|background_analysis"] = {
            dotnet_analyzer_diagnostics_scope = "fullSolution",
            dotnet_compiler_diagnostics_scope = "fullSolution",
            csharp_enable_background_analysis = true,
            csharp_enable_background_analysis_on_type = true,
            csharp_enable_background_analysis_on_text_changed = true,
          },
          ["csharp|code_action"] = {
            csharp_enable_code_action = true,
            csharp_enable_code_action_on_type = true,
            csharp_enable_code_action_on_text_changed = true,
          },
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
            dotnet_enable_rename_code_lens = true,
            dotnet_enable_tests_code_lens = true,
          },
          ["csharp|signature_help"] = {
            csharp_enable_signature_help_for_inferred_types = true,
            csharp_enable_signature_help_for_lambda_parameter_types = true,
            csharp_enable_signature_help_for_types = true,
            dotnet_enable_signature_help_for_indexer_parameters = true,
            dotnet_enable_signature_help_for_literal_parameters = true,
            dotnet_enable_signature_help_for_object_creation_parameters = true,
            dotnet_enable_signature_help_for_other_parameters = true,
            dotnet_enable_signature_help_for_parameters = true,
          },
          ["csharp|formatting"] = {
            csharp_format_on_type = true,
            csharp_format_on_save = true,
            otnet_organize_imports_on_format = true,
          },
          ["csharp|diagnostics"] = {
            csharp_enable_diagnostic = true,
            csharp_enable_diagnostic_on_save = true,
            csharp_enable_diagnostic_on_type = true,
            csharp_enable_diagnostic_on_text_changed = true,
            dotnet_organize_imports_on_format = true,
          },
          ["csharp|completion"] = {
            dotnet_provide_regex_completions = true,
            dotnet_show_completion_items_from_unimported_namespaces = true,
            dotnet_show_name_completion_suggestions = true,
            csharp_enable_completion = true,
            csharp_enable_completion_for_inferred_types = true,
            csharp_enable_completion_for_lambda_parameter_types = true,
            csharp_enable_completion_for_types = true,
            dotnet_enable_completion_for_indexer_parameters = true,
            dotnet_enable_completion_for_literal_parameters = true,
            dotnet_enable_completion_for_object_creation_parameters = true,
            dotnet_enable_completion_for_other_parameters = true,
            dotnet_enable_completion_for_parameters = true,
          },
          ["csharp|rename"] = {
            csharp_enable_rename = true,
            csharp_enable_rename_on_type = true,
            csharp_enable_rename_on_text_changed = true,
          },
          ["csharp|references"] = {
            csharp_enable_references = true,
            csharp_enable_references_on_type = true,
            csharp_enable_references_on_text_changed = true,
          },
          ["csharp|symbol_search"] = {
            dotnet_search_reference_assemblies = true,
          },
        },
      },
      -- your configuration comes here; leave empty for default settings
      -- NOTE: You must configure `cmd` in `config.cmd` unless you have installed via mason
      filewatching = "auto",

      -- Whether or not to look for solution files in the child of the (root).
      -- Set this to true if you have some projects that are not a child of the
      -- directory with the solution file
      broad_search = true,
    },
  },
}
