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

# Atomic images may have /root -> /var/roothome without the target directory.
# Create the target first: mkdir -p cannot traverse a dangling symlink.
if [ -L "$HOME" ] && [ ! -e "$HOME" ]; then
	home_target=$HOME
	link_count=0
	while [ -L "$home_target" ]; do
		if [ "$link_count" -ge 40 ]; then
			printf 'Cannot resolve HOME: too many symbolic links: %s\n' "$HOME" >&2
			exit 1
		fi
		link_target=$(readlink "$home_target")
		case "$link_target" in
			/*) home_target=$link_target ;;
			*) home_target=$(dirname "$home_target")/$link_target ;;
		esac
		link_count=$((link_count + 1))
	done
	(
		umask 077
		mkdir -p "$home_target"
	)
fi

# Running nu in the rpm-ostree script environment fails if the config directory
# doesn't exist, preventing the post-install.nu script from being run.
if [ -z "${XDG_CONFIG_HOME:-}" ]; then
	export XDG_CONFIG_HOME="$HOME/.config"
fi
mkdir -p "$XDG_CONFIG_HOME"

nu /usr/libexec/nushell/post-install.nu
