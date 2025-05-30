local function folder()
  -- Cross-platform way to get folder name from cwd
  local cwd = vim.fn.getcwd()
  return vim.fn.fnamemodify(cwd, ":t")
end

-- Safely require icons
local ok_icons, icons = pcall(require, "utils.icons")

local hostname = require("utils.statusline.hostname").get
local lsp_status = require("utils.statusline.lsp").status
local session_name = require("utils.statusline.session").name
local macro_recording = require("utils.statusline.macro").recording
local rest_status = require("utils.statusline.rest").status

return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "zbirenbaum/copilot.lua",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    options = {
      theme = "auto",
      icons_enabled = true,
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      globalstatus = true,
      disabled_filetypes = {
        statusline = { "dashboard", "lazy" },
        winbar = {
          "dap-repl",
          "dapui_breakpoints",
          "dapui_console",
          "dapui_scopes",
          "dapui_stacks",
          "dapui_watches",
          "dashboard",
          "help",
          "neogitstatus",
          "qf",
          "startify",
          "toggleterm",
        },
      },
      always_divide_middle = true,
    },

    sections = {
      lualine_a = {
        { hostname, icon = "💻" },
        "mode",
        {
          "filename",
          path = 1, -- 0: just the filename, 1: relative path, 2: absolute path
          shorting_target = 40,
          symbols = {
            modified = "✏️ ",
            readonly = "🔒 ",
            unnamed = "[No Name]",
            newfile = "[New File]",
          },
        },
        -- {
        --   "buffers",
        --   show_filename_only = true,
        --   hide_filename_extension = true,
        --   show_modified_status = true,
        --   mode = 2,
        --   max_length = vim.o.columns * 0.4,
        --   symbols = {
        --     modified = "✏️",
        --     alternate_file = "🔀",
        --     directory = "",
        --   },
        --   filetype_names = {
        --     TelescopePrompt = "Telescope",
        --     fzf = "FZF",
        --     fzf_list = "FZF",
        --     fzf_lua = "FZF",
        --     lazy = "Lazy",
        --     lazyterm = "LazyTerm",
        --     NvimTree = "NvimTree",
        --     startify = "Startify",
        --   },
        -- },
      },
      lualine_b = {
        {
          "branch",
          fmt = function(str)
            local slash_index = str:find("/")
            if slash_index then
              return str:sub(1, slash_index) .. "..."
            elseif #str > 12 then
              return str:sub(1, 9) .. "..."
            else
              return str
            end
          end,
          color = function()
            local dict = vim.b.gitsigns_status_dict
            if dict and dict.head then
              return { fg = "#87ff87", gui = "bold" } -- green
            end
            return { fg = "#ffaf00" } -- fallback yellow
          end,
        },
        {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          symbols = { error = "⛔ ", warn = "⚠️ ", info = "ℹ️ ", hint = "💡" },
        },
        {
          "diff",
          symbols = {
            added = ok_icons and icons.icons.git.added or "+",
            modified = ok_icons and icons.icons.git.modified or "~",
            removed = ok_icons and icons.icons.git.removed or "-",
          },
        },
      },
      lualine_c = {
        { folder, color = { gui = "bold" }, separator = "/", padding = { left = 1, right = 0 } },
      },
      lualine_x = {
        {
          function()
            local name = session_name()
            if #name > 20 then
              return name:sub(1, 17) .. "..."
            end
            return name
          end,
          cond = function()
            return vim.g.custom_lualine_show_session_name
          end,
        },
        { rest_status, icon = "", color = { fg = "#428890" } },
        "encoding",
        { lsp_status, icon = "📡" },
        {
          macro_recording,
          cond = function()
            return vim.fn.reg_recording() ~= ""
          end,
          color = { fg = "#ff007c" },
        },
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },

    extensions = { "lazy", "man", "quickfix" },
  },

  config = function(_, opts)
    local function safe_insert(component, key, index)
      if component then
        table.insert(opts.sections.lualine_x, index, component.lualine_component)
      else
        vim.notify("Lualine: " .. key .. " component not loaded", vim.log.levels.WARN)
      end
    end

    safe_insert(opts.copilot, "copilot", 1)
    safe_insert(opts.dap_status, "dap_status", 2)
    safe_insert(opts.noice, "noice", 3)

    require("lualine").setup(opts)
  end,
}
