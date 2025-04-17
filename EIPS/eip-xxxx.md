---
eip: xxxx
title: RLP Block Size Limit
description: Introduce a protocol-level cap on the maximum RLP-encoded block size to 10 MB.
author: Giulio Rebuffo (@Giulio2002)
discussions-to: https://ethereum-magicians.org/t/eip-7826-rlp-block-size-limit/21849
status: Draft
type: Standards Track
category: Core
created: 2025-04-16
---

## Abstract

This proposal introduces a protocol-level cap on the maximum RLP-encoded block size to 10 megabytes (MB) to facilitate predictable validation and propagation of Ethereum blocks.

## Motivation

Currently, Ethereum does not enforce a strict upper limit on the encoded size of blocks. This lack of constraint can result in:

1. **Network Instability**: Extremely large blocks slow down propagation and increase the risk of temporary forks and reorgs.
3. **DoS Risks**: Malicious actors could generate exceptionally large blocks to disrupt network performance.

Additionally, blocks exceeding 10 MB are not propagated by the consensus layer's (CL) gossip protocol, potentially causing network fragmentation or denial-of-service (DoS) conditions.

By imposing a protocol-level limit on the RLP-encoded block size, Ethereum can ensure Enhanced resilience against targeted attacks on block validation times.

Therefore, this EIP proposes a maximum RLP-encoded block size of 10 MB, which is consistent with the current block size dynamics and the limitations of the Ethereum consensus layer, this way increase block size limits is safer.

## Specification

### Block Size Cap

- Introduce a constant `MAX_RLP_BLOCK_SIZE` set to **10 MB (10,485,760 bytes)**.
- Any RLP-encoded block exceeding `MAX_RLP_BLOCK_SIZE` must be considered invalid.

Thus add the following check to the Ethereum protocol:
```python
# if true, the block is invalid and should be rejected/not get built
def exceed_max_rlp_block_size(block: Block) -> bool:
    return len(rlp.encode(block)) > MAX_RLP_BLOCK_SIZE
```

### Changes to Protocol Behavior

1. **Block Creation**: Validators must ensure the total RLP-encoded size of any produced block does not exceed `MAX_RLP_BLOCK_SIZE`.
2. **Block Validation**: Nodes must reject blocks whose RLP-encoded size exceeds `MAX_RLP_BLOCK_SIZE`.

### Protocol Adjustment

- All Ethereum client implementations must integrate this size check as part of block validation and propagation.
- This limit applies independently of gas-related metrics.

## Rationale

### Why 10 MB?

A cap of 10 MB aligns with the gossip protocol constraint in Ethereum's consensus layer (CL), ensuring compatibility and consistent block propagation across the network. Blocks larger than 10 MB will not be broadcast by the CL, which could lead to network fragmentation or denial-of-service scenarios.

## Backwards Compatibility

This change is **not backward-compatible** with any blocks larger than the newly specified size limit. Validators and miners will need to ensure their block construction logic strictly respects this limit.

## Security Considerations

1. **Enhanced DoS Mitigation**: Restricting maximum block size provides inherent protection against deliberate oversized-block attacks.
2. **Predictable Validation**: More consistent block sizes streamline validation and synchronization, strengthening the network's resilience and decentralization.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).

