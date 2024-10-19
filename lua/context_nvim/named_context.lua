local Utils = require("context_nvim.utils")

-- NamedContext class
local NamedContext = {}

function NamedContext.new(target_size)
  local self = {}

  local named_contexts = {}
  local max_size = target_size or math.huge -- If target_size is not provided, use infinity
  local names = {}

  function self.set_target_size(s)
    max_size = s
  end

  function self.save_named_context(name, entry)
    named_contexts[name] = entry
    table.insert(names, name)
    if #names >= max_size then
      local oldest_name = table.remove(names, 1)
      named_contexts[oldest_name] = nil
    end

    return entry
  end

  function self.save_and_name_context(entry)
    local name = entry.name
    return self.save_named_context(name, entry)
  end

  function self.add_by_filepath(filename)
    local entry = self.create_context_for_filepath(filename)
    entry.name = filename
    self.save_named_context(filename, entry)
  end

  function self.add_context(only_if_file)
    local entry = self.create_context_for_current_buffer()

    if only_if_file and not entry.is_file then
      return
    end

    self.save_and_name_context(entry)
  end

  function self.create_context_for_lsp_line_diagnostics()
    local name = Utils.get_current_buffer_name()
    local selection_type = "visual_selection"
    local content = Utils.get_current_lsp_diagnostic()
    local filetype, filename, ext, is_file, line_num = Utils.get_current_buffer_info()
    if content == "" then
      return nil
    end
    local entry = {
      name = "lsp,line:" .. tostring(line_num) .. ":" .. name,
      content = content,
      selection_type = selection_type,
      filetype = filetype,
      filename = filename,
      ext = ext,
      is_file = is_file,
    }
    return entry
  end

  function self.add_context_for_lsp_line_diagnostics()
    local entry = self.create_context_for_lsp_line_diagnostics()
    if entry ~= nil then
      self.save_and_name_context(entry)
    end
  end

  function self.create_context_for_current_buffer(opts)
    local name = Utils.get_current_buffer_name()
    local content, selection_type = Utils.get_current_selection(opts)
    local filetype, filename, ext, is_file, _line_num = Utils.get_current_buffer_info()
    local entry = {
      name = name,
      content = content,
      selection_type = selection_type,
      filetype = filetype,
      filename = filename,
      ext = ext,
      is_file = is_file,
    }
    return entry
  end

  function self.create_context_for_filepath(filepath)
    local filetype, filename, ext, is_file = Utils.get_file_info(filepath)
    local entry = {
      name = filename,
      content = nil,
      selection_type = "file_path",
      filetype = filetype,
      filename = filename,
      ext = ext,
      is_file = is_file,
    }
    return entry
  end

  function self.delete_named_context(name)
    named_contexts[name] = nil
    for idx, n in ipairs(names) do
      if n == name then
        table.remove(names, idx)
        return
      end
    end
  end

  function self.add_current(opts)
    local entry = self.create_context_for_current_buffer(opts)
    self.save_and_name_context(entry)
  end

  function self.clear_named_context()
    named_contexts = {}
    names = {}
  end

  function self.get_named_context(name)
    return named_contexts[name]
  end

  function self.get_all_named_contexts()
    local results = {}
    for k, v in pairs(named_contexts) do
      table.insert(results, v)
    end
    return results
  end

  function self.add_all_from_qflist()
    local paths = Utils.get_file_paths_from_qflist()
    for _, path in ipairs(paths) do
      self.add_by_filepath(path)
    end
  end

  function self.add_all_files_in_dir(dir, opts)
    opts = opts or {}
    local files = Utils.get_files_in_dir(dir, opts)
    for _, file in ipairs(files) do
      self.add_by_filepath(file)
    end
  end

  return self
end

return NamedContext
