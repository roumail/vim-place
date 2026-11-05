# vim-place

A convention for where Vim plugins keep their files. Instead of each plugin
finding the git dir and choosing a path, every plugin asks vim-place and
gets the same answer: inside the repository's git dir, so the files are
never committed and outlive a work tree, or a per-directory state folder
outside a repository.

The files are state, not cache: saved comments, saved lists, prompts an
agent still reads. They stay until the plugin that wrote them deletes them.

## The convention

A plugin following it does two things:

1. **Calls `roumail_place#dir('<plugin-name>/...')` for its files**, naming
   the directory after itself. That name is what keeps plugins sharing a
   git dir apart: `fugitive-extras/comments`, `qf-tools`,
   `vim-prompts/prompts`.
2. **Asks each time, and stores no path.** The answer depends on the buffer
   and the current directory: the same plugin keeps one repository's files
   in that repository, and another's in the other.

## Where the files go

`roumail_place#dir(name [, opts])` returns the directory, created if
missing, the first of:

1. `<git dir>/<name>` when the buffer, or else the current directory, is in a
   git repository (found by vim-fugitive): the git dir shared by all work
   trees, so the files outlive a work tree.
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
| `worktree` | `0`. `1`: the work tree's own git dir, which git removes with the work tree, for files of no use after it (vim-prompts' prompts). |

## Where a plugin is working

`roumail_place#get([bufnr])` is the same answer as a directory to work in,
as `{dir, repo}`: the work tree of the repository `dir()` keeps files in,
with `repo` 1, else the current directory, with `repo` 0. Paths a plugin
shows or saves are relative to `dir`, so they read the same in every work
tree.

## Settings

| Variable | Default |
| --- | --- |
| `g:roumail_place_dir` | Unset: what plugins keep outside a repository goes in the XDG state directory (`$XDG_STATE_HOME`, else `~/.local/state`). |

## Install

Requires [vim-fugitive](https://github.com/tpope/vim-fugitive), which finds
the git directory. It has no commands; plugins call it.

```vim
Plug 'tpope/vim-fugitive'
Plug 'roumail/vim-place'
```

## Tests

```sh
vim -Nu NONE -i NONE -Es -S test/run.vim
```

vim-fugitive comes from `$FUGITIVE`, else vim-plug's copy.
