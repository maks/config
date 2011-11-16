syntax on
set ruler

" size of a hard tabstop
set tabstop=4

" size of an "indent"
set shiftwidth=4

" make "tab" insert indents instead of tabs at the beginning of a line
set smarttab

" always uses spaces instead of tab characters
set expandtab

set smartindent

filetype on
filetype plugin on
filetype indent on

" don't warn about hiding unssaved buffers
set hidden

" At least let yourself know what mode you're in
set showmode
"
" Enable enhanced command-line completion. Presumes you have compiled
" with +wildmenu.  See :help 'wildmenu'
set wildmenu
"
" Let's make it easy to edit this file (mnemonic for the key sequence is
" 'e'dit 'v'imrc)
nmap <silent> ,ev :e $MYVIMRC<cr>

