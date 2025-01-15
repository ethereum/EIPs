---
eip: 7840
title: Add blob schedule to EL config files
description: Include a per-fork schedule of max and target blob counts in client configuration files
author: lightclient (@lightclient)
discussions-to: https://ethereum-magicians.org/t/add-blob-schedule-to-execution-client-configuration-files/22182
status: Review
type: Informational
created: 2024-12-12
---


## Abstract

Add a new object to client configuration files `blobSchedule` which lists the
target blob count per block and max blob count per block for each fork.

## Motivation

- ensure there is a way to dynamically adjust the target and max blob counts per
  block
- avoid complex handshake over engine API

## Specification

Extend the client configuration files with the object `blobSchedule` with the
following shape:

```json
"blobSchedule": {
  "cancun": {
    "target": 3,
    "max": 6
  },
  "prague": {
    "target": 6,
    "max": 9
  }
}
```

When there is no explicit configuration for the current fork, use the last
specified fork value. If no last value is specified, set both to zero.

## Rationale

Although maintaining the target and max blob only in the consensus client is
desirable, we acknowledge the reality that execution clients need these values
for various activities. For example, the `eth_feeHistory` RPC method returns a
field `blobGasUsedRatio` that does require the max, even though the core
protocol doesn't specifically need such value. Passing this value over the
engine API every block seem overkill so we believe a configuration value is a
good middle ground.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

No security considerations found.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
