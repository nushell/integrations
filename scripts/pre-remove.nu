#!/usr/bin/env nu
# Author: hustcer
# Created: 2025/03/10 08:25:20
# Description: Script to run before removing Nushell.

# Remove /usr/bin/nu from /etc/shells
def 'remove-nu-from-shells' [] {
  let new_content = open /etc/shells
    | lines
    | where $it !~ '/usr/bin/nu'
    | str join "\n"
  # Keep a new line at the end of file to prevent other packages from making mistake
  # when modifying this file.
  $new_content ++ "\n" | save -rf /etc/shells
}

def main [] {
  remove-nu-from-shells
}
