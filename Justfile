# Author: hustcer
# Created: 2025/03/21 19:15:20
# Description:
#   Some helper task for making Nushell packages for various Linux distributions.
# Ref:
#   1. https://github.com/casey/just
#   2. https://www.nushell.sh/book/

set shell := ['nu', '-c']

# The export setting causes all just variables
# to be exported as environment variables.

set export := true
set dotenv-load := true

# If positional-arguments is true, recipe arguments will be
# passed as positional arguments to commands. For linewise
# recipes, argument $0 will be the name of the recipe.

set positional-arguments := true

# Use `just --evaluate` to show env vars

# Used to handle the path separator issue
NU_DISTRO_PATH := parent_directory(justfile())
NU_DIR := parent_directory(`(which nu).path.0`)
_query_plugin := if os_family() == 'windows' { 'nu_plugin_query.exe' } else { 'nu_plugin_query' }

# To pass arguments to a dependency, put the dependency
# in parentheses along with the arguments, just like:
# default: (sh-cmd "main")

# List available commands by default
default:
  @just --list --list-prefix "··· "

# Bump Nushell version for supported Linux distributions
bump *OPTIONS:
  @overlay use {{ join(NU_DISTRO_PATH, 'nu', 'bump-ver.nu') }}; \
    bump-version {{OPTIONS}}

# Release a new version for Nushell
release *OPTIONS:
  @overlay use {{ join(NU_DISTRO_PATH, 'nu', 'release.nu') }}; \
    fetch release {{OPTIONS}}; publish pkg {{OPTIONS}}

# Plugins need to be registered only once after nu v0.61
_setup:
  @register -e json {{ join(NU_DIR, _query_plugin) }}
