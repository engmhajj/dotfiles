--- @param name string
--- @return string

local root_files = {
  "*.csproj",
  "*.sln",
  "Directory.Build.props",
  "Directory.Build.targets",
  ".git",
}

local omnisharp_bin = vim.fn.expand("~/.local/share/fredrik/mason/packages/omnisharp/OmniSharp")
local netcoredbg_bin = vim.fn.expand("~/.local/share/fredrik/mason/packages/netcoredbg/netcoredbg")

-- local plugin_directory = get_plugin_directory()
local netcoredbg_path = netcoredbg_bin

local pid = vim.fn.getpid()

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "c_sharp" })
    end,
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        cs = { "csharpier" },
      },
      formatters = {
        csharpier = {
          command = "dotnet-csharpier",
          args = { "--write-stdout" },
        },
      },
    },
  },

  {
    "virtual-lsp-config",
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
          {
            "williamboman/mason.nvim",
            opts = function(_, opts)
              opts.ensure_installed = opts.ensure_installed or {}
              vim.list_extend(opts.ensure_installed, {
                "csharp-language-server",
                "omnisharp",
                "xmlformatter",
                "csharpier",
                "prettier",
                "json-lsp",
              })
            end,
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {})
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        omnisharp = {
          organize_imports_on_format = true,
          enable_import_completion = true,
          cmd = { omnisharp_bin, "--languageserver", "--hostPID", tostring(pid) },
          -- root_markers = root_files,
          log_level = vim.lsp.protocol.MessageType.Debug,
          root_dir = function(fname)
            local primary = require("lspconfig").util.root_pattern("*.sln")(fname)
            local fallback = require("lspconfig").util.root_pattern("*.csproj")(fname)
            return primary or fallback
          end,
          filetypes = { "cs", "csproject" },
        },
      },
    },
  },

  {
    "nvim-neotest/neotest",
    requires = {
      {
        "Issafalcon/neotest-dotnet",
      },
      opts = function(_, opts)
        opts.adapters = opts.adapters or {}
        opts.adapters["neotest-dotnet"] = {
          runner = "cstest",
          -- args = { "--filter", "FullyQualifiedName~" .. vim.fn.expand("%:t:r") },
          -- args = { "--filter", "FullyQualifiedName~" .. vim.fn.expand("%:t") },
          -- args = { "--filter", "FullyQualifiedName~" .. vim.fn.expand("%:r") },
          args = { "--filter", "FullyQualifiedName~" .. vim.fn.expand("%:t") },
          dap = { justMyCode = false },
        }
      end,
    },
  },

  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = {
          "williamboman/mason.nvim",
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "neotest-dotnet", "coreclr", "netcoredbg" })
        end,
      },
    },
    opts = function()
      local dap = require("dap")

      dap.adapters.cs = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }

      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }
      local dotnet_build_project = function()
        local default_path = vim.fn.getcwd() .. "/"

        local number_indices = function(array)
          local result = {}
          for i, value in ipairs(array) do
            result[i] = i .. ": " .. value
          end
          return result
        end

        local display_options = function(prompt_title, options)
          options = number_indices(options)
          table.insert(options, 1, prompt_title)

          local choice = vim.fn.inputlist(options)

          if choice > 0 then
            return options[choice + 1]
          else
            return nil
          end
        end

        local file_selection = function(cmd, opts)
          local results = vim.fn.systemlist(cmd)

          if #results == 0 then
            print(opts.empty_message)
            return
          end

          if opts.allow_multiple then
            return results
          end

          local result = results[1]
          if #results > 1 then
            result = display_options(opts.multiple_title_message, results)
          end

          return result
        end

        local project_selection = function(project_path, allow_multiple)
          local check_csproj_cmd = string.format('find %s -type f -name "*.csproj"', project_path)
          local project_file = file_selection(check_csproj_cmd, {
            empty_message = "No csproj files found in " .. project_path,
            multiple_title_message = "Select project:",
            allow_multiple = allow_multiple,
          })
          return project_file
        end
        local project_file = project_selection(project_path)
        if project_file == nil then
          return
        end
        local project_name = vim.fn.fnamemodify(project_file, ":t:r")

        if vim.g["dotnet_last_proj_path"] ~= nil then
          default_path = vim.g["dotnet_last_proj_path"]
        end

        local path = vim.fn.input("Path to your *proj file", default_path .. project_name .. ".csproj", "file")

        vim.g["dotnet_last_proj_path"] = path

        local cmd = "dotnet build -c Debug " .. path .. " > /dev/null"

        print("")
        print("Cmd to execute: " .. cmd)

        local f = os.execute(cmd)

        if f == 0 then
          print("\nBuild: ✔️ ")
        else
          print("\nBuild: ❌ (code: " .. f .. ")")
        end
      end

      local dotnet_get_dll_path = function()
        local request = function()
          return vim.fn.input(
            "Path to dll to debug: ",
            vim.fn.getcwd() .. "/bin/Debug/" .. "project_name" .. ".dll",
            "file"
          )
        end

        if vim.g["dotnet_last_dll_path"] == nil then
          vim.g["dotnet_last_dll_path"] = request()
        else
          if vim.fn.confirm("Change the path to dll?\n" .. vim.g["dotnet_last_dll_path"], "&yes\n&no", 2) == 1 then
            vim.g["dotnet_last_dll_path"] = request()
          end
        end

        return vim.g["dotnet_last_dll_path"]
      end
      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch - coreclr (nvim-dap)",
          request = "launch",
          program = function()
            if vim.fn.confirm("Rebuild first?", "&yes\n&no", 2) == 1 then
              dotnet_build_project()
            end

            return dotnet_get_dll_path()
          end,
        },
      }

      dap.configurations.cpp = {
        {
          name = "Launch an executable",
          type = "cppdbg",
          request = "launch",
          cwd = "${workspaceFolder}",
          program = function()
            return coroutine.create(function(coro)
              local pickers = require("telescope.pickers")
              local finders = require("telescope.finders")
              local conf = require("telescope.config").values
              local actions = require("telescope.actions")
              local action_state = require("telescope.actions.state")
              local opts = {}
              pickers
                .new(opts, {
                  prompt_title = "Path to executable",
                  finder = finders.new_oneshot_job({ "fd", "--hidden", "--no-ignore", "--type", "x" }, {}),
                  sorter = conf.generic_sorter(opts),
                  attach_mappings = function(buffer_number)
                    actions.select_default:replace(function()
                      actions.close(buffer_number)
                      coroutine.resume(coro, action_state.get_selected_entry()[1])
                    end)
                    return true
                  end,
                })
                :find()
            end)
          end,
        },
      }

      vim.api.nvim_create_user_command("RunScriptWithArgs", function(t)
        -- :help nvim_create_user_command
        args = vim.split(vim.fn.expand(t.args), "\n")
        approval = vim.fn.confirm(
          "Will try to run:\n    "
            .. vim.bo.filetype
            .. " "
            .. vim.fn.expand("%")
            .. " "
            .. t.args
            .. "\n\n"
            .. "Do you approve? ",
          "&Yes\n&No",
          1
        )
        if approval == 1 then
          dap.run({
            type = vim.bo.filetype,
            request = "launch",
            name = "Launch file with custom arguments (adhoc)",
            program = "${file}",
            args = args,
          })
        end
      end, {
        complete = "file",
        nargs = "*",
      })
      vim.keymap.set("n", "<leader>R", ":RunScriptWithArgs ")
    end,
  },
}
