---
eip: <to be assigned>
title: EXTCLEAR Opcode For SELFDESTRUCTed contracts
author: William Morriss (@wjmelements)
discussions-to: https://ethereum-magicians.org/t/eip-2936-extclear-for-selfdestruct/4569
status: Draft
type: Standards Track
category: Core
created: 2020-09-03
replaces: 2751
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
`EXTCLEAR` Opcode For `SELFDESTRUCT`ed contracts

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Enable new opcode to clear storage for `SELFDESTRUCTED`ed contracts.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
`SELFDESTRUCT` complexity can be reduced by deferring state cleanup.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
`SELFDESTRUCT` is unnecessarily complex because it clears an unbounded amount of contract storage.
It is computationally expensive for nodes to track all of the storage used in every contract in case the contract `SELFDESTRUCT`s.
Further, contracts can be re-initialized using `CREATE2`, and then `SLOAD` prior storage.
Therefore, several ethereum clients do not clear storage at all, and just check if the contract was initiated since `SSTORE` during `SLOAD`.
Nobody expected `SELFDESTRUCT` and `CREATE2` to increase the cost of `SLOAD`.
Also, bugs in this implementation could split the network.

Instead this defers the time of storage cleanup, and leaves the storage in-place, which reduces the complexity of `SLOAD` and `SELFDESTRUCT`.

This empowers the `CREATE2` reincarnation proxy pattern by retaining storage during upgrade, which would otherwise have to be reset again.
An atomic reincarnation upgrade could clear a subset of storage during the upgrade, while the contract is destroyed, before reinstating it.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

After `FORK_BLOCK_NUM`, a new opcode, `EXTCLEAR`, is enabled at `0x5c` to clear storage for `SELFDESTRUCT`ed contracts.
`EXTCLEAR`:
* does not push any words onto the stack
* pops two words off the stack: the destroyed contract address and a storage address
* if the contract exists, charge the same gas cost as `EXTCODEHASH`
* otherwise, if the storage is zero, charge the same gas as `EXTCODEHASH` plus `SLOAD`
* otherwise, the destroyed contract's slot is reset to 0, charging the same gas as `EXTCODEHASH` and `SSTORE` when resetting storage, while also refunding the amount specified in `SSTORE`.

`SELFDESTRUCT` is modified to not clear contract storage.
This change also works retroactively: all prior destroyed contracts can be cleaned up.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
`0x5c` is available in the same range as `SSTORE` and `SLOAD`.

Opcode pricing is compatible with both EIP 2929 and 2200.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
A reincarnation upgrade mechanism that expects all internal storage to be cleared might break, but such an upgrade mechanism would allow adaptation to this new behavior.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
TODO

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Implementation is required on all major clients to add the opcode.

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
A reincarnated contract that does not expect its state to be cleared by malicious actors SHOULD reinitialize itself to avoid antagonistic `EXTCLEAR`.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
