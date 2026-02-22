-- Plugin specs for lazy.nvim
-- Each entry is a plugin spec: https://lazy.folke.io/spec

return {

  -- ── Colorscheme ──────────────────────────────────────────────────────────────
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,  -- load before other plugins
    config   = function()
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- ── Status line ──────────────────────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme     = "catppuccin",
        component_separators = "|",
        section_separators   = "",
      },
    },
  },

  -- ── Syntax highlighting ───────────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc",
          "javascript", "typescript", "tsx",
          "python", "go", "rust",
          "json", "yaml", "toml", "markdown",
          "html", "css",
          "bash",
        },
        auto_install    = true,
        highlight       = { enable = true },
        indent          = { enable = true },
      })
    end,
  },

  -- ── Fuzzy finder ─────────────────────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    branch       = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      local builtin   = require("telescope.builtin")

      telescope.setup({
        defaults = { path_display = { "truncate" } },
      })
      telescope.load_extension("fzf")

      local map = vim.keymap.set
      map("n", "<leader>ff", builtin.find_files,  { desc = "Find files" })
      map("n", "<leader>fg", builtin.live_grep,   { desc = "Live grep" })
      map("n", "<leader>fb", builtin.buffers,     { desc = "Find buffer" })
      map("n", "<leader>fh", builtin.help_tags,   { desc = "Help tags" })
      map("n", "<leader>fr", builtin.oldfiles,    { desc = "Recent files" })
    end,
  },

  -- ── LSP ───────────────────────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        -- Mason will auto-install these LSPs when you open a relevant file
        ensure_installed = {
          "lua_ls",
          "ts_ls",        -- TypeScript / JavaScript
          "pyright",      -- Python
          "gopls",        -- Go
          "rust_analyzer",
        },
        automatic_installation = true,
      })

      local lspconfig   = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Attach keymaps when an LSP connects to a buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          local builtin = require("telescope.builtin")

          map("gd",         builtin.lsp_definitions,      "Go to definition")
          map("gr",         builtin.lsp_references,        "Go to references")
          map("gI",         builtin.lsp_implementations,   "Go to implementation")
          map("K",          vim.lsp.buf.hover,             "Hover docs")
          map("<leader>rn", vim.lsp.buf.rename,            "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action,       "Code action")
          map("<leader>f",  function() vim.lsp.buf.format({ async = true }) end, "Format")
        end,
      })

      -- Configure each LSP (capabilities shared by all)
      local servers = { "lua_ls", "ts_ls", "pyright", "gopls", "rust_analyzer" }
      for _, server in ipairs(servers) do
        lspconfig[server].setup({ capabilities = capabilities })
      end
    end,
  },

  -- ── Autocompletion ────────────────────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp    = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]     = cmp.mapping.select_next_item(),
          ["<C-p>"]     = cmp.mapping.select_prev_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- ── Debugging (DAP) ───────────────────────────────────────────────────────────
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",   -- required by dap-ui
      "williamboman/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
    },
    config = function()
      local dap    = require("dap")
      local dapui  = require("dapui")

      -- Auto-install debug adapters via Mason
      require("mason-nvim-dap").setup({
        ensure_installed = { "python", "node2", "delve" },
        automatic_installation = true,
        handlers = {},  -- use default handlers from mason-nvim-dap
      })

      dapui.setup()

      -- Auto-open/close UI when debugging starts/ends
      dap.listeners.after.event_initialized["dapui_config"]  = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"]  = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"]      = function() dapui.close() end

      local map = vim.keymap.set
      map("n", "<leader>db", dap.toggle_breakpoint,          { desc = "Toggle breakpoint" })
      map("n", "<leader>dc", dap.continue,                   { desc = "Continue" })
      map("n", "<leader>ds", dap.step_over,                  { desc = "Step over" })
      map("n", "<leader>di", dap.step_into,                  { desc = "Step into" })
      map("n", "<leader>do", dap.step_out,                   { desc = "Step out" })
      map("n", "<leader>dq", function() dap.terminate(); dapui.close() end, { desc = "Stop debugger" })
      map("n", "<leader>du", dapui.toggle,                   { desc = "Toggle DAP UI" })
    end,
  },

  -- ── Git ───────────────────────────────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs  = package.loaded.gitsigns
        local map = function(mode, keys, func, desc)
          vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = desc })
        end

        map("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(gs.next_hunk)
          return "<Ignore>"
        end, "Next hunk")

        map("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(gs.prev_hunk)
          return "<Ignore>"
        end, "Previous hunk")

        map("n", "<leader>hs", gs.stage_hunk,        "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk,        "Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk,      "Preview hunk")
        map("n", "<leader>hb", gs.blame_line,        "Blame line")
      end,
    },
  },

}
