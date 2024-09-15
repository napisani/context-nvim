local get_context_picker = require("telescope._extensions.context_nvim.context_picker")
local add_file_picker = require("telescope._extensions.context_nvim.add_file_picker")

-- NOTE: this file should return things like this to be loaded by telescope
return require("telescope").register_extension({
  setup = function(ext_config, config) end,
  exports = {
    -- NOTE: name it the same as plugin name, so it can be access without pain
    -- this is always a picker you want to export
    -- :Telescope your_extension
    ["context_nvim"] = get_context_picker("manual_context"),

    -- NOTE: this picker can be call with
    -- :Telescope context_nvim find_context
    ["find_context_history"] = get_context_picker("history_context"),
    ["find_context_manual"] = get_context_picker("manual_context"),

    -- NOTE: this picker can be call with
    -- :Telescope context_nvim add_file
    ["add_file"] = add_file_picker,

    -- you can also export other things, such as sorters or previewers ...
  },
})
