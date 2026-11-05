# vim-place

Where a plugin is working, and where it keeps its files: one answer for
every plugin, so a plugin finds no git dir and picks no directory of its
own. It has no commands; other plugins call it.

## Install

Requires [vim-fugitive](https://github.com/tpope/vim-fugitive), which finds
the git directory.

```vim
Plug 'tpope/vim-fugitive'
Plug 'roumail/vim-place'
```

## Where a plugin is working

`roumail_place#get([bufnr])` is where a plugin is working, as `{dir, repo}`:
the work tree of the buffer's repository (default: the current buffer), else
of the current directory's, with `repo` 1; else the current directory, with
`repo` 0. Paths a plugin shows or keeps are relative to `dir`.

## Where it keeps its files

`roumail_place#dir(name [, opts])` returns the directory a plugin keeps its
files in (saves, prompts), created if missing, the first of:

1. `<git dir>/<name>` in a git repository, found by vim-fugitive: the git
   dir shared by all work trees, so the files outlive a work tree and are
   never committed.
2. `<g:roumail_place_dir>/<place>/<name>` outside a repository, when it is
   set.
3. `<$XDG_STATE_HOME>/<place>/<name>` (`~/.local/state/<place>/<name>`)
   otherwise.

Outside a repository, `<place>` keeps each directory's files apart, as a
repository's git dir does: the current directory's name and a short hash of
its path, e.g. `notes-1a2b3c4d`.

| Option | Default |
| --- | --- |
| `bufnr` | The current buffer: whose repository it is. A buffer that isn't a file (a list, a draft) is in the current directory's. |
| `worktree` | `0`. `1`: the work tree's own git dir, which git removes with the work tree, for files of no use after it. |

A plugin names its directory after itself, e.g.
`roumail_place#dir('my-plugin/notes', {'worktree': 1})`.

## Settings

| Variable | Default |
| --- | --- |
| `g:roumail_place_dir` | Unset: what plugins keep outside a repository goes in the XDG state directory (`$XDG_STATE_HOME`, else `~/.local/state`). |

## Tests

```sh
vim -Nu NONE -i NONE -Es -S test/run.vim
```

vim-fugitive comes from `$FUGITIVE`, else vim-plug's copy.
