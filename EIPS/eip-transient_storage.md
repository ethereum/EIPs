---
eip: <to be assigned>
title: Transient storage opcodes
author: Alexey Akhunov (@AlexeyAkhunov)
discussions-to: https://ethereum-magicians.org/t/eip-transient-storage-opcodes/553
status: Draft
type: Standards Track
category Core
created: 2018-06-15
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Support for efficient transient storage in EVM. It is like regular storage (SLOAD/SSTORE), but with the lifetime limited to one Ethereum transaction.
Notable use case is efficient reentrancy lock.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
This proposal introduces transient storage, which behaves similar to storage,
but the updates will only persist within one Ethereum transaction. Transient storage is accessible to smart contracts via new opcodes: TLOAD and TSTORE (“T” stands for Transient).

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Running a transaction in Ethereum can generate multiple nested frames of execution, each created by CALL (or similar) instructions.
Contracts can be re-entered during the same transaction, in which case there are more than one frame belonging to one contract.
Currently, these frames can communicate in two ways - via inputs/outputs passed via CALL instructions, and via storage updates.
If there is an intermediate frame belonging to another contract, communication via inputs/outputs is not secure. Notable example is a reentrancy lock which cannot rely on the intermediate frame to pass through the state of the lock.
Communication via storage (SSTORE/SLOAD) is costly. Transient storage is a dedicated and gas efficient solution to the problem of inter frame communication.

Language support could be added in relatively easy way. For example, in Solidity, a qualifier “transient” can be introduced (similar to the existing qualifiers “memory” and “storage”). Since addressing scheme of TSTORE and TLOAD is the same as for SSTORE and SLOAD, code generation routines that exist for storage variables, can be easily generalised to also support transient storage.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
Two new opcodes are added to EVM, TLOAD and TSTORE.

They use the same arguments on stack as SLOAD and SSTORE.

TLOAD pops one 32-byte word from the top of the stack, treats this value as the address, fetches 32-byte word from the transient storage at that address, and pops the value on top of the stack.

TSTORE pops two 32-byte words from the top of the stack. The word on the top is the address, and the next is the value. TSTORE saves the value at the given address in the transient storage.

Addressing is the same as SLOAD and SSTORE. i.e. each 32-byte address points to a unique 32-byte word.

Gas cost for both is 8 units of gas, regardless of values stored.

The effects of transient storage are discarded at the end of transactions.


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
There is a proposal to alleviate the cost of inter-frame communication by reducing the cost of SSTORE when it modifies the same item multiple times within the same transaction (EIP-1087).

Relative cons of the transient storage: new opcodes; new code in the clients; new concept for the yellow paper (more to update); requires separation of concerns (persistence and inter-frame communication) when programming.

Relative pros of the transient storage:  cheaper to use; does not change the semantics of the existing operations; very simple gas accounting rules;

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
This EIP requires a hard fork to implement.

Since this EIP does not change semantics of any existing opcodes, it does not pose risk of backwards incompatibility for existing deployed contracts.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
TBD

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Most straightforward implementation would be a dictionary (map), similar to what exists for the ‘dirty’ storage, with the difference that it gets re-initialised at the start of each transaction, and does not get persisted.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
