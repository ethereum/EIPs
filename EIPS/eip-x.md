---
eip: <to be assigned>
title: Contract Code for Externally Owned Accounts
description: An opcode that allows EOAs to publish contract code at their address.
author: Dan Finlay (@danfinlay), Sam Wilson (@SamWilsn)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2022-03-26
requires: 3607
---

## Abstract

This EIP introduces a new opcode, `AUTH_USURP`, which allows an EOA to publish code at its own address, which combined with [EIP 3607: Reject transactions from senders with deployed code](https://eips.ethereum.org/EIPS/eip-3607) effectively revokes the original signing key's authority.

## Motivation

EOAs currently hold a significant amount of user-controlled value on Ethereum blockchains, but are limited by the protocol in a variety of critical ways. Rotating keys for security, batching to save gas, MetaTransactions to reduce the need to hold ether yourself, as well as countless other benefits that come from having a contract account or account abstraction, like choosing one's own authorization algorithm, spending limits, social recovery, key rotation, arbitrary transitive capability delegation, and just about anything else we can imagine.

These benefits can be achieved with new users using new contract accounts, or new contracts adopting new standards to enable app-layer account abstraction (like [EIP 2585: Minimal Native Meta Transaction Forwarder](https://github.com/wighawag/EIPs/blob/eip-2585/EIPS/eip-2585.md) or [EIP 4337: account abstraction without Ethereum protocol changes](https://medium.com/infinitism/erc-4337-account-abstraction-without-ethereum-protocol-changes-d75c9d94dc4a)), but these would neglect the vast majority of existing Ethereum users' accounts. Whether we like it or not, those users exist today, and they also need a path to achieving their security goals.

Those added benefits would mostly come along with EIP-3074 itself, but with one significant shortcoming, the presence of the original signing key. This would mean while an EOA could delegate its authority to some _additional_ contract, the key itself would linger, continuing to provide an attack vector, and a constantly horrifying question lingering: Have I been leaked?

Also, today EOAs have no path to key rotation of any sort. A leaked private key (either through phishing, or accidental access) cannot be taken back: The information once shared cannot be proven un-known, you can't put the toothpaste back in the tube. A prudent user concerned about their key security might perform [the current process of migrating to a new secret recovery phrase](https://metamask.zendesk.com/hc/en-us/articles/360015289952-How-to-migrate-to-a-new-Secret-Recovery-Phrase) but this both requires a transaction per asset (making it extremely expensive), and some powers (like hard-coded owners in a smart contract) might not be transferrable at all.

We know that EOAs cannot provide ideal user experience or safety, and [we need to change the norm to contract-based accounts](https://vitalik.ca/general/2021/01/11/recovery.html), but if that transition is designed without regard for the vast majority of users today, for whom Ethereum has always meant EOAs, we will be continually struggling against the need to support both of these userbases. This EIP provides a path not [to enshrine EOAs](https://ethereum-magicians.org/t/we-should-be-moving-beyond-eoas-not-enshrining-them-even-further-eip-3074-related/6538), but to provide a migration path off of them, once and for all.

This proposal combines well with [EIP-3074: AUTH and AUTHCALL opcodes](https://eips.ethereum.org/EIPS/eip-3074), which provides op-codes that could enable any externally owned account (EOA) to delegate its signing authority to an arbitrary smart contract. It allows an EOA to assign a contract account on its behalf _without forgoing its own powers_, while this one provides a final migration path off the EOA's original signing key. Additionally, this EIP alone requires each account to submit a transaction itself to perform the migration (requiring gas), but if combined with EIP-3074, even accounts with no ether for gas would be able to sign delegation messages capable of deploying contract code at their addresses.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).

## Rationale
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

## Backwards Compatibility
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes.  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation
An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations
All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
