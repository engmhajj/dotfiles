return {
  {
    "akinsho/bufferline.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {
      options = {
        mode = "tabs", -- show only tabs
        always_show_bufferline = false, -- hide if only one tab
        diagnostics = "nvim_lsp", -- show LSP diagnostics on buffers
        diagnostics_update_in_insert = false, -- update diagnostics only outside insert mode
        show_close_icon = false, -- hide close icon on bufferline itself
        show_buffer_close_icons = true, -- show close icon on individual buffers
        persist_buffer_sort = true, -- keep the sort order of buffers
        separator_style = "thin", -- line style between buffers (can be "thick", "thin", "slant")
        offsets = { -- adjust offset for file explorer or other windows
          {
            filetype = "NvimTree",
            text = "File Explorer",
            padding = 1,
          },
        },
      },
      highlights = {
        -- Customize highlights (optional)
        fill = {
          bg = "#282c34",
        },
        background = {
          fg = "#5c6370",
          bg = "#282c34",
        },
        buffer_selected = {
          fg = "#ffffff",
          bold = true,
          italic = false,
        },
        close_button = {
          fg = "#ff5c57",
        },
        close_button_visible = {
          fg = "#ff5c57",
        },
        close_button_selected = {
          fg = "#ffffff",
        },
      },
    },
  },
}
