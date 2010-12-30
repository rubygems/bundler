let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
inoremap <silent> <S-Tab> =BackwardsSnippet()
inoremap <C-Tab> 	
snoremap <silent> 	 i<Right>=TriggerSnippet()
snoremap  b<BS>
noremap s :TCommentAs =&ft_
noremap n :TCommentAs =&ft 
noremap a :TCommentAs 
noremap b :TCommentBlock
vnoremap <silent> r :TCommentRight
vnoremap <silent> i :TCommentInline
nnoremap <silent> r :TCommentRight
onoremap <silent> r :TCommentRight
noremap   :TComment 
noremap <silent> p m`vip:TComment``
vnoremap <silent>  :TCommentMaybeInline
nnoremap <silent>  :TComment
onoremap <silent>  :TComment
snoremap % b<BS>%
snoremap ' b<BS>'
imap ã :call ToggleCommentify()j 
xmap S <Plug>VSurround
snoremap U b<BS>U
vmap [% [%m'gv``
snoremap \ b<BS>\
noremap \_s :TCommentAs =&ft_
noremap \_n :TCommentAs =&ft 
noremap \_a :TCommentAs 
noremap \_b :TCommentBlock
vnoremap <silent> \_r :TCommentRight
nnoremap <silent> \_r :TCommentRight
onoremap <silent> \_r :TCommentRight
vnoremap <silent> \_i :TCommentInline
noremap \_  :TComment 
noremap <silent> \_p vip:TComment
vnoremap <silent> \__ :TCommentMaybeInline
nnoremap <silent> \__ :TComment
onoremap <silent> \__ :TComment
map \rwp <Plug>RestoreWinPosn
map \swp <Plug>SaveWinPosn
map \tt <Plug>AM_tt
map \tsq <Plug>AM_tsq
map \tsp <Plug>AM_tsp
map \tml <Plug>AM_tml
map \tab <Plug>AM_tab
map \m= <Plug>AM_m=
map \t@ <Plug>AM_t@
map \t~ <Plug>AM_t~
map \t? <Plug>AM_t?
map \w= <Plug>AM_w=
map \ts= <Plug>AM_ts=
map \ts< <Plug>AM_ts<
map \ts; <Plug>AM_ts;
map \ts: <Plug>AM_ts:
map \ts, <Plug>AM_ts,
map \t= <Plug>AM_t=
map \t< <Plug>AM_t<
map \t; <Plug>AM_t;
map \t: <Plug>AM_t:
map \t, <Plug>AM_t,
map \t# <Plug>AM_t#
map \t| <Plug>AM_t|
map \T~ <Plug>AM_T~
map \Tsp <Plug>AM_Tsp
map \Tab <Plug>AM_Tab
map \T@ <Plug>AM_T@
map \T? <Plug>AM_T?
map \T= <Plug>AM_T=
map \T< <Plug>AM_T<
map \T; <Plug>AM_T;
map \T: <Plug>AM_T:
map \Ts, <Plug>AM_Ts,
map \T, <Plug>AM_T,o
map \T# <Plug>AM_T#
map \T| <Plug>AM_T|
map \Htd <Plug>AM_Htd
map \anum <Plug>AM_aunum
map \aunum <Plug>AM_aenum
map \afnc <Plug>AM_afnc
map \adef <Plug>AM_adef
map \adec <Plug>AM_adec
map \ascom <Plug>AM_ascom
map \aocom <Plug>AM_aocom
map \adcom <Plug>AM_adcom
map \acom <Plug>AM_acom
map \abox <Plug>AM_abox
map \a( <Plug>AM_a(
map \a= <Plug>AM_a=
map \a< <Plug>AM_a<
map \a, <Plug>AM_a,
map \a? <Plug>AM_a?
nmap <silent> \t :CommandT
map \gc :Gcommit
map \gs :Gstatus
map \rd :silent call RailsScriptSearch(expand("'def .*<cword>'")):cc
map \rg :silent call RailsScriptSearch(expand("<cword>")):cc
vmap ]% ]%m'gv``
snoremap ^ b<BS>^
snoremap ` b<BS>`
vmap a% [%v]%
nmap cs <Plug>Csurround
nmap ds <Plug>Dsurround
nmap gx <Plug>NetrwBrowseX
vnoremap <silent> gC :TCommentMaybeInline
nnoremap <silent> gCc :let w:tcommentPos = getpos(".") | set opfunc=tcomment#OperatorLineAnywayg@$
nnoremap <silent> gC :let w:tcommentPos = getpos(".") | set opfunc=tcomment#OperatorAnywayg@
vnoremap <silent> gc :TCommentMaybeInline
nnoremap <silent> gcc :let w:tcommentPos = getpos(".") | set opfunc=tcomment#OperatorLineg@$
nnoremap <silent> gc :let w:tcommentPos = getpos(".") | set opfunc=tcomment#Operatorg@
xmap gS <Plug>VgSurround
xmap s <Plug>Vsurround
nmap ySS <Plug>YSsurround
nmap ySs <Plug>YSsurround
nmap yss <Plug>Yssurround
nmap yS <Plug>YSurround
nmap ys <Plug>Ysurround
snoremap <Left> bi
snoremap <Right> a
snoremap <BS> b<BS>
snoremap <silent> <S-Tab> i<Right>=BackwardsSnippet()
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
nmap <silent> <Plug>RestoreWinPosn :call RestoreWinPosn()
nmap <silent> <Plug>SaveWinPosn :call SaveWinPosn()
nmap <SNR>21_WE <Plug>AlignMapsWrapperEnd
map <SNR>21_WS <Plug>AlignMapsWrapperStart
map <F8> :FuzzyFinderFile
map <F3> :TMiniBufExplorer
map <F2> :Project
map <F9> :call DiffPreview()
map <F6> :!ctags -R --c++-kinds=+p --fields=+iaS --extra=+q .
map <F5> :make
map <F10> :TlistToggle
imap S <Plug>ISurround
imap s <Plug>Isurround
inoremap <silent> 	 =TriggerSnippet()
inoremap <silent> 	 =ShowAvailableSnips()
imap  <Plug>Isurround
inoremap s :TCommentAs =&ft_
inoremap n :TCommentAs =&ft 
inoremap a :TCommentAs 
inoremap b :TCommentBlock
inoremap <silent> r :TCommentRight
inoremap   :TComment 
inoremap <silent> p :norm! m`vip:TComment``
inoremap <silent>  :TComment
map <silent> î :cprev
map <silent> ð :cnext
map ã :call ToggleCommentify()j
let &cpo=s:cpo_save
unlet s:cpo_save
set autoindent
set autowrite
set backspace=indent,eol,start
set cinoptions=>4
set clipboard=autoselect,exclude:cons\\|linux,unnamed
set comments=:#
set commentstring=#\ %s
set confirm
set directory=~/.vim/tmp
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set helplang=en
set history=256
set laststatus=2
set omnifunc=rubycomplete#Complete
set operatorfunc=tcomment#OperatorLine
set pastetoggle=<F4>
set printoptions=paper:letter
set ruler
set runtimepath=~/.vim,~/.vim/bundle/Command-T,~/.vim/bundle/CSApprox,~/.vim/bundle/gist,~/.vim/bundle/IndexedSearch,~/.vim/bundle/jquery,~/.vim/bundle/nerdtree,~/.vim/bundle/snipmate.vim,~/.vim/bundle/textile.vim,~/.vim/bundle/vim-align,~/.vim/bundle/vim-cucumber,~/.vim/bundle/vim-fugitive,~/.vim/bundle/vim-git,~/.vim/bundle/vim-haml,~/.vim/bundle/vim-markdown,~/.vim/bundle/vim-rails,~/.vim/bundle/vim-repeat,~/.vim/bundle/vim-ruby,~/.vim/bundle/vim-ruby-debugger,~/.vim/bundle/vim-shoulda,~/.vim/bundle/vim-supertab,~/.vim/bundle/vim-surround,~/.vim/bundle/vim-tcomment,~/.vim/bundle/vim-vividchalk,/var/lib/vim/addons,/usr/share/vim/vimfiles,/usr/share/vim/vim72,/usr/share/vim/vimfiles/after,/var/lib/vim/addons/after,~/.vim/bundle/snipmate.vim/after,~/.vim/after
set shiftwidth=2
set showmatch
set softtabstop=2
set statusline=%<%f\ %h%m%r%=%-20.(%)%h%m%r%=%-40(%n%Y%)%P
set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc
set tabstop=2
set timeoutlen=300
set updatetime=200
set viminfo=!,'100,<50,s10,h
set window=73
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/Projects/heroku_work/bundler
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +120 spec/install/git_spec.rb
badd +33 spec/support/path.rb
badd +43 spec/spec_helper.rb
badd +18 ../zentracker/spec/spec_helper.rb
badd +10 Rakefile
badd +296 spec/install/gems/simple_case_spec.rb
badd +2 lib/bundler/version.rb
badd +178 spec/other/clean_spec.rb
badd +1 spec/other/check_spec.rb
badd +302 spec/support/builders.rb
badd +61 spec/cache/gems_spec.rb
badd +36 spec/support/matchers.rb
badd +3 ~/Projects/heroku_work/bundler/spec/cache/path_spec.rb
badd +12 bin/bundle
badd +37 lib/bundler/cli.rb
badd +3 lib/bundler/definition.rb
badd +115 lib/bundler.rb
badd +86 lib/bundler/runtime.rb
badd +22 NERD_tree_10
badd +10 lib/bundler/lazy_specification.rb
badd +10 lib/bundler/remote_specification.rb
badd +24 lib/bundler/rubygems_ext.rb
badd +14 NERD_tree_11
badd +239 spec/support/helpers.rb
badd +10 NERD_tree_13
badd +73 lib/bundler/gem_helper.rb
badd +54 lib/bundler/installer.rb
badd +20 NERD_tree_18
badd +534 lib/bundler/source.rb
badd +98 spec/other/gem_helper_spec.rb
silent! argdel *
edit spec/other/clean_spec.rb
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
exe 'vert 1resize ' . ((&columns * 79 + 157) / 315)
exe 'vert 2resize ' . ((&columns * 235 + 157) / 315)
argglobal
nnoremap <buffer> <silent> g} :exe        "ptjump =RubyCursorIdentifier()"
nnoremap <buffer> <silent> } :exe          "ptag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g] :exe      "stselect =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g :exe        "stjump =RubyCursorIdentifier()"
nnoremap <buffer> <silent>  :exe v:count1."stag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> ] :exe v:count1."stag =RubyCursorIdentifier()"
nnoremap <buffer> <silent>  :exe  v:count1."tag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g] :exe       "tselect =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g :exe         "tjump =RubyCursorIdentifier()"
cnoremap <buffer> <expr>  fugitive#buffer().rev()
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=RubyBalloonexpr()
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=>4
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=^\\s*#\\s*define
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=%+E%f:%l:\ parse\ error,%W%f:%l:\ warning:\ %m,%E%f:%l:in\ %*[^:]:\ %m,%E%f:%l:\ %m,%-C%tfrom\ %f:%l:in\ %.%#,%-Z%tfrom\ %f:%l,%-Z%p^,%-G%.%#
setlocal expandtab
if &filetype != 'ruby'
setlocal filetype=ruby
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
set foldlevel=1
setlocal foldlevel=1
setlocal foldmarker={{{,}}}
set foldmethod=syntax
setlocal foldmethod=syntax
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=^\\s*\\<\\(load\\|w*require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.rb','')
setlocal indentexpr=GetRubyIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,e,=end,=elsif,=when,=ensure,=rescue,==begin,==end
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=ri
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=ruby\ -w\ $*
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=rubycomplete#Complete
setlocal path=.,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/bin,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/lib,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby/1.8/x86_64-linux,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby/1.8/x86_64-linux,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/1.8/x86_64-linux,,~/.rvm/gems/ree-1.8.7-2010.02@global/gems/rake-0.8.7/lib,~/.rvm/gems/ree-1.8.7-2010.02@global/gems/rdoc-2.5.8/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/bundler-1.0.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/bundler-1.0.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/configuration-1.1.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/crack-0.1.8/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/heroku-1.10.5/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/highline-1.6.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/hitch-0.6.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/json_pure-1.4.6/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/launchy-0.3.7/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/mime-types-1.16/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/parka-0.5.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rack-1.2.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rdoc-2.5.11/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rest-client-1.4.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/ruby-graphviz-0.9.17/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sequel-3.15.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sinatra-1.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sqlite3-ruby-1.3.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/taps-0.3.12/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/thor-0.14.1/lib
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=2
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.rb
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'ruby'
setlocal syntax=ruby
endif
setlocal tabstop=2
setlocal tags=./tags,./TAGS,tags,TAGS,~/Projects/heroku_work/bundler/.git/tags
setlocal textwidth=0
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
3
normal zo
4
normal zo
5
normal zo
15
normal zo
5
normal zo
14
normal zo
35
normal zo
4
normal zc
36
normal zo
37
normal zo
46
normal zo
36
normal zc
69
normal zo
70
normal zo
79
normal zo
69
normal zc
102
normal zo
103
normal zo
127
normal zo
102
normal zo
128
normal zo
132
normal zo
143
normal zo
161
normal zo
128
normal zo
162
normal zo
166
normal zo
195
normal zo
196
normal zo
195
normal zo
162
normal zo
195
normal zo
196
normal zo
207
normal zo
195
normal zo
3
normal zo
let s:l = 3 - ((2 * winheight(0) + 35) / 71)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
3
normal! 023l
wincmd w
argglobal
edit lib/bundler/runtime.rb
nnoremap <buffer> <silent> g} :exe        "ptjump =RubyCursorIdentifier()"
nnoremap <buffer> <silent> } :exe          "ptag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g] :exe      "stselect =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g :exe        "stjump =RubyCursorIdentifier()"
nnoremap <buffer> <silent>  :exe v:count1."stag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> ] :exe v:count1."stag =RubyCursorIdentifier()"
nnoremap <buffer> <silent>  :exe  v:count1."tag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g] :exe       "tselect =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g :exe         "tjump =RubyCursorIdentifier()"
cnoremap <buffer> <expr>  fugitive#buffer().rev()
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=RubyBalloonexpr()
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=>4
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=%+E%f:%l:\ parse\ error,%W%f:%l:\ warning:\ %m,%E%f:%l:in\ %*[^:]:\ %m,%E%f:%l:\ %m,%-C%tfrom\ %f:%l:in\ %.%#,%-Z%tfrom\ %f:%l,%-Z%p^,%-G%.%#
setlocal expandtab
if &filetype != 'ruby'
setlocal filetype=ruby
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
set foldlevel=1
setlocal foldlevel=6
setlocal foldmarker={{{,}}}
set foldmethod=syntax
setlocal foldmethod=syntax
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=^\\s*\\<\\(load\\|w*require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.rb','')
setlocal indentexpr=GetRubyIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,e,=end,=elsif,=when,=ensure,=rescue,==begin,==end
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=ri
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=ruby\ -w\ $*
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=rubycomplete#Complete
setlocal path=.,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/bin,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/lib,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby/1.8/x86_64-linux,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby/1.8/x86_64-linux,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/1.8/x86_64-linux,,~/.rvm/gems/ree-1.8.7-2010.02@global/gems/rake-0.8.7/lib,~/.rvm/gems/ree-1.8.7-2010.02@global/gems/rdoc-2.5.8/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/bundler-1.0.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/bundler-1.0.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/configuration-1.1.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/crack-0.1.8/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/heroku-1.10.5/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/highline-1.6.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/hitch-0.6.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/json_pure-1.4.6/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/launchy-0.3.7/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/mime-types-1.16/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/parka-0.5.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rack-1.2.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rdoc-2.5.11/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rest-client-1.4.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/ruby-graphviz-0.9.17/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sequel-3.15.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sinatra-1.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sqlite3-ruby-1.3.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/taps-0.3.12/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/thor-0.14.1/lib
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=2
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.rb
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'ruby'
setlocal syntax=ruby
endif
setlocal tabstop=2
setlocal tags=./tags,./TAGS,tags,TAGS,~/Projects/heroku_work/bundler/.git/tags
setlocal textwidth=0
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
3
normal zo
4
normal zo
7
normal zo
7
normal zc
47
normal zo
47
normal zc
73
normal zo
73
normal zc
94
normal zo
108
normal zo
108
normal zo
94
normal zo
118
normal zo
121
normal zo
122
normal zo
126
normal zo
121
normal zo
127
normal zo
130
normal zo
130
normal zo
145
normal zo
149
normal zo
150
normal zo
166
normal zo
149
normal zo
130
normal zo
127
normal zo
137
normal zo
159
normal zo
159
normal zo
184
normal zo
159
normal zo
137
normal zo
118
normal zo
163
normal zo
167
normal zo
168
normal zo
184
normal zo
167
normal zo
4
normal zo
3
normal zo
let s:l = 119 - ((10 * winheight(0) + 35) / 71)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
119
normal! 047l
wincmd w
exe 'vert 1resize ' . ((&columns * 79 + 157) / 315)
exe 'vert 2resize ' . ((&columns * 235 + 157) / 315)
tabedit lib/bundler/cli.rb
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
exe '1resize ' . ((&lines * 38 + 37) / 74)
exe 'vert 1resize ' . ((&columns * 79 + 157) / 315)
exe '2resize ' . ((&lines * 38 + 37) / 74)
exe 'vert 2resize ' . ((&columns * 79 + 157) / 315)
argglobal
nnoremap <buffer> <silent> g} :exe        "ptjump =RubyCursorIdentifier()"
nnoremap <buffer> <silent> } :exe          "ptag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g] :exe      "stselect =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g :exe        "stjump =RubyCursorIdentifier()"
nnoremap <buffer> <silent>  :exe v:count1."stag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> ] :exe v:count1."stag =RubyCursorIdentifier()"
nnoremap <buffer> <silent>  :exe  v:count1."tag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g] :exe       "tselect =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g :exe         "tjump =RubyCursorIdentifier()"
cnoremap <buffer> <expr>  fugitive#buffer().rev()
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=RubyBalloonexpr()
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=>4
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=^\\s*#\\s*define
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=%+E%f:%l:\ parse\ error,%W%f:%l:\ warning:\ %m,%E%f:%l:in\ %*[^:]:\ %m,%E%f:%l:\ %m,%-C%tfrom\ %f:%l:in\ %.%#,%-Z%tfrom\ %f:%l,%-Z%p^,%-G%.%#
setlocal expandtab
if &filetype != 'ruby'
setlocal filetype=ruby
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
set foldlevel=1
setlocal foldlevel=7
setlocal foldmarker={{{,}}}
set foldmethod=syntax
setlocal foldmethod=syntax
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=^\\s*\\<\\(load\\|w*require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.rb','')
setlocal indentexpr=GetRubyIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,e,=end,=elsif,=when,=ensure,=rescue,==begin,==end
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=ri
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=ruby\ -w\ $*
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=rubycomplete#Complete
setlocal path=.,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/bin,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/lib,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby/1.8/x86_64-linux,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby/1.8/x86_64-linux,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/1.8/x86_64-linux,,~/.rvm/gems/ree-1.8.7-2010.02@global/gems/rake-0.8.7/lib,~/.rvm/gems/ree-1.8.7-2010.02@global/gems/rdoc-2.5.8/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/bundler-1.0.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/bundler-1.0.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/configuration-1.1.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/crack-0.1.8/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/heroku-1.10.5/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/highline-1.6.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/hitch-0.6.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/json_pure-1.4.6/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/launchy-0.3.7/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/mime-types-1.16/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/parka-0.5.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rack-1.2.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rdoc-2.5.11/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rest-client-1.4.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/ruby-graphviz-0.9.17/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sequel-3.15.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sinatra-1.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sqlite3-ruby-1.3.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/taps-0.3.12/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/thor-0.14.1/lib
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=2
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.rb
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'ruby'
setlocal syntax=ruby
endif
setlocal tabstop=2
setlocal tags=./tags,./TAGS,tags,TAGS,~/Projects/heroku_work/bundler/.git/tags
setlocal textwidth=0
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
9
normal zo
10
normal zo
500
normal zo
502
normal zo
503
normal zo
510
normal zo
502
normal zo
500
normal zo
514
normal zo
519
normal zo
522
normal zo
519
normal zo
10
normal zo
9
normal zo
let s:l = 508 - ((23 * winheight(0) + 19) / 38)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
508
normal! 06l
wincmd w
argglobal
edit lib/bundler.rb
nnoremap <buffer> <silent> g} :exe        "ptjump =RubyCursorIdentifier()"
nnoremap <buffer> <silent> } :exe          "ptag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g] :exe      "stselect =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g :exe        "stjump =RubyCursorIdentifier()"
nnoremap <buffer> <silent>  :exe v:count1."stag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> ] :exe v:count1."stag =RubyCursorIdentifier()"
nnoremap <buffer> <silent>  :exe  v:count1."tag =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g] :exe       "tselect =RubyCursorIdentifier()"
nnoremap <buffer> <silent> g :exe         "tjump =RubyCursorIdentifier()"
cnoremap <buffer> <expr>  fugitive#buffer().rev()
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=RubyBalloonexpr()
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=>4
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=^\\s*#\\s*define
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=%+E%f:%l:\ parse\ error,%W%f:%l:\ warning:\ %m,%E%f:%l:in\ %*[^:]:\ %m,%E%f:%l:\ %m,%-C%tfrom\ %f:%l:in\ %.%#,%-Z%tfrom\ %f:%l,%-Z%p^,%-G%.%#
setlocal expandtab
if &filetype != 'ruby'
setlocal filetype=ruby
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
set foldlevel=1
setlocal foldlevel=1
setlocal foldmarker={{{,}}}
set foldmethod=syntax
setlocal foldmethod=syntax
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=^\\s*\\<\\(load\\|w*require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.rb','')
setlocal indentexpr=GetRubyIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,e,=end,=elsif,=when,=ensure,=rescue,==begin,==end
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=ri
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=ruby\ -w\ $*
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=rubycomplete#Complete
setlocal path=.,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/bin,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/lib,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby/1.8/x86_64-linux,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/site_ruby,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby/1.8/x86_64-linux,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/vendor_ruby,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/1.8,~/.rvm/rubies/ree-1.8.7-2010.02/lib/ruby/1.8/x86_64-linux,,~/.rvm/gems/ree-1.8.7-2010.02@global/gems/rake-0.8.7/lib,~/.rvm/gems/ree-1.8.7-2010.02@global/gems/rdoc-2.5.8/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/bundler-1.0.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/bundler-1.0.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/configuration-1.1.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/crack-0.1.8/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/gem-open-0.1.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/heroku-1.10.5/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/highline-1.6.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/hitch-0.6.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/json_pure-1.4.6/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/launchy-0.3.7/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/mime-types-1.16/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/parka-0.5.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rack-1.2.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rdoc-2.5.11/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/rest-client-1.4.2/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/ruby-graphviz-0.9.17/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sequel-3.15.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sinatra-1.0/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/sqlite3-ruby-1.3.1/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/taps-0.3.12/lib,~/.rvm/gems/ree-1.8.7-2010.02@heroku_work/gems/thor-0.14.1/lib
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal readonly
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=2
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.rb
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'ruby'
setlocal syntax=ruby
endif
setlocal tabstop=2
setlocal tags=./tags,./TAGS,tags,TAGS,~/Projects/heroku_work/bundler/.git/tags
setlocal textwidth=0
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
8
normal zo
66
normal zo
94
normal zo
97
normal zo
94
normal zo
114
normal zo
151
normal zo
155
normal zo
159
normal zo
165
normal zo
169
normal zo
173
normal zo
177
normal zo
185
normal zo
189
normal zo
193
normal zo
201
normal zo
202
normal zo
201
normal zo
209
normal zo
213
normal zo
217
normal zo
220
normal zo
221
normal zo
225
normal zo
233
normal zo
225
normal zo
221
normal zo
220
normal zo
217
normal zo
245
normal zo
246
normal zo
245
normal zo
259
normal zo
261
normal zo
264
normal zo
261
normal zo
259
normal zo
66
normal zo
8
normal zo
let s:l = 160 - ((0 * winheight(0) + 19) / 38)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
160
normal! 06l
wincmd w
exe '1resize ' . ((&lines * 38 + 37) / 74)
exe 'vert 1resize ' . ((&columns * 79 + 157) / 315)
exe '2resize ' . ((&lines * 38 + 37) / 74)
exe 'vert 2resize ' . ((&columns * 79 + 157) / 315)
tabnew
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
argglobal
enew
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal balloonexpr=
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,0#,!^F,o,O,e
setlocal cinoptions=>4
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != ''
setlocal filetype=
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
set foldlevel=1
setlocal foldlevel=1
setlocal foldmarker={{{,}}}
set foldmethod=syntax
setlocal foldmethod=syntax
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=tcq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=
setlocal iminsert=2
setlocal imsearch=2
setlocal include=
setlocal includeexpr=
setlocal indentexpr=
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=rubycomplete#Complete
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=2
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != ''
setlocal syntax=
endif
setlocal tabstop=2
setlocal tags=
setlocal textwidth=0
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
tabnext 1
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToO
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
