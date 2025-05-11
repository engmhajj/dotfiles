-- Extend LSP capabilities and set up LSP servers.
--
-- LSP servers and clients (like Neovim) are able to communicate to each other what
-- features they support.
-- By default, Neovim doesn't support everything that is in the LSP Specification.
-- When you add nvim-cmp, blink, luasnip, etc. Neovim now has *more* capabilities.
-- So, we create new capabilities here, and then broadcast that to the LSP servers.
--
local utils = require("fredrik.utils.utils")
---@param servers table<string, vim.lsp.Config>
local function extend_capabilities(servers)
  local client_capabilities = vim.tbl_deep_extend(
    "force",
    vim.lsp.protocol.make_client_capabilities(),
    require("blink.cmp").get_lsp_capabilities()
  )
  for server, server_opts in pairs(servers) do
    local extended_capabilities = vim.tbl_deep_extend("force", client_capabilities, server_opts.capabilities or {})
    servers[server].capabilities = extended_capabilities
  end

  -- FIXME: workaround for https://github.com/neovim/neovim/issues/28058
  -- if servers["gopls"] ~= nil then
  --   local server_opts = servers["gopls"]
  --   for _, v in pairs(server_opts) do
  --     if type(v) == "table" and v.workspace then
  --       -- vim.notify(vim.inspect("Disabling workspace/didChangeWatchedFiles for " .. server), vim.log.levels.INFO)
  --       v.workspace.didChangeWatchedFiles = {
  --         dynamicRegistration = false,
  --         relativePatternSupport = false,
  --       }
  --     end
  --   end
  -- end
end

--- Ensure LSP binaries are installed with mason-lspconfig.
---@param servers table<string, vim.lsp.Config>
local function ensure_servers_installed(servers)
  local supported_servers = {}
  local lspmasonmapping = require("mason-lspconfig").get_mappings().lspconfig_to_package

  local have_mason_lspconfig, _ = pcall(require, "mason-lspconfig")
  if have_mason_lspconfig then
    supported_servers = vim.tbl_keys(lspmasonmapping)
    local enabled_servers = {
      -- pyright = "delance-langserver",
      -- ruff = "ruff",
      -- lua_ls = "lua-language-server",
      -- -- ltex = "ltex-ls",
      -- -- clangd = "clangd",
      -- bashls = "bash-language-server",
      -- dockerls = "docker-langserver",
      -- basedpyright = "basedpyright-langserver",
      -- yamlls = "yaml-language-server",
      -- jsonls = "vscode-json-language-server",
      -- graphql = "graphql-lsp",
      -- gopls = "gopls",
      -- zls = "zls",
      -- vtsls = "vtsls",
      -- templ = "templ",
      -- -- terraformls = "terraform-ls",
      -- superhtml = "superhtml",
      -- buf_ls = "buf",
      -- ruby_lsp = "ruby-lsp",
    }
    for server_name, lsp_executable in pairs(servers) do
      if lsp_executable then
        vim.lsp.enable(server_name)
        if lsp_executable.mason ~= false and vim.tbl_contains(supported_servers, server_name) then
          table.insert(enabled_servers, server_name)
        else
          local msg = string.format(
            "Executable '%s' for server '%s' not found! Server will not be enabled",
            lsp_executable,
            server_name
          )
          vim.notify(msg, vim.log.levels.WARN, { title = "Nvim-config" })
        end
      end
    end
    -- See `:h mason-lspconfig
    require("mason-lspconfig").setup({
      ---@type string[]
      ensure_installed = enabled_servers,
    })
  end
end

--- Configure and enable LSP servers.
---
--- Use native vim.lsp functionality
--- https://github.com/neovim/neovim/pull/31031
--- https://github.com/neovim/nvim-lspconfig/pull/3659
---
---@param servers table<string, vim.lsp.Config>
local function register_lsp_servers(servers)
  for server, server_opts in pairs(servers) do
    if server_opts.cmd == nil then
      vim.notify("No cmd specified for LSP server: " .. server, vim.log.levels.ERROR)
    end
    if server_opts.filetypes == nil then
      vim.notify("No filetypes specified for LSP server: " .. server, vim.log.levels.ERROR)
    end
    if not server_opts.root_dir and not server_opts.root_markers then
      vim.notify("No root_dir or root_markers specified for LSP server: " .. server, vim.log.levels.ERROR)
    end
    if server_opts.root_dir and server_opts.root_markers then
      vim.notify(
        "Both root_dir and root_markers specified for LSP server (root_dir will be used): " .. server,
        vim.log.levels.ERROR
      )
    end

    vim.lsp.config[server] = server_opts -- NOTE: overwrite
    -- vim.lsp.config(server, server_opts) -- NOTE: extend
    vim.lsp.enable(server, true)
  end
end

-- Register LSP attach autocmd.
local function register_lspattach_autocmd()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
    ---@param args vim.api.keyset.create_autocmd.callback_args
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        -- set up codelens
        if client:supports_method("textDocument/codeLens", args.buf) then
          vim.lsp.codelens.refresh()
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = args.buf,
            callback = vim.lsp.codelens.refresh,
          })
        end

        -- setup LSP-provided folding
        if client:supports_method("textDocument/foldingRange", args.buf) then
          require("fredrik.config.options").lsp_foldexpr()
        end

        -- set up workspace diagnostics
        require("workspace-diagnostics").populate_workspace_diagnostics(client, args.buf)
      end

      -- set up keymaps
      require("fredrik.config.keymaps").setup_lsp_autocmd_keymaps(args.buf)
    end,
  })
end

return {
  {
    "neovim/nvim-lspconfig",
    -- virtual = true, -- NOTE: not an actual plugin
    lazy = false,
    -- event = "VeryLazy",
    dependencies = {
      "jose-elias-alvarez/typescript.nvim",
      {
        -- the new lspconfig with vim.lsp servers
        "TheRealLorenz/nvim-lspconfig",
        -- opts = function()
        --   local lspconfig = require("lspconfig").gopls
        --   vim.notify(vim.inspect(lspconfig.gopls))
        -- end,
      },
      {
        "williamboman/mason-lspconfig.nvim",
        -- NOTE: this is here because mason-lspconfig must install servers prior to running nvim-lspconfig
        lazy = false,
        dependencies = {
          {
            -- NOTE: this is here because mason.setup must run prior to running nvim-lspconfig
            -- see mason.lua for more settings.
            "williamboman/mason.nvim",
            lazy = false,
          },
        },
      },
      {
        "saghen/blink.cmp",
        opts_extend = {
          "sources.default",
        },
      },
      {
        "artemave/workspace-diagnostics.nvim",
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        zls = {
          -- lsp: https://github.com/zigtools/zls
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/zls.lua
          cmd = { "zls" },
          filetypes = { "zig", "zir" },
          root_markers = { "zls.json", "build.zig" },
          settings = {
            zls = {},
          },
        },

        ---@type vim.lsp.Config
        yamlls = {
          -- lsp: https://github.com/redhat-developer/yaml-language-server
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/yamlls.lua
          cmd = { "yaml-language-server", "--stdio" },
          filetypes = { "yaml", "gha", "dependabot", "yaml", "yaml.docker-compose", "yaml.gitlab" },
          root_markers = { ".git" },
          settings = {
            -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
            redhat = { telemetry = { enabled = false } },
          },
        },

        ---@type vim.lsp.Config
        vtsls = {
          -- lsp: https://github.com/yioneko/vtsls
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/vtsls.lua
          cmd = { "vtsls", "--stdio" },
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
          init_options = {
            hostInfo = "neovim",
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
            javascript = { -- NOTE: just copy the typescript settings here
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
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
        },

        ---@type vim.lsp.Config
        -- taplo = {
        --   -- lsp: https://taplo.tamasfe.dev/cli/usage/language-server.html
        --   -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/taplo.lua
        --   cmd = { "taplo", "lsp", "stdio" },
        --   filetypes = { "toml" },
        --   root_markers = { ".git" },
        --   settings = {
        --     taplo = {},
        --   },
        -- },

        ---@type vim.lsp.Config
        -- terraformls = {
        --   -- lsp: https://github.com/hashicorp/terraform-ls
        --   -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/terraformls.lua
        --   cmd = { "terraform-ls", "serve" },
        --   filetypes = { "terraform", "tf", "terraform-vars" },
        --   root_markers = { ".terraform", "terraform" },
        --   settings = {
        --     terraformls = {},
        --   },
        -- },

        ------@type vim.lsp.Config
        ---templ = {
        ---  -- lsp: https://templ.guide/developer-tools/ide-support#neovim--050
        ---  -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/templ.lua
        ---  cmd = { "templ", "lsp" },
        ---  filetypes = { "templ" },
        ---  root_markers = { "go.work", "go.mod", ".git" },
        ---  settings = {
        ---    templ = {},
        ---  },
        ---},

        ---@type vim.lsp.Config
        bashls = {
          -- lsp: https://github.com/bash-lsp/bash-language-server
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/bashls.lua
          cmd = { "bash-language-server", "start" },
          filetypes = { "sh" },
          root_markers = { ".git" },
          settings = {
            bashIde = {
              -- Glob pattern for finding and parsing shell script files in the workspace.
              -- Used by the background analysis features across files.

              -- Prevent recursive scanning which will cause issues when opening a file
              -- directly in the home directory (e.g. ~/foo.sh).
              --
              -- Default upstream pattern is "**/*@(.sh|.inc|.bash|.command)".
              -- globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
            },
          },
        },

        ------@type vim.lsp.Config
        ---buf_ls = {
        ---  -- lsp: https://github.com/bufbuild/buf
        ---  -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/protols.lua
        ---  cmd = { "buf", "beta", "lsp", "--timeout=0", "--log-format=text" },
        ---  filetypes = { "proto" },
        ---  root_markers = { "buf.yaml", "buf.yml", ".git" },
        ---  settings = {
        ---    buf_ls = {},
        ---  },
        ---},
        ---@type vim.lsp.Config
        lua_ls = {
          -- lsp: https://github.com/luals/lua-language-server
          -- reference: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/lua_ls.lua
          cmd = { "lua-language-server" },

          filetypes = { "lua" },
          root_markers = {
            ".luarc.json",
            ".luarc.jsonc",
            ".luacheckrc",
            ".stylua.toml",
            "stylua.toml",
            "selene.toml",
            "selene.yml",
            ".git",
          },
          log_level = vim.lsp.protocol.MessageType.Warning,
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = false, -- causes annoying flickering
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
            },
          },
        },

        ---@type vim.lsp.Config
        jsonls = {
          -- lsp: https://github.com/microsoft/vscode-json-languageservice
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/jsonls.lua
          cmd = { "vscode-json-language-server", "--stdio" },
          filetypes = { "json", "jsonc", "json5" },
          root_markers = { ".git" },
          init_options = {
            provideFormatter = false, -- use conform.nvim instead
          },
          settings = {
            json = {
              validate = { enable = true },
            },
          },
        },
        --- https://github.com/kristoff-it/superhtml
        ---@type vim.lsp.Config
        superhtml = {
          cmd = { "superhtml", "lsp" },
          filetypes = { "html", "shtml", "htm", "gotmpl", "gohtml" },
          root_markers = { ".git" },
          settings = {
            superhtml = {},
          },
        },

        ---@type vim.lsp.Config
        graphql = {
          -- cli: https://github.com/graphql/graphiql/blob/main/packages/graphql-language-service-server/README.md
          -- lsp: https://www.npmjs.com/package/graphql-language-service-cli
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/graphql.lua
          cmd = { "graphql-lsp", "server", "-m", "stream" },
          filetypes = { "graphql" },
          root_markers = { ".graphqlrc", ".graphql.config", "graphql.config" },
          settings = {
            graphql = {},
          },
        },
        ------@type vim.lsp.Config
        ---gopls = {
        ---  -- lsp: https://github.com/golang/tools/blob/master/gopls
        ---  -- reference: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/gopls.lua
        ---  --
        ---  -- main readme: https://github.com/golang/tools/blob/master/gopls/doc/features/README.md
        ---  --
        ---  -- for all options, see:
        ---  -- https://github.com/golang/tools/blob/master/gopls/doc/vim.md
        ---  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
        ---  -- for more details, also see:
        ---  -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
        ---  -- https://github.com/golang/tools/blob/master/gopls/README.md
        ---  cmd = { "gopls" },
        ---  filetypes = { "go", "gomod", "gowork", "gosum" },
        ---  root_markers = { "go.work", "go.mod", ".git" },
        ---  settings = {
        ---    gopls = {
        ---      buildFlags = { "-tags=wireinject,integration" },
        ---      -- env = {},
        ---      -- analyses = {
        ---      --   -- https://github.com/golang/tools/blob/master/gopls/internal/settings/analysis.go
        ---      --   -- https://github.com/golang/tools/blob/master/gopls/doc/analyzers.md
        ---      -- },
        ---      -- codelenses = {
        ---      --   -- https://github.com/golang/tools/blob/master/gopls/doc/codelenses.md
        ---      --   -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
        ---      -- },
        ---      hints = {
        ---        -- https://github.com/golang/tools/blob/master/gopls/doc/inlayHints.md
        ---        -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
        ---
        ---        parameterNames = true,
        ---        assignVariableTypes = true,
        ---        constantValues = true,
        ---        compositeLiteralTypes = true,
        ---        compositeLiteralFields = true,
        ---        functionTypeParameters = true,
        ---      },
        ---      -- completion options
        ---      -- https://github.com/golang/tools/blob/master/gopls/doc/features/completion.md
        ---      -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
        ---
        ---      -- build options
        ---      -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
        ---      -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md#build
        ---      directoryFilters = { "-**/node_modules", "-**/.git", "-.vscode", "-.idea", "-.vscode-test" },
        ---
        ---      -- formatting options
        ---      -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
        ---      gofumpt = false, -- handled by conform instead.
        ---
        ---      -- ui options
        ---      -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
        ---      semanticTokens = false, -- disabling this enables treesitter injections (for sql, json etc)
        ---
        ---      -- diagnostic options
        ---      -- https://github.com/golang/tools/blob/master/gopls/internal/settings/settings.go
        ---      staticcheck = true,
        ---      vulncheck = "imports",
        ---      analysisProgressReporting = true,
        ---    },
        ---  },
        ---},
        ---
        ---@type vim.lsp.Config
        basedpyright = {
          -- lsp: https://github.com/DetachHead/basedpyright
          --      https://docs.basedpyright.com/latest/configuration/language-server-settings/
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/basedpyright.lua
          cmd = { "basedpyright-langserver", "--stdio" },
          filetypes = { "python" },
          root_markers = {
            "pyproject.toml",
            "ruff.toml",
            ".ruff.toml",
            "requirements.txt",
            "uv.lock",
            "setup.py",
            "setup.cfg",
            "Pipfile",
            "pyrightconfig.json",
            ".git",
          },
          log_level = vim.lsp.protocol.MessageType.Debug,
          settings = {
            python = {
              venvPath = os.getenv("VIRTUAL_ENV"),
              pythonPath = vim.fn.exepath("python"),
            },
            basedpyright = {
              -- https://docs.basedpyright.com/#/settings
              disableOrganizeImports = true, -- deletgate to ruff
              analysis = {
                -- NOTE: uncomment this to ignore linting. Good for projects where
                -- basedpyright lights up as a christmas tree.
                ignore = { "*" },
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },
        ruby_lsp = {
          mason = true,
          cmd = { "ruby-lsp" },
          filetypes = { "ruby", "Vagrantfile" },
          -- root_markers = { "Vagrantfile" },
          -- cmd = { vim.fn.expand("~/.asdf/shims/ruby-lsp") },
          root_dir = function(fname)
            return require("lspconfig").util.root_pattern("Gemfile", ".git", "Vagrantfile")(fname) or vim.fn.getcwd()
          end,
          formatter = "none",
        },
        ---@type vim.lsp.Config
        dockerls = {
          cmd = { "docker-langserver", "--stdio" },
          filetypes = { "dockerfile" },
          root_markers = { "Dockerfile" },
          settings = {
            docker = {},
          },
        },

        ---@type vim.lsp.Config
        ruff = {
          -- lsp: https://docs.astral.sh/ruff/editors/setup/#neovim
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/ruff.lua
          cmd = { "ruff", "server" },
          filetypes = { "python" },
          root_markers = {
            "pyproject.toml",
            "ruff.toml",
            ".ruff.toml",
            "requirements.txt",
            "uv.lock",
            "setup.py",
            "setup.cfg",
            "Pipfile",
            "pyrightconfig.json",
            ".git",
          },
          -- root_dir = (function()
          --   return vim.fs.root(0, root_files)
          -- end)(),
          on_attach = function(client, bufnr)
            if client.name == "ruff" then
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
            end
          end,
          -- HACK: explicitly setting offset encoding:
          -- https://github.com/astral-sh/ruff/issues/14483#issuecomment-2526717736
          capabilities = {
            general = {
              -- positionEncodings = { "utf-8", "utf-16", "utf-32" }  <--- this is the default
              positionEncodings = { "utf-16" },
            },
          },
          init_options = {
            settings = {
              -- https://docs.astral.sh/ruff/editors/settings/
              configurationPreference = "filesystemFirst",
              lineLength = 88,
            },
          },
          settings = {
            ruff = {},
          },
        },
        -- -- Example LSP settings below for opts.servers:
        -- lua_ls = {
        --   cmd = { ... },
        --   filetypes = { ... },
        --   root_dir = function() ... end,
        --   root_markers = { ... },
        --   on_attach = { ... },
        --   capabilities = { ... },
        --   settings = {
        --     Lua = {
        --       workspace = {
        --         checkThirdParty = false,
        --       },
        --       codeLens = {
        --         enable = true,
        --       },
        --       completion = {
        --         callSnippet = "Replace",
        --       },
        --     },
        --   },
        -- },
      },
    },
    config = function(_, opts)
      extend_capabilities(opts.servers)
      ensure_servers_installed(opts.servers)
      register_lsp_servers(opts.servers)
      register_lspattach_autocmd()

      require("fredrik.config.keymaps").setup_lsp_keymaps()
    end,
  },
}
