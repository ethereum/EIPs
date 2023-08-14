---
title: `GAS_TO_ETH` opcode
description: An opcode which converts gas to ETH
author: Charles Cooper (@charles-cooper)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2023-08-12
requires: EIP-2929
---

## Abstract

This EIP proposes a `GAS_TO_ETH` opcode which makes it possible to convert gas directly to ether.

## Motivation

This EIP begins from the supposition that smart contract authors should be allowed to be paid for their work. Furthermore, they should be able to paid in a way which scales with the usage of their contract - a contract which is popular and commonly used provides value to users in the form of functionality provided to users. It provides value to the network by increasing demand for blockspace (which is Ethereum's _raison d'être_), and by extension it provides value to miners/validators who are effectively getting paid to run contracts.

Currently, monetizing smart contracts in a scalable way is not easy. The fact that this is the case is demonstrated by the existence of many different monetisation methods across different smart contracts - from charging fees to launching tokens with "tokenomics" of varying levels of complexity.

Providing a `GAS_TO_ETH` opcode allows contract authors a new way to accomplish these goals. By charging gas, they tie-in to a standard UX that is already accepted and whose purpose is already well-understood by users. UX-related tooling around creating and sending transactions does not need to change. By charging gas, they additionally participate economically in network usage - by the very nature of gas pricing, they will be compensated more during times of heavy network usage and less during times of lighter network usage, further aligning the incentives of smart contract authors and validators and the broader network as a whole.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

A new opcode is introduced, `GAS_TO_ETH` (`0xfa`), which:

- Pops two values from the stack: `addr` then `gas_amount`. If there are fewer than two values on the stack, the calling context should fail with stack underflow.
- Deducts `gas_amount` from the current calling context.
- Computes `wei_val` by multiplying `gas_amount` by the current transaction context's `gas_price`.
- Endows the address `addr` with `wei_val` wei.
- If the gas cost of this opcode + `gas_amount` is greater than the available gas in the current calling context, the calling context should fail with 'out of gas' and any state changes reverted.
- Pushes `wei_val` onto the stack.

The proposed cost of this opcode is similar to the recently proposed `PAY` opcode, but changing the base cost from `9000` to `2400`. That is:

- The base cost of this opcode is `2400`. This is priced so that invoking `GAS_TO_ETH` on a cold account costs the same as a cold `SSTORE`.
- If `addr` is not the zero address, the [EIP-2929](./eip-2929.md) account access costs for `addr` (but NOT the current account) are also incurred: 100 gas for a warm account, 2600 gas for a cold account, and 25000 gas for a new account.
- If any of these costs are changed, the pricing for the `GAS_TO_ETH` opcode must also be changed.

Note that the `CALL2` EIP eliminates the extra gas cost for value transfer. If that proposal is accepted into the EVM, the pricing for `GAS_TO_ETH` should be updated to commensurately reduce or remove the `2400` gas value transfer cost.

## Rationale

- `gas_to_eth` vs pro-rata: pro-rata encourages needlessly 'fluffing' contract gas usage in order to increase fees - this proposal allows contract authors to charge the amount they want directly
- having target address vs just increasing balance of current contract - target address is much more flexible, allows contract authors to write more modular code and separate concerns of fee recipient vs contract code. For example, the contract may not have (and may not want to have) any way for the fee recipient to withdraw directly from the contract.
- charging gas instead of ether - does not play nice with UX, does not allow contract authors to participate in gas demand (directly).

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
