if not require("fredrik.config").pde.csharp then
  return {}
end

--- @param name string
--- @return string

local omnisharp_bin = "/Users/mohamadelhajhassan/.local/share/fredrik/mason/packages/omnisharp/OmniSharp"

local function getCurrentFileDirName()
  local fullPath = vim.fn.expand("%:p:h") -- Get the full path of the directory containing the current file
  local dirName = fullPath:match("([^/\\]+)$") -- Extract the directory name
  return dirName
end

-- vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
--   pattern = { "*.cs", "cs" },
--   callback = function()
--     vim.opt_local.tabstop = 4
--     vim.opt_local.softtabstop = 4
--     vim.opt_local.shiftwidth = 4
--     vim.opt_local.expandtab = true
--     vim.opt_local.colorcolumn = "120"
--   end,
-- })
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "c_sharp" })
    end,
  },
  {
    "virtual-lsp-config",
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
          {
            "williamboman/mason.nvim",
            opts = function(_, opts)
              opts.ensure_installed = opts.ensure_installed or {}
              vim.list_extend(opts.ensure_installed, {
                -- "csharp-language-server",
                "omnisharp",
                "netcoredbg",
              })
            end,
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, {})
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        ---@type vim.lsp.Config
        omnisharp = {
          organize_imports_on_format = true,
          enable_import_completion = true,
          root_markers = { ".sln", ".csproj" },
          filetypes = { "cs" },
          cmd = { omnisharp_bin, "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
          on_attach = function(client, bufnr)
            if client.name == "omnisharp" then
              client.server_capabilities.semanticTokensProvider = {
                full = vim.empty_dict(),
                legend = {
                  tokenModifiers = { "static_symbol" },
                  tokenTypes = {
                    "comment",
                    "excluded_code",
                    "identifier",
                    "keyword",
                    "keyword_control",
                    "number",
                    "operator",
                    "operator_overloaded",
                    "preprocessor_keyword",
                    "string",
                    "whitespace",
                    "text",
                    "static_symbol",
                    "preprocessor_text",
                    "punctuation",
                    "string_verbatim",
                    "string_escape_character",
                    "class_name",
                    "delegate_name",
                    "enum_name",
                    "interface_name",
                    "module_name",
                    "struct_name",
                    "type_parameter_name",
                    "field_name",
                    "enum_member_name",
                    "constant_name",
                    "local_name",
                    "parameter_name",
                    "method_name",
                    "extension_method_name",
                    "property_name",
                    "event_name",
                    "namespace_name",
                    "label_name",
                    "xml_doc_comment_attribute_name",
                    "xml_doc_comment_attribute_quotes",
                    "xml_doc_comment_attribute_value",
                    "xml_doc_comment_cdata_section",
                    "xml_doc_comment_comment",
                    "xml_doc_comment_delimiter",
                    "xml_doc_comment_entity_reference",
                    "xml_doc_comment_name",
                    "xml_doc_comment_processing_instruction",
                    "xml_doc_comment_text",
                    "xml_literal_attribute_name",
                    "xml_literal_attribute_quotes",
                    "xml_literal_attribute_value",
                    "xml_literal_cdata_section",
                    "xml_literal_comment",
                    "xml_literal_delimiter",
                    "xml_literal_embedded_expression",
                    "xml_literal_entity_reference",
                    "xml_literal_name",
                    "xml_literal_processing_instruction",
                    "xml_literal_text",
                    "regex_comment",
                    "regex_character_class",
                    "regex_anchor",
                    "regex_quantifier",
                    "regex_grouping",
                    "regex_alternation",
                    "regex_text",
                    "regex_self_escaped_character",
                    "regex_other_escape",
                  },
                },
                range = true,
              }
            end
            vim.keymap.set(
              "n",
              "gd",
              "<cmd>lua require('omnisharp_extended').telescope_lsp_definitions()<cr>",
              { buffer = bufnr, desc = "Goto [d]efinition" }
            )

            vim.keymap.set(
              "n",
              "gr",
              "<cmd>lua require('omnisharp_extended').telescope_lsp_references()<cr>",
              { buffer = bufnr, desc = "Goto [r]eferences" }
            )

            vim.keymap.set(
              "n",
              "gI",
              "<cmd>lua require('omnisharp_extended').telescope_lsp_implementation()<cr>",
              { buffer = bufnr, desc = "Goto [I]mplementation" }
            )
            vim.keymap.set(
              "n",
              "gD",
              "<cmd>lua require('omnisharp_extended').telescope_type_definitions()<cr>",
              { buffer = bufnr, desc = "Goto Type [D]efinition" }
            )
            vim.keymap.set(
              "n",
              "<space>rW",
              "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",
              { buffer = bufnr, desc = "[A]dd workspace folder" }
            )
            vim.keymap.set(
              "n",
              "<space>rx",
              "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
              { buffer = bufnr, desc = "Remove workspace folder" }
            )

            vim.keymap.set(
              "n",
              "<space>rl",
              "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>",
              { buffer = bufnr, desc = "List workspace folders" }
            )
            vim.keymap.set("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", { buffer = bufnr, desc = "Rename" })
            -- https://github.com/OmniSharp/omnisharp-roslyn/issues/2483
            local function toSnakeCase(str)
              return string.gsub(str, "%s*[- ]%s*", "_")
            end

            local tokenModifiers = client.server_capabilities.semanticTokensProvider.legend.tokenModifiers
            for i, v in ipairs(tokenModifiers) do
              tokenModifiers[i] = toSnakeCase(v)
            end
            local tokenTypes = client.server_capabilities.semanticTokensProvider.legend.tokenTypes
            for i, v in ipairs(tokenTypes) do
              tokenTypes[i] = toSnakeCase(v)
            end
          end,

          -- settings = {
          --   omnisharp = {},
          -- },
        },
      },
    },
  },

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

      local function get_plugin_directory()
        local str = debug.getinfo(1, "S").source:sub(2)
        str = str:match("(.*/)") -- Get the directory of the current file
        return str:gsub("/[^/]+/[^/]+/$", "/") -- Go up two directories
      end

      local plugin_directory = get_plugin_directory()
      local netcoredbg_path = plugin_directory .. "netcoredbg/build/src/netcoredbg"

      dap.adapters.cs = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
        -- cwd = function()
        --   return vim.fn.input("Workspace folder: ", vim.fn.getcwd() .. "/", "file")
        -- end,
        env = {
          ASPNETCORE_ENVIRONMENT = function()
            return vim.fn.input("ASPNETCORE_ENVIRONMENT: ", "Development")
          end,
          ASPNETCORE_URL = function()
            return vim.fn.input("ASPNETCORE_URL: ", "http://localhost:7500")
          end,
        },
      }

      vim.api.nvim_create_user_command("RunScriptWithArgs", function(t)
        -- :help nvim_create_user_command
        args = vim.split(vim.fn.expand(t.args), "\n")

        dap.run({
          request = "launch",
          name = "Launch file with custom arguments (adhoc)",
          type = "cs",
          command = netcoredbg_path,
          args = { "--interpreter=vscode", "--engineLogging", "--consoleLogging" },
          program = function()
            return vim.fn.input(
              "Path to dll: ",
              vim.fn.getcwd() .. "/bin/Debug/net9.0/" .. getCurrentFileDirName() .. ".dll",
              "file"
            )
          end,
          cwd = "${fileDirname}" .. getCurrentFileDirName(),
          env = {
            ASPNETCORE_ENVIRONMENT = function()
              return vim.fn.input("ASPNETCORE_ENVIRONMENT: ", "Development")
            end,
            ASPNETCORE_URL = function()
              return vim.fn.input("ASPNETCORE_URL: ", "http://localhost:7500")
            end,
          },
        })
      end, {
        complete = "file",
        nargs = "*",
      })
      vim.keymap.set("n", "<leader>R", ":RunScriptWithArgs ")
    end,
  },
  {
    "nvim-neotest/neotest",
    requires = {
      {
        "Issafalcon/neotest-dotnet",
      },
      opts = function(_, opts)
        vim.list_extend(opts.adapters, {
          require("neotest-dotnet"),
        })
      end,
    },
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "csharpier" })
        end,
      },
    },
    keys = {
      {
        "<leader>rF",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        cs = { "csharpier" },
        xml = { "xmlformat" }, -- Works for both .xml and .xaml files
      },
      -- format_on_save = {
      --   lsp_fallback = true,
      --   timeout_ms = 2000, -- Increased timeout for larger files
      -- },
      formatters = {
        csharpier = {
          command = "dotnet csharpier format .",
          args = { "--write-stdout" },
          stdin = true,
          -- When cwd is not found, don't run the formatter (default false)
          require_cwd = true,

          inherit = true,
          -- When inherit = true, add these additional arguments to the beginning of the command.
          -- This can also be a function, like args
          prepend_args = { "--use-tabs" },
          -- When inherit = true, add these additional arguments to the end of the command.
          -- This can also be a function, like args
          append_args = { "--trailing-comma" },
        },
        xmlformat = {
          command = "xmlformat",
          args = { "--selfclose", "-" },
          stdin = true,
        },
      },
    },
  },
}
