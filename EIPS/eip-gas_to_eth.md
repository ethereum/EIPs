---
title: `GAS2ETH` opcode
description: Introduces a new opcode, `GAS2ETH`, to convert gas/mana to ETH
author: Charles Cooper (@charles-cooper)
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

This EIP is based on the premise that smart contract authors and compiler teams should be compensated for their contributions. Moreover, their compensation should scale with the usage of their contracts. A widely used and popular contract offers significant value to its users through its functionality and to the network by driving demand for blockspace — Ethereum's core purpose. Consequently, this increased demand also benefits miners and validators, who are rewarded for executing these contracts.

Monetizing smart contracts in a scalable manner remains a challenging task. This difficulty is evident from the diverse array of monetization strategies employed across various smart contracts — ranging from fee structures to the issuance of tokens with complex "tokenomics".

Introducing the `GAS2ETH` opcode offers contract authors a novel approach to achieving their monetization objectives. By leveraging gas/mana charges, they integrate smoothly with an established user experience that is both familiar and understood by users. The proposed instruction ensures that existing transaction creation and processing tools remain unchanged. Moreover, by charging gas/mana, contract authors align economically with network activity; they benefit from higher compensation during periods of intense network usage and receive less when activity is low. This alignment helps harmonize the incentives of smart contract authors, validators, and the broader network.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

A new opcode is introduced, `GAS2ETH` (`0x2f`), which:

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

- `GAS2ETH` vs. pro-rata: The pro-rata model incentivizes inflating contract gas usage to increase fees artificially. In contrast, this proposal empowers contract authors to charge their desired amount directly, eliminating the need for unnecessary gas consumption.
- Target address vs. increasing contract balance: Using a target address provides greater flexibility, enabling contract authors to write more modular code and separate the concerns of fee collection from contract functionality. This approach allows the contract to designate a specific recipient for fees without necessarily granting them direct withdrawal access. For instance, the contract may intentionally avoid including any mechanism for the fee recipient to withdraw funds directly, ensuring a clearer separation of roles and responsibilities.
- Charging gas instead of ETH: Charging ETH directly can complicate the user experience and prevents contract authors from benefiting directly from fluctuations in gas demand.

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
