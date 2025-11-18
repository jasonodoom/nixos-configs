# Neovim configuration for perdurabo
{ config, pkgs, lib, ... }:

{
  # Configure neovim with plugins
  environment.systemPackages = [
    (pkgs.neovim.override {
      configure = {
        customRC = ''
          " ============================================
          " Editor Behavior
          " ============================================

          " Line numbers
          set number                    " Show absolute line numbers
          set relativenumber            " Show relative line numbers

          " Tab and space settings
          set expandtab                 " Use spaces instead of tabs
          set tabstop=4                 " Tab width
          set shiftwidth=4              " Indent width
          set softtabstop=4             " Backspace removes 4 spaces
          set smartindent               " Smart auto-indenting

          " System clipboard integration
          set clipboard=unnamedplus     " Use system clipboard for all operations

          " Search settings
          set ignorecase                " Case insensitive search
          set smartcase                 " Case sensitive if uppercase present
          set incsearch                 " Incremental search
          set hlsearch                  " Highlight search results

          " Cursor line highlighting (IMPORTANT)
          set cursorline                " Highlight current line

          " Split window behavior
          set splitbelow                " Horizontal splits open below
          set splitright                " Vertical splits open right

          " General improvements
          set hidden                    " Allow hidden buffers
          set scrolloff=8               " Keep 8 lines visible above/below cursor
          set signcolumn=yes            " Always show sign column (prevents shifting)
          set updatetime=300            " Faster completion

          " Enable true color support
          set termguicolors

          " ============================================
          " Plugin Configuration
          " ============================================

          lua << EOF
          -- Onedark colorscheme
          require('onedark').setup {
            style = 'darker',
            transparent = false,
            term_colors = true,
            code_style = {
              comments = 'italic',
              keywords = 'none',
              functions = 'none',
              strings = 'none',
              variables = 'none'
            },
          }
          require('onedark').load()

          -- Treesitter configuration
          require('nvim-treesitter.configs').setup {
            highlight = {
              enable = true,
              additional_vim_regex_highlighting = false,
            },
            indent = {
              enable = true,
            },
          }

          -- Telescope fuzzy finder
          require('telescope').setup {
            defaults = {
              file_ignore_patterns = { "node_modules", ".git/" },
            }
          }

          -- Nvim-tree file explorer
          require('nvim-tree').setup {
            view = {
              width = 30,
            },
            renderer = {
              group_empty = true,
            },
            filters = {
              dotfiles = false,
            },
          }

          -- Lualine status line
          require('lualine').setup {
            options = {
              theme = 'onedark',
              section_separators = "",
              component_separators = "|"
            }
          }
EOF

          " ============================================
          " Keybindings
          " ============================================

          " Leader key
          let mapleader = " "

          " Telescope fuzzy finder
          nnoremap <leader>ff <cmd>Telescope find_files<cr>
          nnoremap <leader>fg <cmd>Telescope live_grep<cr>
          nnoremap <leader>fb <cmd>Telescope buffers<cr>

          " Nvim-tree file explorer
          nnoremap <leader>e <cmd>NvimTreeToggle<cr>

          " Clear search highlighting
          nnoremap <leader>h <cmd>nohlsearch<cr>
        '';

        packages.myVimPackage = with pkgs.vimPlugins; {
          start = [
            # Colorscheme
            onedark-nvim

            # Treesitter
            nvim-treesitter.withAllGrammars

            # File explorer
            nvim-tree-lua
            nvim-web-devicons

            # Fuzzy finder
            telescope-nvim
            plenary-nvim

            # Status line
            lualine-nvim
          ];
        };
      };
    })
  ];
}
