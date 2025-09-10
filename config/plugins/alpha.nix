# packages/nvf/ui/alpha.nix
{pkgs, ...}: {
  vim = {
    startPlugins = with pkgs.vimPlugins; [
      alpha-nvim
      nvim-web-devicons
    ];

    pluginRC.alpha-nvim = ''
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      -- Set header
      dashboard.section.header.val = {
        [[                                                    ]],
        [[ ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗]],
        [[ ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║]],
        [[ ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║]],
        [[ ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
        [[ ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║]],
        [[ ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        [[                                                    ]],
        [[              Welcome to Your Editor               ]],
        [[                                                    ]],
      }

      -- Set menu
      dashboard.section.buttons.val = {
        dashboard.button("f", "󰈞  Find file", ":Telescope find_files <CR>"),
        dashboard.button("r", "󰊄  Recently used files", ":Telescope oldfiles <CR>"),
        dashboard.button("p", "󰉋  Find project", ":Telescope projects <CR>"),
        dashboard.button("g", "󰊢  Find text", ":Telescope live_grep <CR>"),
        dashboard.button("c", "  Configuration", ":e ~/.config/nvim/init.lua <CR>"),
        dashboard.button("n", "  New file", ":ene <BAR> startinsert <CR>"),
        dashboard.button("s", "  Load session", ":SessionManager load_session <CR>"),
        dashboard.button("q", "󰅚  Quit Neovim", ":qa<CR>"),
      }

      -- Set footer
      local function footer()
        local total_plugins = #vim.tbl_keys(packer_plugins or {})
        local datetime = os.date(" %d-%m-%Y   %H:%M:%S")
        local version = vim.version()
        local nvim_version_info = "   v" .. version.major .. "." .. version.minor .. "." .. version.patch

        return datetime .. "   " .. total_plugins .. " plugins" .. nvim_version_info
      end

      dashboard.section.footer.val = footer()

      -- Send config to alpha
      alpha.setup(dashboard.opts)

      -- Disable folding on alpha buffer
      vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])

      -- Hide statusline and tabline in alpha buffer
      vim.api.nvim_create_autocmd("User", {
        pattern = "AlphaReady",
        desc = "disable status and tabline for alpha",
        callback = function()
          local prev_showtabline = vim.opt.showtabline:get()
          local prev_status = vim.opt.laststatus:get()
          vim.opt.laststatus = 0
          vim.opt.showtabline = 0
          vim.api.nvim_create_autocmd("BufUnload", {
            pattern = "<buffer>",
            callback = function()
              vim.opt.laststatus = prev_status
              vim.opt.showtabline = prev_showtabline
            end,
          })
        end,
      })
    '';
  };
}
