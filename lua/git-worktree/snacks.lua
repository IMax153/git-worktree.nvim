---Snacks.nvim picker integration and standalone worktree actions
local M = {}

local git = require("git-worktree.git")
local worktree_mod = require("git-worktree.worktree")

---Prompt for branch name and path, then create worktree
---@param callback? fun(wt: Worktree?, err: string?) Called after creation
local function prompt_create_worktree(callback)
  -- First prompt: branch name
  vim.ui.input({ prompt = "Branch name: " }, function(branch)
    if not branch or branch == "" then
      return
    end

    -- Get git root for default path
    local git_root, root_err = git.get_git_root()
    if root_err then
      vim.notify("Failed to get git root: " .. root_err, vim.log.levels.ERROR)
      return
    end

    local default_path = vim.fn.fnamemodify(git_root, ":h") .. "/" .. branch

    -- Second prompt: path
    vim.ui.input({ prompt = "Worktree path: ", default = default_path }, function(path)
      if not path or path == "" then
        return
      end

      -- Create worktree with callback
      worktree_mod.create({ branch = branch, path = path, create_branch = true }, function(wt, err)
        if err then
          vim.notify("Failed to create worktree: " .. err, vim.log.levels.ERROR)
          if callback then
            callback(nil, err)
          end
          return
        end

        if wt then
          vim.notify("Created worktree: " .. wt.path, vim.log.levels.INFO)
        end

        if callback then
          callback(wt, nil)
        end
      end)
    end)
  end)
end

---Create worktree action for Snacks picker
---Prompts for branch name, then path, creates worktree and switches to it
---@param picker snacks.Picker
local function create_worktree_action(picker)
  prompt_create_worktree(function()
    -- Close picker after successful creation (switch happens automatically)
    picker:close()
  end)
end

---Prompt for worktree selection and delete it
---@param callback? fun(success: boolean, err: string?) Called after deletion
local function prompt_delete_worktree(callback)
  local worktrees, list_err = worktree_mod.list()
  if list_err then
    vim.notify("Failed to list worktrees: " .. list_err, vim.log.levels.ERROR)
    return
  end

  if not worktrees or #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  -- Filter out current worktree and bare repository
  local deletable = vim.tbl_filter(function(wt)
    return not wt.is_current and not wt.is_bare
  end, worktrees)

  if #deletable == 0 then
    vim.notify("No worktrees available to delete", vim.log.levels.WARN)
    return
  end

  vim.ui.select(deletable, {
    prompt = "Select worktree to delete:",
    format_item = function(wt)
      local dirty = git.is_dirty(wt.path) and " [dirty]" or ""
      return string.format("%s (%s)%s", wt.branch or "(detached)", wt.path, dirty)
    end,
  }, function(wt)
    if not wt then
      return
    end

    -- Confirmation prompt local confirm_msg = string.format("Delete worktree at %s?", wt.path)
    vim.ui.select({ "Yes", "No" }, { prompt = confirm_msg }, function(choice)
      if choice ~= "Yes" then
        return
      end

      local success, err = worktree_mod.delete(wt.path)

      if not success then
        vim.notify("Failed to delete worktree: " .. (err or "unknown error"), vim.log.levels.ERROR)
        if callback then
          callback(false, err)
        end
        return
      end

      vim.notify("Deleted worktree: " .. wt.path, vim.log.levels.INFO)
      if callback then
        callback(true, nil)
      end
    end)
  end)
end

---Prompt for worktree selection and switch to it
---@param callback? fun(success: boolean, err: string?) Called after switch
local function prompt_switch_worktree(callback)
  local worktrees, list_err = worktree_mod.list()
  if list_err then
    vim.notify("Failed to list worktrees: " .. list_err, vim.log.levels.ERROR)
    return
  end

  if not worktrees or #worktrees == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  -- Filter out current worktree and bare repository
  local switchable = vim.tbl_filter(function(wt)
    return not wt.is_current and not wt.is_bare
  end, worktrees)

  if #switchable == 0 then
    vim.notify("No other worktrees to switch to", vim.log.levels.WARN)
    return
  end

  vim.ui.select(switchable, {
    prompt = "Select worktree to switch to:",
    format_item = function(wt)
      local dirty = git.is_dirty(wt.path) and " [dirty]" or ""
      return string.format("%s (%s)%s", wt.branch or "(detached)", wt.path, dirty)
    end,
  }, function(wt)
    if not wt then
      return
    end

    local success, err = worktree_mod.switch(wt.path)

    if not success then
      vim.notify("Failed to switch worktree: " .. (err or "unknown error"), vim.log.levels.ERROR)
      if callback then
        callback(false, err)
      end
      return
    end

    if callback then
      callback(true, nil)
    end
  end)
end

---Delete worktree action for Snacks picker
---Confirms deletion and removes the selected worktree
---@param picker snacks.Picker
---@param item snacks.picker.finder.Item
local function delete_worktree_action(picker, item)
  if not item or not item.worktree then
    vim.notify("No worktree selected", vim.log.levels.WARN)
    return
  end

  local wt = item.worktree

  -- Prevent deleting current worktree
  if wt.is_current then
    vim.notify("Cannot delete current worktree. Switch to another worktree first.", vim.log.levels.ERROR)
    return
  end

  -- Confirmation prompt
  local confirm_msg = string.format("Delete worktree at %s?", wt.path)
  vim.ui.select({ "Yes", "No" }, { prompt = confirm_msg }, function(choice)
    if choice ~= "Yes" then
      return
    end

    local success, err = worktree_mod.delete(wt.path)

    if not success then
      vim.notify("Failed to delete worktree: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    vim.notify("Deleted worktree: " .. wt.path, vim.log.levels.INFO)

    -- Refresh the picker
    picker:find()
  end)
end

---Open Snacks picker for worktrees
---@param opts? table Options for the picker
function M.worktrees(opts)
  -- Check if Snacks is available
  local ok, snacks = pcall(require, "snacks")
  if not ok or not snacks.picker then
    vim.notify("Snacks.nvim is not installed or picker module is not available", vim.log.levels.ERROR)
    return
  end

  local worktree = require("git-worktree.worktree")

  opts = opts or {}

  ---@type snacks.picker.finder
  local function finder(_, ctx)
    local worktrees, err = worktree.list()
    if err then
      vim.notify("Failed to list worktrees: " .. err, vim.log.levels.ERROR)
      return {}
    end

    local items = {} ---@type snacks.picker.finder.Item[]
    for _, wt in ipairs(worktrees) do
      -- Check dirty state for each worktree
      local is_dirty = git.is_dirty(wt.path)

      local item = {
        worktree = wt,
        path = wt.path,
        branch = wt.branch or "(detached HEAD)",
        is_current = wt.is_current,
        is_dirty = is_dirty,
        file = wt.path,
      }

      -- Build text for searching/filtering
      item.text = vim.tbl_keys({
        [wt.path] = true,
        [wt.branch or "detached"] = true,
      })

      table.insert(items, item)
    end

    return ctx.filter:filter(items)
  end

  ---@type snacks.picker.Config
  local picker_opts = vim.tbl_deep_extend("force", {
    title = "Git Worktrees",
    prompt = "🌲 ",
    format = "file",
    finder = finder,
    ---@param picker snacks.Picker
    ---@param item snacks.picker.finder.Item
    confirm = function(picker, item)
      picker:close()
      if item and item.worktree then
        local wt = item.worktree
        if not wt.is_current then
          local success, switch_err = worktree.switch(wt.path)
          if not success then
            vim.notify("Failed to switch worktree: " .. (switch_err or "unknown error"), vim.log.levels.ERROR)
          end
        end
      end
    end,
    ---@param item snacks.picker.finder.Item
    ---@return string
    formatters = {
      file = {
        filename_first = true,
      },
    },
    format_item = function(item)
      local indicator = item.is_current and "*" or " "
      local dirty = item.is_dirty and " [dirty]" or ""
      local branch = item.branch or "(detached)"
      return string.format("%s %-30s %s%s", indicator, branch, item.path, dirty)
    end,
    actions = {
      create_worktree = function(picker)
        create_worktree_action(picker)
      end,
      delete_worktree = function(picker, item)
        delete_worktree_action(picker, item)
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-n>"] = "create_worktree",
          ["<c-d>"] = "delete_worktree",
        },
      },
    },
  }, opts)

  snacks.picker.pick(picker_opts)
end

---Create a new worktree interactively
---Prompts for branch name and path using vim.ui.input
---@param callback? fun(wt: Worktree?, err: string?) Called after creation
function M.create_worktree(callback)
  prompt_create_worktree(callback)
end

---Switch to a worktree interactively
---Prompts for worktree selection using vim.ui.select
---@param callback? fun(success: boolean, err: string?) Called after switch
function M.switch_worktree(callback)
  prompt_switch_worktree(callback)
end

---Delete a worktree interactively
---Prompts for worktree selection and confirmation using vim.ui.select
---@param callback? fun(success: boolean, err: string?) Called after deletion
function M.delete_worktree(callback)
  prompt_delete_worktree(callback)
end

return M
