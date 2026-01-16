# Configuration and Hooks

## Overview

Implement plugin configuration system with lifecycle hooks for create, switch, and delete operations.

## Requirements

- `setup()` is optional - plugin works without it
- `setup({ hooks = { on_switch = fn } })` registers switch hook
- `setup({ hooks = { on_create = fn } })` registers create hook
- `setup({ hooks = { on_delete = fn } })` registers delete hook
- Hooks receive Worktree objects as arguments
- Config validation via `vim.validate()`

## Acceptance Criteria

- [ ] Plugin loads and functions without calling `setup()`
- [ ] `setup()` accepts `hooks.on_switch` callback
- [ ] `setup()` accepts `hooks.on_create` callback
- [ ] `setup()` accepts `hooks.on_delete` callback
- [ ] `on_switch` called with (old_worktree, new_worktree) after switch
- [ ] `on_create` called with (worktree) after creation
- [ ] `on_delete` called with (worktree) after deletion
- [ ] Invalid config types cause validation errors via `vim.validate()`
- [ ] Hooks are optional - no error if not provided

## Known Issues

_None yet_

## Status

- [ ] Not started
