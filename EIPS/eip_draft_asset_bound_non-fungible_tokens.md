---
title: Asset-bound Non-Fungible Tokens
description: Asset-bound Non-Fungible Tokens anchor a token 1:1 to a (physical or digital) asset and token transfers are authorized through attestation of control over the asset.
author: Thomas Bergmueller (@tbergmueller) <tb@authenticvision.com>, Lukas Meyer <lukas@ibex.host>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-04-24
requires: 721, 165
---

## Abstract

This standard allows to integrate "plain" physical and digital assets without signing capabilities into dApps/web3 by extending ERC-721.

An `ASSET`, e.g. a physical object, is equipped with an `ANCHOR`. The ANCHOR technology must be chosen s.t. an ANCHOR allows to uniquely identify the ASSET. The ANCHOR technology must further allow to proof control over the ASSET through an `ORACLE`. For physical ASSETS, proof-of-control corresponds to proof-of-physical-presence. 

The ANCHOR is wrapped 1:1 in a token, hence represents each individual ASSET 1:1 on-chain.
Wrapping in a secure, inseperable manner requires the ORACLE to issue an off-chain signed `ATTESTATION`, which is verified on-chain. Through the ATTESTATION, the ORACLE testifies that a particular ASSET associated with an ANCHOR has been `CONTROLLED` when defining a `to`-address.

This standard to proposes to use `ATTESTATIONS` as authorization for the following ERC721 mechanisms: `transfer`, `burn` and `approve`. The proposed `transferAnchor(attestation)`, `burnAnchor(attestation)` and `approveAnchor(attestation)` are permissionless, i.e. neither the sender/owner (`from`) nor the receiver (`to`) need to sign. Authorization is solely provided through the ORACLE's ATTESTATION. 

We also outline for optional use
- a `FLOATING`-concept (temporarily or permanently enabling "traditional" ERC-721 transfers without ATTESTATION)
- `ATTESTATION-LIMITS`, which are RECOMMENDED to implement for security reasons when gas is paid through a central account


## Motivation
The well-known ERC-721 establishes that NFTs may represent "ownership over physical properties [...] as well as digital collectables and even more abstract things such as responsibilities" - in a broader sense, we will refer to all those things as `ASSETS`, which typically have value to people.

### The Problem
NFTs are nowadays often confused as being assets themselves. Very commonly people treat an NFT's metdata (images, traits, ...) as asset-class, with the their rarity often defining the value of an invididual NFT. 
It is a common misconception from NFT-investors that metadata is immutable, often to an extent, where said experts are shocked when learning that their PFP metadata (which they've seen as an asset) can be changed anytime through the controller of metadata, although there are even standards (ERC-4906) to spread the word when metadata changes.

While we do not want to solve for this misconception, we do see a huge issue with a related common practice today. Off-chain ASSETS ("ownership over physical products", "digital collectables", "in-game assets", "responsibilities", ...) are linked to an NFT solely through metadata. Approaches to ensure on-chain integrity between metadata (=reference to ASSET) and a token are rarely seen.
Without ensuring integrity of metadata on-chain, we consider linking an asset through metadata very problematic, as it requires absolute trust inte controller of the metadata. We need to trust the controller of metadata to not not [accidentially or willingly] alter the metadata. Further, we need to trust that the metadata provider at tokenURI is available until eternity, which has been proven otherwise (IPFS bucket disappears, central tokenURI-provider has downtimes, ...).

Finally, representing ownership of off-chain ASSETS through NFT suffers from the inhert problem that the integrity between off-chain ownership and on-chain representation as NFT is not enforcible. dApps merely rely on some extra off-chain processes *trying* to ensure integrity, but as soon as the current owner of an NFT is incooperative or incapacitated, those approaches typically and integrity is no longer given.

### ASSET-BOUND NON-FUNGIBLE TOKENS
In this standard we propose to
1. Elevate the concept of representing physical or digital off-chain `ASSETS` by on-chain anchoring the `ASSET` inseperably into an NFT. 
1. Being off-chain in control over the `ASSET` must mean being on-chain in control over the anchored NFT.
1. (Related) A change in off-chain ownership over the `ASSET` inevitably should be reflected by a change in on-chain ownership over the anchored NFT. 

As 2. and 3. indicate, the control/ownership/posession of the ASSET should be the source of truth, _not_ the posession of an NFT anchored the ASSET. Hence, we propose an `ASSET-BOUND NFT`, where off-chain CONTROL over the ASSET enforces on-chain CONTROL over the anchored NFT.
Also the proposed ASSET-BOUND NFTs allow to anchor digital metadata inseperably to the `ASSET`. When the `ASSET` is a physical asset, this allows to design "phygitals" in their purest form, i.e. creating a "phygital" asset with a physical and digital component that are inseperable. [Note that metadata itself can still change, e.g. for "Evolvable NFT"]

We propose to complement the existing transfer control mechanisms of a token according to ERC-721, `Approval` according to EIP-721 and `Permit` according to EIP-4494, by another mechanism; `ATTESTATION`. An ATTESTATION is signed off-chain by the ORACLE and must only be issued when the ORACLE verified that whoever specifies the `to` address or beneficiary address has simultanously been in control over the ASSET. The `to` address of an attestation may be used for Transfers as well as for approvals and other authorizations.

Transactions authorized via `ATTESTATION` shall not require signature or approval from neither the `from` (donor, owner, sender) nor `to` (beneficiary, receiver) account, i.e. making transfers permissionless. Ideally, transaction are signed independent from the `ORACLE` as well, allowing different scenarios in terms of gas-fees. 

Lastly we want to mention two major side-benefits of using the proposed standard, which drastically lowers hurdles in onboarding web2 users and increase their security;

- New users can participate in dApps/DeFi without ever owning crypto currency (when gas-fees are paid through a third-party account, typically the ASSET issuer, who signs `transferAnchor()` transactions)
- Users cannot get scammed. Common attacks (e.g. wallet-drainer scams) are no longer possible or easily reverted, since only the anchored NFT can be stolen, not the ASSET itself. Also mishaps like transferring the NFT to the wrong account, losing access to an account etc can be mitigated by executing another `transferAnchor()` transaction based on proofing control over the `ASSET`, i.e. the physical object.


### Related work
We primarily aim to onboard physical or digital ASSETS into dApps, which do not signing-capabilities of their own (contrary to EIP-5791's approach using crypto-chip based solutions). Note that we do not see any restrictions preventing to use EIP-5791 in combination with this standard, as the address of the crypto-chip qualifies as an ANCHOR.

--- TO BE EXTENDED ---


## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions (alphabetical)

- An `ANCHOR` uniquely identifies the off-chain ASSET, being it physical or digital. 
- An `ANCHOR TECHNOLOGY` MUST ensure that
  - the ANCHOR is inseperable from the ASSET (physically or otherwise)
  - an ORACLE can establish beyond reasonable doubt that the ASSET is CONTROLLED.
  - For physical ASSETS, MUST fulfill [Specification for Physical Assets](#additional-specifications-for-physical-assets)

- `ASSET` refers to the "thing", being it physical or digital, which is represented through NFTs according to the proposed standard. Typically, an ASSET does not have signing capabilities.

- `ATTESTATION` is the confirmation that PROOF OF CONTROL was established when specifying the `to` (receiver, beneficiary) address. 

- `PROOF OF CONTROL` over the ASSET means owning or otherwise controlling an ASSET. How Proof of Control is established depends on the ASSET and may be implemented using technical, legal or other means. For physical ASSETS, CONTROL is typically verified by proofing physical proximity between a physical ASSET and an input device (e.g. a smartphone) used to specify the `to` address.

- An `ORACLE` has signing capabilities. MUST be able to sign ATTESTATIONS off-chain in a way s.t. signatures can be verified on-chain.

- An ATTESTATION 

### ORACLE

- MUST provide an `ATTESTATION`. Below we define the format (the `ATTESTATION`), how the oracle testifies that the `to` address of a transfer has been specified under the pre-condition of `CONTROLLING THE ASSET` associated with the particular `ANCHOR` being transferred to `to`.
- The `ATTESTATION` MUST contain
  - `to`, MUST be address
  - `anchor`, MUST be 1:1 mappable to the `ASSET`
  - `attestationTime`, Time of attestation (MUST be UTC seconds),
  - `validStartTime`, Blocktime must be greater than this value (MUST be UTC seconds)
  - `validEndTime`, Blocktime must be smaller than this value(MUST be UTC seconds)
  - `proof`, Carrier for proof-Mechanism for checking whether an anchor is valid. Typically Merkle-Proof
  - `signature`, ETH-signature (65 bytes), Signature when a trusted oracle signed the `keccak256([to, anchor, attestationTime, expireTime, proof])`, typically abi-encoded.

### Smart contract

- MUST implement ERC-721 interface
- MUST ensure tokens only exist for valid `ANCHOR`.
- MUST have an immutable `canFloat` boolean, indicating whether anchors can be released, i.e. whether tokens can be transferred without attestation, i.e. without proof of CONTROL OVER ASSET. RECOMMENDED to set canFloat via constructor at deploy time.
- MUST define a `maxAttestationValidTime`, which is enforced in case an `ATTESTATION`'s `expireTime` is bigger.
- MUST have bidirectional mapping `tokenPerAnchor[anchor]` and `anchorPerToken[token]`. This implies that a maximum of one token per `ANCHOR` exists.
- MUST have `isReleasedAnchor[anchor]`, indicating which particular anchors are currently released, i.e. can be transfered or minted.
  - This MAY be used to implement a "temporary" decoupling of tokens, which is not subject to this standard but a reference implementation is available.
  - `transferAnchor()` ensures `isReleasedAnchor[anchor]` is temporarily set to true
- MUST implement a mechanism `validAnchor(anchor, ...)` to ensure an ANCHOR passed through attestation is valid, i.e. is on the "list" of valid anchors. RECOMMENDED to implement this through Merkle-Trees, i.e. `validAnchor(anchor, proof)`.
- MUST implement `validateAttestation(...)` modifier, which MUST throw when any of the below occurs:
  - `ATTESTATION` originates from a non-trusted `ORACLE`.
  - `ATTESTATION` has expired, either when
    - WHEN `attestation.attestationTime + maxAttestationValidTime > block.timestamp`
    - OR when `block.timestamp > attestation.expireTime`
  - `ATTESTATION` has already been used. "Used" being defined in at least one transfer has been made using a particular `ATTESTATION`.
  - `validAnchor(anchor, ...) == False`
  - MAY throw under OPTIONAL additional conditions

- MUST extend ERC-721 token transfer mechanisms by adding additional conditions to i.e. `transferFrom`, `safeTransferFrom` and RECOMMENDED to implement that through ERC721 `_beforeTokenTransfer` hook which
  - MUST throw when `isReleased[anchor[tokenId]] == false`
  - MUST increment `transfersPerAnchor[tokenByAnchor[anchor]]`, whenever an associated token has been transferred through this method
- MUST implement `transferAnchor(attestation)` which
  - MUST use the `validateAttestation(attestation)` modifier
  - MUST record each `attestation` used to authorize each token transfer. RECOMMENDED by storing `keccak256(attestation)`
  - MUST temporarily set `isReleasedAnchor[anchor]=true` to allow a transfer or mint
  - MUST ensure `isReleasedAnchor[anchor]` has the same state before and invoking `transferAnchor()`.
  - MUST either
    - call `_safeTransferFrom(ownerOf(tokenPerAnchor[anchor]), to, tokenPerAnchor[anchor])` when `tokenPerAnchor[anchor]` exists
    - or create a new token wrapping the `ANCHOR` through calling the de-facto standard `_safeMint(to, newTokenId)` if `tokenByAnchor[anchor]` does not exist. It is RECOMMENDED use the ERC721-Enumerable mechanics to acquire `newTokenId`.

- RECOMMENDED to implement any or multiple of the following interfaces: transferable(tokenId), isSoulbound(tokenId), isNonTransferable (), `isNonTransferable(tokenId)` according to IERC6454.
- RECOMMENDED to have a `tokenURI(tokenId)` implemented to return an anchorBased-URI, i.e. `baseURI/anchor`. (= Anchoring metadata to anchored ASSET). So even if there are different tokens in time, which represent the same anchor, the same tokenURI needs to be returned for all those tokens (granted baseURI etc does not change).  

- MAY implement the `IERCxxxxAttestedTransferLimit` interface. This is a MUST when transaction-costs are provided through a central account, e.g. through the ORACLE (or associated authorities) itself to avoid fund-draining. If implemented, this mechanism
  - MUST implement `transferLimit(anchor)`, specifying how often an `ANCHOR` can be transferred in total. The contract
    - SHALL support different transfer limit update modes, namely FIXED, INCREASABLE, DECREASABLE, FLEXIBLE (= INCREASABLE and DECREASABLE)
    - MUST immutably define one of the above listed modes expose it via `transferLimitUpdateMode()`
    - RECOMMENDED to have a global transfer limit, which can be overwritten on a token-basis (when `transferLimitUpdateMode() != FIXED`)
  - MUST implement `transfersLeft(anchor)`, returning the number of transfers left (i.e. `transferLimit(anchor)-transfersPerAnchor[anchor]`) for a particular anchor
  - MAY be immutably configureable (at deploytime), wheter transfer limit is FIXED, INCREASABLE, DECREASABLE, FLEXIBLE (= INCREASABLE and DECREASABLE)
  - RECOMMENDED to have a global transfer limit, which can be overwritten on a token-basis (if not configured as FIXED)
  - The above mechanism MAY be used for DeFi application, lending etc to temporarily block transferAnchor(anchor), e.g. over a renting or lending period.

## Additional Specifications for PHYSICAL ASSETS

In case the `ASSET` is a physical object, good or property, the following ADDITIONAL specifications apply:

### ORACLE

- Issuing an `ATTESTATION` requires that the `ORACLE`
  - MUST proof physical proximity between an input device (e.g. smartphone) specifying the `to` address and a particular physical `ANCHOR` and it's associated physical object. Typical acceptable proximity is ranges between some millimeters to several meters.
  - The physical presence MUST be verified beyond reasonable doubt, in particular the employed method
    - MUST be robust against duplication or reproduction attempts of the physical `ANCHOR`,
    - MUST be robust against spoofing (e.g. presentation attacks) etc.
  - MUST be implemented under the assumption that the party defining the `to` address has malicious intent and to acquire false `ATTESTATION`, without currently or ever having access to the physical object comprising the physical `ANCHOR`.

### Physical Object

- MUST comprise an `ANCHOR`, acting as the unique physical object identifier, typically a serial number (plain (NOT RECOMMENDED) or hashed (RECOMMENDED))
- MUST comprise a physical security device, marking or any other feature that enables proofing physical presence for `ATTESTATION` through the `ORACLE`
- Is RECOMMENDED to employ `ANCHOR` technologies featuring irreproducible security features.
- In general it is NOT RECOMMENDED to employ `ANCHOR` technologies that can easily be replicated (e.g. barcodes, "ordinary" NFC chips, .. ). Replication includes physical and digital replication.

## Specification when using digital ASSETs

TODO - if any input?

## Alternatives Considered

- Soulbound burn+mint combi, e.g. through Consensual Soulbound Tokens (EIP-5484)
- Addign a blockTransfer(tokenId) for DeFi -> Decided not to standardize as not core-functionality, can be built on top of this standard like for normal NFT-lending.

TODO:

- Instead of burn, maybe better to return tokens to this smart contract? otherwise, when a user burns, a new token is issued representing an anchor that was wrapped into a previous token before. Not an issue for most use-cases, but strictly speaking breaks historic "1:1" relation and makes tokenURI strictly necessary to tie to anchor.
- -> Definitely do this, also eliminates complexity around the allowance wallet as stated in chat.

## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TODO not really started


TODO make a point that NFTs today are often seen as asset and that decoupling the asset from the NFT has the benefit, of the token can being stolen, but this does not mean the asset is stolen. 

Why 1:1? For N:1 etc, use a contract to proxy or wrap this contract.

Gas fees are paid through
- ORACLE respectively associated centralized account (so not from the beneficiary)
- or through arbitrary accounts, most commonly by either the `from` or `to` account I assume.

### Supported use-cases
- A means to block transfer by `ATTESTATION` and through pre-approved operators under certain conditions and an immutable indication wether it's blockable.. (e.g. block all transfers until DeFi Loan is paid off.)

- A `AllowTransferMode` that is set immutably at contract creation time and allows to limit the authorization mechanisms allowed to transfer. (e.g. AllowTransferAttestation, AllowTransferAttestationBurn, AllowTransferAll)
- A limit of `ATTESTATIONs` that can be issued per token, and an indication `AttestationMode` wether this limit is mutable. (e.g. LimitImmutable, LimitIncreaseOnly, LimitMutable)


## Backwards Compatibility

<!--

  This section is optional.

  All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

No backward compatibility issues found.

## Test Cases

<!--
  This section is optional for non-Core EIPs.

  The Test Cases section should include expected input/output pairs, but may include a succinct set of executable tests. It should not include project build files. No new requirements may be be introduced here (meaning an implementation following only the Specification section should pass all tests here.)
  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed

  TODO: Remove this comment before submitting
-->

## Reference Implementation

<!--
  This section is optional.

  The Reference Implementation section should include a minimal implementation that assists in understanding or implementing this specification. It should not include project build files. The reference implementation is not a replacement for the Specification section, and the proposal should still be understandable without it.
  If the reference implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`. External links will not be allowed.

  TODO: Remove this comment before submitting
-->

Reference-Implementation WIP: <https://git.avdev.at/dlt/physical-transferable-nft/-/tree/initial?ref_type=heads>

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.
TODO

- Add merkle-tree leaves

## Copyright

TBD (copyright and related rights will be waved somehow)
