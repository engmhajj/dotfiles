return {

  "MoaidHathot/dotnet.nvim",
  event = "VeryLazy",
  cmd = "DotnetUI",
  opts = {
    bootstrap = {
      auto_bootstrap = true, -- Automatically call "bootstrap" when creating a new file, adding a namespace and a class to the files
    },
    project_selection = {
      path_display = "filename_first", -- Determines how file paths are displayed. All of Telescope's path_display options are supported
    },
  },
}
