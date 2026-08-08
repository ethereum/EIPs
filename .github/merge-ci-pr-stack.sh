#!/usr/bin/env bash
set -euo pipefail

repo="ethereum/EIPs"
gate_pr=12017
final_pr=12018
obsolete_prs=(12016 11923 11983)
reviewers=(g11tech jochem-brouwer lightclient SamWilsn xinbenlv)

dry_run=false
wait_for_merge=false
refresh_final_branch=true
default_branch=""
check_access_only=false

usage() {
  cat <<'EOF'
Usage: .github/merge-ci-pr-stack.sh [options]

Coordinate the workflow-maintenance PR stack for ethereum/EIPs:
1. Request human editor reviews on PR 12017 and enable auto-merge.
2. Optionally wait for PR 12017 to merge.
3. Refresh PR 12018's branch on the repository default branch.
4. Request human editor reviews on PR 12018 and enable auto-merge.
5. Optionally wait for PR 12018 to merge.
6. Close PRs 12016, 11923, and 11983 as superseded once PR 12018 is merged.

Options:
  --dry-run              Print actions without mutating GitHub or git state.
  --wait                 Wait for each auto-merge step to complete.
  --no-refresh           Skip rebasing the PR 12018 branch on origin/master.
  --repo <owner/name>    Override the target repository. Default: ethereum/EIPs
  --base-branch <name>   Override the branch used for refresh/rebase.
  --check-access         Only validate GitHub access/permissions and exit.
  --help                 Show this message.
EOF
}

log() {
  printf '[merge-ci-pr-stack] %s\n' "$*"
}

die() {
  printf '[merge-ci-pr-stack] %s\n' "$*" >&2
  exit 1
}

run() {
  if [[ "$dry_run" == true ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_tools() {
  local tool

  for tool in gh git jq; do
    have_cmd "$tool" || die "missing required tool: $tool"
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run=true
        ;;
      --wait)
        wait_for_merge=true
        ;;
      --no-refresh)
        refresh_final_branch=false
        ;;
      --repo)
        [[ $# -ge 2 ]] || die "--repo requires a value"
        repo="$2"
        shift
        ;;
      --base-branch)
        [[ $# -ge 2 ]] || die "--base-branch requires a value"
        default_branch="$2"
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      --check-access)
        check_access_only=true
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
    shift
  done
}

ensure_repo_root() {
  local root
  root="$(git rev-parse --show-toplevel)"
  cd "$root"
}

gh_auth_info() {
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated"
}

repo_owner() {
  printf '%s' "${repo%%/*}"
}

repo_name() {
  printf '%s' "${repo##*/}"
}

run_gh() {
  local output

  if [[ "$dry_run" == true ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
    return 0
  fi

  if ! output="$($@ 2>&1)"; then
    if printf '%s' "$output" | grep -q "Resource not accessible by integration"; then
      die "GitHub token cannot modify $repo (resource not accessible by integration). Use a maintainer-authenticated gh session or PAT with repo/PR write permissions."
    fi
    printf '%s\n' "$output" >&2
    return 1
  fi

  if [[ -n "$output" ]]; then
    printf '%s\n' "$output"
  fi
}

check_repo_access() {
  local permission
  local owner
  local name

  owner="$(repo_owner)"
  name="$(repo_name)"

  permission="$(gh api graphql \
    -f query='query($owner:String!, $name:String!){ repository(owner:$owner,name:$name){ viewerPermission }}' \
    -f owner="$owner" \
    -f name="$name" \
    --jq '.data.repository.viewerPermission' 2>/dev/null || true)"

  if [[ -z "$permission" || "$permission" == "null" ]]; then
    log "unable to determine viewerPermission for $repo; continuing with runtime checks"
    return 0
  fi

  log "viewerPermission on $repo: $permission"
  case "$permission" in
    ADMIN|MAINTAIN|WRITE)
      return 0
      ;;
    *)
      if [[ "$dry_run" == true && "$check_access_only" != true ]]; then
        log "read-only permission ($permission); continuing because --dry-run was requested"
        return 0
      fi
      die "insufficient GitHub permission ($permission) for reviewer/comment/close actions on $repo"
      ;;
  esac
}

resolve_default_branch() {
  if [[ -n "$default_branch" ]]; then
    return 0
  fi

  default_branch="$(gh repo view "$repo" --json defaultBranchRef --jq '.defaultBranchRef.name')"
  [[ -n "$default_branch" ]] || die "unable to resolve default branch for $repo"
}

pr_json() {
  gh pr view "$1" --repo "$repo" --json state,mergedAt,headRefName,reviewDecision,reviewRequests,title,isDraft
}

pr_state() {
  pr_json "$1" | jq -r 'if .mergedAt then "MERGED" else .state end'
}

pr_is_merged() {
  [[ "$(pr_state "$1")" == "MERGED" ]]
}

pr_is_closed_unmerged() {
  [[ "$(pr_state "$1")" == "CLOSED" ]]
}

pr_head_ref() {
  pr_json "$1" | jq -r '.headRefName'
}

print_pr_summary() {
  local pr="$1"

  log "PR $pr"
  pr_json "$pr" | jq '{title, draft: .isDraft, reviewDecision, reviewRequests: [.reviewRequests[].login], state: (if .mergedAt then "MERGED" else .state end), headRefName}'
}

request_reviewers() {
  local pr="$1"
  local reviewer
  local args=()

  for reviewer in "${reviewers[@]}"; do
    args+=(--add-reviewer "$reviewer")
  done

  log "requesting human reviewers on PR $pr"
  if ! run_gh gh pr edit "$pr" --repo "$repo" --remove-reviewer eth-bot "${args[@]}"; then
    die "failed to request reviewers on PR $pr (likely missing maintainer permissions on $repo)"
  fi
}

enable_auto_merge() {
  local pr="$1"

  log "enabling auto-merge on PR $pr"
  if ! run_gh gh pr merge "$pr" --repo "$repo" --merge --auto; then
    die "failed to enable auto-merge on PR $pr (branch protection/permissions may block this)"
  fi
}

wait_until_merged() {
  local pr="$1"
  local attempt=1
  local max_attempts=40
  local state

  if [[ "$dry_run" == true ]]; then
    log "would wait for PR $pr to merge"
    return 0
  fi

  while [[ $attempt -le $max_attempts ]]; do
    state="$(pr_state "$pr")"
    log "PR $pr state: $state ($attempt/$max_attempts)"

    if [[ "$state" == "MERGED" ]]; then
      return 0
    fi

    if [[ "$state" == "CLOSED" ]]; then
      die "PR $pr was closed without merging"
    fi

    attempt=$((attempt + 1))
    sleep 15
  done

  die "timed out waiting for PR $pr to merge"
}

refresh_branch() {
  local pr="$1"
  local branch

  branch="$(pr_head_ref "$pr")"
  log "refreshing branch $branch for PR $pr"

  run git fetch origin

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    run git checkout "$branch"
  else
    run git checkout -b "$branch" "origin/$branch"
  fi

  run git rebase "origin/$default_branch"
  run git push --force-with-lease origin "$branch"
}

close_superseded_prs() {
  local pr

  if ! pr_is_merged "$final_pr"; then
    log "PR $final_pr is not merged yet; leaving superseded PRs open"
    return 0
  fi

  for pr in "${obsolete_prs[@]}"; do
    if pr_is_merged "$pr"; then
      log "PR $pr is already merged; skipping close"
      continue
    fi

    if pr_is_closed_unmerged "$pr"; then
      log "PR $pr is already closed; skipping close"
      continue
    fi

    log "closing superseded PR $pr"
    if ! run_gh gh pr close "$pr" --repo "$repo" --comment "Superseded by #$gate_pr and #$final_pr. The reviewer-routing fix landed in #$gate_pr, and the consolidated CI/workflow changes landed in #$final_pr."; then
      die "failed to close superseded PR $pr (missing permissions on $repo)"
    fi
  done
}

merge_pr_in_order() {
  local pr="$1"

  if pr_is_merged "$pr"; then
    log "PR $pr is already merged"
    return 0
  fi

  if pr_is_closed_unmerged "$pr"; then
    die "PR $pr is closed and unmerged; cannot continue this merge sequence"
  fi

  request_reviewers "$pr"
  enable_auto_merge "$pr"

  if [[ "$wait_for_merge" == true ]]; then
    wait_until_merged "$pr"
  fi
}

main() {
  parse_args "$@"
  require_tools
  gh_auth_info
  check_repo_access
  resolve_default_branch
  ensure_repo_root

  if [[ "$check_access_only" == true ]]; then
    log "access check passed for $repo"
    return 0
  fi

  log "mode: $([[ "$dry_run" == true ]] && echo dry-run || echo live), base branch: $default_branch"
  print_pr_summary "$gate_pr"
  print_pr_summary "$final_pr"

  merge_pr_in_order "$gate_pr"

  if ! pr_is_merged "$gate_pr"; then
    log "PR $gate_pr must merge before any PR $final_pr actions; rerun later or use --wait"
    return 0
  fi

  if [[ "$refresh_final_branch" == true ]] && ! pr_is_merged "$final_pr"; then
    refresh_branch "$final_pr"
  fi

  merge_pr_in_order "$final_pr"
  close_superseded_prs
}

main "$@"