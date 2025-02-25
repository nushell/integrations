#!/usr/bin/env nu
# Author: hustcer
# Created: 2025/02/25 19:05:20
# Description: Script to run after installing Nushell.

const PLUGIN_PATH = '/usr/libexec/nushell'

# Register the plugins after installation
def 'setup-plugins' [] {
  let plugin_config_dir = $nu.plugin-path | path dirname
  # This directory must exist before registering plugins
  if not ($plugin_config_dir | path exists) { mkdir $plugin_config_dir }
  const NU_PLUGINS = [
    nu_plugin_inc
    nu_plugin_query
    nu_plugin_gstat
    nu_plugin_polars
    nu_plugin_formats
  ]
  for p in $NU_PLUGINS {
    plugin add $'($PLUGIN_PATH)/($p)'
  }
}

def main [] {
  setup-plugins
}
