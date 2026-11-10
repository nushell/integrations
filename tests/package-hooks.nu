#!/usr/bin/env nu
# Run with: nu --no-config-file tests/package-hooks.nu --image ubuntu:24.04
# Only disposable container files are writable; source scripts are read-only.
# cspell:words esac mktemp roothome

const SCRIPTS_DIR = path self ../scripts

def main [--image: string = 'ubuntu:24.04', --scripts-dir: path = $SCRIPTS_DIR] {
  let fixture_code = r##'
set -eu
scenario="$1"
hook="$2"
fixture=$(mktemp -d)
mkdir "$fixture/bin"
printf '#!/bin/sh\nprintf "%%s\\n" "$HOME" "$XDG_CONFIG_HOME" "$1" > "$XDG_CONFIG_HOME/invocation"\n' > "$fixture/bin/nu"
chmod +x "$fixture/bin/nu"
export PATH="$fixture/bin:/usr/bin:/bin"
export HOME=/root
unset XDG_CONFIG_HOME
mv /root "$fixture/original-root"
expected_failure=false
repair=false
case "$scenario" in
  normal) mkdir /root; chmod 750 /root ;;
  atomic-absolute|atomic-explicit-default) ln -s /var/roothome /root; repair=true ;;
  atomic-relative) ln -s var/roothome /root; repair=true ;;
  atomic-xdg|atomic-new-xdg) ln -s /var/roothome /root ;;
  custom-home|custom-home-xdg) export HOME="$fixture/home"; ln -s "$fixture/custom-target" "$HOME" ;;
  readonly-home-xdg) export HOME="$fixture/home"; ln -s /proc/nushell-missing-home "$HOME" ;;
  other-root|other-root-xdg) ln -s "$fixture/custom-target" /root ;;
  chained-root) ln -s "$fixture/next" /root; ln -s /var/roothome "$fixture/next" ;;
  linked-target|linked-target-xdg) ln -s /var/roothome /root; ln -s "$fixture/custom-target" /var/roothome ;;
  cycle-xdg) ln -s root /root ;;
  linked-var) mv /var "$fixture/original-var"; ln -s "$fixture/original-var" /var; ln -s /var/roothome /root ;;
  empty-env) export HOME=; export XDG_CONFIG_HOME=; cd "$fixture" ;;
  unset-env) unset HOME; cd "$fixture" ;;
esac
case "$scenario" in
  atomic-explicit-default) export XDG_CONFIG_HOME=/root/.config ;;
  *-xdg) export XDG_CONFIG_HOME="$fixture/config"; mkdir "$XDG_CONFIG_HOME" ;;
esac
case "$scenario" in
  atomic-new-xdg) export XDG_CONFIG_HOME="$fixture/new-config" ;;
  custom-home|other-root|chained-root|linked-target|linked-var) expected_failure=true ;;
esac
if /bin/sh "/scripts/$hook.sh" > "$fixture/stdout" 2> "$fixture/stderr"; then
  status=0
else
  status=$?
fi
if "$expected_failure"; then
  [ "$status" -ne 0 ]
else
  if [ "$status" -ne 0 ]; then cat "$fixture/stderr" >&2; exit 1; fi
  case "$scenario" in
    empty-env|unset-env) expected_home="$fixture" ;;
    *) expected_home="$HOME" ;;
  esac
  expected_config="${XDG_CONFIG_HOME:-$expected_home/.config}"
  printf '%s\n' "$expected_home" "$expected_config" "/usr/libexec/nushell/$hook.nu" > "$fixture/expected"
  cmp "$fixture/expected" "$expected_config/invocation"
fi
if "$repair"; then
  [ -L /root ]
  [ "$(stat -c %a /var/roothome)" = 700 ]
else
  [ ! -e /var/roothome ]
  [ ! -e "$fixture/custom-target" ]
fi
if [ "$scenario" = normal ]; then [ "$(stat -c %a /root)" = 750 ]; fi
if [ "$scenario" = linked-target ] || [ "$scenario" = linked-target-xdg ]; then
  [ -L /var/roothome ]
fi
'##
  let scenarios = [
    normal atomic-absolute atomic-relative atomic-explicit-default
    atomic-xdg atomic-new-xdg custom-home custom-home-xdg readonly-home-xdg
    other-root other-root-xdg chained-root linked-target linked-target-xdg
    cycle-xdg linked-var empty-env unset-env
  ]
  for scenario in $scenarios {
    for hook in [post-install pre-remove] {
      let result = (
        ^docker run --rm --network none --user 0
          --volume $'($scripts_dir | path expand):/scripts:ro'
          $image /bin/sh -c $fixture_code fixture $scenario $hook
        | complete
      )
      if $result.exit_code != 0 {
        error make {msg: $'($scenario) / ($hook): ($result.stderr | str trim)'}
      }
    }
  }
  let case_count = ($scenarios | length) * 2
  print $'Passed ($case_count) package hook checks on ($image)'
}
