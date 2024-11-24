local context_nvim = require("context_nvim")
local Config = require("context_nvim.config")
local utils = require("context_nvim.utils")
local cmp = require("cmp")

local max_preview_len = 10
local source = {
  manual_keyword = "@manual_context",
  history_keyword = "@history_context",
  prompt_keyword = "@prompt",
}

function source:set_manual_keyword(keyword)
  source.manual_keyword = keyword
end

function source:set_history_keyword(keyword)
  source.history_keyword = keyword
end

function source:set_prompt_keyword(keyword)
  source.prompt_keyword = keyword
end

---Return whether this source is available in the current context or not (optional).
---@return boolean
function source:is_available()
  return true
end

---Return the debug name of this source (optional).
---@return string
function source:get_debug_name()
  return "context_nvim"
end

---Return LSP's PositionEncodingKind.
---@NOTE: If this method is omitted, the default value will be `utf-16`.
---@return lsp.PositionEncodingKind
function source:get_position_encoding_kind()
  return "utf-16"
end

---Return the keyword pattern for triggering completion (optional).
---If this is omitted, nvim-cmp will use a default keyword pattern. See |cmp-config.completion.keyword_pattern|.
---@return string
function source:get_keyword_pattern()
  return [[@\w*]]
end

---Return trigger characters for triggering completion (optional).
function source:get_trigger_characters()
  return { "@" }
end

local function build_context_completion_item(for_history)
  local context_items = for_history and context_nvim.history_context.get_all_named_contexts()
    or context_nvim.manual_context.get_all_named_contexts()
  if #context_items == 0 then
    return nil
  end

  local preview = {}
  for i, context in ipairs(context_items) do
    if i > max_preview_len then
      break
    end
    table.insert(preview, context.name)
  end
  local remaining = #context_items - max_preview_len
  if remaining > 0 then
    table.insert(preview, string.format("and %d more...", remaining))
  end
  local joined_preview = table.concat(preview, "\n")

  return {
    label = for_history and source.history_keyword or source.manual_keyword,
    word = "",
    index = _,
    documentation = joined_preview,
    kind = cmp.lsp.CompletionItemKind.Text,
  }
end

local function build_prompt_completion_items()
  local prompts = Config.config.prompts
  if #prompts == 0 then
    return nil
  end

  local prompt_items = {}
  for _, prompt in ipairs(prompts) do
    local prompt_item = {
      label = source.prompt_keyword .. (prompt.cmp or prompt.name),
      word = "",
      index = _,
      documentation = prompt.prompt,
      kind = cmp.lsp.CompletionItemKind.Text,
    }
    table.insert(prompt_items, prompt_item)
  end
  return prompt_items
end

---Invoke completion (required).
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
function source:complete(_params, callback)
  local completion_items = {}
  local manual_context_completion_item = build_context_completion_item(false)
  if manual_context_completion_item then
    table.insert(completion_items, manual_context_completion_item)
  end

  local history_context_completion_item = build_context_completion_item(true)
  if history_context_completion_item then
    table.insert(completion_items, history_context_completion_item)
  end

  local prompt_completion_items = build_prompt_completion_items()
  if prompt_completion_items then
    for _, prompt_item in ipairs(prompt_completion_items) do
      table.insert(completion_items, prompt_item)
    end
  end

  callback(completion_items)
end

---Resolve completion item (optional). This is called right before the completion is about to be displayed.
---Useful for setting the text shown in the documentation window (`completion_item.documentation`).
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:resolve(completion_item, callback)
  callback(completion_item)
end

---Executed after the item was selected.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:execute(completion_item, callback)
  local md_lines = {}
  local context_items = nil
  if completion_item.label == source.manual_keyword then
    context_items = context_nvim.manual_context.get_all_named_contexts()
  elseif completion_item.label == source.history_keyword then
    context_items = context_nvim.history_context.get_all_named_contexts()
  end

  -- it wasn't a history or manual context, so it must be a prompt
  if context_items == nil then
    for _, prompt in ipairs(Config.config.prompts) do
      if completion_item.label == source.prompt_keyword .. (prompt.cmp or prompt.name) then
        context_items = prompt.context
        -- insert the prompt without converting it to markdown, then return
        vim.api.nvim_put({ prompt.prompt }, "", false, true)
        callback(completion_item)
        return
      end
    end
  end

  if context_items then
    for _, context in ipairs(context_items) do
      local lines = utils.entry_to_md(context)
      for _, line in ipairs(lines) do
        table.insert(md_lines, line)
      end
    end
  end

  vim.api.nvim_put(md_lines, "l", true, true)
  callback(completion_item)
end

return source
