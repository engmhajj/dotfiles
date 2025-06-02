-- ~/.config/nvim/lua/config/lsp_servers.lua

local util = require("lspconfig").util
local schemastore = require("schemastore")
local omnisharp_bin = "/Users/mohamadelhajhassan/.local/share/nvim/mason/packages/omnisharp/OmniSharp"
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
    "-z",
    "--hostPID",
    tostring(vim.fn.getpid()),
    "--encoding",
    "utf-8",
    "--languageserver",
  },
  filetypes = { "cs", "vb" },
  root_dir = function(fname)
    local root = util.root_pattern(".sln", ".csproj", ".git")(fname)
    if root then
      return root
    else
      -- No root found, don't start OmniSharp
      return nil
    end
  end,
  single_file_support = false, -- important to avoid multiple instances
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
          resolveSupport = {
            properties = { "documentation", "detail", "additionalTextEdits", "command", "data" },
          },
          snippetSupport = true,
          tagSupport = { valueSet = { 1 } },
        },
        completionList = {
          itemDefaults = { "commitCharacters", "editRange", "insertTextFormat", "insertTextMode", "data" },
        },
        contextSupport = true,
        insertTextMode = 1,
      },
    },
    workspace = {
      workspaceFolders = false,
    },
  },
  settings = {
    FormattingOptions = {
      EnableEditorConfigSupport = true,
    },
    MsBuild = {},
    RenameOptions = {},
    RoslynExtensionsOptions = {},
    Sdk = {
      IncludePrereleases = true,
    },
  },
}

servers.roslyn = {
  cmd = {
    "/Users/mohamadelhajhassan/.local/share/nvim/mason/bin/roslyn",
    "--logLevel=Information",
    "--extensionLogDirectory=/Users/mohamadelhajhassan/.local/state/nvim",
    "--stdio",
  },
  cmd_env = { Configuration = "Debug" },
  filetypes = { "cs" },
  root_dir = function(fname)
    local root = util.root_pattern(".sln", ".csproj", ".git")(fname)
    if root then
      return root
    else
      -- No root found, don't start OmniSharp
      return nil
    end
  end,
  single_file_support = false, -- important to avoid multiple instances
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
}

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
  root_dir = util.root_pattern(".git"),
}

return servers
