local M = {}

---@class GitWorktreeHooks
---@field on_switch? fun(old: Worktree, new: Worktree)
---@field on_create? fun(worktree: Worktree)
---@field on_delete? fun(worktree: Worktree)

---@class GitWorktreeConfig
---@field hooks? GitWorktreeHooks

---@type GitWorktreeConfig
local defaults = {
  hooks = {},
}

---@type GitWorktreeConfig
M.options = vim.deepcopy(defaults)

---@param opts? GitWorktreeConfig
function M.setup(opts)
  opts = opts or {}
  
  vim.validate({
    hooks = { opts.hooks, 'table', true },
  })
  
  if opts.hooks then
    vim.validate({
      on_switch = { opts.hooks.on_switch, 'function', true },
      on_create = { opts.hooks.on_create, 'function', true },
      on_delete = { opts.hooks.on_delete, 'function', true },
    })
  end
  
  M.options = vim.tbl_deep_extend('force', defaults, opts)
end

return M
