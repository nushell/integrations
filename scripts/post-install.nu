#!/usr/bin/env nu
# Author: hustcer
# Created: 2025/02/25 19:05:20
# Description: Script to run after installing Nushell.

const PLUGIN_PATH = '/usr/libexec/nushell'

# Register the plugins after installation
def 'setup-plugins' [] {

  let plugin_config_dir = $nu.plugin-path | path dirname
  # This directory must exist before registering plugins
  if not ($plugin_config_dir | path exists) {
    mkdir $plugin_config_dir
    config reset -w
  }

  const NU_PLUGINS = [
    nu_plugin_inc
    nu_plugin_query
    nu_plugin_gstat
    nu_plugin_polars
    nu_plugin_formats
  ]
  print $'Nushell plugins were installed to (ansi g)($PLUGIN_PATH)(ansi reset)'
  print $'(ansi g)Registering plugins...(ansi reset)'
  for p in $NU_PLUGINS {
    plugin add $'($PLUGIN_PATH)/($p)'
  }
  # plugin list | select name version filename | print
}

# Add /usr/bin/nu to /etc/shells if it's not already there
def 'add-shells' [] {
  let shells = open /etc/shells
  if not ($shells =~ $'/usr/bin/nu') {
    echo '/usr/bin/nu' o>> /etc/shells
  }
}

def main [] {
  setup-plugins
  add-shells
}
