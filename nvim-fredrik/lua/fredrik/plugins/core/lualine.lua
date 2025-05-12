local function folder()
  local cwd = vim.fn.getcwd()
  local foldername = cwd:match("([^/]+)$")
  return foldername
end
local icons = require("fredrik.utils.icons")
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "zbirenbaum/copilot.lua",
  },
  opts = {

    -- see copilot.lua...
    -- copilot = {
    --   lualine_component = "filename",
    -- },
    --
    -- see debug.lua...
    -- dap_status = {
    --  lualine_component = "filename",
    --  },
    --
    -- see noice.lua...
    -- noice = {
    --   lualine_component = "filename",
    -- },
    --   
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
        {
          "hostname",
          symbols = {
            readonly = "[🔒]",
          },
        },
        "mode",
        {
          "buffers",
          show_filename_only = true,
          hide_filename_extension = true, -- Hide filename extension when set to true.
          show_modified_status = true,
          mode = 2,
          max_length = vim.o.columns * 0.5,
          -- buffers_color = {
          --   -- Same values as the general color option can be used here.
          --   active = "#00ff00", -- Color for active buffer.
          --   inactive = "lualine_{section}_inactive", -- Color for inactive buffer.
          -- },

          symbols = {
            modified = "✏️", -- Text to show when the buffer is modified
            alternate_file = "🔀", -- Text to show to identify the alternate file
            directory = "", -- Text to show when the buffer is a directory
          },
          filetype_names = {
            TelescopePrompt = "Telescope",
            fzf = "FZF",
            fzf_list = "FZF",
            fzf_lua = "FZF",
            lazy = "Lazy",
            lazyterm = "LazyTerm",
            NvimTree = "NvimTree",
            startify = "Startify",
          },
        },
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
        },

        {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          symbols = { error = "⛔ ", warn = "⚠️ ", info = "ℹ️ ", hint = "💡" },
        },
        {
          "diff",
          symbols = {
            added = icons.icons.git.added,
            modified = icons.icons.git.modified,
            removed = icons.icons.git.removed,
          },
        },
      },
      lualine_c = {
        { folder, color = { gui = "bold" }, separator = "/", padding = { left = 1, right = 0 } },
      },
      lualine_x = {
        {
          function()
            return require("auto-session.lib").current_session_name(true)
          end,
          cond = function()
            return vim.g.custom_lualine_show_session_name
          end,
        },
        "encoding",
        { "lsp_status", icon = "📡" },
        {
          function()
            return "recording @" .. vim.fn.reg_recording()
          end,
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
  opts_extend = {
    "options.disabled_filetypes",
    "sections.extensions",
  },
  config = function(_, opts)
    -- TODO: make more generic insertion function which can insert anywhere.
    if opts.copilot then
      table.insert(opts.sections.lualine_x, 1, opts.copilot.lualine_component)
    else
      vim.notify("Lualine: copilot component not loaded", vim.log.levels.WARN)
    end

    if opts.dap_status then
      table.insert(opts.sections.lualine_x, 2, opts.dap_status.lualine_component)
    else
      vim.notify("Lualine: dap_status component not loaded", vim.log.levels.WARN)
    end

    if opts.noice then
      table.insert(opts.sections.lualine_x, 3, opts.noice.lualine_component)
    else
      vim.notify("Lualine: noice component not loaded", vim.log.levels.WARN)
    end

    require("lualine").setup(opts)
  end,
}
