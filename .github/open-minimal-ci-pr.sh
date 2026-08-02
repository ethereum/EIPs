#!/usr/bin/env bash
set -euo pipefail

repo="ethereum/EIPs"
base_branch="master"
source_branch=""
new_branch=""
create_pr=true

files=(
  ".github/workflows/ci.yml"
  ".github/workflows/post-ci.yml"
  ".github/workflows/auto-review-trigger.yml"
  ".github/actions/merge-repos/action.yml"
  ".github/CODEOWNERS"
)

usage() {
  cat <<'EOF'
Usage: .github/open-minimal-ci-pr.sh [options]

Create a minimal CI-only branch from the repository default base and optionally open a PR.

Options:
  --source <branch>      Source branch to copy minimal files from. Default: current branch.
  --base <branch>        Base branch to branch from. Default: master.
  --new-branch <name>    Name for the new branch. Default: ci/minimal-<timestamp>.
  --repo <owner/name>    Upstream repo for PR creation. Default: ethereum/EIPs.
  --no-pr                Do not create a PR automatically.
  --help                 Show this help message.

Examples:
  .github/open-minimal-ci-pr.sh --source fix/htmlproofer-pages-assets
  .github/open-minimal-ci-pr.sh --source my/stack --new-branch ci/minimal-my-stack --no-pr
EOF
}

die() {
  printf '[open-minimal-ci-pr] %s\n' "$*" >&2
  exit 1
}

log() {
  printf '[open-minimal-ci-pr] %s\n' "$*"
}

require_clean_tree() {
  if [[ -n "$(git status --porcelain)" ]]; then
    die "working tree is not clean; commit or stash changes first"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source)
        [[ $# -ge 2 ]] || die "--source requires a value"
        source_branch="$2"
        shift
        ;;
      --base)
        [[ $# -ge 2 ]] || die "--base requires a value"
        base_branch="$2"
        shift
        ;;
      --new-branch)
        [[ $# -ge 2 ]] || die "--new-branch requires a value"
        new_branch="$2"
        shift
        ;;
      --repo)
        [[ $# -ge 2 ]] || die "--repo requires a value"
        repo="$2"
        shift
        ;;
      --no-pr)
        create_pr=false
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
    shift
  done
}

require_tools() {
  command -v git >/dev/null 2>&1 || die "git is required"
  if [[ "$create_pr" == true ]]; then
    command -v gh >/dev/null 2>&1 || die "gh is required for PR creation"
  fi
}

current_branch() {
  git rev-parse --abbrev-ref HEAD
}

default_new_branch() {
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  printf 'ci/minimal-%s' "$stamp"
}

ensure_source_branch() {
  if [[ -z "$source_branch" ]]; then
    source_branch="$(current_branch)"
  fi

  git rev-parse --verify "$source_branch" >/dev/null 2>&1 || die "source branch not found: $source_branch"
}

fetch_base() {
  log "fetching origin/$base_branch"
  git fetch origin "$base_branch"
}

create_branch_from_base() {
  if [[ -z "$new_branch" ]]; then
    new_branch="$(default_new_branch)"
  fi

  log "creating branch $new_branch from origin/$base_branch"
  git checkout -b "$new_branch" "origin/$base_branch"
}

copy_minimal_files() {
  log "copying minimal CI files from $source_branch"
  git checkout "$source_branch" -- "${files[@]}"
}

commit_changes() {
  if git diff --quiet -- "${files[@]}"; then
    die "no changes detected in minimal file set; nothing to commit"
  fi

  git add "${files[@]}"
  git commit -m "ci: minimal stack for htmlproofer, artifact flow, and editor routing"
}

push_branch() {
  log "pushing $new_branch"
  git push -u origin "$new_branch"
}

open_pr() {
  local owner
  owner="$(gh api user --jq '.login')"

  local body
  body=$(cat <<'EOF'
## Summary
- harden HTMLProofer scope/fallback logic and keep Pages-prefixed asset normalization
- replace deprecated artifact download usage in post-ci with compatibility handling
- remove obsolete artifact handoff from auto-review trigger
- route workflow file ownership to human editors in CODEOWNERS
- retain ERC-7730 Liquid delimiter escape handling in merge-repos action

## Why this minimal PR
This carries only the essential CI workflow fixes to reduce review friction and unblock merge.
EOF
)

  log "creating PR in $repo"
  gh pr create \
    --repo "$repo" \
    --base "$base_branch" \
    --head "$owner:$new_branch" \
    --title "CI: minimal stack to unblock htmlproofer and artifact flow" \
    --body "$body"
}

main() {
  parse_args "$@"
  require_tools
  require_clean_tree
  ensure_source_branch
  fetch_base
  create_branch_from_base
  copy_minimal_files
  commit_changes
  push_branch

  if [[ "$create_pr" == true ]]; then
    open_pr
  else
    log "skipped PR creation (--no-pr set)"
  fi

  log "done"
}

main "$@"