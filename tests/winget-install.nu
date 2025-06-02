
use std/assert
use common.nu [check-user-install, check-version-match, get-latest-tag]

const KOMAC = 'C:\Users\runneradmin\AppData\Local\Programs\Komac\bin\komac.exe'

def main [--scope: string] {
  prepare-manifest
  let install_dir = $'($nu.home-path)\AppData\Local\Programs\nu'
  let scope_tip = if $scope in [user, machine] { $'($scope) scope' } else { $'default scope' }
  print $'Using winget to test MSI (ansi g)($scope_tip)(ansi reset) installation'
  let args = [
      --silent
      --ignore-security-hash
      --disable-interactivity
      --accept-source-agreements
      --accept-package-agreements
    ]
  let version = get-latest-tag | split row + | first
  let scope_arg = if $scope in [user, machine] { [--scope $scope] } else { [] }
  winget settings --enable LocalManifestFiles
  winget settings --enable InstallerHashOverride
  winget install --manifest $'manifests\n\Nushell\Nushell\($version)\' ...$args ...$scope_arg
  check-user-install $install_dir
  check-version-match $version $install_dir
}

def prepare-manifest [] {
  let version = get-latest-tag | split row + | first
  let urls = get-download-url
  ^$KOMAC update Nushell.Nushell --dry-run -v $version -u  ...$urls -o (pwd)
}

def get-download-url [] {
  http get https://api.github.com/repos/nushell/nightly/releases
    | sort-by -r created_at
    | where tag_name =~ nightly | get assets.0.browser_download_url
    | where $it =~ 'msi'
}
