---
eip: <to be assigned>
title: Oracle Interface
author: Alan Lu (@cag)
status: Draft
type: Standards Track
category: ERC
created: 2018-06-13
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
A standard interface for oracles.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
In order for ethereum smart contracts to interact with off-chain systems, oracles must be used. These oracles report values which are normally off-chain, allowing smart contracts to react to the state of off-chain systems. A distinction and a choice is made between push and pull based oracle systems. Furthermore, a standard interface for oracles is described here, allowing different oracle implementations to be interchangeable.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
The Ethereum ecosystem currently has many different oracle implementations available, but they do not provide a unified interface. Smart contract systems would be locked into a single set of oracle implementations, or they would require developers to write adapters/ports specific to the oracle system chosen in a given project.

Beyond naming differences, there is also the issue of whether or not an oracle report-resolving transaction *pushes* state changes by calling affected contracts or changes the oracle state, allowing dependent contracts to *pull* the updated value from the oracle. These differing system semantics introduce inefficiencies when adapting between them.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
```solidity
interface OracleHandler {
    function receiveResult(bytes32 id, bytes32 result) external;
}
```

`receiveResult` MUST revert if the `msg.sender` is not an oracle authorized to provide the `result` for that `id`.

`receiveResult` MUST revert if `receiveResult` has been called before.

`receiveResult` MAY revert if the `id` or `result` cannot be handled by the handler.

The oracle may be any Ethereum account.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The specs are currently similar to what is implemented by LINK and Oraclize, two of the larger players in the space.

### Pull-based Interface
(Alternate specs based on Gnosis v1 contracts)

```solidity
interface Oracle {
    function resultFor(bytes32 id) external returns (bytes32 result);
}
```

`resultFor` MUST revert if the result for an `id` is not available yet.

`resultFor` MUST return the same result for an `id` after that result is available.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
