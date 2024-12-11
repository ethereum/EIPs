---
eip: xxxx
title: Unified Network Configuration
description: Execution Layer to fetch network parameters from Consensus Layer
author: Barnabas Busa (@barnabasbusa), Parithosh Jayanthi (@parithosh), Toni Wahrstätter (@nerolation)
discussions-to:
status: Draft
type: Standards Track
category: Core
created: 2024-12-11
requires: N/A
---

## Abstract

This EIP proposes a protocol for the Execution Layer (EL) to fetch its configuration parameters from the Consensus Layer (CL) at startup. This eliminates duplicate configuration and ensures consistency between layers by making the CL the source of truth for network parameters.

## Motivation

Currently, many configuration parameters must be defined separately for both the Execution Layer and Consensus Layer. This creates several problems:

1. Configuration duplication increases the chance of inconsistencies between layers
2. Parameters that should be derived from each other (like max gas limit from blob counts) must be manually kept in sync
3. Fork schedules must be maintained in multiple places
4. Network upgrades require coordinating changes across multiple configuration files

By allowing the EL to fetch its configuration from the CL, we can:

1. Eliminate duplicate configuration
2. Ensure parameters stay in sync automatically
3. Simplify network upgrades by having a single source of truth
4. Reduce operator error from misconfiguration

## Specification

### Configuration API

The CL must implement a new API endpoint that returns a "one-off" configuration parameters for all post merge values:


| CL configuration values | EL configuration (geth style example) values |
| ----------------------- | -------------------------------------------- |
| `DEPOSIT_NETWORK_ID`    | `chainId`                                     |
| `BELLATRIX_FORK_EPOCH`  | `mergeNetsplitBlock`                          |
| `TERMINAL_TOTAL_DIFFICULTY` | `terminalTotalDifficulty`                 |
| `CAPELLA_FORK_EPOCH`    | `shanghaiTime`                                |
| `DENEB_FORK_EPOCH`      | `cancunTime`                                  |
| `ELECTRA_FORK_EPOCH`    | `pragueTime`                                  |
| `FULU_FORK_EPOCH`       | `osakaTime`                                   |
| `GOSSIP_MAX_SIZE`       | `gasLimit`                                    |

All legacy parameters pre merge may be dropped from the EL configuration to further simplify it.

Additional parameters can be added to the API as needed.
For example:

`GOSSIP_MAX_SIZE_ELECTRA` -> adjust max gas at fork transition only

`TARGET_BLOBS_PER_BLOCK_ELECTRA` -> target blobs adjustment per block at fork transition

`MAX_BLOBS_PER_BLOCK_ELECTRA` -> max blobs adjustment per block at fork transition

`GOSSIP_MAX_SIZE_FULU` -> adjust max gas at fork transition only

`TARGET_BLOBS_PER_BLOCK_FULU` -> target blobs adjustment per block at fork transition

`MAX_BLOBS_PER_BLOCK_FULU` -> max blobs adjustment per block at fork transition


### EL Startup Behavior

1. On startup, the EL must attempt to fetch configuration from the CL
2. The EL must retry with exponential backoff until successful
3. The EL must not start processing blocks until configuration is received
4. Configuration values must be validated before use

### Parameter Derivation

Some parameters must be calculated rather than directly copied:

1. Max gas limit must be derived from `gossip_max_size` according to [formula](#formula) instead of people individually setting it on their nodes.
2. Fork activation times must be converted from epoch numbers to timestamps for the EL to use.
3. Target and max blobs per blocks can be used to calculate


### Formula
Worst case scenario:

Max Gas limit = `gossip_max_size` * `cost of zero-byte calldata`

Max Gas limit = `10 * 2**20 * 4` == `41,943,040`

Suggested gas limit = `0.75 * Max Gas limit`

Node operators can set the gas limit to `0.9 * Max Gas limit`

Future fork examples:

Max Gas limit Osaka = `gossip_max_size_fulu * 4`

### Error Handling

1. If the CL is unreachable, the EL must continue retrying, and should not start processing blocks until configuration is received.
2. If received parameters are invalid, the EL must reject them and retry fetching configuration.
3. The EL may log all configuration related errors for debugging.
4. The EL may retry to fetch the configuration periodically. This would enable CL only changes to be triggered without needing to restart the EL.
## Rationale

This design:

1. Makes the CL's config.yaml the single source of truth for network configuration.
2. Allows for future extension of synchronized parameters.
3. Easily extendable to include new one-off parameters without passing constant parameters in the engine API.
4. Max Gas limit can be adjusted at fork transitions to ensure proper testing and validation before deployment.

The retry mechanism ensures the EL will eventually get configuration even if the CL is not immediately available at startup.

## Backwards Compatibility

This EIP is backwards compatible as clients can fall back to existing manual configuration if the CL does not implement the new API.

## Security Considerations

1. The EL must validate all received configuration values.
2. The connection between EL and CL must be authenticated.
3. Invalid configuration must not cause the EL to start with unsafe parameters.
4. The retry mechanism must not create DOS vectors.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).