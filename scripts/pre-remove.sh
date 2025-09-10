#!/bin/sh
# Author: hustcer
# Created: 2025/03/10 08:35:20

set -e

# Running nu in the rpm-ostree script environment fails if the config directory
# doesn't exist, preventing the pre-remove.nu script from being run.
if [ -n "${XDG_CONFIG_HOME+x}" ]; then
	mkdir -p "$XDG_CONFIG_HOME"
elif [ -n "${HOME+x}" ]; then
	mkdir -p "$HOME/.config"
else
	export XDG_CONFIG_HOME="$PWD/.config"
	mkdir -p "$XDG_CONFIG_HOME"
fi

nu /usr/libexec/nushell/pre-remove.nu
