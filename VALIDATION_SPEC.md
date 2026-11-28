# EIP/ERC Validation Specification

The canonical current validation contract is [EIP/ERC Validation Specification v1](docs/validation-spec-v1.md).

It defines the repository-neutral inputs, published rules, validator and rule versions, result semantics, JSON report schema, neutrality requirements, independent implementation expectations, and local reproducibility contract.

Public test vectors are maintained in [tests/validation/vectors.json](tests/validation/vectors.json). The reference command is:

```sh
cargo install eipw --version 0.11.0 --locked
./scripts/verify-eip --commit "$(git rev-parse HEAD)" --source EIPS/eip-1.md --report validation.json
```

CI integration must use this same interface after the eipw TOML configuration path is available outside the GitHub Action wrapper. Until that migration is complete, the existing `eipw-action` job remains the CI execution path and the local verifier is the independent reference path.
