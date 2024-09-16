local actions = require("telescope.actions")
local context_nvim = require("context_nvim")
local action_state = require("telescope.actions.state")
local scan = require("plenary.scandir")
local os_sep = package.config:sub(1, 1)
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local make_entry = require("telescope.make_entry")
local action_set = require("telescope.actions.set")

local add_dir_picker = function(opts)
  opts = vim.tbl_extend("force", {
    hidden = false,
    respect_gitignore = true,
  }, opts or {})
  local data = {}
  scan.scan_dir(context_nvim.config.root_dir, {
    hidden = opts.hidden,
    only_dirs = true,
    respect_gitignore = opts.respect_gitignore,
    on_insert = function(entry)
      table.insert(data, vim.fs.joinpath(entry, os_sep))
    end,
  })
  table.insert(data, 1, vim.fs.joinpath(".", os_sep))

  pickers
    .new(opts, {
      prompt_title = "Add directory to context",
      finder = finders.new_table({ results = data, entry_maker = make_entry.gen_from_file(opts) }),
      previewer = conf.file_previewer(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        action_set.select:replace(function()
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          local dirs = {}
          local selections = current_picker:get_multi_selection()
          if vim.tbl_isempty(selections) then
            table.insert(dirs, action_state.get_selected_entry().value)
          else
            for _, selection in ipairs(selections) do
              table.insert(dirs, selection.value)
            end
          end
          actions._close(prompt_bufnr, current_picker.initial_mode == "insert")
          for _, dir in ipairs(dirs) do
            context_nvim.manual_context.add_all_files_in_dir(dir, opts)
          end
        end)
        return true
      end,
    })
    :find()
end

return add_dir_picker
