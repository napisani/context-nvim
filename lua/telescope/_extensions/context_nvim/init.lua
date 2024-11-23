local get_context_picker = require("telescope._extensions.context_nvim.context_picker")
local add_file_picker = require("telescope._extensions.context_nvim.add_file_picker")
local add_dir_picker = require("telescope._extensions.context_nvim.add_dir_picker")
local prompt_picker = require("telescope._extensions.context_nvim.prompt_picker")

return require("telescope").register_extension({
  setup = function(ext_config, config) end,
  exports = {
    ["context_nvim"] = get_context_picker("manual_context"),
    ["find_context_history"] = get_context_picker("history_context"),
    ["find_context_manual"] = get_context_picker("manual_context"),

    ["add_file"] = add_file_picker,
    ["add_dir"] = add_dir_picker,

    ["prompts"] = prompt_picker,
  },
})
