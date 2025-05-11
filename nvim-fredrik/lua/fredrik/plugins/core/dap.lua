return {

  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      {
        -- Required dependency for nvim-dap-ui
        "nvim-neotest/nvim-nio",
        -- Installs the debug adapters for you
        "williamboman/mason.nvim",
        "jay-babu/mason-nvim-dap.nvim",

        cmd = { "DapInstall", "DapUninstall" },
      },
    },
    config = function(_, opts)
      local dap = require("dap")
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
          -- Update this to ensure that you have the debuggers for the langs you want
          -- 'delve',
        },
      })
      -- Set nice color highlighting at the stopped line
      -- vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      -- Show nice icons in gutter instead of the default characters
      for name, sign in pairs(require("fredrik.utils.icons").icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define("Dap" .. name, {
          text = sign[1],
          texthl = sign[2] or "DiagnosticInfo",
          linehl = sign[3],
          numhl = sign[3],
        })
      end

      local dap = require("dap")
      if opts.configurations ~= nil then
        local merged = require("fredrik.utils.table").deep_merge(dap.configurations, opts.configurations)
        dap.configurations = merged
      end
      dap.listeners.after.event_initialized["dapui_config"] = dapui.open
      dap.listeners.before.event_terminated["dapui_config"] = dapui.close
      dap.listeners.before.event_exited["dapui_config"] = dapui.close
      -- local dap_utils = require 'user.plugins.configs.dap.utils'
      local BASH_DEBUG_ADAPTER_BIN = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/bash-debug-adapter"
      local BASHDB_DIR = vim.fn.stdpath("data") .. "/mason/packages/bash-debug-adapter/extension/bashdb_dir"
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
    end,
    keys = require("fredrik.config.keymaps").setup_dap_keymaps(),
  },

  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
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
