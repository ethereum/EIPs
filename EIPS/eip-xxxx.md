---
eip: xxxx
title: Limit blob count per transaction via blob schedule
description: 
author: Alexey Osipov (@flcl42)
discussions-to: 
status: Draft
type: Standards Track
category: Core
created: 2025-04-10
---

## Abstract

This EIP proposes adding a configurable limit to the number of blobs that can be included in a single transaction. This setting will be incorporated into the `blobSchedule`.

## Motivation

Limiting the number of blobs per transaction allows the transaction pool (txpool) to be scaled independently of consensus layer scaling.

## Specification

Extend `blobSchedule` section of client configuration files, with an additional optional field

```json
"blobSchedule": {
  ...
  "osaka": {
    "maxPerTx" : 6
  }
}
```

Clients must consider this setting when validating a blob transaction received from the network.
The limit applies during block building and validation too.

When the field is not present, a transaction can contain as many blobs as a block.

## Rationale

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

This change improves security by reducing the potential for resource exhaustion via very large blob transactions.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
