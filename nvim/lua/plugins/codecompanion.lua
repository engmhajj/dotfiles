-- Improved CodeCompanion configuration with better structure and error checks

local function read_api_key(secret)
  local key = vim.fn.system("op read " .. secret .. " --no-newline")
  return key ~= "" and key or nil
end

local function safe_extend(adapter, config)
  local status, module = pcall(require, "codecompanion.adapters")
  if not status then
    vim.notify("Failed to load CodeCompanion adapters", vim.log.levels.ERROR)
    return nil
  end
  return module.extend(adapter, config)
end

local supported_adapters = {
  anthropic = function()
    return safe_extend("anthropic", {
      env = {
        api_key = read_api_key("op://Personal/Anthropic/tokens/neovim"),
      },
    })
  end,
  openai = function()
    return safe_extend("openai", {
      env = {
        api_key = read_api_key("op://Personal/OpenAI/tokens/neovim"),
      },
    })
  end,
  gemini = function()
    return safe_extend("gemini", {
      env = {
        api_key = read_api_key("op://Personal/Google/tokens/gemini"),
      },
      schema = {
        model = { default = "gemini-2.5-pro-exp-03-25" },
      },
    })
  end,
  deepseek = function()
    return safe_extend("deepseek", {
      env = {
        api_key = read_api_key("op://Personal/DeepSeek/tokens/neovim"),
      },
    })
  end,
  ollama = function()
    return safe_extend("ollama", {
      schema = {
        model = { default = "gemma3:1b" },
        num_ctx = { default = 16384 },
        num_predict = { default = -1 },
      },
    })
  end,
}

local function save_path()
  local Path = require("plenary.path")
  local p = Path:new(vim.fn.stdpath("data") .. "/codecompanion_chats")
  p:mkdir({ parents = true })
  return p
end

-- Load Chat Command
vim.api.nvim_create_user_command("CodeCompanionLoad", function()
  local fzf = require("fzf-lua")
  local files = vim.fn.glob(save_path() .. "/*", false, true)

  fzf.fzf_exec(files, {
    prompt = "Saved Chats | <c-r>: delete",
    previewer = "builtin",
    actions = {
      ["default"] = function(selected)
        if #selected > 0 then
          local filepath = selected[1]
          fzf.fzf_exec(vim.tbl_keys(supported_adapters), {
            prompt = "Select Adapter > ",
            actions = {
              ["default"] = function(adapter)
                vim.cmd("CodeCompanionChat " .. adapter[1])
                local lines = vim.fn.readfile(filepath)
                vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
              end,
            },
          })
        end
      end,
      ["ctrl-r"] = function(selected)
        os.remove(selected[1])
      end,
    },
  })
end, {})

-- Save Chat Command
vim.api.nvim_create_user_command("CodeCompanionSave", function(opts)
  local codecompanion = require("codecompanion")
  local chat = codecompanion.buf_get_chat(0)
  if not chat then
    return vim.notify("Not in a CodeCompanion chat buffer", vim.log.levels.ERROR)
  end

  if #opts.fargs == 0 then
    return vim.notify("Filename is required", vim.log.levels.ERROR)
  end

  local filename = table.concat(opts.fargs, "-") .. ".md"
  local filepath = save_path():joinpath(filename)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  filepath:write(table.concat(lines, "\n"), "w")
  vim.notify("Chat saved to " .. filepath.filename)
end, { nargs = "*" })

-- Plugin Config
return {
  "olimorris/codecompanion.nvim",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "ravitemer/mcphub.nvim",
    {
      "saghen/blink.cmp",
      opts = {
        fuzzy = { implementation = "prefer_rust_with_warning" },
        sources = {
          default = { "codecompanion", "lsp", "easy-dotnet", "path" },
          providers = {
            ["easy-dotnet"] = {
              name = "easy-dotnet",
              module = "easy-dotnet.completion.blink",
              enabled = true,
              score_offset = 10000,
              async = true,
            },
            codecompanion = {
              name = "CodeCompanion",
              module = "codecompanion.providers.completion.blink",
              enabled = true,
            },
          },
        },
      },
      opts_extend = {
        "sources.default",
      },
    },
  },
  keys = require("config.keymaps").setup_codecompanion_keymaps(),
  opts = {
    adapters = supported_adapters,
    strategies = {
      chat = {
        adapter = "anthropic",
        slash_commands = {
          buffer = { opts = { provider = "snacks" } },
          file = { opts = { provider = "snacks" } },
          help = { opts = { provider = "snacks" } },
          symbols = { opts = { provider = "snacks" } },
        },
        tools = {
          mcp = {
            callback = function()
              return require("mcphub.extensions.codecompanion")
            end,
            description = "Access MCP tools",
            opts = { requires_approval = true },
          },
        },
      },
      inline = { adapter = "copilot" },
      cmd = { adapter = "copilot" },
    },
    display = {
      chat = { show_settings = true },
      action_palette = { provider = "default" },
      diff = { provider = "default" },
    },
    prompt_library = require("utils.llm_prompts").to_codecompanion(),
  },
  config = function(_, opts)
    require("codecompanion").setup(opts)
  end,
}
