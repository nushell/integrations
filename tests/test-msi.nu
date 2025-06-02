
use std/assert
use std/testing *
use common.nu [check-user-install, check-version-match]


@before-all
def setup [] {
  mkdir msi-pkgs
  cd msi-pkgs
  let arch = $nu.os-info.arch
  let release_tag = get-latest-tag
  gh release download $release_tag --repo nushell/nightly --pattern $"*-($arch)-*.msi"
  let msi = ls | where name =~ msi | get name.0
  print $'MSI File: ($msi)'
  let install_dir = $'($nu.home-path)\AppData\Local\Programs\nu'
  { msi: $msi, install_dir: $install_dir, release_tag: $release_tag }
}

@test
def 'msi-install：MSI should exists' [] {
  let pkg = $in.msi
  cd msi-pkgs
  let package = ls $pkg
  assert equal ($package | length) 1
  assert greater ($package | get size.0) 15mb
}

@test
def 'msi-install：MSI should install successfully for per-user' [] {
  let pkg = $in.msi
  let install_dir = $in.install_dir
  let release_tag = $in.release_tag

  cd msi-pkgs

  print 'Using msiexec to test MSI installation'
  # msiexec /i $pkg ALLUSERS=1 /a /quiet /qn /L*V install.txt
  msiexec /i $pkg MSIINSTALLPERUSER=1 /quiet /qn /L*V install.txt
  # print (open -r install.txt)
  check-user-install $install_dir
  check-version-match $release_tag $install_dir
}

def get-latest-tag [] {
  http get https://api.github.com/repos/nushell/nightly/releases
    | sort-by -r created_at
    | where tag_name =~ nightly
    | get tag_name?.0?
    | default ''
}
