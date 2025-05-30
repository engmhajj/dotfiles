-- Create augroups once to avoid clearing repeatedly
local checktime_group = vim.api.nvim_create_augroup("checktime", {})
local yank_group = vim.api.nvim_create_augroup("Yank", {})
local resize_group = vim.api.nvim_create_augroup("resize_splits", {})
local lastloc_group = vim.api.nvim_create_augroup("last_loc", {})
local auto_create_dir_group = vim.api.nvim_create_augroup("auto_create_dir", {})
local help_window_group = vim.api.nvim_create_augroup("help_window_right", {})

-- Reload file on focus gain, terminal close or leave
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = checktime_group,
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Highlight on yank and copy to clipboard on WSL
vim.api.nvim_create_autocmd("TextYankPost", {
  group = yank_group,
  callback = function()
    if vim.fn.has("wsl") == 1 then
      vim.fn.system("clip.exe", vim.fn.getreg('"'))
    else
      vim.hl.on_yank()
    end
  end,
})

-- Resize splits when Vim window is resized
vim.api.nvim_create_autocmd("VimResized", {
  group = resize_group,
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- Go to last location when opening a buffer (except for gitcommit filetype)
vim.api.nvim_create_autocmd("BufReadPost", {
  group = lastloc_group,
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto-create directory on file save if it doesn't exist
vim.api.nvim_create_autocmd("BufWritePre", {
  group = auto_create_dir_group,
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Always open help window on the right (vertical split)
vim.api.nvim_create_autocmd("FileType", {
  group = help_window_group,
  pattern = "help",
  callback = function()
    vim.cmd.wincmd("L")
  end,
})

-- Customize LSP hover with rounded border
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
})

-- Show diagnostics in floating window on cursor hold, only warnings or above
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false, severity = { min = vim.diagnostic.severity.WARN } })
  end,
})

-- Diagnostics configuration
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  float = {
    border = "rounded",
    source = true,
  },
})

-- Define diagnostic signs
local signs = { Error = "✖", Warn = "⚠", Info = "ℹ", Hint = "💡" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Optional: keymap to open diagnostic float manually
vim.api.nvim_set_keymap(
  "n",
  "<leader>dd",
  "<cmd>lua vim.diagnostic.open_float()<CR>",
  { noremap = true, silent = true }
)

-- Fix conceallevel for JSON files
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("json_conceal", { clear = true }),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Add custom filetypes for GitHub Actions and Dependabot
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "gha", "dependabot" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true

    vim.opt_local.colorcolumn = "120" -- NOTE: also see yamllint config
  end,
})

vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
  callback = function()
    require("lint").try_lint()
  end,
})
