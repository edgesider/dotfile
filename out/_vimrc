func! SetGui()
    source $VIMRUNTIME/delmenu.vim
    source $VIMRUNTIME/menu.vim
    set guioptions-=m
    set guioptions-=T
    set guioptions-=e
    set guioptions-=r
    set guioptions-=L
    set guioptions+=!
    set guioptions+=c
    " 将所有的光标设置为白块不闪烁，然后单独设置visual模式的光标
    set guicursor=a:block-Cursor-blinkon0,v:block-Cursor
    set backspace=indent,eol,start   " 任何时候都可以使用退格键
endfunc

func! SetWin32()
    set encoding=utf8
    set fileencoding=utf8
    set lines=30 columns=100
    set guifont=consolas:h14
    set guifontwide=黑体
    set pythonthreedll=python36.dll
endfunc

func! SetGtkGUI()
    set guifont=Source\ Code\ Pro\ Medium\ 15
    set guifontwide=黑体
endfunc

" 查看模式保持光标在中间
func! LookingMap()
    try
        nnoremap <buffer> j jzz
        nnoremap <buffer> k kzz
        nnoremap <buffer> G Gzz
        nnoremap <buffer> <c-e> jzz
        nnoremap <buffer> <c-y> kzz
        nnoremap <buffer> <c-d> <c-d>zz
        nnoremap <buffer> <c-u> <c-u>zz
        nnoremap <buffer> * *zz
        nnoremap <buffer> # #zz
        nnoremap <buffer> <Down> <Down>zz
        nnoremap <buffer> <Up> <Up>zz
        vnoremap <buffer> j jzz
        vnoremap <buffer> k kzz
        vnoremap <buffer> G Gzz
        vnoremap <buffer> <c-e> jzz
        vnoremap <buffer> <c-y> kzz
        vnoremap <buffer> <c-d> <c-d>zz
        vnoremap <buffer> <c-u> <c-u>zz
        vnoremap <buffer> * *zz
        vnoremap <buffer> # #zz
        vnoremap <buffer> <Down> <Down>zz
        vnoremap <buffer> <Up> <Up>zz
    endtry
    set colorcolumn=0
endfunc
func! NonLookingMap()
    try
        nunmap <buffer> j
        nunmap <buffer> k
        nunmap <buffer> G
        nunmap <buffer> <c-e>
        nunmap <buffer> <c-y>
        nunmap <buffer> <c-d>
        nunmap <buffer> <c-u>
        nunmap <buffer> *
        nunmap <buffer> #
        nunmap <buffer> <down>
        nunmap <buffer> <up>
        vunmap <buffer> j
        vunmap <buffer> k
        vunmap <buffer> G
        vunmap <buffer> <c-e>
        vunmap <buffer> <c-y>
        vunmap <buffer> <c-d>
        vunmap <buffer> <c-u>
        vunmap <buffer> *
        vunmap <buffer> #
        vunmap <buffer> <down>
        vunmap <buffer> <up>
    endtry
    set colorcolumn=100
endfunc
command! Imlooking call LookingMap()
command! Imwriting call NonLookingMap()

func! SaveSpace()
py3 << EOF
import vim
import os
if not os.path.isdir('.vimws'):
    os.mkdir('.vimws')
if os.path.isfile('.vimws/session'):
    os.rename('.vimws/session', '.vimws/last_session')
if os.path.isfile('.vimws/info'):
    os.rename('.vimws/info', '.vimws/last_info')
vim.command('mksession! .vimws/session')
vim.command('wviminfo! .vimws/info')
vim.command("echo 'workspace saved'")
EOF
endfunc

func! LoadSpace()
    if filereadable('.vimws/session')
        source .vimws/session
        cd ..
    else
        echo 'session file not exist'
    endif
    if filereadable('.vimws/info')
        rviminfo .vimws/info
    else
        echo 'info file not exist'
    endif
endfunc

func! LoadLastSpace()
    if filereadable('.vimws/session')
        source .vimws/last_session
        cd ..
    else
        echo 'last session file not exist'
    endif
    if filereadable('.vimws/last_info')
        rviminfo .vimws/last_info
    else
        echo 'last info file not exist'
    endif
endfunc

" 编译或运行
func! RunOrCompile()
    if &filetype ==# 'c'
        exec 'w'
        exec '!gcc % -o %<'
        exec '!./%<'
    elseif &filetype ==# 'cpp'
        exec 'w'
        exec '!g++ % -std=c++11 -o %<'
        exec '!./%<'
    elseif &filetype ==# 'python'
        exec 'w'
        exec '!python %'
    elseif &filetype ==# 'perl'
        exec 'w'
        exec '!perl %'
    elseif &filetype ==# 'sh'
        exec 'w'
        exec '!bash %'
    elseif &filetype ==# 'go'
        exec 'w'
        exec '!go run %'
    elseif &filetype ==# 'cs'
        exec 'w'
        exec '!csc %; mono ./%<.exe'
    endif
endfunc

func! GenDoc()
py3 << EOF
import vim
import os

def gen_doc_from_pack_folder(folder):
    pack_path = os.path.join(folder, 'pack', 'plugins', 'opt')
    current_dir = os.getcwd()
    os.chdir(pack_path)

    for pack in os.listdir(pack_path):
        if os.path.isdir(os.path.join(pack, 'doc')) \
            and not os.path.isfile(os.path.join(pack, 'doc', 'tags')):
            vim.command('helptags {}'.format(os.path.join(pack, 'doc')))
    os.chdir(current_dir)

packpath_list = vim.eval('&packpath').split(',')

gen_doc_from_pack_folder(packpath_list[0])
EOF
endfunc
command! Gendoc call GenDoc()

packadd! vim-surround
packadd! jedi-vim
packadd! ultisnips      " snippet
packadd! vim-snippets   " 常用snippet
packadd! delimitMate    " 括号、引号补全
packadd! nerdcommenter  " 注释
packadd! easy-align     " 对齐
packadd! vim-airline
packadd! LeaderF
packadd! easymotion
packadd! c-syntax.vim
packadd! python-syntax

if has('unix')
    " windows 太卡了
    packadd! tagbar
endif

set sessionoptions-=curdir
set sessionoptions+=sesdir
set sessionoptions-=blank
set sessionoptions+=winpos
set sessionoptions+=resize
set sessionoptions+=winsize
set sessionoptions+=unix
set sessionoptions+=slash
nnoremap <silent> <C-F9> :call SaveSpace()<CR>
nnoremap <silent> <C-F10> :call LoadSpace()<CR>

"colorscheme molokai
let g:PaperColor_Theme_Options = {
  \   'language': {
  \     'python': {
  \       'highlight_builtins' : 1
  \     },
  \     'cpp': {
  \       'highlight_standard_library': 1
  \     },
  \     'c': {
  \       'highlight_builtins' : 1
  \     }
  \   }
  \ }
set background=dark
colorscheme PaperColor

"自动补全
filetype plugin indent on
setlocal cryptmethod=blowfish2  " 设置加密方式
set autoread
set number
set shiftwidth=4  "操作（<<和>>）时缩进的列数
set tabstop=4    "tabstop 一个tab键所占的列数
set expandtab   "输入tab时自动将其转化为空格
set nowrap " 禁止折行
set laststatus=2 " 显示光标当前位置
set number
set cursorline cursorcolumn " 高亮显示当前行/列
set hlsearch " 高亮显示搜索结果
set incsearch " 实时搜索
set showcmd    " 右下角按键显示
set autowrite " 自动保存
set ignorecase  " 忽略大小写
set smartindent
set foldmethod=indent " 折叠方式
" set foldcolumn=2    ' 折叠层次显示
set foldlevelstart=100 " 默认不折叠
set colorcolumn=100  " 80个字符处划线
" set fillchars=vert:\   ' 将分割线设置为空格，末尾有空格，需要转义
set wildmenu wildmode=longest,full " Ex模式下Tab键补全窗口
set clipboard=unnamed
set completeopt=longest,menu
set updatetime=100 " 及时写入swap文件，保证tagbar的及时更新
set ttimeoutlen=100 " 退出编辑模式不等待
set noshowmode

syntax enable " 开启语法高亮功能
syntax on " 允许用指定语法高亮配色方案替换默认方案

" 键盘映射
let mapleader=' ' "自定义前缀键
let localleader=' ' "自定义前缀键
nnoremap <silent> <leader>l :nohlsearch<CR>

nnoremap <silent> <leader>T :terminal fish<CR>
nnoremap <silent> <leader>t :Tagbar<CR>

" leaderF
nnoremap <silent> <leader>t :LeaderfBufTag<CR>
nnoremap <silent> <leader>m :LeaderfMru<CR>

nnoremap <C-S> :w<CR>
nnoremap <silent> <F5> :call RunOrCompile()<CR>

" 窗口切换
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" buffer切换
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
tnoremap <silent> <C-W>[b <C-W>:bprevious<CR>
tnoremap <silent> <C-W>]b <C-W>:bnext<CR>

" 标签页切换
nnoremap <silent> \t :tabnew .<CR>
nnoremap <silent> [t :tabprevious<CR>
nnoremap <silent> ]t :tabnext<CR>
tnoremap <silent> <C-W>[t <C-W>:tabprevious<CR>
tnoremap <silent> <C-W>]t <C-W>:tabnext<CR>

" ale lint切换
nnoremap [a :ALEPrevious<CR>
nnoremap ]a :ALENext<CR>

" quickfix
noremap <silent> \q :copen<CR>
noremap <silent> ]q :cnext<CR>
noremap <silent> [q :cprevious<CR>

" copy
vnoremap <C-C> "+y
nnoremap <C-C> "+yy

" ycm
"nnoremap <silent> ygd :YcmCompleter GoTo<CR>

" easy-align
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" easy-motion
map <leader><leader>l <Plug>(easymotion-lineforward)
map <leader><leader>j <Plug>(easymotion-j)
map <leader><leader>k <Plug>(easymotion-k)
map <leader><leader>h <Plug>(easymotion-linebackward)

" command mode key bindings
cnoremap <C-A> <Home>
cnoremap <C-E> <End>
cnoremap <C-F> <Right>
cnoremap <C-B> <Left>

inoremap <C-A> <Home>
inoremap <C-E> <End>
inoremap <C-F> <Right>
inoremap <C-B> <Left>

" unmap unused bind
inoremap <C-@> <ESC>

let g:tagbar_left = 1

let g:jedi#force_py_version = '3.7'
let g:jedi#popup_on_dot=0

let g:UltiSnipsExpandTrigger='<c-j>'  " ultisnip snip扩展快捷键
let g:UltiSnipsEditSplit='vertical'   " ultisnip 编辑模式横向窗口打开

let g:Lf_WindowHeight = 0.3
let g:Lf_PreviewResult = {
        \ 'File': 0,
        \ 'Buffer': 0,
        \ 'Mru': 0,
        \ 'Tag': 0,
        \ 'BufTag': 0,
        \ 'Function': 0,
        \ 'Line': 0,
        \ 'Colorscheme': 0
        \}

autocmd Filetype json let g:indentLine_enabled = 0

" let a match a and A, but A will only match A
let g:EasyMotion_smartcase = 1

if has('win32')
    let g:UltiSnipsSnippetDirectories = ['~/vimfiles/ultisnips/']
else
    let g:UltiSnipsSnippetDirectories = ['~/.vim/ultisnips/']
end

" call GenDoc()

if !has('win32')
    set shell=/bin/bash
    set fileencodings=ucs-bom,utf-8,cp936,default,latin1
endif
scriptencoding utf8

if has('gui_running')
    call SetGui()

    if has('win32') && has('gui_running')
        call SetWin32()
    endif

    if has('gui_gtk')
        call SetGtkGUI()
    endif
endif

