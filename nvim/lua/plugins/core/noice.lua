return {
  {
    "folke/noice.nvim",
    lazy = false, -- avoid lualine jumping on startup
    dependencies = {
      "MunifTanjim/nui.nvim",
      {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
          local function mode()
            local mode_ = require("noice").api.status.mode.get()
            local filters = { "INSERT", "VISUAL", "TERMINAL" }
            for _, filter in ipairs(filters) do
              if string.find(mode_, filter) then
                return "" -- hide these modes from noice component
              end
            end
            return mode_
          end

          opts.noice = {
            lualine_component = {
              mode,
              cond = function()
                return package.loaded["noice"] and require("noice").api.status.mode.has()
              end,
              color = require("utils.colors").fgcolor("Constant"),
            },
          }
        end,
      },
    },
    config = function()
      require("noice").setup({
        lsp = {
          signature = {
            enabled = false, -- handled by blink.cmp
          },
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
          },
        },
        presets = {
          bottom_search = false,       -- classic bottom cmdline for search
          command_palette = true,      -- position cmdline & popupmenu together
          long_message_to_split = true, -- long messages go to a split
          inc_rename = false,          -- disables input dialog for inc-rename.nvim
          lsp_doc_border = true,       -- add border to hover docs and signature help
        },
      })
    end,
  },
}
