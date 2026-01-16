---Health check for git-worktree.nvim
local M = {}

---Check function for :checkhealth git-worktree
function M.check()
  vim.health.start("git-worktree.nvim")

  -- Check Neovim version >= 0.11
  local nvim_version = vim.version()
  if nvim_version.major > 0 or (nvim_version.major == 0 and nvim_version.minor >= 11) then
    vim.health.ok(string.format("Neovim version %d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch))
  else
    vim.health.error(
      string.format(
        "Neovim version %d.%d.%d is too old. Requires >= 0.11",
        nvim_version.major,
        nvim_version.minor,
        nvim_version.patch
      )
    )
  end

  -- Check git executable exists
  if vim.fn.executable("git") == 1 then
    local git_version = vim.fn.system("git --version"):gsub("[\n\r]+", "")
    vim.health.ok(git_version)
  else
    vim.health.error("git not found in PATH")
  end

  -- Check current directory is a git repository
  local git = require("git-worktree.git")
  local git_root, err = git.get_git_root()
  if git_root then
    vim.health.ok("In git repository: " .. git_root)
  else
    vim.health.warn("Not in a git repository: " .. (err or "unknown error"))
  end

  -- Check Snacks.nvim availability (optional dependency)
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.picker then
    vim.health.ok("Snacks.nvim picker available")
  else
    vim.health.info("Snacks.nvim not installed (optional - enables :Worktree pick)")
  end
end

return M
