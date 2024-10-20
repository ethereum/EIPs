---
title: `GAS2ETH` opcode
description: Introduces a new opcode, `GAS2ETH`, to convert gas/mana to ETH
author: Charles Cooper (@charles-cooper), Pascal Caversaccio (@pcaversaccio)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2024-08-13
requires: EIP-2929
---

## Abstract

This EIP introduces a new `GAS2ETH` opcode that enables the direct conversion of gas/mana into ether (ETH).

## Motivation

This EIP is based on the premise that smart contract authors and compiler teams should be compensated for their contributions. Moreover, their compensation should scale with the usage of their contracts. A widely used and popular contract offers significant value to its users through its functionality and to the network by driving demand for blockspace — Ethereum's _raison d'être_. This increased demand also benefits miners and validators, who are rewarded for executing these contracts.

Monetizing smart contracts in a scalable manner remains challenging at the time of this writing. This difficulty is evident from existence of many different monetization strategies employed across various smart contracts — ranging from fee structures to the issuance of tokens with "tokenomics" of varying levels of complexity.

Introducing the `GAS2ETH` opcode offers contract authors a new way to achieve their monetization objectives. By charging gas, they integrate with an established user experience that is both familiar and understood by users. The proposed instruction ensures that existing transaction creation and processing tools remain unchanged. Moreover, by charging gas, contract authors align economically with network activity; they benefit from higher compensation during periods of intense network usage and receive less when activity is low. This helps align the incentives of smart contract authors, validators, and the broader network.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

A new opcode is introduced, `GAS2ETH` (`0xFC`), which:

- Pops two values from the stack: `addr` then `gas_amount`. If there are fewer than two values on the stack, the calling context should fail with stack underflow.
- Deducts `gas_amount` from the current calling context.
- Computes `wei_val` by multiplying `gas_amount` by the current transaction context's `gas_price`.
- Endows the address `addr` with `wei_val` wei.
- If the gas cost of this opcode + `gas_amount` is greater than the available gas in the current calling context, the calling context should fail with "out-of-gas" and any state changes reverted.
- Pushes `wei_val` onto the stack.

Note that the transfer of `wei_val` to the given account cannot fail. In particular, the destination account code (if any) is not executed, or, if the account does not exist, the balance is still added to the given address `addr`.

The proposed cost of this opcode is similar to the recently proposed `PAY` opcode, but changing the base cost from `9000` to `2400`. That is:

- The base cost of this opcode is `2400`. This is priced so that invoking `GAS2ETH` on a cold account costs the same as a cold `SSTORE`.
- If `addr` is not the zero address, the [EIP-2929](./eip-2929.md) account access costs for `addr` (but NOT the current account) are also incurred: 100 gas for a warm account, 2600 gas for a cold account, and 25000 gas for a new account.
- If any of these costs are changed, the pricing for the `GAS2ETH` opcode must also be changed.

Note that the [`EXTCALL`](./eip-7069.md) EIP eliminates the extra gas cost for value transfer. If that proposal is accepted into the EVM, the pricing for `GAS2ETH` should be updated to commensurately reduce or remove the `2400` gas value transfer cost.

## Rationale

- `GAS2ETH` vs. pro-rata: The pro-rata model incentivizes inflating contract gas usage to artificially increase fees. In contrast, this proposal allows contract authors to charge their desired amount directly, eliminating the need for unnecessary gas consumption.
- Target address vs. simply increasing balance of the currently executing contract: Using a target address is more flexible, enabling contract authors to write more modular code and separate the concerns of fee collection from contract functionality. For instance, the contract may want to designate a specific recipient for fees without necessarily granting them direct withdrawal access.
- Charging gas instead of ETH: Charging ETH directly complicates the user experience and prevents contract authors from participate in fluctuations in gas demand directly.

## Backwards Compatibility

No backward compatibility issues found.

## Test Cases

TBD

## Reference Implementation

TBD

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
