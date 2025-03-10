#!/usr/bin/env nu
# Author: hustcer
# Created: 2025/03/10 08:25:20
# Description: Script to run before removing Nushell.

# Remove /usr/bin/nu from /etc/shells
def 'remove-shells' [] {
  open /etc/shells
    | lines
    | where $it !~ '/usr/bin/nu'
    | str join "\n"
    | save -rf /etc/shells
}

def main [] {
  remove-shells
}
