if true then
  return {}
end

return {
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
      local utils = require("dap.utils")

      local rpc = require("dap.rpc")

      -- vsdbg certification
      local function send_payload(client, payload)
        local msg = rpc.msg_with_content_length(vim.json.encode(payload))
        client.write(msg)
      end

      -- See https://github.com/mfussenegger/nvim-dap/discussions/869#discussioncomment-8121995 for contents of file vsdbgsignature
      local SIGNJS = "/Users/mohamadelhajhassan/.dotfiles/nvim-fredrik/lua/vsdbgsignature.js"

      function RunHandshake(self, request_payload)
        local signResult = io.popen("node " .. SIGNJS .. " " .. request_payload.arguments.value)
        if signResult == nil then
          vim.notify("error while signing handshake", vim.log.levels.ERROR)
          return
        end
        local signature = signResult:read("*a")
        signature = string.gsub(signature, "\n", "")
        local response = {
          type = "response",
          seq = 0,
          command = "handshake",
          request_seq = request_payload.seq,
          success = true,
          body = {
            signature = signature,
          },
        }
        send_payload(self.client, response)
      end

      dap.adapters.netcoredbg = {

        type = "executable",
        command = "/Users/mohamadelhajhassan/.dotfiles/nvim-fredrik/lua/netcoredbg/netcoredbg",
        args = { "--interpreter=vscode" },
        options = {
          detached = false,
          externalTerminal = true,
        },
      }

      dap.adapters.coreclr = {
        id = "coreclr",
        type = "executable",
        command = "/Users/mohamadelhajhassan/.vscode/extensions/ms-dotnettools.csharp-2.72.34-darwin-arm64/.debugger/arm64/vsdbg-ui", -- Note: Please include the actual path!
        args = {
          "--interpreter=vscode",
          "--engineLogging",
          "--consoleLogging",
        },
        options = {
          externalTerminal = true,
        },
        runInTerminal = true,
        reverse_request_handlers = {
          handshake = RunHandshake,
        },
      }
      dap.adapters.cs = {
        id = "coreclr",
        type = "executable",
        command = "/Users/mohamadelhajhassan/.vscode/extensions/ms-dotnettools.csharp-2.72.34-darwin-arm64/.debugger/arm64/vsdbg-ui", -- Note: Please include the actual path!
        args = {
          "--interpreter=vscode",
          "--engineLogging",
          "--consoleLogging",
        },
        options = {
          externalTerminal = true,
        },
        runInTerminal = true,
        reverse_request_handlers = {
          handshake = RunHandshake,
        },
      }

      dap.configurations.cs = {
        type = "coreclr",
        name = "Launch",
        request = "launch",
        program = "/usr/local/share/dotnet/dotnet", -- Note: Please include the actual path!
        args = {},
        cwd = vim.fn.getcwd(),
        clientID = "vscode",
        clientName = "Visual Studio Code",
        externalTerminal = true,
        columnsStartAt1 = true,
        linesStartAt1 = true,
        locale = "en",
        pathFormat = "path",
        externalConsole = true,
      }
      dap.listeners.after.event_initialized["set_exception_breakpoints"] = function()
        dap.set_exception_breakpoints({ "raised", "uncaught" })
      end

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
            clientID = "vscode",
            clientName = "Visual Studio Code",
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
