# Snacks Picker Create Action

## Overview

Add create worktree action to Snacks picker via `<C-n>` keybinding, prompting for branch/path and creating the worktree inline.

## Requirements

- `<C-n>` in picker prompts for branch name
- After branch, prompts for path (defaults to `../<branch>`)
- Creates worktree and switches to it
- Picker refreshes or closes after creation

## Acceptance Criteria

- [ ] `<C-n>` keybinding registered in Snacks picker
- [ ] First prompt asks for branch name via `vim.ui.input()`
- [ ] Second prompt asks for path, defaulting to `../<branch>`
- [ ] Calls `require('git-worktree').create()` with inputs
- [ ] Switches to new worktree on success
- [ ] Picker closes or refreshes after successful creation
- [ ] Errors shown via `vim.notify` on failure

## Known Issues

_None yet_

## Status

- [ ] Not started
