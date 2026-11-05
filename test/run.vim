" Headless tests, from the repository's root:
"   vim -Nu NONE -i NONE -Es -S test/run.vim
" Prints one line per test and exits non-zero when one fails; TEST=<pattern>
" in the environment runs the tests whose names match.
set nocompatible hidden
execute 'set runtimepath^=' . fnameescape(expand('<sfile>:p:h:h'))
" Only this plugin and fugitive, which finds git dirs for it ($FUGITIVE,
" else vim-plug's copy): Vim's own ones aren't all quiet in silent Ex mode
let s:fugitive = empty($FUGITIVE) ? expand('~/.vim/plugged/vim-fugitive') : $FUGITIVE
execute 'set runtimepath^=' . fnameescape(s:fugitive)
execute 'source' fnameescape(s:fugitive . '/plugin/fugitive.vim')

let s:tmp = resolve(tempname())
call mkdir(s:tmp . '/repo', 'p')
call system('git -C ' . shellescape(s:tmp . '/repo') . ' init -q')
call system('git -C ' . shellescape(s:tmp . '/repo') . ' -c user.name=t -c user.email=t@t'
      \ . ' commit -q --allow-empty -m init')
call system('git -C ' . shellescape(s:tmp . '/repo') . ' worktree add -q '
      \ . shellescape(s:tmp . '/linked'))
call mkdir(s:tmp . '/plain/sub', 'p')
let g:roumail_place_dir = s:tmp . '/saves'
let s:out = []

function! s:reset() abort
  silent! only!
  silent! %bwipeout!
  execute 'cd' fnameescape(s:tmp . '/plain')
endfunction

" What vim-place names a directory outside a repository by
function! s:place(dir) abort
  return fnamemodify(a:dir, ':t') . '-' . sha256(a:dir)[:7]
endfunction

function! s:test_dir() abort
  let l:git = s:tmp . '/repo/.git'
  execute 'edit' fnameescape(s:tmp . '/repo/file.txt')
  call assert_equal(l:git . '/my-plugin/x', roumail_place#dir('my-plugin/x'))
  call assert_true(isdirectory(l:git . '/my-plugin/x'))
  " A linked work tree: the common git dir, else its own
  execute 'edit' fnameescape(s:tmp . '/linked/file.txt')
  call assert_equal(l:git . '/p', roumail_place#dir('p'))
  call assert_equal(l:git . '/worktrees/linked/p', roumail_place#dir('p', {'worktree': 1}))
  " Another buffer's repository
  let l:linked = bufnr()
  execute 'edit' fnameescape(s:tmp . '/outside.txt')
  call assert_equal(l:git . '/worktrees/linked/q', roumail_place#dir('q', {'bufnr': l:linked, 'worktree': 1}))
  " Outside a repository: one directory per current directory
  call assert_equal(g:roumail_place_dir . '/' . s:place(s:tmp . '/plain') . '/my-plugin/x',
        \ roumail_place#dir('my-plugin/x'))
  cd sub
  call assert_equal(g:roumail_place_dir . '/' . s:place(s:tmp . '/plain/sub') . '/my-plugin/x',
        \ roumail_place#dir('my-plugin/x'))
  call delete(g:roumail_place_dir, 'rf')
endfunction

function! s:test_dir_xdg() abort
  let l:saved = [g:roumail_place_dir, $XDG_STATE_HOME]
  unlet g:roumail_place_dir
  let $XDG_STATE_HOME = s:tmp . '/state'
  try
    execute 'edit' fnameescape(s:tmp . '/outside.txt')
    let l:dir = s:tmp . '/state/' . s:place(s:tmp . '/plain') . '/my-plugin'
    call assert_equal(l:dir, roumail_place#dir('my-plugin'))
    call assert_true(isdirectory(l:dir))
  finally
    let [g:roumail_place_dir, $XDG_STATE_HOME] = l:saved
    call delete(s:tmp . '/state', 'rf')
  endtry
endfunction

" A file outside any repository, with the current directory in one: both
" say the current directory's repository
function! s:test_get_and_dir_agree() abort
  execute 'edit' fnameescape(s:tmp . '/plain/file.txt')
  execute 'cd' fnameescape(s:tmp . '/repo')
  call assert_equal({'dir': s:tmp . '/repo', 'repo': 1}, roumail_place#get())
  call assert_equal(s:tmp . '/repo/.git/p', roumail_place#dir('p'))
  " A buffer of a repository fugitive hasn't seen yet: by its path
  execute 'badd' fnameescape(s:tmp . '/linked/other.txt')
  let l:linked = bufnr(s:tmp . '/linked/other.txt')
  call assert_equal({'dir': s:tmp . '/linked', 'repo': 1}, roumail_place#get(l:linked))
  call assert_equal(s:tmp . '/repo/.git/worktrees/linked/q',
        \ roumail_place#dir('q', {'bufnr': l:linked, 'worktree': 1}))
endfunction

function! s:test_get() abort
  execute 'edit' fnameescape(s:tmp . '/repo/file.txt')
  call assert_equal({'dir': s:tmp . '/repo', 'repo': 1}, roumail_place#get())
  execute 'edit' fnameescape(s:tmp . '/linked/file.txt')
  call assert_equal({'dir': s:tmp . '/linked', 'repo': 1}, roumail_place#get())
  let l:linked = bufnr()
  execute 'edit' fnameescape(s:tmp . '/outside.txt')
  call assert_equal({'dir': s:tmp . '/linked', 'repo': 1}, roumail_place#get(l:linked))
  call assert_equal({'dir': s:tmp . '/plain', 'repo': 0}, roumail_place#get())
  " Outside a repository, the current directory's, if it is in one
  execute 'cd' fnameescape(s:tmp . '/repo')
  call assert_equal({'dir': s:tmp . '/repo', 'repo': 1}, roumail_place#get())
endfunction

let s:failed = 0
let s:prefix = expand('<SID>') . 'test_'
let s:names = []
for s:line in split(execute('function'), "\n")
  if stridx(s:line, 'function ' . s:prefix) == 0
    call add(s:names, matchstr(s:line, '^function \zs[^(]\+'))
  endif
endfor
for s:name in s:names
  let s:label = matchstr(s:name, 'test_\zs\w\+')
  if !empty($TEST) && s:label !~# $TEST
    continue
  endif
  call s:reset()
  let v:errors = []
  try
    call call(s:name, [])
  catch
    call add(v:errors, v:exception . ' @ ' . v:throwpoint)
  endtry
  if empty(v:errors)
    call add(s:out, 'ok   ' . s:label)
  else
    let s:failed += 1
    call add(s:out, 'FAIL ' . s:label)
    call extend(s:out, map(copy(v:errors), '"     " . v:val'))
  endif
endfor
call add(s:out, s:failed ? s:failed . ' failed' : 'all passed')
call writefile(s:out, '/dev/stdout')
call delete(s:tmp, 'rf')
execute 'cquit' (s:failed ? 1 : 0)
