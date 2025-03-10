local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local make_entry = require("telescope.make_entry")
local context_nvim = require("context_nvim")
local utils = require("context_nvim.utils")
local putils = require("telescope.previewers.utils")
local actions = require("telescope.actions")

local custom_previewer = previewers.new_buffer_previewer({
  title = "Context Preview",
  get_buffer_by_name = function(_, entry)
    return entry.value
  end,

  define_preview = function(self, entry, status)
    if entry.selection_type == "file_path" and entry.is_file then
      -- the entry is already persisted as a file, show the
      -- file-based preview
      conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
      })
    else
      -- the entry is not a file, show the content as preview,
      -- using the contents of the entry
      local lines = context_nvim.utils.split_by_newline(entry.content)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    end

    putils.regex_highlighter(self.state.bufnr, entry.filetype)
  end,
})
function get_context_picker(context_type)
  if context_nvim[context_type] == nil then
    return nil
  end
  local ctx = context_nvim[context_type]
  local context_picker = function(opts)
    opts = opts or {}

    opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

    local make_finder = function()
      return finders.new_table({
        results = ctx.get_all_named_contexts(),
        entry_maker = function(r)
          return {
            value = r.name,
            display = r.name,
            ordinal = r.name,
            is_file = r.is_file,
            filetype = r.filetype,
            selection_type = r.selection_type,
            filename = r.filename,
            content = r.content,
          }
        end,
      })
    end
    pickers
      .new(opts, {
        prompt_title = "AI Contexts",
        previewer = custom_previewer,
        finder = make_finder(),
        sorter = conf.file_sorter(opts),

        attach_mappings = function(prompt_bufnr, map)
          local select_action = function()
            context_nvim.logger.debug("selecting")
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local item = ctx.get_named_context(selection.display)

            local md_lines = {}
            local lines = utils.entry_to_md(item)
            for _, line in ipairs(lines) do
              table.insert(md_lines, line)
            end

            vim.api.nvim_put(md_lines, "l", false, true)
          end

          map("i", "<CR>", select_action)
          map("n", "<CR>", select_action)

          map("n", "dd", function()
            context_nvim.logger.debug("deleting")
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection ~= nil then
              ctx.delete_named_context(selection.display)
              current_picker:refresh(make_finder(), { reset_prompt = false })
            end
          end)
          return true
        end,
      })
      :find()
  end

  return context_picker
end
return get_context_picker
