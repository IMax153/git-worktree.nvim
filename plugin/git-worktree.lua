-- Register the :Worktree command
vim.api.nvim_create_user_command('Worktree', function(opts)
  local args = vim.split(opts.args, '%s+', { trimempty = true })
  local subcommand = args[1]

  if subcommand == 'list' then
    local worktrees = require('git-worktree').list()
    if not worktrees or #worktrees == 0 then
      vim.notify('No worktrees found', vim.log.levels.WARN)
      return
    end

    local lines = {}
    for _, wt in ipairs(worktrees) do
      local prefix = wt.is_current and '* ' or '  '
      local branch = wt.branch or '(detached HEAD)'
      table.insert(lines, string.format('%s%-30s %s', prefix, branch, wt.path))
    end

    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  elseif subcommand == 'create' then
    local branch = args[2]
    local path = args[3]

    if branch then
      -- Branch provided: create immediately or prompt for path
      local ok, result = require('git-worktree').create({
        branch = branch,
        path = path,
      })
      if not ok then
        vim.notify('Failed to create worktree: ' .. (result or 'unknown error'), vim.log.levels.ERROR)
      end
    else
      -- No args: prompt for branch first
      vim.ui.input({ prompt = 'Branch name: ' }, function(input_branch)
        if not input_branch or input_branch == '' then
          return
        end
        -- Then create (will prompt for path if needed)
        local ok, result = require('git-worktree').create({
          branch = input_branch,
        })
        if not ok then
          vim.notify('Failed to create worktree: ' .. (result or 'unknown error'), vim.log.levels.ERROR)
        end
      end)
    end
  elseif subcommand == 'switch' then
    local path = args[2]

    if not path then
      vim.notify(':Worktree switch requires a path argument', vim.log.levels.ERROR)
      return
    end

    local ok, err = require('git-worktree').switch(path)
    if not ok then
      vim.notify('Failed to switch worktree: ' .. (err or 'unknown error'), vim.log.levels.ERROR)
    end
  elseif subcommand == 'delete' then
    local path = args[2]

    if not path then
      vim.notify(':Worktree delete requires a path argument', vim.log.levels.ERROR)
      return
    end

    local force = false
    for i = 3, #args do
      if args[i] == '--force' or args[i] == '-f' then
        force = true
        break
      end
    end

    local ok, err = require('git-worktree').delete(path, { force = force })
    if not ok then
      local msg = 'Failed to delete worktree: ' .. (err or 'unknown error')
      -- Check if error mentions dirty/modified files
      if err and err:match('modified') or err and err:match('dirty') then
        msg = msg .. '\nUse --force to delete anyway'
      end
      vim.notify(msg, vim.log.levels.ERROR)
    end
  elseif subcommand == 'pick' then
    require('git-worktree.snacks').worktrees()
  else
    vim.notify('Unknown subcommand: ' .. (subcommand or '(none)'), vim.log.levels.ERROR)
  end
end, {
  nargs = '*',
  desc = 'Manage git worktrees',
  complete = function(arg_lead, cmd_line, _)
    local args = vim.split(cmd_line, '%s+', { trimempty = true })
    
    -- Remove 'Worktree' from args
    if args[1] == 'Worktree' then
      table.remove(args, 1)
    end

    -- If we're completing the first argument (subcommand)
    if #args == 0 or (#args == 1 and cmd_line:match('%s$') == nil) then
      local subcommands = { 'list', 'create', 'switch', 'delete', 'pick' }
      local matches = {}
      for _, subcmd in ipairs(subcommands) do
        if vim.startswith(subcmd, arg_lead) then
          table.insert(matches, subcmd)
        end
      end
      return matches
    end

    -- If we're completing arguments for switch/delete subcommands
    local subcommand = args[1]
    if subcommand == 'switch' or subcommand == 'delete' then
      local ok, worktrees = pcall(require('git-worktree').list)
      if not ok or not worktrees then
        return {}
      end

      local matches = {}
      for _, wt in ipairs(worktrees) do
        if vim.startswith(wt.path, arg_lead) then
          table.insert(matches, wt.path)
        end
      end
      return matches
    end

    return {}
  end,
})
