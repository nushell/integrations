# neovim config

The idea of the `init.lua` is to show a minimal config for a better integration of nushell with neovim.

You should read it and copy/paste the relevant parts into your own config. 
If you want to quickly test it in isolation you can use the [`$env.NVIM_APPNAME`](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME), here is how:

## Testing the configuration in isolation

- Copy or Symlink this folder to `$XDG_CONFIG_HOME/nvim-nu`:
  - On unix it's usually: `$env.HOME/.config/nvim-nu`
  - On Windows: `$env.LOCALAPPDATA/nvim-nu`

- Run nvim using `NVIM_APPNAME=nvim-nu nvim`. This will run the config in isolation (with an isolated data folder).
- On first run lazy will bootstrap itself and install the required plugins.

## Tips for LSP Setup (Optional)

### Override Default Configuration

You can minimize the configuration autoloaded when the server starts, which may improve performance as complicated Nushell configurations can slow down the language server.

```lua
require("lspconfig").nushell.setup({
  cmd = {
    "nu",
    "--config",
    vim.env.XDG_CONFIG_HOME .. "/nushell/lsp.nu",
    "--lsp",
  },
  flags = { debounce_text_changes = 1000 },
  filetypes = { "nu" },
})
```

Typical things to setup in a minimal lsp.nu:
* Environment variables such as `path`
* External completer
* `NU_LIB_DIRS`, for importing definitions from extra nu libraries outside of the project

### Disable Unwanted Features

For example, to disable inlay hints:

```lua
{
  "neovim/nvim-lspconfig",
  ...
  opts = {
    inlay_hints = {
      enabled = true,
      exclude = { "nu" }, -- to disable inlay hints for nushell
    },
  },
  config = function()
  ...
  end
}
```

### Useful Autocommands

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "nu",
  callback = function(event)
    -- Mapping Ctrl-f to invoke signature help
    vim.api.nvim_buf_set_keymap(event.buf, "i", "<C-f>", "", {
      callback = function()
        vim.lsp.buf.signature_help()
      end,
    })
    -- Popup signature help automatically after selecting commands
    -- from the completion menu, requires blink.cmp
    vim.api.nvim_create_autocmd("User", {
      pattern = "BlinkCmpAccept",
      callback = function(ev)
        local item = ev.data.item
        -- function/method kind
        if item.kind == 3 or item.kind == 2 then
          vim.defer_fn(function()
            vim.lsp.buf.signature_help()
          end, 500)
        end
      end,
    })
  end,
})
```
