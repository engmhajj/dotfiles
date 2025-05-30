return {

  {
    "nvim-neotest/neotest",
    lazy = true,
    ft = { "zig" },
    dependencies = {
      {
        "lawrence-laz/neotest-zig",
        version = "*",
      },
    },
    opts = {
      adapters = {
        ["neotest-zig"] = {
          dap = {
            adapter = "lldb",
          },
        },
      },
    },
  },

  {
    "CRAG666/code_runner.nvim",
    lazy = true,
    opts = {
      filetype = {
        zig = {
          "zig run",
        },
      },
    },
  },
}
