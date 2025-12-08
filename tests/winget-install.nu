
use std/assert
use std/util ['path add']
use common.nu [MACHINE_INSTALL_DIR, USER_INSTALL_DIR]
use common.nu [check-user-install, check-local-machine-install, check-version-match, get-latest-tag]


const KOMAC_PATH = $'($nu.home-dir)\AppData\Local\Programs\Komac\bin\'

const WINGET_ARGS = [
      --silent
      --ignore-security-hash
      --disable-interactivity
      --accept-source-agreements
      --accept-package-agreements
    ]

def main [--scope: string] {
  prepare-manifest
  let scope_tip = if $scope in [user, machine] { $'($scope) scope' } else { $'default scope' }
  print $'Using winget to test MSI (ansi g)($scope_tip)(ansi reset) installation'
  let version = get-latest-tag | split row + | first
  let scope_arg = if $scope in [user, machine] { [--scope $scope] } else { [] }
  winget settings --enable LocalManifestFiles
  winget settings --enable InstallerHashOverride
  winget install --manifest $'manifests\n\Nushell\Nushell\($version)\' ...$WINGET_ARGS ...$scope_arg
  if $scope == 'machine' {
    check-local-machine-install
    check-version-match $version $MACHINE_INSTALL_DIR
    return
  }
  check-user-install $USER_INSTALL_DIR
  check-version-match $version $USER_INSTALL_DIR
}

export def prepare-manifest [] {
  let version = get-latest-tag | split row + | first
  let urls = get-download-url
  path add $KOMAC_PATH
  ls $KOMAC_PATH | print
  komac --version | print
  komac update Nushell.Nushell --dry-run -v $version -u ...$urls -o (pwd)
}

def get-download-url [] {
  http get https://api.github.com/repos/nushell/nightly/releases
    | sort-by -r created_at
    | where tag_name =~ nightly | get assets.0.browser_download_url
    | where $it =~ 'msi'
}
