---Buffer management for worktree switching
local M = {}

---Save all modified buffers
function M.save_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    -- Only save loaded buffers that are modifiable and modified
    if vim.api.nvim_buf_is_loaded(bufnr) 
       and vim.api.nvim_get_option_value('modifiable', { buf = bufnr })
       and vim.api.nvim_get_option_value('modified', { buf = bufnr }) then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd('silent! write')
      end)
    end
  end
end

---Update buffer paths from old worktree root to new worktree root
---@param old_root string Path to the old worktree root
---@param new_root string Path to the new worktree root
function M.repoint(old_root, new_root)
  -- Canonicalize paths to handle symlinks
  local resolved_old = vim.fn.resolve(old_root)
  local resolved_new = vim.fn.resolve(new_root)
  
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      
      -- Skip empty bufnames (scratch buffers)
      if bufname == '' then
        goto continue
      end
      
      -- Get buffer type - skip special buffers
      local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
      if buftype ~= '' then
        -- Skip terminals, quickfix, help, etc.
        goto continue
      end
      
      -- Resolve the buffer path to handle symlinks
      local resolved_bufname = vim.fn.resolve(bufname)
      
      -- Check if buffer is within old worktree
      if vim.startswith(resolved_bufname, resolved_old) then
        -- Calculate relative path from old root
        local relative = resolved_bufname:sub(#resolved_old + 2) -- +2 to skip leading slash
        
        -- Construct new absolute path
        local new_path = resolved_new .. '/' .. relative
        
        -- Check if file exists in new worktree
        if vim.fn.filereadable(new_path) == 1 then
          -- Update buffer name to new path
          vim.api.nvim_buf_set_name(bufnr, new_path)
          
          -- Reload the buffer content
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd('silent! edit!')
          end)
        else
          -- File doesn't exist in new worktree - close buffer with notification
          vim.notify(
            string.format("File no longer exists in new worktree: %s", relative),
            vim.log.levels.INFO
          )
          
          -- Delete the buffer
          vim.api.nvim_buf_delete(bufnr, { force = true })
        end
      end
      
      ::continue::
    end
  end
end

return M
