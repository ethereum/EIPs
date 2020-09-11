---
eip: 2185
title: CREATELINK opcode
author: William Morriss (@wjmelements)
discussions-to: [Github PR](https://github.com/ethereum/EIPs/pull/2185)
status: Draft
type: Standards Track
category Core
created: 2019-07-09
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
A cheaper way to proliferate identical smart contracts.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
This EIP specifies a new opcode, `CREATELINK`, which creates a new contract matching the code of an existing address.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Hundreds of thousands of identical contracts are proliferating from contract factories.
Because they share the same immutable code, a node implementation could detect these identical contracts and share their storage similar to how hard-linked files share theirs.
New links require less storage than new code.
Therefore, empowering this design with an opcode will reduce the overhead of operating a node long-term.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
The opcode for `CREATELINK` is `0xf7`.
`CREATELINK` pops one word, the target address.
As with `BALANCE`, `EXTCODESIZE`, `EXTCODECOPY`, and `EXTCODEHASH`, the upper 12 bytes are zeroed.
A new account is created with code matching the account at the target address, and its address is pushed onto the stack.

In case the account does not exist or does not have code, the opcode is equivalent to a revert returning 32 bytes, the `OR` of `0xf7 << 31` and the non-existent account address.
For example, a call to a contract with code `0x3df7` would revert, returning data `0xf700000000000000000000000000000000000000000000000000000000000000` and the remaining gas.

The new account address is calulated the same way as in `CREATE`.

The gas cost of `CREATELINK` is 30000.

## Rationale
`0xf7` is in the middle of the `0xf_` series, "System Operations".
It borders two unassigned opcodes, which allows for there to be many or few `CREATE` and `LINK` operations.

No constructor code is called.
Few profilerated contracts require initialization, but for the ones that do, they could provide an initialization method that can only be called by the factory, and call it immediately after `CREATELINK`.

There are several alternatives to reverting when the target account has no code.
In comparison to `INVALID`, `REVERT` does not waste the additional gas, and would allow a caller to inspect the error.
Another alternative would be to not revert at all, and instead push onto the stack an invalid address: some number greater than or equal to `(1 << 160)`.
However, because the intent of `CREATELINK` will never be to check whether an account has code (`EXTCODEHASH` is the cheapest way to do that), nor to create an empty account, those cases are exceptional.
Most wallets estimate gas before issuing transactions; standardized revert data can help developers to diagnose the issue.
If the transaction did not revert automatically, a contract factory expecting itself to always work could cease to work but continue to waste gas quietly and automatically.
Treating these cases as exceptional reduces the amount of work to be wasted by the network.

With neither the built-in call frame nor the inserted code state, `CREATELINK` gas should be less than `CREATE`, currently 32000.
Its gas should also be greater than the refund of `SELFDESTRUCT`, currently 24000.
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
Calling contract `0x3df7` reverts, returning `0xf700000000000000000000000000000000000000000000000000000000000000` and consuming 300001 gas.

TODO add more test cases after specification undergoes more peer review.

## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
