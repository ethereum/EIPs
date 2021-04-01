---
eip: <to be assigned>
title: SUDO Opcode
author: William Morriss (@wjmelements)
discussions-to: <URL>
status: Draft
type: Standards Track
category Core
created: 2021-04-01
---

## Simple Summary
A new opcode is introduced to allow calling from an arbitrary sender address.

## Abstract
A new opcode, `SUDO`, is introduced with the same parameters as `CALL`, plus another parameter to specify the sender address.

## Motivation
There are many use cases for being able to set the sender.
Many tokens are stuck irretrievably because nobody has the key for the owner address.
In particular, at address zero there is approximately 17 billion USD in tokens and ether according to [etherscan](https://etherscan.io/address/0x0000000000000000000000000000000000000000).
With `SUDO`, anyone could free that value, leading to an economic boom that would end poverty and world hunger.
Instead it is sitting there idle like the gold in Fort Knox.
`SUDO` fixes this.

It is a common mistake to send ERC20 tokens to the token address instead of the intended recipient.
This happens because users paste the token address into the recipient fields.
Currently there is no way to recover these tokens.
`SUDO` fixes this.

Many scammers have received ETH via trust-trading.
Their victims currently have no way to recover their funds.
`SUDO` fixes this.


## Specification
Adds a new opcode (`SUDO`) at `0xf8`.
`SUDO` pops 8 parameters from the stack.
Besides the sender parameter, the parameters shall match `CALL`.

1. Gas: Integer; Gas allowance for message call
2. Sender: Address, truncated to lower 40 bytes; Sets `CALLER` inside the call frame
3. To: Address, truncated to lower 40 bytes; sets `ADDRESS`
4. Value: Integer, raises exception amount specified is less than the value in Sender account; transferred with call to recipient balance, sets `CALLVALUE`
5. InStart: Integer; beginning of memory to use for `CALLDATA`
6. InSize: Integer; beginning of memory to use for `CALLDATA`
7. OutStart: Integer; beginning of memory to replace with `RETURNDATA`
8. OutSize: Integer; maximum `RETURNDATA` to place in memory

Following execution, `SUDO` pushes a result value to the stack, indicating success or failure.
If the call ended with `STOP`, `RETURN`, or `SELFDESTRUCT`, `1` is pushed.
If the call ended with `REVERT`, `INVALID`, or an EVM assertion, `0` is pushed.

## Rationale
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

## Backwards Compatibility
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Reference Implementation
An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations
All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
