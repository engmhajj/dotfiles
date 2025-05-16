if not require("fredrik.config").pde.csharp then
  return {}
end

--- @param name string
--- @return string

local omnisharp_bin = "/Users/mohamadelhajhassan/.local/share/fredrik/mason/packages/omnisharp/OmniSharp"

local function getCurrentFileDirName()
  local fullPath = vim.fn.expand("%:p:h") -- Get the full path of the directory containing the current file
  local dirName = fullPath:match("([^/\\]+)$") -- Extract the directory name
  return dirName
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "c_sharp" })
    end,
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
                -- "csharp-language-server",
                "omnisharp",
                "netcoredbg",
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
        ---@type vim.lsp.Config
        omnisharp = {
          root_markers = { ".sln", ".csproj" },
          filetypes = { "cs" },
          cmd = { omnisharp_bin, "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
          on_attach = function(_, bufnr)
            vim.keymap.set(
              "n",
              "gd",
              "<cmd>lua require('omnisharp_extended').telescope_lsp_definitions()<cr>",
              { buffer = bufnr, desc = "Goto [d]efinition" }
            )

            vim.keymap.set(
              "n",
              "gr",
              "<cmd>lua require('omnisharp_extended').telescope_lsp_references()<cr>",
              { buffer = bufnr, desc = "Goto [r]eferences" }
            )

            vim.keymap.set(
              "n",
              "gI",
              "<cmd>lua require('omnisharp_extended').telescope_lsp_implementation()<cr>",
              { buffer = bufnr, desc = "Goto [I]mplementation" }
            )

            vim.keymap.set(
              "n",
              "gD",
              "<cmd>lua require('omnisharp_extended').telescope_type_definitions()<cr>",
              { buffer = bufnr, desc = "Goto Type [D]efinition" }
            )
          end,

          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,
          settings = {
            FormattingOptions = {
              -- Enables support for reading code style, naming convention and analyzer
              -- settings from .editorconfig.
              EnableEditorConfigSupport = true,
              -- Specifies whether 'using' directives should be grouped and sorted during
              -- document formatting.
              OrganizeImports = true,
            },
            MsBuild = {
              -- If true, MSBuild project system will only load projects for files that
              -- were opened in the editor. This setting is useful for big C# codebases
              -- and allows for faster initialization of code navigation features only
              -- for projects that are relevant to code that is being edited. With this
              -- setting enabled OmniSharp may load fewer projects and may thus display
              -- incomplete reference lists for symbols.
              LoadProjectsOnDemand = nil,
            },
            RoslynExtensionsOptions = {
              -- Enables support for roslyn analyzers, code fixes and rulesets.
              EnableAnalyzersSupport = true,
              -- Enables support for showing unimported types and unimported extension
              -- methods in completion lists. When committed, the appropriate using
              -- directive will be added at the top of the current file. This option can
              -- have a negative impact on initial completion responsiveness,
              -- particularly for the first few completion sessions after opening a
              -- solution.
              EnableImportCompletion = true,
              -- Only run analyzers against open files when 'enableRoslynAnalyzers' is
              -- true
              AnalyzeOpenDocumentsOnly = nil,
              -- Decompilation support
              EnableDecompilationSupport = true,
              -- Inlay Hints
              InlayHintsOptions = {
                EnableForParameters = true,
                ForLiteralParameters = true,
                ForIndexerParameters = true,
                ForObjectCreationParameters = true,
                ForOtherParameters = true,
                SuppressForParametersThatDifferOnlyBySuffix = false,
                SuppressForParametersThatMatchMethodIntent = false,
                SuppressForParametersThatMatchArgumentName = false,
                EnableForTypes = true,
                ForImplicitVariableTypes = true,
                ForLambdaParameterTypes = true,
                ForImplicitObjectCreation = true,
              },
            },
            Sdk = {
              -- Specifies whether to include preview versions of the .NET SDK when
              -- determining which version to use for project loading.
              IncludePrereleases = true,
            },
            settings = {
              omnisharp = {},
            },
          },
        },
      },
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

      local function get_plugin_directory()
        local str = debug.getinfo(1, "S").source:sub(2)
        str = str:match("(.*/)") -- Get the directory of the current file
        return str:gsub("/[^/]+/[^/]+/$", "/") -- Go up two directories
      end

      local plugin_directory = get_plugin_directory()
      local netcoredbg_path = plugin_directory .. "netcoredbg/build/src/netcoredbg"

      dap.adapters.cs = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
        -- cwd = function()
        --   return vim.fn.input("Workspace folder: ", vim.fn.getcwd() .. "/", "file")
        -- end,
        env = {
          ASPNETCORE_ENVIRONMENT = function()
            return vim.fn.input("ASPNETCORE_ENVIRONMENT: ", "Development")
          end,
          ASPNETCORE_URL = function()
            return vim.fn.input("ASPNETCORE_URL: ", "http://localhost:7500")
          end,
        },
      }

      vim.api.nvim_create_user_command("RunScriptWithArgs", function(t)
        -- :help nvim_create_user_command
        args = vim.split(vim.fn.expand(t.args), "\n")

        dap.run({
          request = "launch",
          name = "Launch file with custom arguments (adhoc)",
          type = "cs",
          command = netcoredbg_path,
          args = { "--interpreter=vscode", "--engineLogging", "--consoleLogging" },
          program = function()
            return vim.fn.input(
              "Path to dll: ",
              vim.fn.getcwd() .. "/bin/Debug/net9.0/" .. getCurrentFileDirName() .. ".dll",
              "file"
            )
          end,
          cwd = "${fileDirname}" .. getCurrentFileDirName(),
          env = {
            ASPNETCORE_ENVIRONMENT = function()
              return vim.fn.input("ASPNETCORE_ENVIRONMENT: ", "Development")
            end,
            ASPNETCORE_URL = function()
              return vim.fn.input("ASPNETCORE_URL: ", "http://localhost:7500")
            end,
          },
        })
      end, {
        complete = "file",
        nargs = "*",
      })
      vim.keymap.set("n", "<leader>R", ":RunScriptWithArgs ")
    end,
  },
  {
    "nvim-neotest/neotest",
    requires = {
      {
        "Issafalcon/neotest-dotnet",
      },
      opts = function(_, opts)
        vim.list_extend(opts.adapters, {
          require("neotest-dotnet"),
        })
      end,
    },
  },
}
