" vim-place: where a plugin is working, and where it keeps its files

" The work tree of the buffer's repository, else of the current directory's,
" else the current directory, as {dir, repo}
function! roumail_place#get(...) abort
  for l:gitdir in [FugitiveGitDir(get(a:, 1, bufnr())), FugitiveExtractGitDir(getcwd())]
    let l:tree = empty(l:gitdir) ? '' : FugitiveWorkTree(l:gitdir)
    if !empty(l:tree)
      return {'dir': l:tree, 'repo': 1}
    endif
  endfor
  return {'dir': getcwd(), 'repo': 0}
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
  let l:git_dir = s:git_dir(get(l:opts, 'bufnr', -1), get(l:opts, 'worktree', 0))
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

" Found by fugitive: the buffer's, else, for a buffer that isn't a file,
" the current directory's
function! s:git_dir(bufnr, worktree) abort
  let l:bufnr = a:bufnr < 0 ? bufnr() : a:bufnr
  let l:dir = a:bufnr < 0 ? FugitiveGitDir() : FugitiveGitDir(l:bufnr)
  if empty(l:dir)
    " Fugitive sets a buffer's git dir once it is current: else by its path
    let l:file = empty(bufname(l:bufnr)) || !empty(getbufvar(l:bufnr, '&buftype'))
          \ ? getcwd() : fnamemodify(bufname(l:bufnr), ':p')
    let l:dir = FugitiveExtractGitDir(l:file)
  endif
  return empty(l:dir) || a:worktree ? l:dir : FugitiveCommonDir(l:dir)
endfunction
