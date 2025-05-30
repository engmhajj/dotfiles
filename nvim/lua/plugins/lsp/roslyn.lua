local util
-- In your plugins.lua (or lazy config)
return {
  -- your existing plugins ...

  {
    "seblj/roslyn.nvim",
    ft = "cs",
    opts = {
      cmd = {
        "/Users/mohamadelhajhassan/.local/share/nvim/mason/bin/roslyn",
        "--logLevel=Information",
        "--extensionLogDirectory=/Users/mohamadelhajhassan/.local/state/nvim",
        "--stdio",
      },
      cmd_env = { Configuration = "Debug" },
      filetypes = { "cs" },
      capabilities = {
        textDocument = {
          completion = {
            completionItem = {
              commitCharactersSupport = false,
              deprecatedSupport = true,
              documentationFormat = { "markdown", "plaintext" },
              insertReplaceSupport = true,
              insertTextModeSupport = { valueSet = { 1 } },
              labelDetailsSupport = true,
              preselectSupport = false,
              resolveSupport = { properties = { "documentation", "detail", "additionalTextEdits", "command", "data" } },
              snippetSupport = true,
              tagSupport = { valueSet = { 1 } },
            },
            completionList = {
              itemDefaults = { "commitCharacters", "editRange", "insertTextFormat", "insertTextMode", "data" },
            },
            contextSupport = true,
            insertTextMode = 1,
          },
          diagnostic = { dynamicRegistration = true },
        },
      },
      commands = {
        ["roslyn.client.completionComplexEdit"] = function()
          vim.notify("[roslyn] CompletionComplexEdit command called", vim.log.levels.INFO)
        end,
        ["roslyn.client.fixAllCodeAction"] = function()
          vim.notify("[roslyn] FixAllCodeAction command called", vim.log.levels.INFO)
        end,
        ["roslyn.client.nestedCodeAction"] = function()
          vim.notify("[roslyn] NestedCodeAction command called", vim.log.levels.INFO)
        end,
      },
      handlers = {
        ["client/registerCapability"] = function(err, result, ctx, config)
          if err then
            vim.notify("[roslyn] Error registering capability: " .. err.message, vim.log.levels.ERROR)
            return
          end
          vim.lsp.handlers["client/registerCapability"](err, result, ctx, config)
        end,
        ["workspace/_roslyn_projectHasUnresolvedDependencies"] = function()
          vim.notify("[roslyn] Project has unresolved dependencies", vim.log.levels.WARN)
        end,
        ["workspace/projectInitializationComplete"] = function()
          vim.notify("[roslyn] Project initialization complete", vim.log.levels.INFO)
        end,
        ["workspace/refreshSourceGeneratedDocument"] = function()
          vim.notify("[roslyn] Source generated document refreshed", vim.log.levels.INFO)
        end,
      },
      on_exit = function(code, signal, client_id)
        print(string.format("[roslyn] exited with code %d, signal %d, client_id %d", code, signal, client_id))
      end,
      on_init = function(client, _)
        print("[roslyn] initialized")
      end,
      root_dir = function(fname)
        if not util then
          util = require("lspconfig.util")
        end
        return util.root_pattern(".sln", ".csproj", ".git")(fname)
      end,
    },
    config = function(_, opts)
      require("roslyn").setup(opts)
    end,
  },

  -- your other plugins ...
}
