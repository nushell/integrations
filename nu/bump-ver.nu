#!/usr/bin/env nu

# TODO:
#   - [√] Check if the tag of the specified version already exists in local git repository

export def bump-version [
  version: string,
  --revision: int = 0,  # Revision number for the version, default is 0
] {
  if not ($version | str replace -ar '^(\d+\.)?(\d+\.)?(\*|\d+)$' '' | is-empty) {
    print $'(ansi r)Invalid version number: ($version)(ansi reset)'
    exit 7
  }

  if (has-ref $'($version)-($revision)') {
    print $'(ansi r)The tag of the specified version already exists: ($version)(ansi reset)'
    exit 5
  }

  open meta.json
    | update version $version
    | update revision $revision
    | save -f meta.json
  git commit -am $'chore: bump version to ($version) of revision ($revision)'
  git tag -am $'chore: bump version to ($version)' $'($version)-($revision)'
  git push --follow-tags
}

# Check if a git repo has the specified ref: could be a branch or tag, etc.
export def has-ref [
  ref: string   # The git ref to check
] {
  let checkRepo = (do -i { git rev-parse --is-inside-work-tree } | complete)
  if not ($checkRepo.stdout =~ 'true') { return false }
  # Brackets were required here, or error will occur
  let parse = (do -i { git rev-parse --verify -q $ref } | complete)
  if ($parse.stdout | is-empty) { false } else { true }
}
