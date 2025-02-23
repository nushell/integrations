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

const ARCH_ALIAS_MAP = {
  amd64: 'x86_64',
  arm64: 'aarch64',
}
const ALPINE_IGNORE = [loongarch64 riscv64]
const RELEASE_QUERY_URL = 'https://api.github.com/repos/nushell/nushell/releases'

# Fetch the latest Nushell release package from GitHub
export def 'fetch release' [
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  const ARCH_MAP = {
    amd64: 'x86_64-unknown-linux-musl',
    arm64: 'aarch64-unknown-linux-musl',
    riscv64: 'riscv64gc-unknown-linux-gnu',
    loongarch64: 'loongarch64-unknown-linux-gnu',
  }
  if $arch not-in $ARCH_MAP {
    print $'Invalid architecture: (ansi r)($arch)(ansi reset)'; exit 1
  }
  let BASE_HEADER = [
      Accept application/vnd.github.v3+json
      Authorization $'Bearer ($env.GITHUB_TOKEN)'
    ]
  let assets = http get -H $BASE_HEADER $RELEASE_QUERY_URL
      | sort-by -r created_at
      | select name created_at assets
      | get 0
      | get assets.browser_download_url
  let download_url = $assets | where $it =~ ($ARCH_MAP | get $arch) | get 0
  if ('release' | path exists) { rm -rf release }
  if not ('release' | path exists) { mkdir release }
  cd release
  print $'Downloading artifact from ($download_url)...'
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
  let version = try {
      run-external 'release/nu' '--version' | complete | get stdout | str trim
    } catch { '' }
  let version = if ($version | is-empty) { $meta.version } else { $version }
  load-env {
    NU_VERSION: $version
    NU_PKG_ARCH: $arch
    NU_VERSION_REVISION: $meta.revision
  }
  if $meta.pkgs.deb { nfpm pkg --packager deb }
  if $meta.pkgs.rpm { nfpm pkg --packager rpm }
  if $meta.pkgs.archlinux { nfpm pkg --packager archlinux }
  if $meta.pkgs.apk and $arch not-in $ALPINE_IGNORE { nfpm pkg --packager apk }

  ls -f nushell* | print
  if $create_release { create-github-release $'($version)-($meta.revision)' $arch }

  if $meta.pkgs.deb { push deb $arch }
  if $meta.pkgs.rpm { push rpm $arch }
  if $meta.pkgs.apk and $arch not-in $ALPINE_IGNORE { push apk $arch }
}

# Create a new release on GitHub, and upload the artifacts
def create-github-release [
  version: string,  # The release version, e.g. 0.102.0
  arch: string,     # The target architecture, e.g. amd64 & arm64
] {
  let repo = 'nushell/integrations'
  let releases = gh release list -R $repo --json name | from json | get name
  if $version not-in $releases {
    gh release create $version -R $repo --title $version
  }
  # --clobber   Overwrite existing assets of the same name
  if $arch in $ALPINE_IGNORE {
    gh release upload $version -R $repo --clobber nu*.deb nu*.rpm nu*.pkg.tar.zst; return
  }
  gh release upload $version -R $repo --clobber nu*.deb nu*.rpm nu*.pkg.tar.zst nu*.apk
}

# Publish the Nushell apk packages to Gemfury
export def 'push apk' [
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  let arch = $ARCH_ALIAS_MAP | get -i $arch | default $arch
  let pkg = ls | where name =~ $'($arch).apk' | get name.0
  if (pkg exists alpine $arch) { print $'Package ($pkg) already exists, ignored...'; return }
  print $'Uploading the ($pkg) package to Gemfury...'
  fury push $pkg --account nushell --api-token $env.GEMFURY_TOKEN
}

# Publish the Nushell deb packages to Gemfury
export def 'push deb' [
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  let pkg = ls | where name =~ $'($arch).deb' | get name.0
  if (pkg exists deb $arch) { print $'Package ($pkg) already exists, ignored...'; return }
  print $'Uploading the ($pkg) package to Gemfury...'
  fury push $pkg --account nushell --api-token $env.GEMFURY_TOKEN
}

# Publish the Nushell rpm packages to Gemfury
export def 'push rpm' [
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  let arch = $ARCH_ALIAS_MAP | get -i $arch | default $arch
  let pkg = ls | where name =~ $'($arch).rpm' | get name.0
  if (pkg exists rpm $arch) { print $'Package ($pkg) already exists, ignored...'; return }
  print $'Uploading the ($pkg) package to Gemfury...'
  fury push $pkg --account nushell --api-token $env.GEMFURY_TOKEN
}

# Check if the package exists on Gemfury
export def 'pkg exists' [
  type: string,   # The package type, e.g. deb & rpm
  arch: string,   # The target architecture, e.g. amd64 & arm64
] {
  let versions = fury versions $'($type):nushell' -a nushell --api-token $env.GEMFURY_TOKEN
      | complete | get stdout | lines
      | skip 3 | str join "\n" | detect columns
  let revision = $env.NU_VERSION_REVISION? | default 0 | into int
  let rev = if $type == 'alpine' { $'r($revision)' } else { $revision }
  let ver = if $revision > 0 { $'($env.NU_VERSION)-($rev)' } else { $env.NU_VERSION }
  ($versions | where filename =~ $arch and version == $ver | length) > 0
}
