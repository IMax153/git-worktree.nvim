# Snacks Picker Integration

## Overview

Implement Snacks.nvim picker integration for browsing and switching between git worktrees with visual indicators for current worktree and dirty state.

## Requirements

- `lua/git-worktree/snacks.lua` exists
- `require('git-worktree.snacks').worktrees()` opens Snacks picker
- Picker shows current worktree indicator
- Picker shows branch name
- Picker shows path
- Picker shows dirty state indicator
- Dirty state is fetched for all worktrees
- `<CR>` switches to selected worktree
- Gracefully errors with `vim.notify` if Snacks not installed

## Acceptance Criteria

- [ ] `lua/git-worktree/snacks.lua` module exists
- [ ] `worktrees()` function opens Snacks picker with all worktrees
- [ ] Current worktree has visual indicator (e.g., `*` or highlight)
- [ ] Each entry displays branch name
- [ ] Each entry displays worktree path
- [ ] Dirty worktrees have visual indicator (e.g., `[dirty]`)
- [ ] Dirty state checked via `git.is_dirty()` for all worktrees
- [ ] Pressing `<CR>` calls `require('git-worktree').switch()`
- [ ] Missing Snacks dependency shows `vim.notify` error, not crash

## Known Issues

_None yet_

## Status

- [ ] Not started
