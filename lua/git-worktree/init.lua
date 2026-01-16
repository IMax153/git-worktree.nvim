---@class GitWorktree
local M = {}

local config = require('git-worktree.config')
local worktree = require('git-worktree.worktree')

---Setup function (optional - plugin works without it)
---@param opts? GitWorktreeConfig
function M.setup(opts)
  config.setup(opts)
end

---List all worktrees in the repository
---@return Worktree[]?, string? worktrees, error
function M.list()
  return worktree.list()
end

---Create a new worktree
---@param opts CreateWorktreeOpts Options for creating the worktree
---@param callback? fun(worktree: Worktree?, error: string?) Async callback
---@return Worktree?, string? worktree, error (only in sync mode when no callback)
function M.create(opts, callback)
  return worktree.create(opts, callback)
end

return M
