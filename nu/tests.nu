#!/usr/bin/env nu
# Description:
#   This script is used to test the Docker image of termix-nu.
# Usage:
#   Change to the directory where the Dockerfile is located and run:
#   docker run -it --rm -v $"(pwd):/work" hustcer/termix:latest-alpine /work/tests/test-docker.nu

use std assert

const NU_VERSION = '0.104.0'

def main [] {
  let test_plan = (
    scope commands
      | where ($it.type == "custom")
          and ($it.name | str starts-with "test ")
          and not ($it.description | str starts-with "ignore")
      | each { |test| create_execution_plan $test.name }
      | str join ", "
  )
  let plan = $"run_tests [ ($test_plan) ]"
  ^$nu.current-exe --commands $"source ($env.CURRENT_FILE); ($plan)"
}

def create_execution_plan [test: string]: nothing -> string {
  $"{ name: \"($test)\", execute: { ($test) } }"
}

def run_tests [tests: list<record<name: string, execute: closure>>] {
  let results = $tests | par-each { run_test $in }

  print_results $results
  print_summary $results

  if ($results | any { |test| $test.result == "FAIL" }) {
    exit 1
  }
}

def print_results [results: list<record<name: string, result: string>>] {
  let display_table = $results | update result { |row|
    let emoji = if ($row.result == "PASS") { "✅" } else { "❌" }
    $"($emoji) ($row.result)"
  }

  if ("GITHUB_ACTIONS" in $env) {
    print ($display_table | to md --pretty)
  } else {
    print $display_table
  }
}

def print_summary [results: list<record<name: string, result: string>>]: nothing -> bool {
  let success = $results | where ($it.result == "PASS") | length
  let failure = $results | where ($it.result == "FAIL") | length
  let count = $results | length

  if ($failure == 0) {
    print $"\nTesting completed: ($success) of ($count) were successful"
  } else {
    print $"\nTesting completed: ($failure) of ($count) failed"
  }
}

def run_test [test: record<name: string, execute: closure>]: nothing -> record<name: string, result: string, error: string> {
  try {
    do ($test.execute)
    { result: $"PASS",name: $test.name, error: "" }
  } catch { |error|
    { result: $"FAIL", name: $test.name, error: $"($error.msg) (format_error $error.debug)" }
  }
}

def format_error [error: string] {
  $error
    # Get the value for the text key in a partly non-json error message
    | parse --regex ".+text: \"(.+)\""
    | first
    | get capture0
    | str replace --all --regex "\\\\n" " "
    | str replace --all --regex " +" " "
}

def "test bin installed correctely" [] {
  const paths = [
    /usr/bin/nu,
    /usr/libexec/nushell/nu_plugin_inc,
    /usr/libexec/nushell/nu_plugin_gstat,
    /usr/libexec/nushell/nu_plugin_query,
    /usr/libexec/nushell/nu_plugin_polars,
    /usr/libexec/nushell/nu_plugin_formats,
  ]
  let exist = $paths | all {|p| $p | path exists }
  assert equal $exist true
}

def "test Nu version is correct" [] {
  let version = nu --version
  assert greater or equal (compare-ver $version $NU_VERSION) 0
}

def "test nu is added as a shell" [] {
  let shell = cat /etc/shells
      | lines
      | where ($it | str contains "nu")
      | first

  assert str contains $shell "/nu"
}

def "test main plugins are installed" [] {
  let plugins = (plugin list) | get name

  assert ("formats" in $plugins)
  assert ("gstat" in $plugins)
  assert ("inc" in $plugins)
  assert ("polars" in $plugins)
  assert ("query" in $plugins)
}

def "test config initialised" [] {
  let files = ls ~/.config/nushell
      | select name size
      | where name ends-with '.nu'
      | insert file { |row| $row.name | parse --regex ".+/(.+\\.nu)" | first | get capture0 }

  let env_size = $files | where file == "env.nu" | get size | first
  let config_size = $files | where file == "config.nu" | get size | first

  assert greater $env_size 300B
  assert greater $config_size 350B
}

# Compare two version number, return `1` if first one is higher than second one,
# Return `0` if they are equal, otherwise return `-1`
# Examples:
#   compare-ver 1.2.3 1.2.0    # Returns 1
#   compare-ver 2.0.0 2.0.0    # Returns 0
#   compare-ver 1.9.9 2.0.0    # Returns -1
# Format: Expects semantic version strings (major.minor.patch)
#   - Optional 'v' prefix
#   - Pre-release suffixes (-beta, -rc, etc.) are ignored
#   - Missing segments default to 0
export def compare-ver [v1: string, v2: string] {
  # Parse the version number: remove pre-release and build information,
  # only take the main version part, and convert it to a list of numbers
  def parse-ver [v: string] {
    $v | str replace -r '^v' '' | str trim | split row -
       | first | split row . | each { into int }
  }
  let a = parse-ver $v1
  let b = parse-ver $v2
  # Compare the major, minor, and patch parts; fill in the missing parts with 0
  # If you want to compare more parts use the following code:
  # for i in 0..([2 ($a | length) ($b | length)] | math max)
  for i in 0..2 {
    let x = $a | get -i $i | default 0
    let y = $b | get -i $i | default 0
    if $x > $y { return 1    }
    if $x < $y { return (-1) }
  }
  0
}
