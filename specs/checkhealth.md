# Checkhealth Integration

## Overview

Implement `:checkhealth git-worktree` to verify plugin dependencies and environment requirements.

## Requirements

- `lua/git-worktree/health.lua` exists
- `:checkhealth git-worktree` runs without error
- Checks Neovim version >= 0.11 (error if not)
- Checks git executable exists (error if not)
- Checks current directory is git repo (warn if not)
- Checks Snacks.nvim availability (info, not error)

## Acceptance Criteria

- [ ] `lua/git-worktree/health.lua` module exists
- [ ] Module exports `check()` function for health framework
- [ ] `:checkhealth git-worktree` executes without errors
- [ ] Reports ERROR if Neovim version < 0.11
- [ ] Reports ERROR if `git` not found in PATH
- [ ] Reports WARN if cwd is not a git repository
- [ ] Reports INFO about Snacks.nvim availability (optional dependency)
- [ ] Reports OK for all passing checks

## Known Issues

_None yet_

## Status

- [ ] Not started
