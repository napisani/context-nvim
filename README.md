# context-nvim 

This is a plugin for neovim that helps you contextual code used for AI prompts.
`context-nvim` allows you to manage two types of contexts: 
1. **Manual Contexts**: These are contexts that you manually define and manage. You can add, remove, and edit these contexts with `context-nvim` subcommands.
2. **History Contexts**: These are contexts that are automatically generated by `context-nvim` based on buffers you have opened recently. 


## Features 
* Telescope picker for viewing / deleting manual contexts
* Telescope picker for viewing / deleting history contexts
* subcommands for managing manual contexts 
* `nvim-cmp` source for referencing history-based and manual contexts in your AI prompts 

## Demo
![demo](https://github.com/napisani/context-nvim/blob/main/demo.gif)

## Installation

Using lazy.nvim:
```lua
{
    "napisani/context-nvim",
    config = function()
        require("context_nvim").setup({ })
    end,
},


```
## Using it


## Configuration

```lua
require("context_nvim").setup({ 
  enable_history = true, -- whether to enable history context by tracking opened files/buffers
  history_length = 10, -- how many history items to track
  history_for_files_only = true, -- only use history for files, any non-file buffers will be ignored
  history_pattern = "*", -- history pattern to match files/buffers that will be tracked
  root_dir = ".", -- root directory of the project, used for finding files and constructing paths
  cmp = {
    enable = true, -- whether to enable the nvim-cmp source for referencing contexts

    register_cmp_avante = true, -- whether to include the cmp source for avante input buffers. 
                                -- They need to be registered using an autocmd, so this is a separate config option
    manual_context_keyword = "@manual_context", -- keyword to use for manual context
    history_keyword = "@history_context", -- keyword to use for history context
    prompt_keyword = "@prompt", -- keyword to use for prompt context
  },

  telescope = {
    enable = true, -- whether to enable the telescope picker
  },

  logger = {
    level = "error", -- log level for the plenary logger 
  },

  lsp = {
    ignore_sources = {}, -- lsp sources to ignore when adding line diagnostics to the manual context
  },
  prompts = {
        { 
            name = 'unit tests', -- the name of the prompt (required)
            prompt = 'Generate a suite of unit tests using Jest, respond with only code.', -- the prompt text (required)
            cmp = 'jest' -- an alternate name for the cmp completion source (optional) defaults to 'name'
        },
    }
})
```

# Subcommands

## add_current_file
Adds the current file to the manual context.
```
:ContextNvim add_current_file
```

## add_current
Adds the current visual selection or buffer to the manual context.
```
:ContextNvim add_current
```

## add_qflist
Adds all items from the quickfix list to the manual context.
```
:ContextNvim add_qflist
```

## clear_history
Clears the history context.
```
:ContextNvim clear_history
```

## clear_manual
Clears the manual context.
```
:ContextNvim clear_manual
```

## add_dir
Opens a Telescope picker to select and add a directory to the manual context.
```
:ContextNvim add_dir
```

## add_file
Opens a Telescope picker to select and add a file to the manual context.
```
:ContextNvim add_file
```

## find_context_history
Opens a Telescope picker to view and manage the history context.
```
:ContextNvim find_context_history
```

## find_context_manual
Opens a Telescope picker to view and manage the manual context.
```
:ContextNvim find_context_manual
```

## add_line_lsp_daig
Adds context for LSP line diagnostics to the manual context.
```
:ContextNvim add_line_lsp_daig
```

## insert_prompt     
Brings up a telescope picker, when an entry is selected. The prompt will be inserted into the buffer. 
```
:ContextNvim insert_prompt 
```


## Example workflow
1. Open a file in neovim
2. Perform one or many of the following actions:
    * Add the current file to the manual context
    * Add the current visual selection to the manual context
    * Add the current buffer to the manual context
    * Add the quickfix list to the manual context
    * Add a directory to the manual context
    * Add a file to the manual context
    * Add line diagnostics to the manual context
3. Open `gp.nvim` or another AI prompt plugin that supports chatting with an AI model
4. start to type `@manual_context` (or `@history_context`)
5. Accept the cmp suggestion to insert the manual context into the chat  
6. start typing the `@prompt` and select a prompt you want to insert 
7. submit the AI prompt
8. Profit?
 

