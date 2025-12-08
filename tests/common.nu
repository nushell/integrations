
use std/assert

const BINS = [
  nu.exe,
  less.exe,
  nu_plugin_inc.exe,
  nu_plugin_gstat.exe,
  nu_plugin_query.exe,
  nu_plugin_polars.exe,
  nu_plugin_formats.exe,
]

export const MACHINE_INSTALL_DIR = 'C:\Program Files\nu'
export const USER_INSTALL_DIR = $'($nu.home-dir)\AppData\Local\Programs\nu'

const ASSETS = [License.rtf README.txt nu.ico bin]

const PROFILE = $'($nu.home-dir)\AppData\Local\Microsoft\Windows Terminal\Fragments\nu\nu.json'

# Run this command locally or in GitHub runners after installing nu
export def check-user-install [install_dir = $USER_INSTALL_DIR: string] {

  let environment = registry query --hkcu environment
      | where name == Path | get 0.value
  print $"(char nl)Path Environment after install: \n"
  print ($environment | split row ';')
  assert equal ($environment | str contains $install_dir) true
  print $'(char nl)(ansi g)Path environment setup successfully...(ansi reset)'
  assert equal (registry query --hkcu Software\nu | where name == installed | get 0.value) 1
  assert equal (registry query --hkcu Software\nu | where name == WindowsTerminalProfile | get 0.value) 1
  check-common-install $install_dir
}

# Run this command locally after uninstalling nu
export def check-uninstall [install_dir = $MACHINE_INSTALL_DIR: string] {

  let environment = registry query --hkcu environment
      | where name == Path | get 0.value
  print $"(char nl)Path Environment after uninstall: \n"
  print ($environment | split row ';')
  assert equal ($environment | str contains $install_dir) false
  assert equal ($environment | str contains $USER_INSTALL_DIR) false
  print $'(char nl)(ansi g)Path environment uninstall successfully...(ansi reset)'
  assert equal ($PROFILE | path exists) false
  print $'(ansi g)Windows Terminal Profile uninstall successfully...(ansi reset)'
  assert equal ($install_dir | path exists) false
  assert equal ($USER_INSTALL_DIR | path exists) false
  print $'(ansi g)Nu binaries uninstalled successfully...(ansi reset)'
  assert equal (try { registry query --hkcu Software\nu } catch {false}) false
}

export def check-local-machine-install [install_dir = $MACHINE_INSTALL_DIR: string] {

  const ENV_REG_KEY = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
  let environment = registry query --hklm $ENV_REG_KEY
      | where name == Path | get 0.value
  print $"(char nl)Path Environment after install: \n"
  print ($environment | split row ';')
  assert equal ($environment | str contains $install_dir) true
  print $'(char nl)(ansi g)Path environment setup successfully...(ansi reset)'
  assert equal (registry query --hklm Software\nu | where name == installed | get 0.value) 1
  assert equal (registry query --hkcu Software\nu | where name == WindowsTerminalProfile | get 0.value) 1
  check-common-install $install_dir
}

# Run this command locally or in GitHub runners after installing nu
export def check-common-install [install_dir = $USER_INSTALL_DIR: string] {

  let profile = open $PROFILE
  let contents = ls -s $install_dir
  let bins = ls -s $'($install_dir)\bin'
  assert greater ($bins | length) 7
  assert greater ($contents | length) 3
  assert equal ($PROFILE | path exists) true
  assert equal ($profile | get profiles.0.icon | path exists) true
  assert equal ($profile | get profiles.0.commandline | str trim --char '"' | path exists) true
  print $'(ansi g)Windows Terminal Profile setup successfully...(ansi reset)'
  assert equal ($BINS | all {|it| $it in ($bins | get name) }) true
  print $'(ansi g)Nu binaries installed successfully...(ansi reset)'
  assert equal ($ASSETS | all {|it| $it in ($contents | get name) }) true
  print (^$'($install_dir)\bin\nu.exe' -c 'version')
}

export def check-version-match [version_expected: string, install_dir = $USER_INSTALL_DIR: string] {

  let version = ^$'($install_dir)\bin\nu.exe' --version | str trim
  assert equal ($version_expected | str contains $version) true
  print $'(ansi g)Installed Nu of the specified version: ($version)(ansi reset)'
}

export def get-latest-tag [] {
  http get https://api.github.com/repos/nushell/nightly/releases
    | sort-by -r created_at
    | where tag_name =~ nightly
    | get tag_name?.0?
    | default ''
}
