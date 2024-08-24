local M = {}

local named_contexts = {}

M.save_named_context = function(name, entry)
  named_contexts[name] = entry
  return entry
end

M.entry_to_md = function(entry)
  local lines = {}
  table.insert(lines, "```" .. entry.filetype)
  table.insert(lines, entry.filename)
  if entry.selection_type == "file_path" and entry.filename ~= nil then
    local f = io.open(entry.filename, "r")
    if f ~= nil then
      local file_contents = f:read("*all")
      f:close()
      table.insert(lines, file_contents)
    end
  else
    table.insert(lines, entry.content)
  end
  table.insert(lines, "```")
  return lines
end

M.delete_named_context = function(name)
  named_contexts[name] = nil
end

function M.name_context()
  local mode = vim.fn.mode()
  mode = mode:lower():sub(-#"v")
  local content
  local selection_type
  if mode == "v" then
    -- get contents under cursor
    selection_type = "visual_selection"
    local start_line, start_col = unpack(vim.fn.getpos("'<"))
    local end_line, end_col = unpack(vim.fn.getpos("'>"))
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    content = table.concat(lines, "\n")
  else
    -- content = vim.fn.getline(1, "$")
    selection_type = "file_path"
  end
  local buf = vim.api.nvim_get_current_buf()
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  local filename = vim.fn.expand("%")
  local ext = vim.fn.expand("%:e")
  local name = vim.fn.input("Enter the name of the context: ")
  M.delete_named_context(name)

  local entry = {
    name = name,
    content = content,
    selection_type = selection_type,
    filetype = filetype,
    filename = filename,
    ext = ext,
  }
  M.save_named_context(name, entry)
end

function M.clear_named_context()
  for k, v in pairs(named_contexts) do
    M.delete_named_context(k)
  end
  named_contexts = {}
end

function M.get_named_context(name)
  return named_contexts[name]
end

function M.get_all_named_contexts()
  local results = {}
  for k, v in pairs(named_contexts) do
    table.insert(results, v)
  end
  return results
end

return M
