return {
  {
    "sindrets/diffview.nvim",
    lazy = true,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      enhanced_diff_hl = true, -- Enhanced syntax highlighting in diffs
      default = {
        disable_diagnostics = false, -- Allow diagnostics in normal diff views
      },
      view = {
        merge_tool = {
          layout = "diff3_mixed", -- Optional: Use 3-way diff view
          disable_diagnostics = false,
          winbar_info = true,
        },
      },
      file_panel = {
        win_config = {
          position = "bottom", -- Optional: default is left, but bottom is more compact
          height = 12,         -- You can control height/width if positioning elsewhere
        },
      },
      hooks = {
        diff_buf_win_enter = function(bufnr)
          vim.opt_local.foldenable = false -- Disable folding in diff view buffers
          -- Optional: set spell checking on in commit messages
          if vim.bo[bufnr].filetype == "gitcommit" then
            vim.opt_local.spell = true
          end
        end,
        view_enter = function()
          -- Optional: open file history to first change
          vim.cmd("normal! ]c")
        end,
      },
    },
    config = function(_, opts)
      require("diffview").setup(opts)
    end,
    keys = require("config.keymaps").setup_diffview_keymaps(),
  },
}
