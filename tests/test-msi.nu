
use std/assert
use std/testing *

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
  let profile = $'($nu.home-path)\AppData\Local\Microsoft\Windows Terminal\Fragments\nu\nu.json'
  const BINS = [
    nu.exe,
    less.exe,
    nu_plugin_inc.exe,
    nu_plugin_gstat.exe,
    nu_plugin_query.exe,
    nu_plugin_polars.exe,
    nu_plugin_formats.exe,
  ]
  cd msi-pkgs

  print 'Using msiexec to test MSI installation'
  # msiexec /i $pkg ALLUSERS=1 /a /quiet /qn /L*V install.txt
  msiexec /i $pkg MSIINSTALLPERUSER=1 /quiet /qn /L*V install.txt
  # print (open -r install.txt)
  let environment = registry query --hkcu environment
      | where name == Path | get 0.value
  print $"Path Environment: \n($environment)"
  let contents = ls -s $install_dir
  let bins = ls -s $'($install_dir)\bin'
  assert greater ($bins | length) 7
  assert greater ($contents | length) 3
  assert equal ($profile | path exists) true
  print $'(ansi g)Windows Terminal Profile setup sucessfully...(ansi reset)'
  assert equal ($environment | str contains $install_dir) true
  print $'(ansi g)Path environment setup sucessfully...(ansi reset)'
  assert equal ($BINS | all {|it| $it in ($bins | get name) }) true
  print $'(ansi g)Nu binaries installed sucessfully...(ansi reset)'
  assert equal ([License.rtf README.txt nu.ico bin] | all {|it| $it in ($contents | get name) }) true
  assert equal (registry query --hkcu Software\nu | where name == installed | get 0.value) 1
  assert equal (registry query --hkcu Software\nu | where name == WindowsTerminalProfile | get 0.value) 1
  print (^$'($install_dir)\bin\nu.exe' -c 'version')
}
