-- main module file
local module = require("context_nvim.module")

---@class Config
---@field opt string Your config option
local config = {
  opt = "Hello!",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.hello = function()
  return module.my_first_function(M.config.opt)
end

for k, v in pairs(module) do
  M[k] = v
end

return M
