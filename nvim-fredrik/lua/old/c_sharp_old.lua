--- @param name string
--- @return string

local root_files = {
  "*.csproj",
  "*.sln",
  "Directory.Build.props",
  "Directory.Build.targets",
  ".git",
}

-- local function get_plugin_directory()
--   local str = debug.getinfo(1, "S").source:sub(2)
--   str = str:match("(.*/)") -- Get the directory of the current file
--   return str:gsub("/[^/]+/[^/]+/$", "/") -- Go up two directories
-- end
local omnisharp_bin = vim.fn.expand("~/.local/share/fredrik/mason/packages/omnisharp/OmniSharp")
local netcoredbg_bin = vim.fn.expand("~/.local/share/fredrik/mason/packages/netcoredbg/netcoredbg")

-- local plugin_directory = get_plugin_directory()
local netcoredbg_path = netcoredbg_bin

local function getCurrentFileDirName()
  local fullPath = vim.fn.expand("%:p:h") -- Get the full path of the directory containing the current file
  local dirName = fullPath:match("([^/\\]+)$") -- Extract the directory name
  return dirName
end

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local function get_dll_path()
  -- local debugPath = (getCurrentFileDirName()):match("(.*/bin/Debug/net[0-9]*/)")
  local debugPath = getCurrentFileDirName()
  if not file_exists(debugPath) then
    return vim.fn.getcwd()
  end
  local command = 'find "' .. debugPath .. '" -maxdepth 1 -type d -name "*net*" -print -quit'
  local handle = io.popen(command)
  local result = handle:read("*a")
  handle:close()
  result = result:gsub("[\r\n]+$", "") -- Remove trailing newline and carriage return
  if result == "" then
    return debugPath
  else
    local potentialDllPath = result .. "/" .. getCurrentFileDirName() .. ".dll"
    if file_exists(potentialDllPath) then
      return potentialDllPath
    else
      return result == "" and debugPath or result .. "/"
    end
    --        return result .. '/' -- Adds a trailing slash if a net folder is found
  end
end

local pid = vim.fn.getpid()

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "c_sharp" })
    end,
  },
  -- {
  --   "nvimtools/none-ls.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   opts = function(_, opts)
  --     opts.sources = opts.sources or {}
  --     vim.list_extend(opts.sources, {
  --       require("null-ls").builtins.formatting.stylua,
  --       require("null-ls").builtins.diagnostics.gdformat,
  --       require("null-ls").builtins.diagnostics.csharpier,
  --     })
  --   end,
  -- },
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
          root_markers = root_files,
          log_level = vim.lsp.protocol.MessageType.Debug,
          root_dir = function(fname)
            local primary = require("lspconfig").util.root_pattern("*.sln")(fname)
            local fallback = require("lspconfig").util.root_pattern("*.csproj")(fname)
            return primary or fallback
          end,
          filetypes = { "cs", "csproject" },
          -- root_dir = "~/.local/share/fredrik/mason/packages/omnisharp",
          -- root_dir = function(fname)
          --   local primary = require("lspconfig").util.root_pattern("*.sln")(fname)
          --   local fallback = require("lspconfig").util.root_pattern("*.csproj")(fname)
          --   return primary or fallback
          -- end,
          -- cmd = {
          --   "omnisharp",
          --   -- "dotnet",
          --   "--languageserver",
          --   "--hostPID",
          --   tostring(vim.fn.getpid()),
          -- },
        },
      },
    },
  },
  -- {
  --   "Issafalcon/neotest-dotnet",
  --   lazy = false,
  --   dependencies = {
  --     "nvim-neotest/neotest",
  --   },
  -- },
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
      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }

      dap.adapters.netcoredbg = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
        cwd = function()
          return vim.fn.input("Workspace folder: ", vim.fn.getcwd() .. "/", "file")
        end,
      }
      dap.adapters.cs = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
        cwd = function()
          return vim.fn.input("Workspace folder: ", vim.fn.getcwd() .. "/", "file")
        end,
      }

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "NetCoreDbg: Launch",
          request = "launch",
          cwd = "${fileDirname}",
          program = function()
            return vim.fn.input("Path to dll: ", get_dll_path() or vim.fn.getcwd(), "file")
          end,
          env = {
            ASPNETCORE_ENVIRONMENT = function()
              return vim.fn.input("ASPNETCORE_ENVIRONMENT: ", "Development")
            end,
            ASPNETCORE_URL = function()
              return vim.fn.input("ASPNETCORE_URL: ", "http://localhost:7500")
            end,
          },
          {
            type = "coreclr",
            name = "attach - MyConsole",
            request = "attach",
            processId = function()
              return vim.fn.input("Process Id ")
            end,
            program = function()
              return vim.fn.input("Path to dll: ", get_dll_path() or vim.fn.getcwd() .. "/bin/Debug/net9.0/", "file")
            end,
          },
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
