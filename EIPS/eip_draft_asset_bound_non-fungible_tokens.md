---
title: Asset-bound Non-Fungible Tokens
description: Asset-bound Non-Fungible Tokens are used to anchor a token 1:1 to an (offchain / physical) asset and the token transfers are authorized through attestation of control over the asset.
author: Thomas Bergmueller (@tbergmueller) <tb@authenticvision.com>, Lukas Meyer <lukas@ibex.host>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-04-20
requires: 721, 165
---

## Abstract
This standard aims to onboard "plain" physical and digital assets without signing capabilities into dApps/web3 by extending ERC-721.

An asset, e.g. a physical object, is equipped with a `ANCHOR` technology. The `ANCHOR` technology must be chosen s.t. it allows to uniquely identify the `ASSET`. The `ANCHOR` technology further needs to enable proofing control over the asset through an `ORACLE` technology. For physical assets, Proof of Control is done by proofing physical presence. By wrapping the `ANCHOR` in a token we can represent each ASSET 1:1 on-chain. 

To do this in a secure, inseperable manner, the `ORACLE` must issue an `ATTESTATION`, where the `ORACLE` testifies that s particular ASSET associated with an ANCHOR has been CONTROLLED when defining the receiving `to`-address for any token transfer. 

Via `transferAnchor(attestation)` transfers are permissionless, i.e. neither the sender (`from`) nor the receiver (`to`) need to sign. Transfer authorization is solely provided through the `ORACLE`'s `ATTESTATION`.

Additionally a structure is proposed, how FLOATING (temporarily decoupling the token from the anchor, hence enabling "traiditional" ERC-721 transfers) may be implemented using the present standard.

## TODO
- Wording
  - `ATTESTATION` may be reserved: https://ethereum.org/en/developers/docs/consensus-mechanisms/pos/`ATTESTATION`s/ 



## Motivation
The widely spread ERC-721 considered that NFTs can represent "ownership over physical properties [...] as well as digital collectables and even more abstract things such as responsibilities" - in a broader sense, we will refer to those as `ASSETS`. 

The following proposed standard extends ERC-721 and elevates the concept of representing physical or digital off-chain `ASSETS` by strictly anchoring the `ASSET` inseperably into an NFT. This implies that a change in ownership over the `ASSET` inevitably must be reflected by a change in ownership over the anchored digital NFT. Moreover, being in control over the off-chain `ASSET` must mean being in control over the anchored NFT. 

Additionally or alternatively NFTs according to this proposed standard allow to anchor digital metadata inseperably to the `ASSET`. When the `ASSET` is a physical asset, this allows to design "phygitals" in their purest form, i.e. making a single phygital asset with a physical and digital component that are inseperable.

The proposed standard primarily aims to onboard physical assets into dApps, which do not have digital processing capabilities. Especially such, which do not have signing-capabilities of their own (contrary to EIP-5791's approach using crypto-chip based solutions). Note that we do not see any restrictions on using the proposed standard for digital or abstract off-chain `ASSETS`.

We propose in this standard to technically limit the number of transfers of a token according to ERC-721, while conceptually still enabling an unliminted number of transfers. Transfers are solely authorized through under the pre-condition of an `ORACLE` verifying that whoever specifies the `to` address has been simultanously been in control over the `ASSET`. Transfers shall not require signature or approval from neither the `from` nor `to` account, i.e. making transfers permissionless. Ideally, signing the transaction is independent from the `ORACLE` as well, allowing different scenarios in terms of gas-fees.

Thus - and this may be counter-intuitive - the anchored NFT can only be transfered through transfering the ASSET. This can be seen as an extreme decentralized/self-custody approach, as it extends to the ASSET, in particular for physical ASSETS even into the physical world. Phygitals implemented with the proposed standard can be traded physically in any traditionally known way, including trading against FIAT, gifting or just swapping for other physical goods (which do not necessarly need to be phygital).  

Lastly, the proposed transfer-mechanism has two major side-benefits, which drastically lower hurdles for onboarding web2 users and increase their security; 
- New users can participate in dApps/DeFi without ever owning crypto currency (when gas fees are paid through a third-party account, typically the ASSET issuer)
- Users cannot get scammed digitally, since common attacks (e.g. wallet-drainer scams) are no longer possible. Also mishaps like transferring the NFT to the wrong account, losing access to once account etc can easily be mitigated by initiating another transaction based on proofing control over the `ASSET`, i.e. the physical object.


## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions

- `ASSET` refers to the "thing", being it physical or digital, which is represented through NFTs according to the proposed standard. Typically, an ASSET does not have signing capabilities.
- `CONTROLLING THE ASSET` ... TODO [_in physical proximity to the physical asset_]
- An `ANCHOR` uniquely identifies the off-chain ASSET, being it physical (Refer Specification for Phygitals) or digital.
- An `ORACLE` has signing capabilities and one or more `ORACLES` are trusted by the Smart Contract.


### ORACLE
- MUST provide an `ATTESTATION`. Below we define the format (the `ATTESTATION`), how the oracle testifies that the `to` address of a transfer has been specified under the pre-condition of `CONTROLLING THE ASSET` associated with the particular `ANCHOR` being transferred to `to`.
- The `ATTESTATION` MUST contain 
  - `to`, MUST be address 
  - `anchor`, MUST be 1:1 mappable to the `ASSET`
  - `attestationTime`, (MUST be UTC seconds)
  - `expireTime`, (MUST be UTC seconds)
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

- MAY implement an anchor-transfer-limit-mechanism. This is a MUST when transaction-costs are provided through a central account, e.g. through the ORACLE (or associated authorities) itself to avoid fund-draining. If implemented, this mechanism
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

The ORACLE can be seen as an "authorized operator" in ERC-721 terms, with authorization being implicitely granted by receiving an NFT through use of the ORACLE *(CAVEAT to be clarified: If I use the oracle and specify to drop an NFT to a foreign account, this account certainly did not implicitely agree to the authorization)*

Why 1:1? For N:1 etc, use a contract to proxy or wrap this contract.

Gas fees are paid through 
- ORACLE respectively associated centralized account (so not from the beneficiary)
- or through arbitrary accounts, most commonly by either the `from` or `to` account I assume.

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

Reference-Implementation WIP: https://git.avdev.at/dlt/physical-transferable-nft/-/tree/initial?ref_type=heads


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
