local NamedContext = require("context_nvim.named_context")
local logger = require("plenary.log")

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
    manual_context_keyword = "@manual_context",
    history_keyword = "@history_context",
  },

  telescope = {
    enable = true,
  },
  logger = {
    level = "error",
  },
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
        M.history_context.add_context(only_if_file)
      end,
    })
  end
end

---@type Config
M.config = config

local function build_context_nvim_command(subcommands)
  local context_nvim_command = function(opts)
    local args = opts.fargs

    if #args == 0 then
      print("Usage: ContextNvim <subcommand> [args...]")
      print("Subcommands: " .. table.concat(subcommands, ", "))
      return
    end

    local subcommand = args[1]
    -- Remove the subcommand from args
    table.remove(args, 1)

    if subcommand == "add_current_file" then
      local path = vim.api.nvim_buf_get_name(0)
      M.manual_context.add_by_filepath(path)
    elseif subcommand == "add_qflist" then
      M.manual_context.add_all_from_qflist()
    elseif subcommand == "add_dir" then
      require("telescope").extensions.context_nvim.add_dir()
    elseif subcommand == "add_file" then
      require("telescope").extensions.context_nvim.add_file()
    elseif subcommand == "find_context_history" then
      require("telescope").extensions.context_nvim.find_context_history()
    elseif subcommand == "find_context_manual" then
      require("telescope").extensions.context_nvim.find_context_manual()
    else
      print("Unknown subcommand: " .. subcommand)
      print("Subcommands: " .. table.concat(subcommands, ", "))
    end
  end
  return context_nvim_command
end

M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
  M.logger = logger.new({
    plugin = "context_nvim",
    level = M.config.logger.level,
  })

  init_history(M.config.history_length)
  register_history_autocmd(
    M.config.history_pattern,
    M.config.history_for_files_only,
    M.config.history_length,
    M.config.enable_history
  )

  if M.config.cmp.enable then
    local status_ok, cmp = pcall(require, "cmp")
    if not status_ok then
      vim.notify("'cmp' not found")
    end
    local source = require("context_nvim.cmp_source")
    source:set_manual_keyword(M.config.cmp.manual_context_keyword)
    source:set_history_keyword(M.config.cmp.history_keyword)
    cmp.register_source("context_nvim", source)
  end

  if M.config.telescope.enable then
    local status_ok, telescope = pcall(require, "telescope")
    if not status_ok then
      vim.notify("'telescope' not found")
    end
    telescope.load_extension("context_nvim")
  end

  local subcommands = { "add_current_file", "add_qflist" }

  if M.config.telescope.enable then
    table.insert(subcommands, "add_dir")
    table.insert(subcommands, "add_file")
    table.insert(subcommands, "find_context_history")
    table.insert(subcommands, "find_context_manual")
  end

  vim.api.nvim_create_user_command("ContextNvim", build_context_nvim_command(subcommands), {
    nargs = "+", -- Requires at least one argument (the subcommand)
    complete = function(ArgLead, CmdLine, CursorPos)
      -- Basic completion for subcommands

      return vim.tbl_filter(function(cmd)
        return cmd:match("^" .. ArgLead)
      end, subcommands)
    end,
    desc = "ContextNvim - manage files that provide context",
  })
end

M.utils = require("context_nvim.utils")

return M
