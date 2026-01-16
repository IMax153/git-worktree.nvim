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
  else
    vim.notify('Unknown subcommand: ' .. (subcommand or '(none)'), vim.log.levels.ERROR)
  end
end, {
  nargs = '*',
  desc = 'Manage git worktrees',
})
