---
eip: <to be assigned> 
title: On-chain registration of chain identifiers
description: <Description is one full (short) sentence>
author: Marco Stronati (@paracetamolo), Jeff Lau <jeff-lau@live.com>
discussions-to: https://ethereum-magicians.org/t/on-chain-registration-of-chain-identifiers/21299
status: Draft
type: Meta
created: 2024-09-26
---

## Abstract

This ERC proposes to derive chain identifiers as a digest of their chain name (and other information) and to use ENS to map chain names to identifiers in place of the centralized list on GitHub.
A solution to support existing chain identifiers that were not derived following this ERC is also proposed.

## Motivation

The mapping between chain names and identifiers, such as `Mainnet -> 0x1`, is currently maintained in a centralized list on GitHub (see ```ethereum-lists/chains``` repo).
However this solution has two main shortcomings:
- It does not scale with the growing number of L2s.
- The list maintainers are a single point of failure.

Desired properties:
- the ability to register new chain names and identifiers in a censorship-resistant way
- the ability to resolve chain names and identifiers in a trustless way
- maintain a unique mapping between names and identifiers

### Chain Identifier Spoofing and Replay Attacks

An important property of the centralized list is that it keeps a one-to-one correspondence between names and indentifiers.

Without this property, an attacker could register a fresh name pointing to an existing identifier. For example `my-testnet` could point to mainnet `0x1`. A user could be tricked into signing a transaction for the innocent looking `my-testnet` while actually signing a transaction for mainnet, a transaction that we attacker can then replay.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Extending chain identifiers

Current chain identifiers are usually chosen arbitrarily to be short. While these identifiers are convenient on a small scale, as their number increases it is more desirable to draw them from a larger space.

We propose to extend the size of identifiers to 32 bytes and to derive them using a cryptographic hash function.
The input to the function MUST contain the chain name and MAY contain additional information.

An example for a L2:
```
chain_id = Keccak-256(CHAIN_NAME, L1_CHAIN_ID, VERSION, BRIDGE)
```
where:
- `L1_CHAIN_ID` is the id of the L1 where the L2 settles, it could be Mainnet or a testnet.
- `VERSION` is to separate the domain of the hash function with an arbitrary string
- `BRIDGE` is the address of the L2 on the L1

### Chain name resolution

Any ENS name can resolve to a chain identifier as specified in ENSIP-11. The name should resolve to a record containing not only the chain identifier, but also all the optional information necessary to verify the identifier.

For example the chain name `rollup` can be converted to a chain identifier on Mainnet by resolving:
```
rollup.eth -> {version : uint, bridge : address, chain_id : chain_id}
```
and then verified using:
```
chain_id == hash("rollup", 0x1, version, bridge)
```

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TBD

## Backwards Compatibility

Existing identifiers, that were not derived using the scheme above, can be supported using a reverse mapping from chain identifiers to chain names, so that one can check for uniqueness.

For example the chain name `legacy-rollup.eth` can be resolved to the chain identifier `0x123`.
Then `0x123` can be resolved in the `chainid.reverse` domain to a `chain_name`.
If `chain_name == legacy-rollup` then the mapping is valid.

### Bootstrapping and handover

In order to bootstrap the handling of legacy chain identifiers, we imagine the EF populating the `chainid.reverse` domain, a temporary `l2.eth` for names and then handing them over.

- EF populates two subdomains `l2.eth` and `chainid.reverse` using Ethereum lists.
- A rollup registers a `rollup.eth` and points it to their `chain_id.
- EF hands over to the rollup `rollup.l2.eth` and `chain_id.chainid.reverse`
- The rollup updates `chain_id.chainid.reverse` to return `rollup.eth`


## Security Considerations

Domain spoofing can lead to replay attacks as described above and can be eliminated by deriving new identifiers using a hash function and by checking the reverse mapping for legacy identifiers.

Domain squatting, the practice of ammassing a large number of domains in the hope to selling them later to legitimate users, is a possibility but with an increasing number of L2 registrations we can expect the same problem to appear in the centralized Github list.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
