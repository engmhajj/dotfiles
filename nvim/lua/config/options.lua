M = {}

-- nvim color
vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1

vim.o.synmaxcol = 200

-- true color support
vim.g.colorterm = os.getenv("COLORTERM")
if vim.fn.exists("+termguicolors") == 1 then
  -- vim.o.t_8f = "<Esc>[38;2;%lu;%lu;%lum"
  -- vim.o.t_8b = "<Esc>[48;2;%lu;%lu;%lum"
  vim.o.termguicolors = true
end

vim.o.cmdheight = 0
-- colorscheme pluginconfig -> colorscheme
vim.o.cursorline = false

vim.o.display = "lastline" -- long lines fit on one line
vim.o.showmode = false
vim.o.showmatch = true -- highlight parentheses correspondence
vim.o.matchtime = 1 -- number of milliseconds to find a pair of parentheses
vim.o.showcmd = true -- Show command as typed
vim.o.number = true -- display line number
vim.o.relativenumber = false
vim.o.wrap = true -- wrap by screen width
vim.o.title = false -- don't rewrite title
vim.o.scrolloff = 5
vim.o.sidescrolloff = 5
vim.o.pumheight = 10 -- number of completion suggestions to display
vim.o.statuscolumn = "%=%{&nu ? v:relnum && mode() != 'i' ? v:relnum : v:lnum : ''} %s%C"
vim.o.signcolumn = "yes"
vim.opt.wildmenu = false
vim.opt.cmdheight = 1 -- Avoid redraw bugs with 0
vim.opt.laststatus = 3 -- Use global statusline
vim.opt.splitbelow = true -- Terminal opens below
vim.opt.splitright = true -- Next terminal opens right

-- Fold
-- vim.o.foldmethod="marker"
-- vim.o.foldmethod = "manual"
-- vim.o.foldlevel = 1
-- vim.o.foldlevelstart = 99
-- vim.w.foldcolumn = "0:"

-- Cursor style
-- vim.o.guicursor = "n-v-c-sm:block-Cursor/lCursor-blinkon0,i-ci-ve:ver25-Cursor/lCursor,r-cr-o:hor20-Cursor/lCursor"
vim.o.cursorlineopt = "number"

-- vim.o.laststatus = 2
vim.o.laststatus = 3
vim.o.shortmess = "aItToOF"
vim.opt.fillchars = {
  horiz = "━",
  horizup = "┻",
  horizdown = "┳",
  vert = "┃",
  vertleft = "┫",
  vertright = "┣",
  verthoriz = "╋",
}

vim.opt.textwidth = 100 -- command 'gw' formats text to this width
vim.opt.colorcolumn = "100"

-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- undo
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold
vim.opt.autoindent = true
-- skip startup screen
vim.opt.shortmess:append("I")

-- fillchars
vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  -- fold = "⸱",
  fold = " ",
  foldsep = " ",
  -- diff = "╱",
  -- diff = "╱",
  diff = "░",
  -- diff = "·",
  eob = " ",
}

-- set tab and indents defaults (can be overridden by per-language configs)
vim.opt.tabstop = 4 -- display tabs as 4 spaces
vim.opt.softtabstop = 4 -- insert 4 spaces when tab is pressed
vim.opt.shiftwidth = 4 -- indent << or >> by 4 spaces
vim.opt.expandtab = false -- expand tab into spaces

-- NOTE: do not set a global ruler here, as it will show in undesirable places.
-- Instead, set this in the per-language config files.
-- vim.opt.colorcolumn = "80"

-- incremental search
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- ignore case when searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- text wrap
-- Enable wrapping of long lines
vim.opt.linebreak = true -- Wrap lines at convenient points

-- completion
vim.opt.completeopt = "menuone,noselect"

-- 24-bit color
vim.opt.termguicolors = true

-- sign column
vim.opt.signcolumn = "yes"

-- cursor line highlight
vim.opt.cursorline = true
vim.opt.guicursor = {
  "n-v-c-sm:block-Cursor", -- Use 'Cursor' highlight for normal, visual, and command modes
  "i-ci-ve:ver25-lCursor", -- Use 'lCursor' highlight for insert and visual-exclusive modes
  "r-cr:hor20-CursorIM", -- Use 'CursorIM' for replace mode
}
-- Enable cursor blinking in all modes
--
-- The numbers represent milliseconds:
-- blinkwait175: Time before blinking starts
-- blinkoff150: Time cursor is invisible
-- blinkon175: Time cursor is visible
-- vim.opt.guicursor = "n-v-c-sm:block-blinkwait175-blinkoff150-blinkon175"

-- splitting
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.termguicolors = true
-- set up diagnostics
require("utils.diagnostics").setup_diagnostics()

-- set up folding
function _G.custom_foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  local line_count = vim.v.foldend - vim.v.foldstart + 1
  local line_text = vim.fn.substitute(line, "\t", " ", "g")
  return string.format("%s (%d lines)", line_text, line_count)
end
function M.treesitter_foldexpr()
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.opt_local.foldtext = "v:lua.custom_foldtext()"
end
function M.lsp_foldexpr()
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.vim.lsp.foldexpr()"
  vim.opt_local.foldtext = "v:lua.custom_foldtext()"
end
vim.opt.foldcolumn = "0"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- scroll off
vim.opt.scrolloff = 4

-- mouse support in all modes
vim.opt.mouse = "a"

-- project specific settings (see lazyrc.lua for .lazy.lua support)
vim.opt.exrc = true -- allow local .nvim.lua .vimrc .exrc files
vim.opt.secure = true -- disable shell and write commands in local .nvim.lua .vimrc .exrc files

-- sync with system clipboard
-- NOTE: https://github.com/neovim/neovim/issues/11804
vim.opt.clipboard = "unnamedplus"

-- TODO: pick from https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
vim.opt.listchars = "tab:▸ ,trail:·,nbsp:␣,extends:❯,precedes:❮" -- show symbols for whitespace

-- NOTE: see auto session for vim.o.sessionoptions

vim.opt.smoothscroll = true

if not vim.g.vscode then
  vim.opt.timeoutlen = 300 -- Lower than default (1000) to quickly trigger which-key
end

-- set titlestring to $cwd if TERM_PROGRAM=ghostty
if vim.fn.getenv("TERM_PROGRAM") == "ghostty" then
  vim.opt.title = true
  vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

if vim.fn.has("nvim-0.11") == 1 then
  -- Rounded borders by default on >= 0.11
  vim.o.winborder = "rounded"
end

-- adding custom filetypes
--
vim.filetype.add({
  -- extension = {},
  -- filename = {},
  pattern = {
    -- can be comma-separated for a list of paths
    [".*/%.github/dependabot.yml"] = "dependabot",
    [".*/%.github/dependabot.yaml"] = "dependabot",
    [".*/%.github/workflows[%w/]+.*%.yml"] = "gha",
    [".*/%.github/workflows/[%w/]+.*%.yaml"] = "gha",
  },
})

-- use the yaml parser for the custom filetypes
vim.treesitter.language.register("yaml", "gha")
vim.treesitter.language.register("yaml", "dependabot")

return M
