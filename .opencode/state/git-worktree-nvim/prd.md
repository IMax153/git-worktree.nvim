# PRD: git-worktree.nvim

**Date:** 2026-01-16

---

## Problem Statement

### What problem are we solving?

Managing git worktrees requires leaving Neovim to run shell commands (`git worktree add`, `git worktree list`, `git worktree remove`). Context switching between editor and terminal breaks flow, especially when frequently switching between feature branches, hotfixes, and main.

Additionally, existing Neovim worktree plugins (e.g., ThePrimeagen's git-worktree.nvim) integrate with Telescope rather than Snacks.nvim, forcing users who prefer Snacks to either use a different picker ecosystem or forgo worktree tooling.

### Why now?

Personal workflow friction. Snacks.nvim has matured as a picker solution and warrants first-class integration.

### Who is affected?

- **Primary user:** Plugin author (personal use)
- **Secondary users:** Neovim users who prefer Snacks.nvim and use git worktrees

---

## Proposed Solution

### Overview

A Neovim plugin providing a Lua API for git worktree operations (list, create, switch, delete) with optional Snacks.nvim picker integration. The plugin handles buffer management automatically when switching worktrees—auto-saving modified buffers and repointing all buffers to the new worktree's files.

### User Experience

#### User Flow: Create and Switch to New Worktree

1. User invokes `:Worktree create` or `require("git-worktree").create()`
2. Plugin prompts for branch name (if not provided)
3. Plugin prompts for worktree path (default: `../<branch-name>`)
4. Plugin creates worktree via `git worktree add`
5. Plugin auto-saves all modified buffers
6. Plugin changes cwd to new worktree
7. Plugin repoints all buffers to equivalent paths in new worktree
8. User is now in the new worktree with their buffer layout preserved

#### User Flow: Switch to Existing Worktree (via Picker)

1. User invokes `:Worktree pick` or `require("git-worktree.pick").worktrees()`
2. Snacks picker opens showing all worktrees with:
   - Current worktree indicator
   - Branch name
   - Path
   - Dirty state indicator
3. User selects a worktree (or uses `<C-d>` to delete, `<C-n>` to create)
4. Plugin auto-saves, changes cwd, repoints buffers
5. Picker closes, user is in selected worktree

#### User Flow: Delete Worktree

1. User invokes `:Worktree delete <path>` or selects delete action in picker
2. Plugin confirms deletion (if worktree is dirty, requires force)
3. Plugin runs `git worktree remove`
4. If deleted worktree was current, user remains in place (error or prompt to switch)

---

## End State

When this PRD is complete, the following will be true:

- [ ] `require("git-worktree").list()` returns all worktrees with metadata
- [ ] `require("git-worktree").create(opts)` creates a new worktree
- [ ] `require("git-worktree").switch(path)` switches to a worktree (auto-save, cwd, buffer repoint)
- [ ] `require("git-worktree").delete(path, opts)` removes a worktree
- [ ] Snacks picker integration exists as optional module (`git-worktree.pick`)
- [ ] Plugin works without Snacks installed (core API only)
- [ ] `:Worktree` command provides CLI access to all operations
- [ ] `:checkhealth git-worktree` validates environment (git, Neovim version, Snacks availability)
- [ ] Plugin follows modern Lua/Neovim conventions (LuaCATS types, lazy-loading, etc.)

---

## Success Metrics

### Quantitative

| Metric | Current | Target | Measurement Method |
|--------|---------|--------|-------------------|
| Shell exits for worktree ops | ~5/day | 0 | Self-observation |
| Time to switch worktree | ~10s (terminal) | <2s (picker) | Self-observation |

### Qualitative

- Seamless worktree switching without losing buffer context
- No friction when creating new worktrees for features/hotfixes

---

## Acceptance Criteria

### Core API: `list()`

- [ ] Returns table of worktree objects
- [ ] Each worktree has: `path`, `head` (SHA), `branch` (or nil if detached), `is_bare`, `is_current`, `is_locked`, `is_prunable`
- [ ] Parses `git worktree list --porcelain` output correctly
- [ ] Handles edge cases: detached HEAD, bare repo, locked worktrees

### Core API: `create(opts)`

- [ ] Creates worktree from existing branch: `create({ branch = "feature-x" })`
- [ ] Creates worktree with new branch: `create({ branch = "feature-x", create_branch = true })`
- [ ] Prompts for path if not provided, defaulting to `../<branch>`
- [ ] Optionally switches to new worktree after creation (`switch = true`, default)
- [ ] Returns worktree object on success, nil + error on failure

### Core API: `switch(path)`

- [ ] Auto-saves all modified buffers before switch
- [ ] Changes `cwd` to target worktree
- [ ] Repoints all buffers: `old_worktree/path/file.lua` → `new_worktree/path/file.lua`
- [ ] Closes buffers for files that don't exist in new worktree (with notification)
- [ ] Restarts LSP clients to ensure fresh language server state
- [ ] Emits `User GitWorktreeSwitched` autocmd event
- [ ] Returns boolean success

### Core API: `delete(path, opts)`

- [ ] Removes worktree via `git worktree remove`
- [ ] `opts.force` allows removing dirty worktrees
- [ ] Prevents deleting current worktree (error with message)
- [ ] Prevents deleting main worktree (error with message)
- [ ] Returns boolean success, nil + error on failure

### Command: `:Worktree`

- [ ] `:Worktree list` — prints worktrees
- [ ] `:Worktree create [branch] [path]` — creates worktree (prompts if args missing)
- [ ] `:Worktree switch <path>` — switches to worktree
- [ ] `:Worktree delete <path>` — deletes worktree
- [ ] `:Worktree pick` — opens Snacks picker (if available)
- [ ] Tab completion for subcommands and paths

### Snacks Integration: `git-worktree.snacks`

- [ ] `require("git-worktree.snacks").worktrees()` opens picker
- [ ] Picker shows: current indicator, branch, path, dirty state
- [ ] Dirty state fetched for all worktrees (informed decision-making)
- [ ] `<CR>` switches to selected worktree
- [ ] `<C-n>` creates new worktree (prompts for branch/path)
- [ ] `<C-d>` deletes selected worktree (with confirmation)
- [ ] Picker gracefully errors if Snacks not installed

### Health Check

- [ ] Checks Neovim version >= 0.11
- [ ] Checks `git` executable exists
- [ ] Checks current directory is a git repo
- [ ] Checks Snacks.nvim availability (info, not error)

### Configuration

- [ ] `setup()` optional (sensible defaults)
- [ ] Configurable: `autopush` (future), `autofetch` (future), hooks
- [ ] Hook: `on_switch(old_worktree, new_worktree)` callback
- [ ] Hook: `on_create(worktree)` callback
- [ ] Hook: `on_delete(worktree)` callback

---

## Technical Context

### Git Commands Used

| Operation | Command |
|-----------|---------|
| List worktrees | `git worktree list --porcelain` |
| Create worktree | `git worktree add [-b branch] <path> [start-point]` |
| Delete worktree | `git worktree remove [--force] <path>` |
| Check dirty state | `git -C <path> status --porcelain` |
| Get current branch | `git rev-parse --abbrev-ref HEAD` |
| Check if bare | `git rev-parse --is-bare-repository` |
| Get git dir | `git rev-parse --git-common-dir` |

### Neovim APIs Used

| Purpose | API |
|---------|-----|
| Run git commands | `vim.system()` (async) |
| Change cwd | `vim.cmd.cd()` or `vim.fn.chdir()` |
| List buffers | `vim.api.nvim_list_bufs()` |
| Get buffer name | `vim.api.nvim_buf_get_name()` |
| Set buffer name | `vim.api.nvim_buf_set_name()` |
| Save buffer | `vim.api.nvim_buf_call()` + `:write` |
| Delete buffer | `vim.api.nvim_buf_delete()` |
| Restart LSP | `vim.lsp.stop_client()` + `vim.cmd("LspStart")` |
| User commands | `vim.api.nvim_create_user_command()` |
| Autocmd events | `vim.api.nvim_exec_autocmds()` |
| Input prompts | `vim.ui.input()` |
| Notifications | `vim.notify()` |
| Config validation | `vim.validate()` |

### Snacks APIs Used

| Purpose | API |
|---------|-----|
| Picker | `Snacks.picker.pick()` |
| Input prompt | `Snacks.input()` |
| Notification | `Snacks.notify()` |

### Directory Structure

```
git-worktree.nvim/
├── lua/
│   └── git-worktree/
│       ├── init.lua          # Public API: setup, list, create, switch, delete
│       ├── config.lua         # Configuration defaults and validation
│       ├── git.lua            # Git command wrappers
│       ├── worktree.lua       # Worktree type and parsing
│       ├── buffer.lua         # Buffer management (save, repoint, close)
│       ├── snacks.lua         # Snacks picker integration
│       ├── command.lua        # :Worktree command implementation
│       ├── health.lua         # :checkhealth implementation
│       └── types.lua          # LuaCATS type definitions
├── plugin/
│   └── git-worktree.lua       # Auto-register :Worktree command
├── doc/
│   └── git-worktree.txt       # Vimdoc
└── README.md
```

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Buffer repointing fails for special buffers (terminals, fugitive, etc.) | Medium | Low | Skip non-file buffers, only repoint normal file buffers |
| Path resolution issues (symlinks, macOS /tmp vs /private/tmp) | Medium | Medium | Canonicalize paths with `vim.fn.resolve()` |
| User loses unsaved work during switch | Low | High | Always auto-save before switch; emit event for custom hooks |
| Git command fails silently | Low | Medium | Check exit codes, parse stderr, surface errors via `vim.notify` |
| Snacks API changes break picker | Low | Low | Pin to known Snacks patterns; graceful degradation |

---

## Alternatives Considered

### Alternative 1: Fork ThePrimeagen's git-worktree.nvim

- **Pros:** Existing codebase, battle-tested
- **Cons:** Telescope-centric architecture, would require significant refactoring
- **Decision:** Rejected. Cleaner to build from scratch with Snacks-first design.

### Alternative 2: Shell wrapper script + Neovim RPC

- **Pros:** Could work outside Neovim too
- **Cons:** Complexity, two codebases, IPC overhead
- **Decision:** Rejected. Pure Lua plugin is simpler and more maintainable.

### Alternative 3: Snacks-only (no fallback)

- **Pros:** Simpler implementation
- **Cons:** Unusable without Snacks; limits API composability
- **Decision:** Rejected. Core Lua API should work standalone; Snacks is optional UI layer.

---

## Non-Goals (v1)

Explicitly out of scope for this PRD:

- **Remote branch checkout** — `git worktree add` from remote branch that doesn't exist locally. Adds complexity; defer to v2.
- **Auto-fetch before list** — Fetching remotes before listing worktrees. User can fetch manually; avoid implicit network calls.
- **Telescope integration** — Only Snacks for now. Could add Telescope later if needed.
- **Worktree templates** — Pre-configured worktree setups (e.g., "create hotfix worktree with specific structure"). Over-engineering for v1.
- **Session management** — Saving/restoring Neovim sessions per worktree. Orthogonal concern; use existing session plugins.
- **Branch management** — Creating/deleting branches independent of worktrees. Out of scope; use fugitive or lazygit.

---

## Interface Specifications

### Lua API

```lua
-- Setup (optional)
require("git-worktree").setup({
  hooks = {
    on_switch = function(old, new) end,
    on_create = function(worktree) end,
    on_delete = function(worktree) end,
  },
})

-- List all worktrees
---@return git-worktree.Worktree[]
require("git-worktree").list()

-- Create a worktree
---@param opts { branch: string, path?: string, create_branch?: boolean, switch?: boolean }
---@return git-worktree.Worktree?, string?
require("git-worktree").create(opts)

-- Switch to a worktree
---@param path string
---@return boolean, string?
require("git-worktree").switch(path)

-- Delete a worktree
---@param path string
---@param opts? { force?: boolean }
---@return boolean, string?
require("git-worktree").delete(path, opts)

-- Snacks picker (if available)
require("git-worktree.snacks").worktrees()
```

### CLI

```
:Worktree list                    List all worktrees
:Worktree create [branch] [path]  Create worktree (prompts if missing)
:Worktree switch <path>           Switch to worktree
:Worktree delete <path>           Delete worktree
:Worktree pick                    Open Snacks picker
```

### Types

```lua
---@class git-worktree.Worktree
---@field path string Absolute path to worktree
---@field head string Commit SHA
---@field branch string? Branch name (nil if detached)
---@field is_bare boolean True if bare repo entry
---@field is_current boolean True if this is cwd
---@field is_locked boolean True if locked
---@field is_prunable boolean True if prunable
---@field is_detached boolean True if detached HEAD
---@field is_dirty boolean? True if uncommitted changes (lazy-loaded)

---@class git-worktree.Config
---@field hooks? git-worktree.Hooks

---@class git-worktree.Hooks
---@field on_switch? fun(old: git-worktree.Worktree, new: git-worktree.Worktree)
---@field on_create? fun(worktree: git-worktree.Worktree)
---@field on_delete? fun(worktree: git-worktree.Worktree)
```

---

## Documentation Requirements

- [ ] README.md with installation, usage, configuration
- [ ] Vimdoc (doc/git-worktree.txt) for `:help git-worktree`
- [ ] Type annotations for LSP hover documentation

---

## Open Questions

None — all questions resolved.

---

## Appendix

### Glossary

- **Worktree:** A linked working directory associated with a git repository, allowing multiple branches to be checked out simultaneously.
- **Bare repo:** A git repository without a working directory, commonly used as a central hub for worktrees.
- **Repoint buffers:** Update buffer file paths from old worktree to new worktree while preserving buffer state.

### References

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Snacks.nvim](https://github.com/folke/snacks.nvim)
- [ThePrimeagen/git-worktree.nvim](https://github.com/ThePrimeagen/git-worktree.nvim) (prior art)
