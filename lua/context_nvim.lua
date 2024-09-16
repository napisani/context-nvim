local NamedContext = require("context_nvim.named_context")

---@class Config
---@field opt string Your config option
local config = {
  enable_history = true,
  history_length = 10,
  history_for_files_only = true,
  history_pattern = "*",
  root_dir = ".",
}

---@class ContextNvim
local M = {
  history_context = NamedContext.new(),
  manual_context = NamedContext.new(),
}

local init_history = function(target_size)
  M.history_context.set_target_size(target_size)
end

local register_history_autocmd = function(pattern, only_if_file, target_size, enable_history)
  if target_size > 0 and enable_history then
    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = pattern or "*",
      callback = function()
        -- vim.notify("Adding context")
        M.history_context.add_context(only_if_file)
      end,
    })
  end
end

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  init_history(M.config.history_length)
  register_history_autocmd(
    M.config.history_pattern,
    M.config.history_for_files_only,
    M.config.history_length,
    M.config.enable_history
  )
end

M.utils = require("context_nvim.utils")

return M
