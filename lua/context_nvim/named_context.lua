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
    vim.notify(vim.inspect(entry))
    named_contexts[name] = entry
    table.insert(names, name)
    if #names >= max_size then
      local oldest_name = table.remove(names, 1)
      named_contexts[oldest_name] = nil
    end

    return entry
  end

  function self.save_and_name_context(entry)
    local name = Utils.get_current_buffer_name()
    return self.save_named_context(name, entry)
  end

  function self.add_context(only_if_file)
    local entry = self.create_context_for_current_buffer()

    if only_if_file and not entry.is_file then
      return
    end

    self.save_and_name_context(entry)
  end

  function self.create_context_for_current_buffer()
    local name = Utils.get_current_buffer_name()
    local content, selection_type = Utils.get_current_selection()
    local filetype, filename, ext, is_file = Utils.get_current_buffer_info()

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

  function self.delete_named_context(name)
    named_contexts[name] = nil
    for idx, n in ipairs(names) do
      if n == name then
        table.remove(names, idx)
        return
      end
    end
  end

  function self.name_context()
    local name = vim.fn.input("Enter the name of the context: ")
    self.delete_named_context(name)
    local entry = self.create_context_for_current_buffer()
    entry.name = name
    self.save_named_context(name, entry)
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

  return self
end

return NamedContext
