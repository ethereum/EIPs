# Validation and Security

## Local verification

Validation is designed to be independently reproducible without GitHub Actions, privileged tokens, or private services. Use the versioned [validation specification](VALIDATION_SPEC.md), [reference verifier](scripts/verify-eip), and public [test vectors](tests/validation/vectors.json).

## Workflow security

The repository continuously checks action pins, token permissions, checkout credential persistence, shell interpolation, artifact handoff behavior, and workflow syntax. See [SECURITY_IMPROVEMENT_PLAN.md](SECURITY_IMPROVEMENT_PLAN.md) and [SECURITY_MIGRATION_GUIDE.md](SECURITY_MIGRATION_GUIDE.md).

## Reporting

Do not include credentials in issues or pull requests. Report suspected workflow, validator, dependency, or publication security problems through the repository's established private security reporting channel when available. Until a private channel is confirmed, avoid public disclosure of exploitable details and contact repository maintainers through the documented project channels.

## Continuity

The rules, validator version, configuration, vectors, and reports should be mirrorable from Git. GitHub Actions is an execution environment and must not be the only way to validate a proposal.
