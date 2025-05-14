
use std/assert
use std/testing *
use common.nu [check-user-install]

const RELEASE_TAG = 'v0.104.1'

@before-all
def setup [] {
  mkdir msi-pkgs
  cd msi-pkgs
  let arch = $nu.os-info.arch
  gh release download $RELEASE_TAG --repo nushell/nightly --pattern $"*-($arch)-*.msi"
  let msi = ls | where name =~ msi | get name.0
  print $'MSI File: ($msi)'
  let install_dir = $'($nu.home-path)\AppData\Local\Programs\nu'
  { msi: $msi, install_dir: $install_dir }
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

  cd msi-pkgs

  print 'Using msiexec to test MSI installation'
  # msiexec /i $pkg ALLUSERS=1 /a /quiet /qn /L*V install.txt
  msiexec /i $pkg MSIINSTALLPERUSER=1 /quiet /qn /L*V install.txt
  # print (open -r install.txt)
  check-user-install $install_dir
}
