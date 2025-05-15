
use std/assert
use common.nu [check-user-install, check-version-match]

const VERSION = '0.104.1'

def main [--scope: string] {

  let install_dir = $'($nu.home-path)\AppData\Local\Programs\nu'
  let scope_tip = if $scope in [user, machine] { $'($scope) scope' } else { $'default scope' }
  print $'Using winget to test MSI (ansi g)($scope_tip)(ansi reset) installation'
  let args = [--accept-source-agreements --accept-package-agreements --ignore-security-hash --silent]
  let scope_arg = if $scope in [user, machine] { [--scope $scope] } else { [] }
  winget settings --enable LocalManifestFiles
  winget settings --enable InstallerHashOverride
  winget install --manifest manifests\n\Nushell\Nushell\($VERSION) ...$args ...$scope_arg
  check-user-install $install_dir
  check-version-match $VERSION $install_dir
}
