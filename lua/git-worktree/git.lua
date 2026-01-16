---Git command wrapper module
local M = {}

---Execute git command and return result
---@param args string[] Command arguments
---@param opts? table Options for vim.system
---@return vim.SystemCompleted
local function exec(args, opts)
  opts = opts or {}
  local cmd = vim.list_extend({ "git" }, args)
  local result = vim.system(cmd, opts):wait()
  return result
end

---List all worktrees
---Runs `git worktree list --porcelain`
---@return string?, string? stdout, error
function M.worktree_list()
  local result = exec({ "worktree", "list", "--porcelain" })
  if result.code ~= 0 then
    return nil, result.stderr or "Failed to list worktrees"
  end
  return result.stdout, nil
end

---Add a new worktree
---@param path string Path for the new worktree
---@param branch string Branch to checkout
---@param opts? { create_branch?: boolean } Options
---@return boolean, string? success, error
function M.worktree_add(path, branch, opts)
  opts = opts or {}
  local args = { "worktree", "add" }
  
  if opts.create_branch then
    table.insert(args, "-b")
    table.insert(args, branch)
    table.insert(args, path)
  else
    table.insert(args, path)
    table.insert(args, branch)
  end
  
  local result = exec(args)
  if result.code ~= 0 then
    return false, result.stderr or "Failed to add worktree"
  end
  return true, nil
end

---Remove a worktree
---@param path string Path to the worktree to remove
---@param opts? { force?: boolean } Options
---@return boolean, string? success, error
function M.worktree_remove(path, opts)
  opts = opts or {}
  local args = { "worktree", "remove" }
  
  if opts.force then
    table.insert(args, "--force")
  end
  
  table.insert(args, path)
  
  local result = exec(args)
  if result.code ~= 0 then
    return false, result.stderr or "Failed to remove worktree"
  end
  return true, nil
end

---Check if a worktree has uncommitted changes
---@param path string Path to the worktree
---@return boolean is_dirty
function M.is_dirty(path)
  local result = exec({ "-C", path, "status", "--porcelain" })
  if result.code ~= 0 then
    return false
  end
  return result.stdout ~= nil and result.stdout ~= ""
end

---Get the git repository root
---@return string?, string? path, error
function M.get_git_root()
  local result = exec({ "rev-parse", "--show-toplevel" })
  if result.code ~= 0 then
    return nil, result.stderr or "Not in a git repository"
  end
  -- Trim trailing newline
  local path = result.stdout:gsub("%s+$", "")
  return path, nil
end

return M
