---Worktree parsing and management module
local M = {}

local git = require('git-worktree.git')

---Parse git worktree list --porcelain output into Worktree objects
---@param porcelain string Output from git worktree list --porcelain
---@return Worktree[]
function M.parse(porcelain)
  local worktrees = {}
  local current = {}
  local cwd = vim.fn.getcwd()
  
  for line in porcelain:gmatch("[^\r\n]+") do
    if line:match("^worktree ") then
      -- Start of a new worktree entry
      if next(current) ~= nil then
        -- Finalize previous entry
        table.insert(worktrees, M._finalize_worktree(current, cwd))
      end
      current = { path = line:match("^worktree (.+)") }
    elseif line:match("^HEAD ") then
      current.head = line:match("^HEAD (%x+)")
    elseif line:match("^branch ") then
      local branch_ref = line:match("^branch (.+)")
      -- Extract branch name from refs/heads/branch-name
      current.branch = branch_ref:match("refs/heads/(.+)") or branch_ref
    elseif line:match("^detached") then
      current.is_detached = true
    elseif line:match("^bare") then
      current.is_bare = true
    elseif line:match("^locked") then
      current.is_locked = true
    elseif line:match("^prunable") then
      current.is_prunable = true
    end
  end
  
  -- Finalize last entry
  if next(current) ~= nil then
    table.insert(worktrees, M._finalize_worktree(current, cwd))
  end
  
  return worktrees
end

---Finalize a worktree entry by setting default fields
---@param wt table Partial worktree data
---@param cwd string Current working directory
---@return Worktree
function M._finalize_worktree(wt, cwd)
  -- Resolve paths to handle symlinks
  local wt_path = vim.fn.resolve(wt.path)
  local resolved_cwd = vim.fn.resolve(cwd)
  
  return {
    path = wt.path,
    head = wt.head or "",
    branch = wt.branch,
    is_bare = wt.is_bare or false,
    is_current = wt_path == resolved_cwd,
    is_locked = wt.is_locked or false,
    is_prunable = wt.is_prunable or false,
    is_detached = wt.is_detached or false,
  }
end

---List all worktrees in the current repository
---@return Worktree[]?, string? worktrees, error
function M.list()
  local stdout, err = git.worktree_list()
  if err then
    return nil, err
  end
  
  local worktrees = M.parse(stdout)
  return worktrees, nil
end

return M
