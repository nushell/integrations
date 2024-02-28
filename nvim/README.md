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
