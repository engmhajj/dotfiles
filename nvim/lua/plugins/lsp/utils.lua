local M = {}
local lspconfig = require("lspconfig")
--- Generate default capabilities using cmp_nvim_lsp and blink.cmp
function M.get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then
    capabilities = cmp.default_capabilities(capabilities)
  end

  local ok_blink, blink = pcall(require, "blink.cmp")
  if ok_blink then
    capabilities = vim.tbl_deep_extend("force", capabilities, blink.get_lsp_capabilities())
  end

  capabilities.textDocument.completion.completionItem.snippetSupport = true
  return capabilities
end

--- Extend base capabilities into each server
---@param servers table<string, vim.lsp.Config>
-- Extend capabilities with cmp_nvim_lsp (if installed)
M.extend_capabilities = function(servers)
  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  local capabilities = ok and cmp_nvim_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()

  for _, server in pairs(servers) do
    server.capabilities = vim.tbl_deep_extend("force", server.capabilities or {}, capabilities)
  end
end

--- Ensure mason installs LSP servers that support it
---@param servers table<string, vim.lsp.Config>
function M.ensure_servers_installed(servers)
  local ok, mason_lspconfig = pcall(require, "mason-lspconfig")
  if not ok then
    vim.notify("[LSP] mason-lspconfig not available", vim.log.levels.WARN)
    return
  end

  local lsp_to_package = mason_lspconfig.get_mappings().lspconfig_to_package
  local supported = vim.tbl_keys(lsp_to_package)
  local to_install = {}

  for server, config in pairs(servers) do
    if config.mason ~= false and vim.tbl_contains(supported, server) then
      table.insert(to_install, server)
    elseif config.mason ~= false then
      vim.notify("⚠️ LSP not supported by mason: " .. server, vim.log.levels.WARN)
    end
  end

  mason_lspconfig.setup({
    automatic_enable = true,
    ensure_installed = to_install,
  })
end

--- Register LSP servers via lspconfig
---@param servers table<string, vim.lsp.Config>
function M.register_lsp_servers(servers)
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    vim.notify("[LSP] lspconfig not available", vim.log.levels.ERROR)
    return
  end

  -- Load enabled servers config
  local lsp_settings_ok, lsp_settings = pcall(require, "config.lsp_settings")
  if not lsp_settings_ok then
    vim.notify("[LSP] config.lsp_settings not available", vim.log.levels.WARN)
    lsp_settings = { enabled_servers = {} }
  end

  for name, config in pairs(servers) do
    -- ❌ Skip server if explicitly disabled
    if lsp_settings.enabled_servers[name] == false then
      vim.notify("🔇 Skipping disabled LSP: " .. name, vim.log.levels.INFO)
      goto continue
    end

    -- Validations
    if not config.cmd then
      vim.notify("❗ LSP server missing `cmd`: " .. name, vim.log.levels.ERROR)
    end
    if not config.filetypes then
      vim.notify("❗ LSP server missing `filetypes`: " .. name, vim.log.levels.ERROR)
    end
    if not config.root_dir and not config.root_markers then
      vim.notify("❗ LSP server missing root detection: " .. name, vim.log.levels.ERROR)
    end
    if config.root_dir and config.root_markers then
      vim.notify(
        "⚠️ Both `root_dir` and `root_markers` are set (ignoring root_markers): " .. name,
        vim.log.levels.WARN
      )
    end

    -- if not lspconfig[name] then
    --   lspconfig.configs[name] = {
    --     default_config = {
    --       cmd = config.cmd,
    --       filetypes = config.filetypes,
    --       root_dir = config.root_dir or util.root_pattern(".git"),
    --       settings = config.settings or {},
    --     },
    --   }
    -- end

    -- Register the LSP
    lspconfig[name].setup(config)

    ::continue::
  end
end

--- Setup LspAttach autocmd for additional features
function M.register_lspattach_autocmd()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      -- CodeLens autorefresh
      if client:supports_method("textDocument/codeLens") then
        vim.lsp.codelens.refresh()
        vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
          buffer = args.buf,
          callback = vim.lsp.codelens.refresh,
        })
      end

      -- Folding range support
      if client:supports_method("textDocument/foldingRange") then
        local ok_opts, opts = pcall(require, "config.options")
        if ok_opts and opts.lsp_foldexpr then
          opts.lsp_foldexpr()
        end
      end

      -- Workspace diagnostics
      local ok_diag, diag = pcall(require, "workspace-diagnostics")
      if ok_diag and diag.populate_workspace_diagnostics then
        diag.populate_workspace_diagnostics(client, args.buf)
      end

      -- LSP-specific keymaps
      local ok_maps, maps = pcall(require, "config.keymaps")
      if ok_maps and maps.setup_lsp_autocmd_keymaps then
        maps.setup_lsp_autocmd_keymaps(args.buf)
      end
    end,
  })
end

function M.validate_servers(servers)
  for name, config in pairs(servers) do
    if not config.cmd then
      vim.notify("❗ Missing cmd for LSP server: " .. name, vim.log.levels.ERROR)
    end
    if not config.filetypes then
      vim.notify("❗ Missing filetypes for LSP server: " .. name, vim.log.levels.ERROR)
    end
  end
end

function M.register_csharp_lsp(servers)
  local function is_roslyn_usable()
    -- local roslyn_path =
    --   vim.fn.expand("~/.local/share/nvim/mason/packages/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll")
    return vim.fn.executable("dotnet") == 1
  end

  if is_roslyn_usable() then
    print("✅ Roslyn is available. Using Roslyn as LSP for C#.")
    servers.roslyn = {
      cmd = {
        "/Users/mohamadelhajhassan/.local/share/nvim/mason/packages/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer",
        "--logLevel=Trace",
        "--extensionLogDirectory=/Users/mohamadelhajhassan/.local/state/nvim",
        "--stdio",
      },
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

      root_dir = function(fname)
        return lspconfig.util.root_pattern("*.sln")(fname)
          or lspconfig.util.root_pattern("*.csproj")(fname)
          or lspconfig.util.find_git_ancestor(fname)
      end,
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
      },
      single_file_support = false,
    }
  else
    print("⚠️ Roslyn not found or failed. Falling back to OmniSharp.")
    servers.omnisharp = {
      cmd = {
        omnisharp_bin,
      },

      -- Use this for monorepos/multi-root workspaces
      root_dir = function(fname)
        return lspconfig.util.root_pattern("*.sln")(fname)
          or lspconfig.util.root_pattern("*.csproj")(fname)
          or lspconfig.util.find_git_ancestor(fname)
      end,

      filetypes = { "cs" },
      single_file_support = false,
      on_attach = on_attach,
      handlers = {
        ["textDocument/definition"] = require("omnisharp_extended").handler,
        ["textDocument/references"] = require("omnisharp_extended").handler,
        ["textDocument/implementation"] = require("omnisharp_extended").handler,
        ["textDocument/typeDefinition"] = require("omnisharp_extended").handler,
      },

      settings = {
        FormattingOptions = {
          EnableEditorConfigSupport = true,
        },
        MsBuild = {
          LoadProjectsOnDemand = true,
        },
        RenameOptions = {},
        RoslynExtensionsOptions = {
          EnableAnalyzersSupport = true,
          EnableImportCompletion = true,
          AnalyzeOpenDocumentsOnly = false,
        },
        Sdk = {
          IncludePrereleases = true,
        },
      },
    }
  end
end

return M
