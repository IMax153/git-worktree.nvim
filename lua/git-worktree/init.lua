---@class GitWorktree
local M = {}

local config = require('git-worktree.config')

---Setup function (optional - plugin works without it)
---@param opts? GitWorktreeConfig
function M.setup(opts)
  config.setup(opts)
end

return M
