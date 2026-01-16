# Snacks Picker Delete Action

## Overview

Add delete worktree action to Snacks picker via `<C-d>` keybinding with confirmation prompt and refresh behavior.

## Requirements

- `<C-d>` in picker deletes selected worktree
- Shows confirmation before delete
- Cannot delete current worktree (shows error)
- Picker refreshes after deletion

## Acceptance Criteria

- [ ] `<C-d>` keybinding registered in Snacks picker
- [ ] Confirmation prompt shown before deletion (e.g., "Delete worktree at <path>?")
- [ ] Calls `require('git-worktree').delete()` on confirmation
- [ ] Attempting to delete current worktree shows error via `vim.notify`
- [ ] Picker refreshes to remove deleted worktree from list
- [ ] Errors from `delete()` shown via `vim.notify`

## Known Issues

_None yet_

## Status

- [ ] Not started
