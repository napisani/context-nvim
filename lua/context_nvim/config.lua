local M = {}

---@class Config
---@field opt string Your config option
local config = {
  enable_history = true,
  history_length = 10,
  history_for_files_only = true,
  history_pattern = "*",
  root_dir = ".",
  cmp = {
    enable = true,
    register_cmp_avante = true,
    manual_context_keyword = "@manual_context",
    history_keyword = "@history_context",
    prompt_keyword = "@prompt",
  },

  telescope = {
    enable = true,
  },
  logger = {
    level = "error",
  },

  lsp = {
    ignore_sources = {},
  },

  prompts = {},
}

function M.setup(args)
  M.config = vim.tbl_deep_extend("force", config, args or {})
end
return M
