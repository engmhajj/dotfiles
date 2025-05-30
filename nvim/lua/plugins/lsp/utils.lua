local M = {}
local util = require("lspconfig").util
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
        "dotnet",
        vim.fn.expand("~/.local/share/nvim/mason/packages/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll"),
      },
      filetypes = { "cs", "vb" },
      root_dir = util.root_pattern("*.sln", "*.csproj"),
    }
  else
    print("⚠️ Roslyn not found or failed. Falling back to OmniSharp.")
    servers.omnisharp = {
      cmd = {
        vim.fn.expand("~/.local/share/nvim/mason/packages/path/to/omnisharp/OmniSharp"),
        "--languageserver",
        "--hostPID",
        tostring(vim.fn.getpid()),
      },
      filetypes = { "cs", "vb" },
      root_dir = util.root_pattern("*.sln", "*.csproj"),
      log_level = vim.lsp.protocol.MessageType.Warning,
      init_options = {
        formattingOptions = {
          useTabs = false,
          tabSize = 2,
          newLinesForBracesInTypes = true,
          newLinesForBracesInMethods = true,
          newLinesForBracesInProperties = true,
          newLinesForBracesInAccessors = true,
          newLinesForBracesInControlBlocks = true,
          newLinesForBracesInAnonymousMethods = true,
        },
      },
      settings = {
        omnisharp = {
          enable_editorconfig_support = true,
          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
        },
      },
    }
  end
end

return M
