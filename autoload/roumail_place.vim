" vim-place: where plugins keep their files (dir), and the repository they work in (get)

" The work tree of the buffer's repository, else of the current directory's,
" else the current directory, as {dir, repo}: the same repository dir()
" keeps files in
function! roumail_place#get(...) abort
  let l:gitdir = s:git_dir(get(a:, 1, bufnr()))
  let l:tree = empty(l:gitdir) ? '' : FugitiveWorkTree(l:gitdir)
  return empty(l:tree) ? {'dir': getcwd(), 'repo': 0} : {'dir': l:tree, 'repo': 1}
endfunction

" Where a plugin keeps its files, named name: in the git dir of the
" repository, else in g:roumail_place_dir, else in the XDG state directory,
" so every plugin keeps its files the same way. The directory is created.
" opts:
"   bufnr     whose repository (default: the current buffer's, else the
"             current directory's)
"   worktree  1: the work tree's own git dir, which git removes with the work
"             tree, for files of no use after it (default: the git dir shared
"             by all work trees, so files outlive the work tree)
function! roumail_place#dir(name, ...) abort
  let l:opts = get(a:, 1, {})
  let l:git_dir = s:git_dir(get(l:opts, 'bufnr', bufnr()))
  if !empty(l:git_dir) && !get(l:opts, 'worktree', 0)
    let l:git_dir = FugitiveCommonDir(l:git_dir)
  endif
  if empty(l:git_dir)
    " Each directory's files apart, as a repository's are in its git dir
    let l:place = roumail_place#get(get(l:opts, 'bufnr', bufnr())).dir
    let l:git_dir = s:outside() . '/' . fnamemodify(l:place, ':t') . '-' . sha256(l:place)[:7]
  endif
  let l:dir = l:git_dir . '/' . a:name
  call mkdir(l:dir, 'p')
  return l:dir
endfunction

" Where files go outside a repository
function! s:outside() abort
  let l:dir = get(g:, 'roumail_place_dir', '')
  if !empty(l:dir)
    return expand(l:dir)
  endif
  return empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME
endfunction

" The git dir of the buffer's repository, else of the current directory's,
" else '': one answer for get() and dir(). Fugitive sets a buffer's git dir
" once it is current: before that, the file's path tells it
function! s:git_dir(bufnr) abort
  let l:dir = FugitiveGitDir(a:bufnr)
  if empty(l:dir) && !empty(bufname(a:bufnr)) && empty(getbufvar(a:bufnr, '&buftype'))
    let l:dir = FugitiveExtractGitDir(fnamemodify(bufname(a:bufnr), ':p'))
  endif
  return empty(l:dir) ? FugitiveExtractGitDir(getcwd()) : l:dir
endfunction
