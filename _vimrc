execute pathogen#infect()
syntax on
filetype plugin indent on
" https://www.shortcutfoo.com/blog/top-50-vim-configuration-options/
set autoindent
set shiftround
filetype indent on
autocmd FileType vue setlocal shiftwidth=2 softtabstop=2 expandtab
autocmd FileType javascript setlocal shiftwidth=2 softtabstop=2 expandtab
autocmd FileType python setlocal shiftwidth=4 softtabstop=4 expandtab
set number
set hlsearch incsearch ignorecase smartcase
set ruler noerrorbells visualbell background=dark
autocmd ShellCmdPost,BufNewFile,BufRead *.tsx   set syntax=typescript
autocmd BufWritePost *.py !test -f .pre-commit-config.yaml && SKIP=pylint,no-commit-to-branch pre-commit run --files % || true
"autocmd BufWritePost *.json !prettier --parser=json --write %
" https://vi.stackexchange.com/questions/16963/remap-esc-key-in-vim
inoremap <F2> <Esc>
inoremap <F1> <Esc>
