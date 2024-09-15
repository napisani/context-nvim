local M = {}

function M.entry_to_md(entry)
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

function M.get_current_selection()
  local mode = vim.fn.mode()
  mode = mode:lower():sub(-#"v")
  local content
  local selection_type
  if mode == "v" then
    selection_type = "visual_selection"
    local start_line, start_col = unpack(vim.fn.getpos("'<"))
    local end_line, end_col = unpack(vim.fn.getpos("'>"))
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    content = table.concat(lines, "\n")
  else
    selection_type = "file_path"
    content = nil
  end
  return content, selection_type
end

function M.get_current_buffer_name()
  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  return bufname
end

function M.get_current_buffer_info()
  local buf = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(buf)
  local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
  local filename = vim.fn.expand("%")
  local ext = vim.fn.expand("%:e")
  local is_file = vim.fn.filereadable(bufname) == 1
  return filetype, filename, ext, is_file
end

function M.get_file_info(filepath)
  local filetype = vim.filetype.match({ filename = filepath })
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local ext = vim.fn.fnamemodify(filepath, ":e")
  local is_file = vim.fn.filereadable(filepath) == 1
  return filetype, filename, ext, is_file
end

return M
