local scan = require("plenary.scandir")
local Config = require("context_nvim.config")
local M = {}

function table_contains(tbl, element)
  for _, value in ipairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end
function M.entry_to_md(entry)
  local lines = {}
  table.insert(lines, "```" .. entry.filetype)
  table.insert(lines, entry.filename)
  if entry.selection_type == "file_path" and entry.name ~= nil then
    local f = io.open(entry.name, "r")
    if f ~= nil then
      for line in f:lines() do
        table.insert(lines, line)
      end
      f:close()
    end
  else
    lines = M.split_by_newline(entry.content or "")
  end
  table.insert(lines, "```")
  return lines
end

function M.split_by_newline(s)
  local lines = {}
  for line in s:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

function M.get_current_lsp_diagnostic()
  local ignore_sources = Config.config.lsp.ignore_sources
  local diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
  local lines = {}
  for _, diagnostic in ipairs(diagnostics) do
    if not table_contains(ignore_sources, diagnostic.source) then
      table.insert(lines, "lsp diagnostic source: " .. diagnostic.source .. ": ")
      table.insert(lines, diagnostic.message)
      local range = diagnostic.range
      local start_line = range.start.line
      local end_line = range["end"].line
      local buffer_content = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
      table.insert(lines, "related code: ")
      for _, line in ipairs(buffer_content) do
        table.insert(lines, line)
      end
    end
  end
  return table.concat(lines, "\n") or ""
end

function M.get_current_selection(opts)
  opts = opts or {}
  local mode = vim.fn.mode()
  mode = mode:lower():sub(-#"v")
  local content
  local selection_type
  if mode == "v" then
    selection_type = "visual_selection"
    local start_line, _start_col = unpack(vim.fn.getpos("'<"))
    local end_line, _end_col = unpack(vim.fn.getpos("'>"))
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    content = table.concat(lines, "\n")
  elseif opts.range ~= 0 and opts.range ~= nil then
    selection_type = "visual_selection"
    local start_line = opts.line1
    local end_line = opts.line2
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
  local line_number = vim.api.nvim_win_get_cursor(0)[1]
  return filetype, filename, ext, is_file, line_number
end

function M.get_file_info(filepath)
  local filetype = vim.filetype.match({ filename = filepath })
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local ext = vim.fn.fnamemodify(filepath, ":e")
  local is_file = vim.fn.filereadable(filepath) == 1
  return filetype, filename, ext, is_file
end

function M.get_file_paths_from_qflist()
  local qf_list = vim.fn.getqflist()
  local file_paths = {}

  for _, entry in ipairs(qf_list) do
    local bufnr = entry.bufnr
    if bufnr > 0 then
      local file_path = vim.api.nvim_buf_get_name(bufnr)
      if file_path and file_path ~= "" and not file_paths[file_path] then
        file_paths[file_path] = true
      end
    end
  end

  local paths = {}
  for k, _ in pairs(file_paths) do
    table.insert(paths, k)
  end
  return paths
end

function M.get_files_in_dir(dir, opts)
  opts = opts or {}
  local files = {}
  scan.scan_dir(dir, {
    hidden = opts.hidden,
    respect_gitignore = opts.respect_gitignore,
    on_insert = function(entry)
      table.insert(files, entry)
    end,
  })
  return files
end

-- reverse ipairs
function M.ripairs(t)
  return function(t, i)
    i = i - 1
    if i ~= 0 then
      return i, t[i]
    end
  end, t, #t + 1
end

return M
