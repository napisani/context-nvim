local NamedContext = require("context_nvim.named_context")
local Utils = require("context_nvim.utils")

describe("NamedContext", function()
  local context
  local mock_utils

  before_each(function()
    context = NamedContext.new(3) -- Setting target_size to 3 for testing purposes

    -- Mocking Utils functions
    mock_utils = {
      get_current_buffer_name = function()
        return "buffer_name"
      end,
      get_current_selection = function()
        return "content", "selection_type"
      end,
      get_current_buffer_info = function()
        return "filetype", "filename", "ext", true
      end,
      get_file_info = function(filepath)
        return "filetype", filepath, "ext", true
      end,
      get_file_paths_from_qflist = function()
        return { "file1", "file2" }
      end,
      get_files_in_dir = function(_dir, _opts)
        return { "file1", "file2", "file3" }
      end,
    }

    Utils.get_current_buffer_name = mock_utils.get_current_buffer_name
    Utils.get_current_selection = mock_utils.get_current_selection
    Utils.get_current_buffer_info = mock_utils.get_current_buffer_info
    Utils.get_file_info = mock_utils.get_file_info
    Utils.get_file_paths_from_qflist = mock_utils.get_file_paths_from_qflist
    Utils.get_files_in_dir = mock_utils.get_files_in_dir
  end)

  it("should save and retrieve named context", function()
    local entry = { content = "sample content" }
    context.save_named_context("test", entry)
    local saved_entry = context.get_named_context("test")
    assert.are.same(entry, saved_entry)
  end)

  it("should save and name context using buffer name", function()
    local entry = { content = "sample content" }
    context.save_and_name_context(entry)
    local saved_entry = context.get_named_context("buffer_name")
    assert.are.same(entry, saved_entry)
  end)

  it("should add context by filepath", function()
    context.add_by_filepath("test_file")
    local saved_entry = context.get_named_context("test_file")
    assert.are.same("test_file", saved_entry.name)
  end)

  it("should add context for current buffer", function()
    context.add_context()
    local saved_entry = context.get_named_context("buffer_name")
    assert.are.same("buffer_name", saved_entry.name)
  end)

  it("should delete named context", function()
    local entry = { content = "sample content" }
    context.save_named_context("test", entry)
    context.delete_named_context("test")
    local saved_entry = context.get_named_context("test")
    assert.is_nil(saved_entry)
  end)

  it("should clear all named contexts", function()
    local entry = { content = "sample content" }
    context.save_named_context("test1", entry)
    context.save_named_context("test2", entry)
    context.clear_named_context()
    assert.are.same({}, context.get_all_named_contexts())
  end)

  it("should add all files from quickfix list", function()
    context.add_all_from_qflist()
    local saved_entry1 = context.get_named_context("file1")
    local saved_entry2 = context.get_named_context("file2")
    assert.are.same("file1", saved_entry1.name)
    assert.are.same("file2", saved_entry2.name)
  end)

  it("should not exceed max size", function()
    context.set_target_size(2)
    context.save_named_context("1", { content = "1" })
    context.save_named_context("2", { content = "2" })
    context.save_named_context("3", { content = "3" })
    local all_contexts = context.get_all_named_contexts()
    assert.are.equal(1, #all_contexts)
    assert.is_nil(context.get_named_context("1"))
  end)
end)
