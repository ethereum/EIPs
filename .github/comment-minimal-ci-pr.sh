#!/usr/bin/env bash
set -euo pipefail

repo="ethereum/EIPs"
minimal_pr=""
dry_run=false
post_on_minimal=true

related_prs=(12018 12017 11923 11983 12016)

usage() {
  cat <<'EOF'
Usage: .github/comment-minimal-ci-pr.sh [options]

Post standardized "minimal PR" comments to related workflow-maintenance PRs.

Options:
  --minimal-pr <number>  The minimal PR number to recommend (required).
  --repo <owner/name>    Repository for related PRs. Default: ethereum/EIPs.
  --related <n1,n2,...>  Comma-separated related PR numbers. Overrides defaults.
  --no-minimal-comment   Do not post summary comment on the minimal PR itself.
  --dry-run              Print actions without posting comments.
  --help                 Show this help message.

Examples:
  .github/comment-minimal-ci-pr.sh --minimal-pr 12069
  .github/comment-minimal-ci-pr.sh --minimal-pr 12069 --related 12018,12017
EOF
}

die() {
  printf '[comment-minimal-ci-pr] %s\n' "$*" >&2
  exit 1
}

log() {
  printf '[comment-minimal-ci-pr] %s\n' "$*"
}

require_tools() {
  command -v gh >/dev/null 2>&1 || die "gh is required"
  command -v jq >/dev/null 2>&1 || die "jq is required"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --minimal-pr)
        [[ $# -ge 2 ]] || die "--minimal-pr requires a value"
        minimal_pr="$2"
        shift
        ;;
      --repo)
        [[ $# -ge 2 ]] || die "--repo requires a value"
        repo="$2"
        shift
        ;;
      --related)
        [[ $# -ge 2 ]] || die "--related requires a value"
        IFS=',' read -r -a related_prs <<< "$2"
        shift
        ;;
      --no-minimal-comment)
        post_on_minimal=false
        ;;
      --dry-run)
        dry_run=true
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

  [[ -n "$minimal_pr" ]] || die "--minimal-pr is required"
  [[ "$minimal_pr" =~ ^[0-9]+$ ]] || die "--minimal-pr must be a number"
}

repo_owner() {
  printf '%s' "${repo%%/*}"
}

repo_name() {
  printf '%s' "${repo##*/}"
}

pr_url() {
  local number="$1"
  printf 'https://github.com/%s/pull/%s' "$repo" "$number"
}

is_already_marked() {
  local number="$1"
  local marker="$2"
  local owner name
  owner="$(repo_owner)"
  name="$(repo_name)"

  gh api "repos/$owner/$name/issues/$number/comments" \
    --jq "map(select(.body | contains(\"$marker\"))) | length" | grep -q '^[1-9]'
}

post_comment() {
  local number="$1"
  local body="$2"
  local marker="$3"

  if is_already_marked "$number" "$marker"; then
    log "PR #$number already has marker $marker; skipping"
    return 0
  fi

  if [[ "$dry_run" == true ]]; then
    log "[dry-run] would comment on PR #$number"
    return 0
  fi

  gh pr comment "$number" --repo "$repo" --body "$body" >/dev/null
  log "commented on PR #$number"
}

comment_for_related() {
  local marker='<!-- minimal-ci-pr-supersede-note -->'
  local minimal_url
  minimal_url="$(pr_url "$minimal_pr")"
  cat <<EOF
$marker
Focused merge path available: #$minimal_pr

This companion PR keeps only the essential CI fixes with a smaller review surface:
- HTMLProofer hardening plus Pages-prefixed asset normalization
- post-CI artifact download modernization with compatibility handling
- removal of obsolete trigger artifact handoff
- workflow CODEOWNERS routing to editors

If preferred, we can merge #$minimal_pr first and close larger stacked PRs as superseded.

$minimal_url
EOF
}

comment_for_minimal() {
  local marker='<!-- minimal-ci-pr-crosslink-note -->'
  local links=""
  local pr

  for pr in "${related_prs[@]}"; do
    links+="- #$pr ($(pr_url "$pr"))\n"
  done

  cat <<EOF
$marker
Cross-link summary for maintainers:

This PR is a minimal, merge-focused alternative to related workflow-maintenance PRs:
$links

Goal: land essential CI stabilization with reduced review friction.
EOF
}

main() {
  parse_args "$@"
  require_tools

  local related_body minimal_body pr
  related_body="$(comment_for_related)"

  for pr in "${related_prs[@]}"; do
    [[ "$pr" =~ ^[0-9]+$ ]] || die "invalid PR number in --related: $pr"
    post_comment "$pr" "$related_body" "<!-- minimal-ci-pr-supersede-note -->"
  done

  if [[ "$post_on_minimal" == true ]]; then
    minimal_body="$(comment_for_minimal)"
    post_comment "$minimal_pr" "$minimal_body" "<!-- minimal-ci-pr-crosslink-note -->"
  fi

  log "done"
}

main "$@"