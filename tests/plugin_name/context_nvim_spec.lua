local M = require("context_nvim.module")

describe("context_nvim module", function()
  it("should save and retrieve named context", function()
    local context_name = "test_context"
    local entry = {
      name = context_name,
      content = "sample content",
      selection_type = "file_path",
      filetype = "lua",
      filename = "test.lua",
      ext = "lua",
    }
    M.delete_named_context(context_name) -- ensure it's deleted if it exists
    local saved_entry = M.save_named_context(context_name, entry)
    assert.are.same(saved_entry, entry)
    local retrieved_entry = M.get_named_context(context_name)
    assert.are.same(retrieved_entry, entry)
  end)

  it("should delete a named context", function()
    local context_name = "delete_test"
    local entry = {
      name = context_name,
      content = "delete this content",
      selection_type = "file_path",
      filetype = "lua",
      filename = "delete_test.lua",
      ext = "lua",
    }
    M.delete_named_context(context_name) -- ensure it's deleted if it exists
    local saved_entry = M.save_named_context(context_name, entry)
    assert.are.same(saved_entry, entry)
    M.delete_named_context(context_name)
    local retrieved_entry = M.get_named_context(context_name)
    assert.is_nil(retrieved_entry)
  end)

  it("should convert entry to markdown format", function()
    local entry = {
      filetype = "lua",
      filename = "test.lua",
      selection_type = "visual_selection",
      content = "print('hello world')",
    }
    local md_lines = M.entry_to_md(entry)
    assert.are.same(md_lines, {
      "```lua",
      "test.lua",
      "print('hello world')",
      "```",
    })
  end)

  it("should clear all named contexts", function()
    local context1 = {
      name = "context1",
      content = "content1",
      selection_type = "file_path",
      filetype = "lua",
      filename = "context1.lua",
      ext = "lua",
    }
    local context2 = {
      name = "context2",
      content = "content2",
      selection_type = "file_path",
      filetype = "lua",
      filename = "context2.lua",
      ext = "lua",
    }
    M.delete_named_context(context1.name)
    M.delete_named_context(context2.name)
    M.save_named_context(context1.name, context1)
    M.save_named_context(context2.name, context2)
    M.clear_named_context()
    local all_contexts = M.get_all_named_contexts()
    assert.are.equal(#all_contexts, 0)
  end)

  it("should get all named contexts", function()
    local context1 = {
      name = "context1",
      content = "content1",
      selection_type = "file_path",
      filetype = "lua",
      filename = "context1.lua",
      ext = "lua",
    }
    local context2 = {
      name = "context2",
      content = "content2",
      selection_type = "file_path",
      filetype = "lua",
      filename = "context2.lua",
      ext = "lua",
    }
    M.delete_named_context(context1.name)
    M.delete_named_context(context2.name)
    M.name_context() -- save context1
    M.name_context() -- save context2
    local all_contexts = M.get_all_named_contexts()
    assert.are.equal(#all_contexts, 2)
  end)
end)
