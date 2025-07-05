const FROM_REF = '0.105.1'
const PREV_VER = '0.105.0'
const LAST_VER = '0.105.1'
const OSS_DEST = 'oss://terminus-new-trantor/open-tools/misc'
const OSS_ENDPOINT = 'https://terminus-new-trantor.oss-cn-hangzhou.aliyuncs.com/open-tools/misc'

export def prepare [] {

  rm -rf obj/ bin/
  nu -c $'NU_RELEASE_VERSION=($PREV_VER) dotnet build -c Release -p:Platform=x64'
  ossutil cp -f bin\x64\Release\nu-x64.msi $'($OSS_DEST)/nu-($PREV_VER)-x86_64-pc-windows-msvc.msi'

  rm -rf obj/ bin/
  nu -c $'NU_RELEASE_VERSION=($LAST_VER) dotnet build -c Release -p:Platform=x64'
  ossutil cp -f bin\x64\Release\nu-x64.msi $'($OSS_DEST)/nu-($LAST_VER)-x86_64-pc-windows-msvc.msi'
}

export def upgrade-nu-by-winget [
  --no-hash(-n),
] {

  let prevUrl = $'($OSS_ENDPOINT)/nu-($PREV_VER)-x86_64-pc-windows-msvc.msi'
  let lastUrl = $'($OSS_ENDPOINT)/nu-($LAST_VER)-x86_64-pc-windows-msvc.msi'
  # sudo winget settings --enable InstallerHashOverride
  winget uninstall nushell | complete
  if ($no_hash) {
    winget install --manifest manifests\n\Nushell\Nushell\($PREV_VER) --ignore-security-hash --silent
    winget upgrade --manifest manifests\n\Nushell\Nushell\($LAST_VER) --ignore-security-hash --silent
    return
  }
  komac update Nushell.Nushell --dry-run -v $PREV_VER -u $prevUrl --output .
  komac update Nushell.Nushell --dry-run -v $LAST_VER -u $lastUrl --output .
  winget install --manifest manifests\n\Nushell\Nushell\($PREV_VER) --ignore-security-hash --silent
  winget upgrade --manifest manifests\n\Nushell\Nushell\($LAST_VER) --ignore-security-hash --silent
}

def rebuild [--fetch(-f)] {
  if $fetch { fetch-nu-pkg }
  rm -rf obj/ bin/
  nu -c $'NU_RELEASE_VERSION=($LAST_VER) dotnet build -c Release -p:Platform=x64'
  ossutil cp -f bin\x64\Release\nu-x64.msi $'($OSS_DEST)/nu-($LAST_VER)-x86_64-pc-windows-msvc.msi'
  winget uninstall nushell | complete
  # msiexec /i bin\x64\Release\nu-x64.msi ALLUSERS=1
  winget install --manifest manifests\n\Nushell\Nushell\($LAST_VER) --ignore-security-hash --silent --scope machine
}

def fetch-nu-pkg [] {
  mkdir nu
  gh release download $FROM_REF --repo nushell/nushell --pattern $'*-x86_64-*.zip' --dir nu
  cd nu
  let pkg = ls *.zip | get name.0
  unzip $pkg
  rm $pkg
  ls | print
}

alias main = rebuild
