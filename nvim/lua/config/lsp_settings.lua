-- config/lsp_settings.lua
return {
  enabled_servers = {
    lua_ls = true,
    dockerls = true,
    superhtml = true,
    jsonls = true,
    basedpyright = false,
    ruff = false,
    bashls = true,
    yamlls = true,
    vtsls = true,
    ruby_lsp = false,
    gopls = false,
    zls = true,
    rust_analyzer = false,
    roslyn = true, -- Enable Roslyn
  },
}
