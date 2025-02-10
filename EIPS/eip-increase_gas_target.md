---
title: Increase Gas Utilization Target
description: Increase the gas utilization target from 50% to 75%
author: Storm Slivkoff (@sslivkoff)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2025-02-10
requires: <1559>
---

## Abstract

This proposal changes the gas utilization target from 50% to 75%. This will increase mean network throughput without increasing the worst case resource utilization for Denial of Service (DoS) attacks.

## Motivation

The current parameterization of [EIP-1559](./eip-1559.md) creates a large separation between Ethereum’s average computational load and its worst case computational load. The gas utilization target is defined as 50% of the gas limit, currently 18M gas and 36M gas respectively. This relationship amplifies the worst case load to always be at least twice as large as the average load. This forces the network to accommodate burstier loads and overprovision by an extra factor of two.

Closing the gap between the average case and worst case will improve the efficiency, scalability, safety of the network.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

Increase the gas target from 50% to 75% of the block gas limit.

The base fee update rule is:
`b_new = b_old * (1 + f(gas_used_old))`

[EIP-1559](./eip-1559.md) currently specifies:
- `gas_target = 0.5 * gas_limit`
- `f(gas_used_old) = (1 / 8) * (gas_used_old - gas_target) / gas_target`

Change these functions to:
- `gas_target = 0.75 * gas_limit`
- `f(gas_used_old) = slope * (gas_used_old - gas_target) / gas_target`
    - if `gas_used_old <= gas_target`: `slope = 1 / 8`
    - if `gas_used_old >= gas_target`: `slope = 3 / 8`

## Rationale

Increasing the gas target from 50% to 75% would have the same effect on mean throughput as raising the gas limit from 36M to 54M. However, the gas target approach is much safer against DoS attacks because it does not increase the size of the worst case computational load.

It would be desirable to target an even higher level of utilization than 75%. However, [EIP-1559](./eip-1559.md) requires that utilization must be able to freely move above and below the gas target, in order for utilization to be a useful indicator of demand. Putting the target near 100% makes it difficult to use utilization as an indicator of demand.

The piecewise modification to the update rule is to maintain that base fee updates remain within the range [-12.5%, +12.5%]. Empirically, this range has proven effective, and maintaining this range should preserve current base fee dynamics as much as possible. This update rule still produces a linear output between -12.5% and 0%, and between 0% and +12.5%.

## Backwards Compatibility

No backward compatibility issues found.

## Security Considerations

This proposal does not increase the worst case load for node clients. This allows the network to scale more safely against the threat of DoS attacks.

This proposal does however come with a one-time increase in the average load that a node must be able to sustain at equilibrium. If this proposal is passed while maintaining the current gas limit, it will be important to ensure that nodes can sustain this increased average load. This is likely to already be the case, as nodes have been tested to resist DoS attacks at least twice the size of the current average load.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).

