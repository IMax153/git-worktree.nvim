-- Register the :Worktree command
vim.api.nvim_create_user_command('Worktree', function(opts)
  -- Command implementation will be added in cmd-* tasks
  vim.notify('Worktree command: ' .. vim.inspect(opts.args), vim.log.levels.INFO)
end, {
  nargs = '*',
  desc = 'Manage git worktrees',
})
