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

return M
