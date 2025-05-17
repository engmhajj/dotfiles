-- local has_git = vim.fn.executable("git") == 1
--
-- local function get_current_directory(state)
--   local node = state.tree:get_node()
--   if node.type ~= "directory" or not node:is_expanded() then
--     node = state.tree:get_node(node:get_parent_id())
--   end
--   return node:get_id()
-- end
--
return {

  -- file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    lazy = false, -- neo-tree will lazily load itself
    cmd = "Neotree",
    keys = {
      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = true })
        end,
        desc = "Explorer NeoTree (Root Dir)",
      },
      {
        "<leader>fE",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      { "<leader>e", "<leader>fe", desc = "Explorer NeoTree (Root Dir)", remap = true },
      { "<leader>E", "<leader>fE", desc = "Explorer NeoTree (cwd)", remap = true },
      {
        "<leader>ge",
        function()
          require("neo-tree.command").execute({ source = "git_status", toggle = true })
        end,
        desc = "Git Explorer",
      },
      {
        "<leader>be",
        function()
          require("neo-tree.command").execute({ source = "buffers", toggle = true })
        end,
        desc = "Buffer Explorer",
      },
    },
    deactivate = function()
      vim.cmd([[Neotree close]])
    end,
    init = function()
      -- FIX: use `autocmd` for lazy-loading neo-tree instead of directly requiring it,
      -- because `cwd` is not set up properly.
      vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("Neotree_start_directory", { clear = true }),
        desc = "Start Neo-tree with directory",
        once = true,
        callback = function()
          if package.loaded["neo-tree"] then
            return
          else
            local stats = vim.uv.fs_stat(vim.fn.argv(0))
            if stats and stats.type == "directory" then
              require("neo-tree")
            end
          end
        end,
      })
    end,
    opts = {
      enable_git_status = true,
      close_if_last_window = true,
      popup_border_style = "rounded",
      sort_case_insensitive = true,
      source_selector = {
        winbar = false,
        show_scrolled_off_parent_node = true,
        padding = { left = 1, right = 0 },
        sources = {
          { source = "filesystem", display_name = "  Files" }, --      
          { source = "buffers", display_name = "  Buffers" }, --      
          { source = "git_status", display_name = " 󰊢 Git" }, -- 󰊢      
        },
      },
      event_handlers = {
        -- Close neo-tree when opening a file.
        {
          event = "file_opened",
          handler = function()
            require("neo-tree").close_all()
          end,
        },
      },
      sources = { "filesystem", "buffers", "git_status" },
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = false },
        use_libuv_file_watcher = true,
        window = {
          mappings = {
            -- Make the mapping anything you want for dotnet
            ["R"] = "easy",
          },
        },
        commands = {
          ["easy"] = function(state)
            local node = state.tree:get_node()
            local path = node.type == "directory" and node.path or vim.fs.dirname(node.path)
            require("easy-dotnet").create_new_item(path, function()
              require("neo-tree.sources.manager").refresh(state.name)
            end)
          end,
        },
      },
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_by_name = {
          ".git",
          ".hg",
          ".svc",
          ".DS_Store",
          "thumbs.db",
          ".sass-cache",
          "node_modules",
          ".pytest_cache",
          ".mypy_cache",
          "__pycache__",
          ".stfolder",
          ".stversions",
        },
        never_show_by_pattern = {
          "vite.config.js.timestamp-*",
        },
      },
      window = {
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["<space>"] = "none",
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg("+", path, "c")
            end,
            desc = "Copy Path to Clipboard",
          },
          ["O"] = {
            function(state)
              require("lazy.util").open(state.tree:get_node().path, { system = true })
            end,
            desc = "Open with System Application",
          },
          ["p"] = { "toggle_preview", config = { use_float = false } },
          ["K"] = { "preview", config = { use_float = true } },
          ["P"] = "paste_from_clipboard",

          -- Custom commands

          ["w"] = function(state)
            local normal = state.window.width
            local large = normal * 1.9
            local small = math.floor(normal / 1.6)
            local cur_width = state.win_width
            local new_width = normal
            if cur_width > normal then
              new_width = small
            elseif cur_width == normal then
              new_width = large
            end
            vim.cmd(new_width .. " wincmd |")
          end,
        },
      },

      default_component_configs = {
        icon = {
          folder_empty = "",
          folder_empty_open = "",
          default = "",
        },
        modified = {
          symbol = "•",
        },
        name = {
          trailing_slash = true,
          highlight_opened_files = true,
          use_git_status_colors = true,
        },
        indent = {
          with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
          expander_collapsed = "",
          expander_expanded = "",
          expander_highlight = "NeoTreeExpander",
        },
        git_status = {
          symbols = {
            added = "❇️",
            modified = "📝",
            removed = "❌",
            unstaged = "󰄱",
            staged = "󰱒",
          },
        },
      },
    },
    config = function(_, opts)
      local function on_move(data)
        Snacks.rename.on_rename_file(data.source, data.destination)
      end

      local events = require("neo-tree.events")
      opts.event_handlers = opts.event_handlers or {}
      vim.list_extend(opts.event_handlers, {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
      })
      require("neo-tree").setup(opts)
      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*lazygit",
        callback = function()
          if package.loaded["neo-tree.sources.git_status"] then
            require("neo-tree.sources.git_status").refresh()
          end
        end,
      })
    end,
  },
}
