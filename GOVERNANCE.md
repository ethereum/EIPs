# EIP Process Governance

## Automation boundary

Automated checks verify published, mechanically testable rules: schema, links, formatting, spelling, repository policy, and validator behavior. They do not decide technical acceptance, community consensus, editorial approval, implementation commitment, or Final status.

Human judgment remains responsible for specification quality, ecosystem need, tradeoffs, security, consensus, and editorial discretion. A green report is evidence that the declared checks passed, not a governance decision.

## Rule ownership

- The validation specification and rule configuration are maintained through reviewed repository changes.
- EIP-1 defines the proposal process and status transitions.
- Editors maintain editorial process decisions; authors and implementers own technical content.
- Exceptions require a version-controlled decision record containing scope, owner, reason, expiry, and replacement plan.

Rules apply uniformly. No workflow or validator condition may special-case an author, organization, proposal number, or favored implementation.

## Policy changes

A rule change must update the versioned validation specification, public vectors, compatibility notes, and machine-readable report contract. Historical validator versions and rule files remain available for reproducing old decisions.

See [VALIDATION_SPEC.md](VALIDATION_SPEC.md) for the validation contract and [CONTRIBUTING.md](CONTRIBUTING.md) for the contributor process.
