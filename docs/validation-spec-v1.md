# EIP/ERC Validation Specification v1

## Status

This document defines the repository-neutral validation contract for EIP and ERC proposals. It is versioned independently from GitHub Actions. A validator implementation MUST report the specification version and validator version in its machine-readable output.

## Inputs

A validation run consists of:

- `source`: one or more proposal files or directories.
- `commit`: the exact Git commit being validated. The reference verifier requires the checked-out `HEAD` to equal this value.
- `rules`: the reviewed rule configuration identified by its SHA-256 digest. For this repository the initial source is `config/eipw.toml`.
- `validator`: the pinned eipw release, initially `0.11.0`.
- `repository_kind`: `eip` or `erc`; this identifies the document family, not an author or special exception.

A validator MUST NOT require GitHub credentials, network APIs, webhooks, proprietary services, or a particular CI platform to validate a source tree.

## Rules

The initial rules are the public default eipw lints at v0.11.0 plus the reviewed repository rule configuration. Rules include:

- proposal preamble structure, ordering, types, dates, statuses, references, and required fields;
- Markdown heading, section, link, spelling, HTML, and citation constraints;
- dependency and status consistency for `requires`;
- filename and proposal-number consistency; and
- repository-specific rule differences expressed in configuration, never author, organization, or favored-implementation exceptions.

Rule changes MUST be made through a reviewed versioned configuration change. A rule change MUST include a decision record, updated vectors, and a compatibility note. Historical rule versions MUST remain available so an old commit can be reproduced.

## Result semantics

A run is:

- `pass` when every requested source satisfies every enabled rule;
- `fail` when one or more errors are found;
- `error` when the verifier cannot load the validator, rules, source, or requested commit.

Warnings MAY be reported with `pass`, but MUST NOT be silently discarded. Each diagnostic SHOULD include a stable rule identifier, source path, line and column when available, severity, and actionable message.

## Machine-readable report

The reference verifier emits JSON with this shape:

```json
{
  "schema": "eip-validation-report-1",
  "specification": "eip-validation-v1",
  "validator": {"name": "eipw", "version": "0.11.0"},
  "rules": {"path": "config/eipw.toml", "sha256": "..."},
  "input": {"commit": "...", "repository_kind": "eip", "sources": ["..."]},
  "result": "pass",
  "exit_code": 0,
  "diagnostics": []
}
```

The JSON is deterministic apart from the input commit and source paths: keys are stable, sources are sorted, and diagnostics preserve validator order. A failed validation MUST still produce a report. An infrastructure error MUST produce `result: error` and a non-zero exit code.

## Reference implementation

Install the pinned public validator without GitHub Actions:

```sh
cargo install eipw --version 0.11.0 --locked
```

Run the repository reference verifier from a checked-out commit:

```sh
./scripts/verify-eip --commit "$(git rev-parse HEAD)" --source EIPS/eip-1.md --report validation.json
```

The verifier checks that `HEAD` matches `--commit`, hashes the rule file, invokes `eipw --format json`, and writes the report. CI MUST invoke this same interface. A user can therefore reproduce a CI decision from the commit, validator version, rule digest, and source list alone.

## Neutrality and exceptions

The rules apply uniformly to every proposal. Differences between EIP and ERC documents MUST be represented by a reviewed `repository_kind` or data configuration, not workflow conditionals keyed to people, organizations, proposal numbers, or expected outcomes.

Temporary exceptions MUST be recorded in a version-controlled decision record with an owner, scope, expiry, reason, and replacement plan. An exception MUST NOT change the validator result invisibly.

## Independent implementations

A second implementation MAY be written in another language, but it MUST consume this specification and the public vectors. Both implementations MUST run the same vector suite. Disagreement is a specification or implementation defect and requires a recorded resolution; neither implementation silently becomes authoritative.

## Reproducibility and availability

The specification, rule files, validator source/version, vectors, and reports MUST be mirrorable from Git. The local verifier MUST work offline after the validator and dependencies are installed. CI is an execution environment, not part of the validation rules.
