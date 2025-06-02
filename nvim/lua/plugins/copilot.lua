return {
  "zbirenbaum/copilot.lua",
  enabled = false,
  lazy = true,
  event = "InsertEnter",
  commit = "5a8fdd34bb67eadc3f69e46870db0bed0cc9841c",
  dependencies = {
    {
      "nvim-lualine/lualine.nvim",
      event = "VeryLazy",
      opts = function(_, opts)
        local function codepilot()
          return require("utils.icons").icons.kinds.Copilot
        end
        local colors = {
          Offline = require("utils.colors").fgcolor("Comment"),
          [""] = require("utils.colors").fgcolor("Special"),
          InProgress = require("utils.colors").fgcolor("DiagnosticWarning"),
          Normal = require("utils.colors").fgcolor("DiagnosticOk"),
          Warning = require("utils.colors").fgcolor("DiagnosticError"),
        }
        opts.copilot = {
          lualine_component = {
            codepilot,
            color = function()
              if not package.loaded["copilot"] or vim.g.custom_copilot_status == "disabled" then
                return colors.Offline
              else
                local status = require("copilot.api").status
                if status.data.message ~= "" then
                  vim.notify_once("Copilot message: " .. vim.inspect(status.data.message))
                end
                return colors[status.data.status]
              end
            end,
          },
        }
      end,
    },
  },
  cmd = "Copilot",
  build = ":Copilot auth",
  opts = {
    panel = {
      enabled = true,
      auto_refresh = true,
    },
    suggestion = {
      enabled = true,
      auto_trigger = true,
      accept = false,
    },
    filetypes = {
      sh = function()
        local filename = vim.fs.basename(vim.api.nvim_buf_get_name(0))
        if string.match(filename, "^%.env.*") then
          return false
        end
        return true
      end,
      ["*"] = true,
    },
  },
  config = function(_, opts)
    require("copilot").setup(opts)
    if package.loaded["utils.private"] and require("utils.private").toggle_copilot then
      require("utils.private").toggle_copilot()
    end
  end,
  keys = require("config.keymaps").setup_copilot_keymaps(),
}
