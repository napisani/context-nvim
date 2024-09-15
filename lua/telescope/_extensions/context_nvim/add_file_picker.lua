local builtin = require("telescope.builtin")
local actions = require("telescope.actions")
local context_nvim = require("context_nvim")
local action_state = require("telescope.actions.state")
function add_file_picker(opts)
  opts = opts or {}
  -- Merge custom attach_mappings with any existing ones
  local custom_attach_mappings = function(prompt_bufnr, map)
    -- -- Keep any existing attachments
    -- if opts.attach_mappings then
    --   opts.attach_mappings(prompt_bufnr, map)
    -- end

    -- Add custom action for adding files to context
    actions.select_default:replace(function()
      local picker = action_state.get_current_picker(prompt_bufnr)
      local selections = picker:get_multi_selection()

      if #selections > 0 then
        -- Add all selected files to context
        for _, selection in ipairs(selections) do
          context_nvim.manual_context.add_by_filepath(selection.path)
        end
      else
        -- Add the single selected file to context
        local selection = action_state.get_selected_entry()
        if selection then
          context_nvim.manual_context.add_by_filepath(selection.path)
        end
      end

      actions.close(prompt_bufnr)
      print("Added file(s) to context")
    end)

    return true
  end

  -- Merge our custom attach_mappings into the opts
  opts.attach_mappings = custom_attach_mappings
  return builtin.find_files(opts)
end
return add_file_picker
