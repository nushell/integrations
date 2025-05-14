
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

const MACHINE_INSTALL_DIR = 'C:\Program Files\nu'
const USER_INSTALL_DIR = $'($nu.home-path)\AppData\Local\Programs\nu'

const ASSETS = [License.rtf README.txt nu.ico bin]

const PROFILE = $'($nu.home-path)\AppData\Local\Microsoft\Windows Terminal\Fragments\nu\nu.json'

# Run this command locally or in GitHub runners after installing nu
export def check-user-install [install_dir = $USER_INSTALL_DIR: string] {

  let environment = registry query --hkcu environment
      | where name == Path | get 0.value
  print $"Path Environment after install: \n"
  print ($environment | split row ';')
  let contents = ls -s $install_dir
  let bins = ls -s $'($install_dir)\bin'
  assert greater ($bins | length) 7
  assert greater ($contents | length) 3
  assert equal ($PROFILE | path exists) true
  print $'(char nl)(ansi g)Windows Terminal Profile setup sucessfully...(ansi reset)'
  assert equal ($environment | str contains $install_dir) true
  print $'(ansi g)Path environment setup sucessfully...(ansi reset)'
  assert equal ($BINS | all {|it| $it in ($bins | get name) }) true
  print $'(ansi g)Nu binaries installed sucessfully...(ansi reset)'
  assert equal ($ASSETS | all {|it| $it in ($contents | get name) }) true
  assert equal (registry query --hkcu Software\nu | where name == installed | get 0.value) 1
  assert equal (registry query --hkcu Software\nu | where name == WindowsTerminalProfile | get 0.value) 1
  print (^$'($install_dir)\bin\nu.exe' -c 'version')
}

# Run this command locally after uninstalling nu
export def check-uninstall [] {

  let environment = registry query --hkcu environment
      | where name == Path | get 0.value
  print $"Path Environment after uninstall: \n"
  print ($environment | split row ';')
  assert equal ($environment | str contains $USER_INSTALL_DIR) false
  assert equal ($environment | str contains $MACHINE_INSTALL_DIR) false
  print $'(char nl)(ansi g)Path environment uninstall sucessfully...(ansi reset)'
  assert equal ($PROFILE | path exists) false
  print $'(ansi g)Windows Terminal Profile uninstall sucessfully...(ansi reset)'
  assert equal ($USER_INSTALL_DIR | path exists) false
  assert equal ($MACHINE_INSTALL_DIR | path exists) false
  print $'(ansi g)Nu binaries uninstalled sucessfully...(ansi reset)'
  assert equal (try { registry query --hkcu Software\nu } catch {false}) false
}

export def check-local-machine-install [] {

}
