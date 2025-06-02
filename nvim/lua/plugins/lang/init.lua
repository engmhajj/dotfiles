return {
  require("plugins.lang.csharp.easy-dotnet"),
  -- require("plugins.lang.csharp.dotnet_utils").setup(),
  require("plugins.lang.csharp.dotnet-terminal").setup({ auto_close_terminals = false }),
}
