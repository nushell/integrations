#!/bin/sh
# Author: hustcer
# Created: 2025/02/25 18:55:20

set -e

# Even with XDG_CONFIG_HOME, nu fails without a HOME variable set and UID
# without a user account.
# See https://github.com/nushell/nushell/issues/18902
if [ -z "${HOME:-}" ]; then
	export HOME="${PWD:-/}"
fi

# Running nu in the rpm-ostree script environment fails if the config directory
# doesn't exist, preventing the post-install.nu script from being run.
if [ -z "${XDG_CONFIG_HOME:-}" ]; then
	export XDG_CONFIG_HOME="$HOME/.config"
fi
mkdir -p "$XDG_CONFIG_HOME"

nu /usr/libexec/nushell/post-install.nu
