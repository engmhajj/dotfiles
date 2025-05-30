return {
  {
    "folke/trouble.nvim",
    -- lazy = true,
    dependencies = {
      -- icons supported via mini-icons.lua
      "nvim-tree/nvim-web-devicons",
      {
        "nvim-lualine/lualine.nvim",
        opts = {
          extensions = { "trouble" },
        },
      },
    },
    config = function()
      require("trouble").setup({
        mode = "diagnostics", -- or "document_diagnostics" or others
        use_diagnostic_signs = true,
        auto_open = false,
        auto_close = false,
        -- remove float mode settings
        position = "bottom", -- default split position
        height = 10,
        width = 50,
        -- you can customize the border and other settings here
        -- icons = true,
      })
      -- Optional: keymap to toggle Trouble floating popup
      vim.keymap.set("n", "<leader>zt", function()
        require("trouble").toggle("diagnostics")
      end, { desc = "Toggle Trouble" })

      vim.keymap.set("n", "<leader>zd", "<cmd>Telescope diagnostics<cr>", { desc = "Telescope diagnostics picker" })
    end,
    keys = require("config.keymaps").setup_trouble_keymaps(),
  },
}
