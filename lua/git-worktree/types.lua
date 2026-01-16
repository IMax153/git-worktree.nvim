---@meta

---Represents a git worktree
---@class Worktree
---@field path string Absolute path to the worktree
---@field head string SHA-1 of the HEAD commit
---@field branch? string Branch name (nil if detached)
---@field is_bare boolean Whether this is the bare repository
---@field is_current boolean Whether this is the current working directory
---@field is_locked boolean Whether the worktree is locked
---@field is_prunable boolean Whether the worktree can be pruned
---@field is_detached boolean Whether HEAD is detached

---@class CreateWorktreeOpts
---@field branch string Branch name to checkout or create
---@field path? string Path for the worktree (defaults to ../<branch>)
---@field create_branch? boolean Whether to create a new branch
---@field switch? boolean Whether to switch to the new worktree (default: true)

---@class DeleteWorktreeOpts
---@field force? boolean Force deletion even if dirty

---@alias GitWorktreeResult boolean|nil, string?
