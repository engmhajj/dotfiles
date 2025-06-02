local actions = require("telescope.actions")
local trouble = require("trouble")
-- local trouble_telescope = require("trouble.sources.telescope")

local function open_trouble(prompt_bufnr)
  local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  local selection = picker:get_selection()
  local bufnr = selection.bufnr

  if bufnr then
    -- Open Trouble with the selected buffer
    trouble.open({
      mode = "diagnostics",
      bufnr = bufnr,
    })
  end
end

return {
  {
    "liangxianzhe/floating-input.nvim",
  },
  {
    "nvim-telescope/telescope.nvim",
    lazy = true,
    event = "VeryLazy",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        enabled = (vim.fn.executable("make") == 1)
          and (vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1),
        build = "make",
      },
      "nvim-telescope/telescope-live-grep-args.nvim",
      "smartpde/telescope-recent-files",
      "nvim-telescope/telescope-project.nvim",
      "gbprod/yanky.nvim",
      "folke/trouble.nvim",
    },
    opts = function(_, opts)
      local custom_opts = {
        defaults = {
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--hidden",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--trim",
            "--glob",
            "!**/.git/*",
            "--glob",
            "!**/node_modules/*",
          },
          mappings = {
            i = {
              ["<C-t>"] = open_trouble,
              ["<C-x>"] = require("trouble").close(),
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
          },
          buffers = {
            sort_lastused = true,
            -- theme = "dropdown",
            -- previewer = false,
            mappings = {
              i = {
                ["<C-d>"] = require("telescope.actions").delete_buffer,
              },
              n = {
                ["<C-d>"] = require("telescope.actions").delete_buffer,
              },
            },
          },
        },
        extensions = {
          ["ui-select"] = require("telescope.themes").get_dropdown({}),
          recent_files = { only_cwd = true },
          project = {
            base_dirs = {
              { path = vim.fn.expand("~/.dotfiles"), max_depth = 1 },
              { path = vim.fn.expand("~/code"), max_depth = 3 },
            },
            cd_scope = { "global", "tab", "window" },
            on_project_selected = function(prompt_bufnr)
              if vim.g.project_set_cwd then
                local persistence = require("persistence")
                persistence.fire("SavePre")
                persistence.save()
                persistence.fire("SavePost")
                require("telescope._extensions.project.actions").change_working_directory(prompt_bufnr, false)
                persistence.load()
              else
                local builtin = require("telescope.builtin")
                local path = require("telescope._extensions.project.actions").get_selected_path(prompt_bufnr)
                builtin.find_files({ cwd = path })
              end
            end,
          },
        },
      }
      return vim.tbl_deep_extend("force", custom_opts, opts or {})
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)

      -- Load all required extensions
      telescope.load_extension("fzf")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("ui-select")
      telescope.load_extension("recent_files")
      telescope.load_extension("project")
      telescope.load_extension("yank_history")
    end,
    keys = require("config.keymaps").setup_telescope_keymaps(),
  },
}
