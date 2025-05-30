return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "InsertLeave" },
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    local lint = require("lint")

    -- Helper to get filename safely
    local function safe_filename(ctx)
      return (ctx and ctx.filename) or vim.api.nvim_buf_get_name(0)
    end

    -- Linters by filetype
    lint.linters_by_ft = {
      lua = { "luacheck" },
      python = { "mypy" },
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      markdown = { "markdownlint" },
      yaml = { "yamllint" },
      dockerfile = { "hadolint" },
      bash = { "shellcheck" },
      toml = { "taplo" },
      zig = { "zls" },
      ruby = { "standardrb" },
      rust = { "rustfmt" },
      go = { "gofmt" },
      sh = { "shellcheck" },
      gha = { "actionlint" },
      cs = { "csharpier" },
      razor = { "razor_wrapper" },
    }

    -- ESLint via eslint_d
    lint.linters.eslint_d = {
      cmd = "eslint_d",
      stdin = true,
      args = {
        "--stdin",
        "--stdin-filename",
        function(ctx)
          return safe_filename(ctx)
        end,
      },
    }

    -- YAML linter
    lint.linters.yamllint = {
      cmd = "yamllint",
      stdin = true,
      args = {
        "--format",
        "parsable",
        "-",
      },
    }

    -- C# linter using CSharpier
    lint.linters.csharpier = {
      cmd = "csharpier",
      stdin = true,
      stream = "stdout",
      ignore_exitcode = true,
      args = {
        "--write-stdout",
        function(ctx)
          return safe_filename(ctx)
        end,
      },
    }

    -- Razor wrapper linter (fake/placeholder)
    lint.linters.razor_wrapper = {
      cmd = "bash",
      stdin = false,
      args = {
        "-c",
        function(ctx)
          return "echo 'No razor linter configured. Skipping: " .. safe_filename(ctx) .. "'"
        end,
      },
      condition = function(ctx)
        return ctx and vim.fn.fnamemodify(ctx.filename, ":e") == "cshtml"
      end,
    }

    -- Debounce utility
    local function debounce(ms, fn)
      local timer = vim.uv.new_timer()
      return function(...)
        local args = { ... }
        timer:start(ms, 0, function()
          timer:stop()
          vim.schedule_wrap(fn)(unpack(args))
        end)
      end
    end

    local function do_lint()
      lint.try_lint()
    end

    -- Autocommand to trigger linting
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("NvimLinting", { clear = true }),
      callback = debounce(100, do_lint),
    })
  end,
}
