#!/bin/sh
# Author: hustcer
# Created: 2025/03/10 08:35:20
# cspell:words ostree roothome

set -e

# Even with XDG_CONFIG_HOME, nu fails without a HOME variable set and UID
# without a user account.
# See https://github.com/nushell/nushell/issues/18902
if [ -z "${HOME:-}" ]; then
	export HOME="${PWD:-/}"
fi

# Running nu in the rpm-ostree script environment requires a config directory.
if [ -z "${XDG_CONFIG_HOME:-}" ]; then
	export XDG_CONFIG_HOME="$HOME/.config"
fi

# Repair only the standard Atomic root home when using its default config path.
# An explicit config path elsewhere must not require creating HOME.
if [ "$HOME" = /root ] && [ "$XDG_CONFIG_HOME" = /root/.config ] &&
	[ -L /root ] && [ ! -e /root ] && [ ! -L /var ] &&
	[ ! -e /var/roothome ] && [ ! -L /var/roothome ]; then
	case "$(readlink /root)" in
		/var/roothome|var/roothome)
			mkdir -m 0700 /var/roothome
			;;
	esac
fi
mkdir -p "$XDG_CONFIG_HOME"

nu /usr/libexec/nushell/pre-remove.nu
