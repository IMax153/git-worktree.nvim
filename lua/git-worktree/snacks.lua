---Snacks.nvim picker integration
local M = {}

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
  local git = require("git-worktree.git")

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
  }, opts)

  snacks.picker.pick(picker_opts)
end

return M
