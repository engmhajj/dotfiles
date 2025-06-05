return {
  "engmhajj/roslyn.nvim",

  enabled = false,
  ft = "cs",
  event = "VeryLazy",
  opts = {

    config = {
      cmd = {
        "/Users/mohamadelhajhassan/.local/share/nvim/mason/packages/roslyn/roslyn",
        "--logLevel=Information",
        "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.get_log_path()),
        "--stdio",
      },
      -- root_dir = function(fname)
      --   local lspconfig = require("lspconfig")
      --   return lspconfig.util.root_pattern("*.sln")(fname)
      --     or lspconfig.util.root_pattern("*.csproj")(fname)
      --     or lspconfig.util.find_git_ancestor(fname)
      -- end,
      filetypes = { "cs" },
      on_attach = function(client, bufnr)
        -- Disable formatting to avoid conflicts with csharpier/conform.nvim
        if client.server_capabilities.documentFormattingProvider then
          client.server_capabilities.documentFormattingProvider = false
        end
        if client.server_capabilities.documentRangeFormattingProvider then
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end,
      single_file_support = false,
      settings = {
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "fullSolution",
          dotnet_compiler_diagnostics_scope = "fullSolution",
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
          dotnet_enable_tests_code_lens = true,
        },
        ["csharp|completion"] = {
          dotnet_provide_regex_completions = true,
          dotnet_show_completion_items_from_unimported_namespaces = true,
          dotnet_show_name_completion_suggestions = true,
        },
        ["csharp|symbol_search"] = {
          dotnet_organize_imports_on_format = true,
        },
        -- Try enabling code fixes and diagnostics for missing usings explicitly
        ["csharp|diagnostics"] = {
          dotnet_enable_missing_usings = true,
        },
      },
    },
  },
  config = function(_, opts)
    require("roslyn").setup(opts)
    -- Diagnostics refresh autocmd on InsertLeave:
    vim.api.nvim_create_autocmd({ "InsertLeave" }, {
      pattern = "*",
      callback = function()
        local clients = vim.lsp.get_clients({ name = "roslyn" })
        if not clients or #clients == 0 then
          return
        end

        local buffers = vim.lsp.get_buffers_by_client_id(clients[1].id)
        for _, buf in ipairs(buffers) do
          vim.lsp.util._refresh("textDocument/diagnostic", { bufnr = buf })
        end
      end,
      desc = "Refresh roslyn diagnostics after insert mode",
    })
  end,
}
