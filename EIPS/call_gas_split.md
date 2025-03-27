---
title: CALL_GAS_SPLIT - Setting gas split portion for EOF calls
description: Opcode that allows splitting gas sent to calls
author: Dragan Rakita (@rakita)
discussions-to: <URL>
status: Draft
type: Standard Track 
created: 2025-03-25
---

## Abstract

This EIP introduces a new instruction that allows EOF contracts to control the portion of gas forwarded to callees without exposing exact gas values.

## Motivation

With the introduction of revamped CALL instructions in [EIP-7069](./eip-7069.md), direct gas limiting for calls is no longer possible. However, there are legitimate use cases where limiting the gas forwarded to callees is necessary.

This EIP addresses this need by allowing contracts to specify a percentage of available gas to be forwarded, without exposing exact gas amounts. This maintains the benefits of gas non-observability while providing necessary control.

A key problem with always forwarding all available gas is that a malicious callee could consume all gas during execution (even in case of a revert), potentially causing denial of service. By allowing the caller to restrict the forwarded gas to a specific portion, this risk can be mitigated.

By default, the gas split is set to `63/64` to match the existing behavior defined in [EIP-150](./eip-150.md).

With future multidimensional gas models, this instruction could potentially restrict all gas types.

## Specification

A new instruction `CALL_GAS_SPLIT` is introduced. This instruction:

1. Pops one item from the stack representing a gas split ratio.
2. Floors this value to `65535` (u16::MAX).
3. Calculates the gas limit by using the **current** gas by spliting it by floored value as `split_gas=(gas*value)/65535`.And preserves this value until the end of the call. 
4. The preserved value should be used in all EXT*CALL operations to set gas limit as `max(split_gas, gas_left)`.

If this value is not set, the EVM interpreter MUST maintain the `63/64` rule that was previously used as default.

## Rationale

Several alternatives were considered for implementing gas split functionality:

Adding gas split parameters directly to `EXT*` call instructions: While possible, this would require setting the split for each call individually. Having a standalone instruction allows setting the split once for multiple calls.

Hardcoding the gas split value as immediate: This would be restrictive for dynamic scenarios where the number of calls is only known at runtime.

Using a stack item for `CALL_GAS_SPLIT`: This approach was chosen as it provides the most flexibility, allowing dynamic adjustment of the gas split ratio.

Flooring popped value allows `push 0xffff, CALL_GAS_SPLIT` to be used to set full gas forwarding and 65535 parts seems big enought.

An alternative to using current gas for a split when `CALL_GAS_SPLIT` is called would be to split current gas when EXT*CALL is used. This alternative would make gas inconsistent and dependent on the amount of gas that was used. The chosen approach gives the benefit of using the same gas limit.

## Backwards Compatibility

This EIP is fully backward compatible if the opcode is not used and will not disrupt other instructions. State tests should be created to verify this.

## Security Considerations

The introduction of `CALL_GAS_SPLIT` allows contracts to limit the gas forwarded to callees, which can help prevent certain denial-of-service attacks. However, setting the gas split too low might prevent legitimate callees from completing their execution.

Implementations must ensure that the gas calculation does not overflow, especially when using 64-bit integers in testing environments.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
