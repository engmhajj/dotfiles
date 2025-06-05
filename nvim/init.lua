print("init.lua loaded!")

-- debugging of config;
-- 1. start neovim: nvim --cmd "lua init_debug=true" (starts server)
-- 2. start another neovim instance normally, set break points
-- 3. run require("dap").continue() (<leader>dc)
--
---@diagnostic disable-next-line: undefined-global
if init_debug then
  local osvpath = vim.fn.stdpath("data") .. "/lazy/one-small-step-for-vimkind"
  vim.opt.rtp:prepend(osvpath)
  require("osv").launch({ port = 8086, blocking = true })
end

-- set up backwards compatibility
require("utils.version").setup_backwards_compat()

-- ╔═════════════════════╗
-- ║     set options     ║
-- ╚═════════════════════╝
require("config.options")

-- set auto commands
require("config.autocmds")

-- ◤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◥
-- ┃          -- setup up plugin manager, load plugin configs          ┃
-- ◣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◢
require("config.lazy")
require("config.dadbob")
require("config.curl-config")
require("boxed_comment.setup").setup({
  style = "kawaii",
  max_width = 80,
  padding = 5,
  filetype_styles = {
    lua = "kawaii",
    python = "ascii",
  },
  strip_existing_comments = true,
})
vim.cmd.colorscheme("eldritch")

require("dotnet_utils").setup()
require("dotnet_utils.keymaps").setup()
