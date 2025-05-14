
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

const ASSETS = [License.rtf README.txt nu.ico bin]

const PROFILE = $'($nu.home-path)\AppData\Local\Microsoft\Windows Terminal\Fragments\nu\nu.json'

export def check-user-install [install_dir: string] {

  let environment = registry query --hkcu environment
      | where name == Path | get 0.value
  print $"Path Environment: \n($environment)"
  let contents = ls -s $install_dir
  let bins = ls -s $'($install_dir)\bin'
  assert greater ($bins | length) 7
  assert greater ($contents | length) 3
  assert equal ($PROFILE | path exists) true
  print $'(ansi g)Windows Terminal Profile setup sucessfully...(ansi reset)'
  assert equal ($environment | str contains $install_dir) true
  print $'(ansi g)Path environment setup sucessfully...(ansi reset)'
  assert equal ($BINS | all {|it| $it in ($bins | get name) }) true
  print $'(ansi g)Nu binaries installed sucessfully...(ansi reset)'
  assert equal ($ASSETS | all {|it| $it in ($contents | get name) }) true
  assert equal (registry query --hkcu Software\nu | where name == installed | get 0.value) 1
  assert equal (registry query --hkcu Software\nu | where name == WindowsTerminalProfile | get 0.value) 1
  print (^$'($install_dir)\bin\nu.exe' -c 'version')
}
