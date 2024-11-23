local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Config = require("context_nvim.config")

local prompt_picker = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "Select a prompt",
      finder = finders.new_table({
        results = Config.config.prompts,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      }),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          vim.api.nvim_put({ selection.value.prompt }, "", false, true)
        end)
        return true
      end,
    })
    :find()
end

return prompt_picker
