#!/usr/bin/env nu
# Description:
#   This script is used to test the Docker image of termix-nu.
# Usage:
#   Change to the directory where the Dockerfile is located and run:
#   docker run -it --rm -v $"(pwd):/work" hustcer/termix:latest-alpine /work/tests/test-docker.nu

use std assert

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

def "test nu is added as a shell" [] {
  let shell = cat /etc/shells
      | lines
      | where ($it | str contains "nu")
      | first

  assert str contains $shell "/nu"
}

def "test app install cache is cleared for containers" [] {
  let distro = cat /etc/os-release
      | lines
      | parse "{key}={value}"
      | where $it.key == "ID"
      | get value
      | first

  match $distro {
    'alpine' => { assert equal (ls /var/cache/apk) [] }
    'debian' => { assert equal (ls /var/cache/apt) [] }
    'ubuntu' => { assert equal (ls /var/cache/apt) [] }
    _ => {}  # Ignore other distributions
  }
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
