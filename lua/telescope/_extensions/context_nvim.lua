local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")
local make_entry = require("telescope.make_entry")
local logger = require("plenary.log")
local context_nvim = require("context_nvim")
local putils = require("telescope.previewers.utils")

local result = {
  "I am the 1th entry",
  "I am the 2nd entry",
  "I am the 3rd entry",
}

local custom_previewer = previewers.new_buffer_previewer({
  title = "Custom Previewer",
  get_buffer_by_name = function(_, entry)
    return entry.value
  end,

  define_preview = function(self, entry, status)
    vim.notify(vim.inspect(entry))
    if entry.is_file then
      -- the entry is already persisted as a file, show the
      -- file-based preview
      conf.buffer_previewer_maker(entry.filename, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
      })
    else
      -- the entry is not a file, show the content as preview,
      -- using the contents of the entry
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.contents, "\\n"))
    end

    putils.regex_highlighter(self.state.bufnr, entry.filetype)
  end,
})

local context_picker = function(opts)
  opts = opts or {}

  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

  local make_finder = function()
    return finders.new_table({
      results = context_nvim.history_context.get_all_named_contexts(),
      entry_maker = function(r)
        return {
          value = r.name,
          display = r.name,
          ordinal = r.name,
          is_file = r.is_file,
          filetype = r.filetype,
          filename = r.filename,
        }
      end,
    })
  end
  pickers
    .new(opts, {
      prompt_title = "AI Contexts",

      previewer = custom_previewer,
      -- previewer = previewers.new_buffer_previewer({
      --   title = "Named Contexts",
      --   define_preview = function(self, entry, status)
      --     -- vim.notify(vim.inspect(entry))
      --     local lines = vim.split(entry["value"], "\n")
      --     vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, lines)
      --     utils.highlighter(self.state.bufnr, "markdown")
      --   end,
      -- }),
      finder = make_finder(),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        map("n", "dd", function()
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection ~= nil then
            -- context_nvim.delete_named_context(selection.display)
            context_nvim.history_context.delete_by_name(selection.display)
            current_picker:refresh(make_finder(), { reset_prompt = false })
          end
        end)
        return true
      end,
    })
    :find()
end

local simple_picker = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "select a entry",
      finder = finders.new_table({
        results = result,
        entry_maker = function(entry)
          return {
            value = entry,
            -- NOTE: display is show as entry in telescope main window
            display = entry,
            -- NOTE: ordinal is used to match user input, sort the result
            ordinal = entry,
            -- NOTE: other keys can be added
          }
        end,
      }),
      -- NOTE: use default picker
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- NOTE: do something with selected item here
        -- this function change default select action
        -- by default it will open a new buffer with a name same as the value field
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          logger.info(selection)
        end)
        return true
      end,
      -- NOTE: previewer open a new window holding a buffer
      -- showing the detail of entry to user
      previewer = previewers.new_buffer_previewer({
        title = "awesome telescope previewer",
        define_preview = function(self, entry, status)
          print(vim.inspect(entry))
          local lines = vim.split(entry["value"], "\n")
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, lines)
          utils.highlighter(self.state.bufnr, "markdown")
        end,
      }),
    })
    :find()
end

-- uncommon this line, and source this file to test the picker
-- simple_picker()

local command_result_picker = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      prompt_title = "select a entry",
      finder = finders.new_oneshot_job({
        -- NOTE: command to execute
        "fd",
        ".",
        "/usr/bin",
      }, {
        entry_maker = function(entry)
          -- NOTE: entry is command stdout, split by line
          -- pitfall here is that you won't be able to get all lines at once
          -- you should not rely on the **whole** output of the command
          logger.info(entry) -- this is useful when developing and debugging your plugin
          return {
            value = entry,
            display = entry,
            ordinal = entry,
          }
        end,
      }),

      -- NOTE: use default picker
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- NOTE: do something with selected item here
        -- this function change default select action
        -- by default it will open a new buffer with a name same as the value field
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          -- here we simple log the result
          logger.info(selection)
        end)
        return true
      end,
      previewer = previewers.new_buffer_previewer({
        title = "awesome telescope previewer",
        define_preview = function(self, entry, status)
          print(vim.inspect(entry))
          local lines = vim.split(entry["value"], "\n")
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, lines)
          utils.highlighter(self.state.bufnr, "markdown")
        end,
      }),
    })
    :find()
end

-- uncommon this line and source this file in nvim to test
-- command_result_picker()

-- NOTE: this file should return things like this to be loaded by telescope
return require("telescope").register_extension({
  setup = function(ext_config, config) end,
  exports = {
    -- NOTE: name it the same as plugin name, so it can be access without pain
    -- this is always a picker you want to export
    -- :Telescope your_extension
    ["context_nvim"] = context_picker,
    -- NOTE: this picker can be call with
    -- :Telescope your_extension subcommand
    -- ["subcommand"] = command_result_picker,
    -- you can also export other things, such as sorters or previewers ...
  },
})
