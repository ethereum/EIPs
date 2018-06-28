---
eip: <to be assigned>
title: eth_getProof 
author: Simon Jentzsch <simon.jentzsch@slock.it>, Christoph Jentzsch <christoph.jentzsch@slock.it>
discussions-to: simon.jentzsch@slock.it
status: Draft
type: Standards Track (Core, Networking, Interface, ERC)
category : Interface
created: 2018-06-24
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

One of the great feature of Ethereum is the fact, that you can verify all data of the state. But in order to allow verification of accounts outside the client, we need a additional function delivering us the required proof. These proofs are important to secure Layer2-Technologies.


## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

Ethereum uses MerkleTrees to store the state of accounts and their storage. This allows verification of each value by simply creating a MerkleProof. But currently the eth-Module does not give you access to these proofs. This EIP suggests a additional RPC-Method, which creates MerkleProofs for Accounts and Storage-Values. 

Combined with a stateRoot (from the blockheader) it enables offline verification of any account or storage-value. This allows especially IOT-Devices or even mobile apps which are not able to run a light client to verify responses from a untrusted source.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

In order to create a MerkleProof access to the full state is required. The current RPC-Methods allow a application to access single values (`eth_getBalance`,`eth_getTransactionCount`,`eth_getStorageAt`,`eth_getCode`), but it is impossible to read Information about the MerkleTree storing these values through the standard RPC-Interface.

Today MerkleProofs are already used internally. For example the [Light Client Protocol](https://github.com/ethereum/wiki/wiki/Light-client-protocol) supports a function creating MerkleProof, which is used in order to verify the requested account or storage-data.
Offering these already existing function through the RPC-Interface as well would enable Applications to store and send these proofs to devices which are not directly connected to the p2p-network and still are able to verify the data. 



## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
