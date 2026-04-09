" Vim/Neovim Configuration
" Add to ~/.vimrc or ~/.config/nvim/init.vim

" ======================
" General Settings
" ======================
set encoding=utf-8
set linebreak
set showcmd
set hidden
set history=1000
set undofile

" ======================
" Indentation
" ======================
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent
set shiftround

" ======================
" Whitespace
" ======================
set listchars=trail:•,nbsp:%,tab:▸\ 
set showbreak=↪
set wrap
set textwidth=100
set colorcolumn=+1

" ======================
" Search
" ======================
set incsearch
set ignorecase
set smartcase
set hlsearch
set wrapscan

" ======================
" UI
" ======================
set number
set relativenumber
set cursorline
set colorcolumn=80,100
set laststatus=2
set showmatch
set matchtime=2

" ======================
" File Handling
" ======================
set autoread
set noswapfile
set nobackup
set nowb
set confirm
set fileencoding=utf-8

" ======================
" Format on Save
" ======================
function! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfunction

autocmd BufWritePre * call TrimWhitespace()

" ======================
" Plugins (using vim-plug)
" ======================
" Add to your vim-plug section:
"
" Plug 'preservim/nerdtree'
" Plug 'editorconfig/editorconfig-vim'
" Plug 'prettier/vim-prettier', { 'do': 'npm install' }
" Plug 'eslint/eslint'
" Plug 'airbnb/vim-react'
" Plug 'posva/vim-cheat40'

" ======================
" Language-Specific
" ======================

" JavaScript/TypeScript
autocmd FileType javascript,typescript setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

" Python
autocmd FileType python setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab

" Go
autocmd FileType go setlocal tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab

" JSON
autocmd FileType json setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

" YAML
autocmd FileType yaml setlocal tabstop=2 softtabstop=2 shiftwidth=2 expandtab

" Markdown
autocmd FileType markdown setlocal wrap linebreak textwidth=80

" ======================
" Key Mappings
" ======================
let mapleader = " "
nnoremap <leader>w :w!<cr>
nnoremap <leader>q :q!<cr>
nnoremap <leader>h :nohlsearch<cr>
