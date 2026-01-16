---Worktree parsing and management module
local M = {}

local git = require("git-worktree.git")

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

---Create a new worktree
---@param opts CreateWorktreeOpts Options for creating the worktree
---@param callback? fun(worktree: Worktree?, error: string?) Async callback
---@return Worktree?, string? worktree, error (only in sync mode when no callback)
function M.create(opts, callback)
  -- Validate required fields
  if not opts or not opts.branch then
    local err = "branch is required"
    if callback then
      callback(nil, err)
      return
    end
    return nil, err
  end

  -- Determine path (prompt if not provided)
  if not opts.path then
    local git_root, root_err = git.get_git_root()
    if root_err then
      if callback then
        callback(nil, root_err)
        return
      end
      return nil, root_err
    end

    local default_path = vim.fn.fnamemodify(git_root, ":h") .. "/" .. opts.branch

    vim.ui.input({
      prompt = "Worktree path: ",
      default = default_path,
    }, function(input_path)
      if not input_path or input_path == "" then
        if callback then
          callback(nil, "path is required")
        end
        return
      end

      -- Continue with the provided path
      local new_opts = vim.tbl_extend("force", opts, { path = input_path })
      M._create_worktree(new_opts, callback)
    end)

    -- Async mode - callback will be called
    if callback then
      return
    end

    -- Sync mode not supported when prompting
    return nil, "path must be provided in synchronous mode"
  end

  -- Path provided - create directly
  return M._create_worktree(opts, callback)
end

---Internal function to create worktree after path is determined
---@param opts CreateWorktreeOpts
---@param callback? fun(worktree: Worktree?, error: string?)
---@return Worktree?, string?
function M._create_worktree(opts, callback)
  local config = require("git-worktree.config")

  -- Create the worktree
  local success, err = git.worktree_add(opts.path, opts.branch, {
    create_branch = opts.create_branch or false,
  })

  if not success then
    if callback then
      callback(nil, err)
      return
    end
    return nil, err
  end

  -- Get the created worktree object
  local worktrees, list_err = M.list()
  if list_err then
    if callback then
      callback(nil, list_err)
      return
    end
    return nil, list_err
  end

  -- Find the newly created worktree (resolve paths to handle symlinks)
  local resolved_path = vim.fn.resolve(opts.path)
  local created_worktree = nil
  for _, wt in ipairs(worktrees) do
    if vim.fn.resolve(wt.path) == resolved_path then
      created_worktree = wt
      break
    end
  end

  if not created_worktree then
    local not_found_err = "Failed to find created worktree"
    if callback then
      callback(nil, not_found_err)
      return
    end
    return nil, not_found_err
  end

  -- Call on_create hook if configured
  if config.options.hooks and config.options.hooks.on_create then
    config.options.hooks.on_create(created_worktree)
  end

  -- Switch to new worktree if requested (default: true)
  if opts.switch ~= false then
    -- Try to get switch function (may not exist yet in early development)
    local ok, main = pcall(require, "git-worktree")
    if ok and main.switch then
      local switch_success, switch_err = main.switch(created_worktree.path)
      if not switch_success then
        -- Still return the created worktree, but note the switch error
        vim.notify("Worktree created but failed to switch: " .. (switch_err or "unknown error"), vim.log.levels.WARN)
      end
    end
  end

  if callback then
    callback(created_worktree, nil)
    return
  end
  return created_worktree, nil
end

---Switch to a different worktree
---@param path string Path to the target worktree
---@return boolean, string? success, error
function M.switch(path)
  local config = require("git-worktree.config")
  local buffer = require("git-worktree.buffer")

  -- Validate that path is a valid worktree
  local worktrees, list_err = M.list()
  if list_err then
    return false, list_err
  end

  -- Resolve target path to handle symlinks
  local resolved_target = vim.fn.resolve(path)

  local target_worktree = nil
  local current_worktree = nil

  for _, wt in ipairs(worktrees) do
    local resolved_wt_path = vim.fn.resolve(wt.path)
    if resolved_wt_path == resolved_target then
      target_worktree = wt
    end
    if wt.is_current then
      current_worktree = wt
    end
  end

  if not target_worktree then
    return false, "Path is not a valid worktree: " .. path
  end

  -- Already in target worktree
  if target_worktree.is_current then
    return true, nil
  end

  -- Save current worktree reference for hook
  if not current_worktree then
    return false, "Could not determine current worktree"
  end

  -- Auto-save all modified buffers
  buffer.save_all()

  -- Change directory to target worktree
  local ok, chdir_err = pcall(vim.fn.chdir, target_worktree.path)
  if not ok then
    return false, "Failed to change directory: " .. tostring(chdir_err)
  end

  -- Repoint buffers to new worktree paths
  buffer.repoint(current_worktree.path, target_worktree.path)

  -- Restart LSP clients
  -- Get all active LSP clients
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    -- Stop each client
    client.stop()
  end

  -- LSP clients will auto-restart when buffers are accessed

  -- Emit autocmd event
  vim.api.nvim_exec_autocmds("User", {
    pattern = "GitWorktreeSwitched",
    data = {
      old = current_worktree,
      new = target_worktree,
    },
  })

  -- Call on_switch hook
  if config.options.hooks and config.options.hooks.on_switch then
    config.options.hooks.on_switch(current_worktree, target_worktree)
  end

  return true, nil
end

---Delete a worktree
---@param path string Path to the worktree to delete
---@param opts? DeleteWorktreeOpts Options
---@return boolean?, string? success, error
function M.delete(path, opts)
  local config = require("git-worktree.config")

  opts = opts or {}

  -- Get all worktrees to validate
  local worktrees, list_err = M.list()
  if list_err then
    return nil, list_err
  end

  -- Resolve target path to handle symlinks
  local resolved_target = vim.fn.resolve(path)

  local target_worktree = nil

  for _, wt in ipairs(worktrees) do
    local resolved_wt_path = vim.fn.resolve(wt.path)
    if resolved_wt_path == resolved_target then
      target_worktree = wt
      break
    end
  end

  if not target_worktree then
    return nil, "Path is not a valid worktree: " .. path
  end

  -- Prevent deleting current worktree
  if target_worktree.is_current then
    return nil, "Cannot delete current worktree. Switch to another worktree first."
  end

  -- Prevent deleting main worktree (bare repo)
  if target_worktree.is_bare then
    return nil, "Cannot delete main (bare) worktree"
  end

  -- Remove the worktree
  local success, err = git.worktree_remove(path, {
    force = opts.force or false,
  })

  if not success then
    return nil, err
  end

  -- Call on_delete hook if configured
  if config.options.hooks and config.options.hooks.on_delete then
    config.options.hooks.on_delete(target_worktree)
  end

  return true, nil
end

return M
