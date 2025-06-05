-- ~/.config/nvim/lua/config/lsp_servers.lua
local lspconfig = require("lspconfig")
local util = require("lspconfig").util
local schemastore = require("schemastore")
-- local omnisharp_bin = "/Users/mohamadelhajhassan/.local/share/nvim/mason/packages/omnisharp/OmniSharp"
-- Get the Omnisharp binary from Mason
local omnisharp_bin = vim.env.HOME .. "/.local/share/nvim/mason/packages/omnisharp/OmniSharp"
local on_attach = function(client, bufnr)
  -- Disable formatting to avoid conflicts with csharpier/conform.nvim
  if client.server_capabilities.documentFormattingProvider then
    client.server_capabilities.documentFormattingProvider = false
  end
  if client.server_capabilities.documentRangeFormattingProvider then
    client.server_capabilities.documentRangeFormattingProvider = false
  end
end
-- local roslyn_bin = "/Users/mohamadelhajhassan/.local/share/nvim/mason/bin/roslyn"
local servers = {}

-- 🐍 Lua
servers.lua_ls = {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = util.root_pattern(
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git"
  ),
  log_level = vim.lsp.protocol.MessageType.Warning,
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" }, -- 👈 This is missing in your current config
      },
      workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file("", true), -- 👈 This too
      },
      codeLens = {
        enable = false,
      },
      completion = {
        callSnippet = "Replace",
      },
      doc = {
        privateName = { "^_" },
      },
      hint = {
        enable = true,
        setType = false,
        paramType = true,
        paramName = "Disable",
        semicolon = "Disable",
        arrayIndex = "Disable",
      },
      telemetry = { enable = false },
    },
  },
}

-- Enhanced Omnisharp with full capabilities, condition, settings, root markers
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

-- lspconfig.roslyn = {
--   default_config = {
--     cmd = {
--       "dotnet",
--       "/Users/mohamadelhajhassan/.local/share/nvim/mason/packages/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer",
--       "--logLevel=Trace",
--       "--extensionLogDirectory=/Users/mohamadelhajhassan/.local/state/nvim",
--       "--stdio",
--     },
--     filetypes = { "cs" },
--     root_dir = function(fname)
--       return lspconfig.util.root_pattern("*.sln")(fname)
--         or lspconfig.util.root_pattern("*.csproj")(fname)
--         or lspconfig.util.find_git_ancestor(fname)
--     end,
--     single_file_support = false,
--     settings = {
--       ["csharp|background_analysis"] = {
--         dotnet_analyzer_diagnostics_scope = "fullSolution",
--         dotnet_compiler_diagnostics_scope = "fullSolution",
--       },
--       ["csharp|inlay_hints"] = {
--         csharp_enable_inlay_hints_for_implicit_object_creation = true,
--         csharp_enable_inlay_hints_for_implicit_variable_types = true,
--         csharp_enable_inlay_hints_for_lambda_parameter_types = true,
--         csharp_enable_inlay_hints_for_types = true,
--         dotnet_enable_inlay_hints_for_indexer_parameters = true,
--         dotnet_enable_inlay_hints_for_literal_parameters = true,
--         dotnet_enable_inlay_hints_for_object_creation_parameters = true,
--         dotnet_enable_inlay_hints_for_other_parameters = true,
--         dotnet_enable_inlay_hints_for_parameters = true,
--         dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
--         dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
--         dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
--       },
--       ["csharp|code_lens"] = {
--         dotnet_enable_references_code_lens = true,
--         dotnet_enable_tests_code_lens = true,
--       },
--       ["csharp|completion"] = {
--         dotnet_provide_regex_completions = true,
--         dotnet_show_completion_items_from_unimported_namespaces = true,
--         dotnet_show_name_completion_suggestions = true,
--       },
--       ["csharp|symbol_search"] = {
--         dotnet_organize_imports_on_format = true,
--       },
--     },
--     on_attach = function(client, bufnr)
--       vim.notify("Roslyn LSP attached!")
--
--       -- Disable built-in formatting to prevent conflicts with external formatters
--       client.server_capabilities.documentFormattingProvider = false
--       client.server_capabilities.documentRangeFormattingProvider = false
--
--       vim.diagnostic.config({
--         virtual_text = true,
--         signs = true,
--         underline = true,
--         update_in_insert = false,
--       }, bufnr)
--     end,
--     filewatching = "auto",
--   },
-- }
-- 🐍 Python
servers.ruff = {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_dir = util.root_pattern(".git"),
  capabilities = {
    general = { positionEncodings = { "utf-16" } },
  },
  init_options = {
    settings = {
      configurationPreference = "filesystemFirst",
      lineLength = 88,
    },
  },
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
}

servers.basedpyright = {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_dir = util.root_pattern(
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
    "requirements.txt",
    "setup.py",
    "setup.cfg",
    ".git"
  ),
  log_level = vim.lsp.protocol.MessageType.Debug,
  settings = {
    python = {
      venvPath = os.getenv("VIRTUAL_ENV"),
      pythonPath = vim.fn.exepath("python"),
    },
    basedpyright = {
      disableOrganizeImports = true,
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
}

-- 🌐 Web (HTML, JS, TS, JSON)
servers.superhtml = {
  cmd = { "superhtml", "lsp" },
  filetypes = { "html", "shtml", "htm" },
  root_dir = util.root_pattern(".git"),
}

servers.vtsls = {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_dir = util.root_pattern("tsconfig.json", "package.json", ".git"),
  init_options = { hostInfo = "neovim" },
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      experimental = {
        completion = { enableServerSideFuzzyMatch = true },
      },
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = { completeFunctionCalls = true },
      inlayHints = {
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
    javascript = {
      updateImportsOnFileMove = { enabled = "always" },
      suggest = { completeFunctionCalls = true },
      inlayHints = {
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        enumMemberValues = { enabled = true },
      },
    },
  },
}

servers.jsonls = {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc", "json5" },
  root_dir = util.root_pattern(".git"),
  init_options = { provideFormatter = false },
  settings = {
    json = {
      schemas = schemastore.json.schemas(),
      validate = { enable = true },
    },
  },
}

-- 🐳 Containers & Shell
servers.dockerls = {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_dir = util.root_pattern("Dockerfile"),
}

servers.bashls = {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash", "zsh" },
  root_dir = util.root_pattern(".git"),
  settings = {
    bashIde = {
      shellcheck = {
        -- Ignore carriage return warning SC1017 (and any others you want)
        exclude = { "SC1017" },
      },
    },
  },
}

-- 🧱 Infra
servers.yamlls = {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "gha", "dependabot" },
  root_dir = util.root_pattern(".git"),
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemaStore = { enable = false, url = "" },
      schemas = schemastore.yaml.schemas(),
      validate = true,
      format = { enable = false },
    },
  },
}

-- 🦀 Rust
servers.rust_analyzer = {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_dir = util.root_pattern("Cargo.toml", ".git"),
}

-- ⚙️ Go + Proto + Templ
servers.gopls = {
  cmd = { "gopls" },
  filetypes = { "go", "templ" },
  root_dir = util.root_pattern("go.mod", ".git"),
  settings = {
    gopls = {
      templateExtensions = { "templ" },
    },
  },
}

servers.templ = {
  cmd = { "templ", "lsp" },
  filetypes = { "templ" },
  root_dir = util.root_pattern("go.work", "go.mod", ".git"),
}

servers.buf_ls = {
  cmd = { "buf", "beta", "lsp", "--timeout=0", "--log-format=text" },
  filetypes = { "proto" },
  root_dir = util.root_pattern("buf.yaml", "buf.yml", ".git"),
}

-- 💎 Ruby
servers.ruby_lsp = {
  cmd = { vim.fn.expand("/opt/homebrew/lib/ruby/gems/3.4.0/bin/ruby-lsp") },
  filetypes = { "ruby" },
  root_dir = util.root_pattern("Gemfile", ".git"),
}

-- ⚡ Zig
servers.zls = {
  cmd = { "zls" },
  filetypes = { "zig", "zir" },
  root_dir = util.root_pattern("zls.json", "build.zig"),
}

-- 🧪 TOML
servers.taplo = {
  cmd = { "taplo", "lsp", "stdio" },
  filetypes = { "toml" },
  root_dir = util.root_pattern("*.toml", ".git"),
}

return servers
