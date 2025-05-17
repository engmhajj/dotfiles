local function rebuild_project(co, path)
  local spinner = require("easy-dotnet.ui-modules.spinner").new()
  spinner:start_spinner("Building")
  vim.fn.jobstart(string.format("dotnet build %s", path), {
    on_exit = function(_, return_code)
      if return_code == 0 then
        spinner:stop_spinner("Built successfully")
      else
        spinner:stop_spinner("Build failed with exit code " .. return_code, vim.log.levels.ERROR)
        error("Build failed")
      end
      coroutine.resume(co)
    end,
  })
  coroutine.yield()
end

return {
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    enabled = true,
    dependencies = {
      {
        -- Required dependency for nvim-dap-ui
        "nvim-neotest/nvim-nio",
        -- Installs the debug adapters for you
        "williamboman/mason.nvim",
        "jay-babu/mason-nvim-dap.nvim",
        {
          "rcarriga/nvim-dap-ui",
          config = function()
            require("dapui").setup()
          end,
        },

        cmd = { "DapInstall", "DapUninstall" },
      },
    },
    config = function()
      local dap = require("dap")
      local dotnet = require("easy-dotnet")
      local dapui = require("dapui")
      require("mason-nvim-dap").setup({
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_installation = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          "bash-debug-adapter",
          "coreclr-debug-adapter",
          "netcoredbg",
          -- Update this to ensure that you have the debuggers for the langs you want
          -- 'delve',
        },
      })
      for name, sign in pairs(require("fredrik.utils.icons").icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define("Dap" .. name, {
          text = sign[1],
          texthl = sign[2] or "DiagnosticInfo",
          linehl = sign[3],
          numhl = sign[3],
        })
      end
      dap.set_log_level("TRACE")

      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end

      vim.keymap.set("n", "<space>dq", function()
        dap.close()
        dapui.close()
      end, { desc = "Close DAP" })

      -- vim.keymap.set("n", "<F5>", dap.continue, {})
      -- vim.keymap.set("n", "<F10>", dap.step_over, {})
      -- vim.keymap.set("n", "<leader>dO", dap.step_over, {})
      -- vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, {})
      -- vim.keymap.set("n", "<leader>dr", dap.repl.toggle, {})
      -- vim.keymap.set("n", "<leader>dj", dap.down, {})
      -- vim.keymap.set("n", "<leader>dk", dap.up, {})
      -- vim.keymap.set("n", "<F11>", dap.step_into, {})
      -- vim.keymap.set("n", "<F12>", dap.step_out, {})
      -- vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, {})
      -- vim.keymap.set("n", "<F2>", require("dap.ui.widgets").hover, {})

      local function file_exists(path)
        local stat = vim.loop.fs_stat(path)
        return stat and stat.type == "file"
      end

      local debug_dll = nil

      local function ensure_dll()
        if debug_dll ~= nil then
          return debug_dll
        end
        local dll = dotnet.get_debug_dll()
        debug_dll = dll
        return dll
      end

      for _, value in ipairs({ "cs" }) do
        dap.configurations[value] = {
          {
            type = "coreclr",
            name = "Program",
            request = "launch",
            env = function()
              local dll = ensure_dll()
              local vars = dotnet.get_environment_variables(dll.project_name, dll.absolute_project_path)
              return vars or nil
            end,
            program = function()
              local dll = ensure_dll()
              local co = coroutine.running()
              rebuild_project(co, dll.project_path)
              if not file_exists(dll.target_path) then
                error("Project has not been built, path: " .. dll.target_path)
              end
              return dll.target_path
            end,
            cwd = function()
              local dll = ensure_dll()
              return dll.absolute_project_path
            end,
          },
        }

        dap.listeners.before["event_terminated"]["easy-dotnet"] = function()
          debug_dll = nil
        end
        local function get_plugin_directory()
          local str = debug.getinfo(1, "S").source:sub(2)
          str = str:match("(.*/)") -- Get the directory of the current file
          return str:gsub("/[^/]+/[^/]+/$", "/") -- Go up two directories
        end

        local plugin_directory = get_plugin_directory()
        local netcoredbg_path = plugin_directory .. "netcoredbg/build/src/netcoredbg"

        dap.adapters.coreclr = {
          type = "executable",
          command = netcoredbg_path,
          args = { "--interpreter=vscode" },
        }
        local BASH_DEBUG_ADAPTER_BIN = vim.fn.expand(
          "~/.local/share/fredrik/mason/packages/bash-language-server/node_modules/.bin/bash-language-server"
        )
        local BASHDB_DIR = vim.fn.expand(
          "~/.local/share/fredrik/mason/packages/bash-language-server/node_modules/bash-language-server/node_modules/.bin/semver"
        )
        dap.adapters.sh = {
          type = "executable",
          command = BASH_DEBUG_ADAPTER_BIN,
        }
        dap.configurations.sh = {
          {
            name = "Launch Bash debugger",
            type = "sh",
            request = "launch",
            program = "${file}",
            cwd = "${fileDirname}",
            pathBashdb = BASHDB_DIR .. "/bashdb",
            pathBashdbLib = BASHDB_DIR,
            pathBash = "bash",
            pathCat = "cat",
            pathMkfifo = "mkfifo",
            pathPkill = "pkill",
            env = {},
            args = {},
            -- showDebugOutput = true,
            -- trace = true,
          },
        }
      end
    end,
    keys = require("fredrik.config.keymaps").setup_dap_keymaps(),
  },
  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
    -- event = "InsertEnter",
    dependencies = {
      "nvim-neotest/nvim-nio",
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
          virt_text_pos = "eol",
        },
      },
      {
        "mfussenegger/nvim-dap",
        opts = {},
      },
      {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = {
          "mfussenegger/nvim-dap",
        },
        opts = function(_, opts)
          opts.extensions = { "nvim-dap-ui" }

          local function dap_status()
            return "  " .. require("dap").status()
          end
          opts.dap_status = {
            lualine_component = {
              dap_status,
              cond = function()
                -- return package.loaded["dap"] and require("dap").status() ~= ""
                return require("dap").status() ~= ""
              end,
              color = require("fredrik.utils.colors").fgcolor("Debug"),
            },
          }
        end,
      },
    },
    opts = {},

    keys = require("fredrik.config.keymaps").setup_dap_ui_keymaps(),
  },
}
