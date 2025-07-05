# Usage:
# Run the following commands to enable local manifest files and installer hash override with admin privileges:
# winget settings --enable LocalManifestFiles
# winget settings --enable InstallerHashOverride

use common.nu [check-user-install, check-version-match, check-local-machine-install]

const VERSION = '0.105.1'
const PREV_VERSION = '0.105.0'
const LAST_VERSION = '0.105.1'
const MSI_PKG = 'wix\bin\x64\Release\nu-x64.msi'
const PER_MACHINE_INSTALL_DIR = 'C:\Program Files\nu'
const PER_USER_INSTALL_DIR = $'($nu.home-path)\AppData\Local\Programs\nu'
const WINGET_ARGS = [
      --silent
      --ignore-security-hash
      --disable-interactivity
      --accept-source-agreements
      --accept-package-agreements
    ]

def main [--msi(-m)] {
  if $msi {
    test-msi-per-user-install
    test-msi-per-machine-install
  }
  test-winget-per-user-install
  test-winget-per-user-upgrade
  test-winget-per-machine-install
  test-winget-per-machine-upgrade
}

export def test-msi-per-user-install [] {
  winget uninstall nushell | complete
  print $'Using msiexec to test MSI (ansi g)per-user(ansi reset) installation'
  print '-------------------------------------------------------------------'
  msiexec /i $MSI_PKG MSIINSTALLPERUSER=1 /quiet /qn /L*V install.txt
  check-user-install $PER_USER_INSTALL_DIR
  check-version-match $VERSION $PER_USER_INSTALL_DIR
  winget list nushell --accept-source-agreements
}

export def test-msi-per-machine-install [] {
  winget uninstall nushell | complete
  print $'(char nl)Using msiexec to test MSI (ansi g)machine scope(ansi reset) installation'
  print '-------------------------------------------------------------------'
  msiexec /i $MSI_PKG ALLUSERS=1 /L*V install.txt
  check-local-machine-install
  check-version-match $VERSION $PER_MACHINE_INSTALL_DIR
  winget list nushell --accept-source-agreements
}

export def test-winget-per-user-install [] {
  winget uninstall nushell | complete
  print $'(char nl)Using winget to test MSI (ansi g)user scope(ansi reset) installation'
  print '-------------------------------------------------------------------'
  winget install --manifest $'manifests\n\Nushell\Nushell\($PREV_VERSION)\' ...$WINGET_ARGS --scope user
  check-user-install $PER_USER_INSTALL_DIR
  check-version-match $PREV_VERSION $PER_USER_INSTALL_DIR
  winget list nushell --accept-source-agreements
}

export def test-winget-per-user-upgrade [] {
  print $'(char nl)Using winget to test MSI (ansi g)user scope(ansi reset) upgrade'
  print '-------------------------------------------------------------------'
  winget install --manifest $'manifests\n\Nushell\Nushell\($LAST_VERSION)\' ...$WINGET_ARGS --scope user
  check-user-install $PER_USER_INSTALL_DIR
  check-version-match $LAST_VERSION $PER_USER_INSTALL_DIR
  winget list nushell --accept-source-agreements
}

export def test-winget-per-machine-install [] {
  winget uninstall nushell | complete
  print $'(char nl)Using winget to test MSI (ansi g)machine scope(ansi reset) installation'
  print '-------------------------------------------------------------------'
  winget install --manifest $'manifests\n\Nushell\Nushell\($PREV_VERSION)\' ...$WINGET_ARGS --scope machine
  check-local-machine-install
  check-version-match $PREV_VERSION $PER_MACHINE_INSTALL_DIR
  winget list nushell --accept-source-agreements
}

export def test-winget-per-machine-upgrade [] {
  print $'(char nl)Using winget to test MSI (ansi g)machine scope(ansi reset) upgrade'
  print '-------------------------------------------------------------------'
  winget install --manifest $'manifests\n\Nushell\Nushell\($LAST_VERSION)\' ...$WINGET_ARGS --scope machine
  check-local-machine-install
  check-version-match $LAST_VERSION $PER_MACHINE_INSTALL_DIR
  winget list nushell --accept-source-agreements
}
