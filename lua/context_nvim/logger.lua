local logger = require("plenary.log")

local M = {}

M.setup = function()

  M.logger = logger.new({
    plugin = "context_nvim",
    level = M.config.logger.level,
  })
end
return M
