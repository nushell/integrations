
use std/assert

def main [] {
  let install_dir = $'($nu.home-path)\AppData\Local\Programs\nu'
  let profile = $'($nu.home-path)\AppData\Local\Microsoft\Windows Terminal\Fragments\nu\nu.json'
  const BINS = [
    nu.exe,
    nu_plugin_inc.exe,
    nu_plugin_gstat.exe,
    nu_plugin_query.exe,
    nu_plugin_polars.exe,
    nu_plugin_formats.exe,
  ]

  print 'Using winget to test MSI installation'
  let args = [--accept-source-agreements --accept-package-agreements --silent]
  winget settings --enable LocalManifestFiles
  winget install --manifest manifests\n\Nushell\Nushell\0.104.1 ...$args
  let environment = registry query --hkcu environment
      | where name == Path | get 0.value
  print $"Path Environment: \n($environment)"
  let contents = ls -s $install_dir
  let bins = ls -s $'($install_dir)\bin'
  assert greater ($bins | length) 5
  assert greater ($contents | length) 3
  assert equal ($profile | path exists) true
  print $'(ansi g)Windows Terminal Profile setup sucessfully...(ansi reset)'
  assert equal ($environment | str contains $install_dir) true
  print $'(ansi g)Path environment setup sucessfully...(ansi reset)'
  assert equal ($BINS | all {|it| $it in ($bins | get name) }) true
  assert equal ([License.rtf README.txt nu.ico bin] | all {|it| $it in ($contents | get name) }) true
  print $'(ansi g)Nu binaries installed sucessfully...(ansi reset)'
}
