--[=====[
Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/project-explorer.lua
~/github/dotfiles-latest/neovim/neobean/lua/plugins/project-explorer.lua

https://github.com/Rics-Dev/project-explorer.nvim

Found out about this through reddit
https://www.reddit.com/r/neovim/comments/1ef1b2q/my_first_ever_neovim_plugin_a_simple_project/

This plugin allows me to explore different projects when using neovide, to kind 
of simulate the tmux-sessionizer functionality, as tmux is not available in neovide
--]=====]
-- if true then
--   return {}
-- end
return {
  "Rics-Dev/project-explorer.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  opts = {
    paths = {
      "~/code",
      os.getenv("HOME") .. "~/code",
      -- "/System/Volumes/Data/mnt",
    }, --custom paths set by user
    newProjectPath = "~/code", --custom path for new projects
    file_explorer = function(dir) --custom file explorer set by user
      Snacks.config.explorer.replace_netrw = true
      Snacks.explorer.open({
        on_close = function()
          Snacks.explorer.open()
        end,
      })
      -- -- By default it uses neotree but I changed it for mini.files
      -- vim.cmd("Neotree " .. dir)
      -- vim.cmd("Neotree close")
      --vim.cmd("Neotree " .. dir)
    end,
    -- Or for oil.nvim:
    -- file_explorer = function(dir)
    --   require("oil").open(dir)
    -- end,
  },
  config = function(_, opts)
    require("project_explorer").setup(opts)
  end,
  keys = {
    { "<leader>fp", "<cmd>ProjectExplorer<cr>", desc = "Code Project Explorer" },
  },
  lazy = false,
}
