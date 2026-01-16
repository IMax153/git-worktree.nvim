# git-worktree.nvim

Manage git worktrees from Neovim with a simple Lua API and commands.

## Features

- List, create, switch, and delete worktrees
- Automatic buffer repointing when switching
- LSP client restart on worktree switch
- Lifecycle hooks (`on_create`, `on_switch`, `on_delete`)
- Optional [Snacks.nvim](https://github.com/folke/snacks.nvim) picker integration
- Health check via `:checkhealth git-worktree`

## Requirements

- Neovim >= 0.11
- git executable in PATH
- (Optional) [Snacks.nvim](https://github.com/folke/snacks.nvim) for picker integration

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "imax153/git-worktree.nvim",
  opts = {},
  -- Optional: Snacks.nvim for picker integration
  dependencies = {
    { "folke/snacks.nvim", optional = true },
  },
}
```

## Commands

| Command | Description |
|---------|-------------|
| `:Worktree list` | List all worktrees (current marked with `*`) |
| `:Worktree create [branch] [path]` | Create a new worktree |
| `:Worktree switch {path}` | Switch to worktree at path |
| `:Worktree delete {path} [--force]` | Delete worktree (use `--force` for dirty worktrees) |
| `:Worktree pick` | Open Snacks picker (requires Snacks.nvim) |

## Lua API

### `require('git-worktree').list()`

List all worktrees in the repository.

```lua
local worktrees, err = require('git-worktree').list()
if err then
  vim.notify('Error: ' .. err)
  return
end
for _, wt in ipairs(worktrees) do
  print(wt.branch, wt.path)
end
```

**Returns:**
- `Worktree[]` - Array of worktree objects
- `string?` - Error message if failed

**Worktree object fields:**
| Field | Type | Description |
|-------|------|-------------|
| `path` | `string` | Absolute path to worktree |
| `head` | `string` | SHA-1 of HEAD commit |
| `branch` | `string?` | Branch name (nil if detached) |
| `is_bare` | `boolean` | Whether this is the bare repository |
| `is_current` | `boolean` | Whether this is current working directory |
| `is_locked` | `boolean` | Whether worktree is locked |
| `is_prunable` | `boolean` | Whether worktree can be pruned |
| `is_detached` | `boolean` | Whether HEAD is detached |

### `require('git-worktree').create(opts, callback?)`

Create a new worktree.

```lua
-- Synchronous (path required)
local wt, err = require('git-worktree').create({
  branch = 'feature-xyz',
  path = '../feature-xyz',
})

-- Asynchronous (path can be prompted)
require('git-worktree').create({
  branch = 'feature-xyz',
}, function(wt, err)
  if err then
    vim.notify('Error: ' .. err)
  else
    vim.notify('Created: ' .. wt.path)
  end
end)
```

**Parameters:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `branch` | `string` | required | Branch name to checkout or create |
| `path` | `string?` | `../<branch>` | Path for the worktree |
| `create_branch` | `boolean?` | `false` | Create a new branch |
| `switch` | `boolean?` | `true` | Switch to new worktree after creation |

### `require('git-worktree').switch(path)`

Switch to a different worktree. Performs:
1. Saves all modified buffers
2. Changes working directory
3. Repoints buffer file paths to new worktree
4. Restarts LSP clients
5. Fires `GitWorktreeSwitched` autocmd
6. Calls `on_switch` hook if configured

```lua
local ok, err = require('git-worktree').switch('../main')
if not ok then
  vim.notify('Failed: ' .. err)
end
```

### `require('git-worktree').delete(path, opts?)`

Delete a worktree. Cannot delete current worktree.

```lua
local ok, err = require('git-worktree').delete('../feature-xyz')
if not ok then
  vim.notify('Failed: ' .. err)
end

-- Force delete dirty worktree
require('git-worktree').delete('../feature-xyz', { force = true })
```

**Options:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `force` | `boolean?` | `false` | Force deletion even if dirty |

## Configuration

Configuration is optional. The plugin works without calling `setup()`.

```lua
require('git-worktree').setup({
  hooks = {
    on_create = function(worktree)
      -- Called after worktree is created
      vim.notify('Created: ' .. worktree.branch)
    end,
    on_switch = function(old_worktree, new_worktree)
      -- Called after switching worktrees
      vim.notify('Switched from ' .. old_worktree.branch .. ' to ' .. new_worktree.branch)
    end,
    on_delete = function(worktree)
      -- Called after worktree is deleted
      vim.notify('Deleted: ' .. worktree.path)
    end,
  },
})
```

### Hooks

| Hook | Parameters | Description |
|------|------------|-------------|
| `on_create` | `(worktree)` | Called after worktree is created |
| `on_switch` | `(old_worktree, new_worktree)` | Called after switching worktrees |
| `on_delete` | `(worktree)` | Called after worktree is deleted |

## Snacks Integration

The `git-worktree.snacks` module provides interactive functions for worktree operations using `vim.ui.input` and `vim.ui.select`. These work standalone (no Snacks.nvim required for the action functions).

### Snacks Picker

If [Snacks.nvim](https://github.com/folke/snacks.nvim) is installed, use the picker:

```lua
require('git-worktree.snacks').worktrees()
```

The picker displays:
- Current worktree indicator (`*`)
- Branch name
- Worktree path
- Dirty state indicator (`[dirty]`)

**Picker keybindings:**
| Key | Action |
|-----|--------|
| `<CR>` | Switch to selected worktree |
| `<C-n>` | Create new worktree (prompts for branch/path) |
| `<C-d>` | Delete selected worktree (with confirmation) |

### Standalone Actions

These functions use `vim.ui.input`/`vim.ui.select` and do **not** require Snacks.nvim:

```lua
-- Create worktree (prompts for branch, then path)
require('git-worktree.snacks').create_worktree()

-- Switch worktree (shows selection menu)
require('git-worktree.snacks').switch_worktree()

-- Delete worktree (shows selection menu, then confirms)
require('git-worktree.snacks').delete_worktree()
```

All functions accept an optional callback:

```lua
require('git-worktree.snacks').create_worktree(function(wt, err)
  if err then
    print('Error: ' .. err)
  else
    print('Created: ' .. wt.path)
  end
end)
```

## Keymaps

Example keymap configuration with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "imax153/git-worktree.nvim",
  opts = {},
  keys = {
    { "<leader>gw", function() require("git-worktree.snacks").worktrees() end, desc = "Git worktrees (picker)" },
    { "<leader>gwc", function() require("git-worktree.snacks").create_worktree() end, desc = "Create worktree" },
    { "<leader>gws", function() require("git-worktree.snacks").switch_worktree() end, desc = "Switch worktree" },
    { "<leader>gwd", function() require("git-worktree.snacks").delete_worktree() end, desc = "Delete worktree" },
  },
}
```

Or manually:

```lua
vim.keymap.set("n", "<leader>gw", function()
  require("git-worktree.snacks").worktrees()
end, { desc = "Git worktrees (picker)" })

vim.keymap.set("n", "<leader>gwc", function()
  require("git-worktree.snacks").create_worktree()
end, { desc = "Create worktree" })

vim.keymap.set("n", "<leader>gws", function()
  require("git-worktree.snacks").switch_worktree()
end, { desc = "Switch worktree" })

vim.keymap.set("n", "<leader>gwd", function()
  require("git-worktree.snacks").delete_worktree()
end, { desc = "Delete worktree" })
```

## Events

### `GitWorktreeSwitched`

Fired after switching worktrees.

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'GitWorktreeSwitched',
  callback = function(args)
    local old = args.data.old
    local new = args.data.new
    vim.notify('Switched to ' .. new.branch)
  end,
})
```

## Health Check

Verify your environment:

```vim
:checkhealth git-worktree
```

## License

MIT
