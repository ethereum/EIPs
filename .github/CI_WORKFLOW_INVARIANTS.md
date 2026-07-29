# CI Workflow Invariants and Failure Modes

This document defines the expected safety properties for workflow changes in this repository.

## Invariants

1. Validation must not silently disappear.
- If scoped checks cannot be computed safely, CI must fall back to full-site validation.

2. HTMLProofer optimizations must preserve correctness.
- Targeted checks are allowed only when rendered outputs are known and present.
- Missing or empty targeted scope must fall back to full-site validation.

3. Long-running validation should not be canceled by metadata-only PR events.
- Concurrency supersession should happen on new commits, not on non-code PR edits.

4. Cross-workflow artifact handoff must be explicit and resilient.
- Artifact producers and consumers must agree on artifact names.
- Compatibility windows can support both legacy and new names during migration.

5. CI failures should be actionable.
- Missing artifacts or invalid state should fail with explicit log messages.
- Runtime behavior should be visible in logs (selected scope, fallback reason).

## Failure-Mode Handling

| Failure mode | Expected behavior |
| --- | --- |
| Changed file scope cannot be computed | Run HTMLProofer on full `_site` |
| Targeted rendered outputs do not exist | Run HTMLProofer on full `_site` |
| Site-wide templates/assets changed | Run HTMLProofer on full `_site` |
| PR metadata edited while CI running | Keep current run; do not cancel |
| New commit pushed to PR | Supersede old run and execute latest |
| Artifact naming mismatch across workflows | Try compatibility path; fail clearly if no valid artifact is found |

## Determinism Notes

- HTMLProofer scope is derived from changed files, with strict fallback to full-site checks.
- ERC merge inputs are external repository content at run time; merge/rewrite steps must remain deterministic and explicit in workflow logs.
- Any temporary compatibility behavior should have clear removal criteria.

## Compatibility Cleanup Policy

Temporary compatibility logic (for example, legacy artifact names) should be removed when all conditions below are true:

1. The replacement path has been stable across recent workflow runs.
2. No active branches rely on the legacy path.
3. Removal is proposed in a dedicated cleanup PR with a brief rationale.

## Review Checklist for CI PRs

- Does this change preserve all invariants above?
- Are failure paths explicit and logged?
- Is there a safe full-validation fallback?
- Does concurrency behavior match event intent?
- If compatibility logic is added, is there a clear cleanup path?
