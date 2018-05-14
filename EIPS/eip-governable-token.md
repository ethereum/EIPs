---
eip: <to be assigned>
title: Governable Token or Asset Interface
author: Bradley Leatherwood <bradleat@inkibra.com>
discussions-to: <email address>
status: Draft
type: ERC
category ERC
created: 2018-05-02
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
This is the suggested template for new EIPs.

Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

The title should be 44 characters or less.

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
A short (~200 word) description of the technical issue being addressed.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
To mitigate the effects of reasonably provable token or asset loss or theft and to help resolve other conflicts. Ethereum's protocol should not be modified because of loss, theft, or conflicts, but it is possible to solve these problems in the protocol layer.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

Extends erc-20 or erc-721
Extends 792 with
dispute() payable
recover() payable
disputedBalanceOf()

How do you prevent grieving? For dispute you have to be party to the transaction. For recover, which you'd use if your funds got trapped then we can delay arbitration because no one has the key. For recover if the funds are stolen, you must also be able to sign with the key with which the funds were stolen from.

createDispute is a no-op?

Should be somewhat like a wallet, but with a mechanism to dispute a balance. Disputed balances can then be resolved by the wallets arbitration provider.

Need ways to move funds into and out of the wallet.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

Not applicable.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

Not applicable.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

Pending.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
