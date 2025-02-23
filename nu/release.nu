#!/usr/bin/env nu
# Author: hustcer
# Created: 2025/03/21 19:15:20
# Description: Script to release Nushell packages for various Linux distributions.
# Usage:
#   docker run -it --rm -v $"(pwd):/work" --platform linux/amd64 ubuntu:latest
#   fury packages -a nushell
#   fury versions rpm:nushell -a nushell
#   fury versions deb:nushell -a nushell
#   fury yank nushell -v 0.102.0-1 -a nushell
#   fury yank rpm:nushell -v 0.102.0-1 -a nushell
# REF:
#   - https://gemfury.com/guide/cli/
#   - https://gemfury.com/help/gpg-signing/
#   - https://manage.fury.io/dashboard/nushell
#

# Fetch the latest Nushell release package from GitHub
export def 'fetch release' [
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  const ARCH_MAP = {
    'amd64': 'x86_64-unknown-linux-musl',
    'arm64': 'aarch64-unknown-linux-musl',
  }
  if $arch not-in $ARCH_MAP {
    print $'Invalid architecture: (ansi r)($arch)(ansi reset)'; exit 1
  }
  let BASE_HEADER = [Authorization $'Bearer ($env.GITHUB_TOKEN)' Accept application/vnd.github.v3+json]
  let assets = http get -H $BASE_HEADER https://api.github.com/repos/nushell/nushell/releases
      | sort-by -r created_at
      | select name created_at assets
      | get 0
      | get assets.browser_download_url
  let download_url = $assets | where $it =~ ($ARCH_MAP | get $arch) | get 0
  if ('release' | path exists) { rm -rf release }
  if not ('release' | path exists) { mkdir release }
  cd release
  http get $download_url | save -rpf nushell.tar.gz
  tar -xzf nushell.tar.gz
  cp nu-*/nu* .
}

# Build the Nushell deb packages
export def --env 'publish pkg' [
  arch: string,       # The target architecture, e.g. amd64 & arm64
  --create-release,   # Create a new release on GitHub
] {
  let meta = open meta.json
  # Trim is required to remove the leading and trailing whitespaces here
  let version = run-external 'release/nu' '--version' | complete | get stdout | str trim
  let version = if ($version | is-empty) { $meta.version } else { $version }
  load-env {
    NU_VERSION: $version
    NU_PKG_ARCH: $arch
    NU_VERSION_REVISION: $meta.revision
  }
  if $meta.pkgs.deb { nfpm pkg --packager deb }
  if $meta.pkgs.rpm { nfpm pkg --packager rpm }
  if $meta.pkgs.apk { nfpm pkg --packager apk }

  ls -f nushell* | print

  if $create_release { create-github-release $version }

  if $meta.pkgs.deb { push deb $arch }
  if $meta.pkgs.rpm { push rpm $arch }
  if $meta.pkgs.apk { push apk $arch }
}

# Create a new release on GitHub, and upload the artifacts
def create-github-release [version: string] {
  let repo = 'nushell/integrations'
  let releases = gh release list -R $repo --json name | from json | get name
  if $version not-in $releases {
    gh release create $version -R $repo --title $version --notes $version
  }
  gh release upload $version -R $repo nushell*.deb nushell*.rpm nushell*.apk
}

# Publish the Nushell apk packages to Gemfury
export def 'push apk' [
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  const ARCH_ALIAS_MAP = {
    'amd64': 'x86_64',
    'arm64': 'aarch64',
  }
  let arch = $ARCH_ALIAS_MAP | get $arch
  let pkg = ls | where name =~ $'($arch).apk' | get name.0
  print $'Uploading the ($pkg) package to Gemfury...'
  let result = fury push $pkg --account nushell --api-token $env.GEMFURY_TOKEN | complete
  handle-push-result $result
}

# Publish the Nushell deb packages to Gemfury
export def 'push deb' [
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  let pkg = ls | where name =~ $'($arch).deb' | get name.0
  print $'Uploading the ($pkg) package to Gemfury...'
  let result = fury push $pkg --account nushell --api-token $env.GEMFURY_TOKEN | complete
  handle-push-result $result
}

# Publish the Nushell rpm packages to Gemfury
export def 'push rpm' [
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  const ARCH_ALIAS_MAP = {
    'amd64': 'x86_64',
    'arm64': 'aarch64',
  }
  let arch = $ARCH_ALIAS_MAP | get $arch
  let pkg = ls | where name =~ $'($arch).rpm' | get name.0
  print $'Uploading the ($pkg) package to Gemfury...'
  let result = fury push $pkg --account nushell --api-token $env.GEMFURY_TOKEN | complete
  handle-push-result $result
}

# Handle the push result, ignore the existing package
def handle-push-result [result] {
  if $result.stdout =~ 'already exists' {
    print 'Package already exists, ignored...'; return
  }
  print $result.stdout
  if ($result.exit_code != 0 ) { print $result.stderr }
  exit $result.exit_code
}
