local context_nvim = require("context_nvim")
local Config = require("context_nvim.config")
local utils = require("context_nvim.utils")

--- @class context_nvim.BlinkSource
local source = {}

local max_preview_len = 10

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = opts or {}
  return self
end

function source:enabled()
  return true
end

function source:get_trigger_characters()
  return { "@" }
end

function source:get_completions(ctx, callback)
  local items = {}
  local edit_range = {
    start = {
      line = ctx.bounds.line_number - 1,
      character = ctx.bounds.start_col - 2,
    },
    ["end"] = {
      line = ctx.bounds.line_number - 1,
      character = ctx.bounds.start_col + ctx.bounds.length,
    },
  }
  -- edit_range = {
  --   start = { line = 0, character = 0 },
  --   ["end"] = { line = 0, character = 0 },
  -- }

  -- Add manual context completion
  local manual_contexts = context_nvim.manual_context.get_all_named_contexts()
  if #manual_contexts > 0 then
    local preview = {}
    for i, context in ipairs(manual_contexts) do
      if i > max_preview_len then
        break
      end
      table.insert(preview, context.name)
    end

    local remaining = #manual_contexts - max_preview_len
    if remaining > 0 then
      table.insert(preview, string.format("and %d more...", remaining))
    end

    local new_text = "manual context"

    table.insert(items, {
      label = Config.config.blink.manual_context_keyword,
      kind = require("blink.cmp.types").CompletionItemKind.Text,
      documentation = {
        kind = "markdown",
        value = table.concat(preview, "\n"),
      },
      textEdit = {
        newText = new_text,
        range = edit_range,
      },
    })
  end

  -- Add history context completion
  local history_contexts = context_nvim.history_context.get_all_named_contexts()
  if #history_contexts > 0 then
    local preview = {}
    for i, context in ipairs(history_contexts) do
      if i > max_preview_len then
        break
      end
      table.insert(preview, context.name)
    end

    local new_text = "history context"
    local remaining = #history_contexts - max_preview_len
    if remaining > 0 then
      table.insert(preview, string.format("and %d more...", remaining))
    end

    table.insert(items, {
      label = Config.config.blink.history_keyword,
      kind = require("blink.cmp.types").CompletionItemKind.Text,
      documentation = {
        kind = "markdown",
        value = table.concat(preview, "\n"),
      },
      textEdit = {
        newText = new_text,
        range = edit_range,
      },
    })
  end

  -- Add prompt completions
  for _, prompt in ipairs(Config.config.prompts) do
    table.insert(items, {
      label = Config.config.blink.prompt_keyword .. (prompt.cmp or prompt.name),
      kind = require("blink.cmp.types").CompletionItemKind.Text,
      documentation = {
        kind = "markdown",
        value = prompt.prompt,
      },
      textEdit = {
        newText = prompt.prompt or "",
        range = edit_range,
      },
    })
  end

  callback({
    items = items,
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  })
end

function source:execute(ctx, item, callback)
  local md_lines = {}
  local context_items = nil

  if item.label == Config.config.blink.manual_context_keyword then
    context_items = context_nvim.manual_context.get_all_named_contexts()
  elseif item.label == Config.config.blink.history_keyword then
    context_items = context_nvim.history_context.get_all_named_contexts()
  end

  if context_items then
    for _, context in ipairs(context_items) do
      local lines = utils.entry_to_md(context)
      for _, line in ipairs(lines) do
        table.insert(md_lines, line)
      end
    end
  end

  vim.api.nvim_put(md_lines, "l", false, true)
  callback()
end

return source
