---
title: Physical transferable NFT
description: Physical-transferable NFTs are used to anchor a token 1:1 to a physical object and the token transfers are solely authorized through attestation of physical presence of the object through an oracle.
author: Thomas Bergmueller (@tbergmueller) <tb@authenticvision.com>, Lukas Meyer <lukas@ibex.host>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-04-13
requires: 721, 165
---

## Abstract
This standard aims to onboard "plain" physical objects without signing capabilities into dApps/web3 by extending ERC-721. 

A physical object is equipped with a physical `ANCHOR` technology. The `ANCHOR` technology must be chosen s.t. it allows to uniquely identify the physical object. The `ANCHOR` technology further needs to be fit to proof physical presence of the physical `ANCHOR` employing an `ORACLE` technology.

By wrapping the `ANCHOR` in a token, i.e. associating `anchorId`:`tokenId`, we can represent each physical object 1:1 digitally. 

To enable this in a secure, inseperable manner, an `ORACLE` must issue an `ATTESTATION`, where the `ORACLE` testifies that the particular physical object associated with the `ANCHOR` has been physically present / close when defining the receiving `to`-address for any token transfer, i.e. by preconditioning any token transfer with valid `ATTESTATION`. 

Finally, token transfers are made permissionless, i.e. neither the sender (`from`) nor the receiver (`to`) need to sign. Transfer authorization is solely provided through the `ORACLE`'s `ATTESTATION`.

Additionally a consensual mechanism is proposed to (temporarily) block transfers on a token-level.

## TODO
- Wording (decide whether anchor or serial shall be used, MINTER_ROLE shall become ORACLE_ROLE)
- Code samples
  - Interface definition in Specification
  - adapt from https://mumbai.polygonscan.com/address/0xd04c443913f9ddcfea72c38fed2d128a3ecd719e 
  - Reference impl of all transfer methods
  - Outline Maintainer-mechanism, but make recommended
  - Rationale
- SHORTEN AND SIMPLIFY!!

- Wording
  - `ATTESTATION` may be reserved: https://ethereum.org/en/developers/docs/consensus-mechanisms/pos/`ATTESTATION`s/ 



## Motivation
The widely spread ERC-721 states that NFTs can represent "ownership over physical properties -- houses, unique artwork". The following proposed standard extends ERC-721 and elevates this concept of representing physical property respectively physical objects in general by anchoring the physical object inseperably into an NFT. This implies that a change in ownership over the physical object inevitably must be reflected by a change in ownership over the anchored digital NFT. 

Additionally or alternatively NFTs according to this proposed standard allow to anchor digital metadata inseperably to the physical object. This allows to design "phygitals" in their purest form, i.e. making a single phygital asset with a physical and digital component that are inseperable.

We aim to onboard physical objects into dApps, which do not have digital processing capabilities. Especially such, which do not have signing-capabilities of their own (contrary to EIP-5791's approach using crypto-chip based solutions). 

We propose in this standard to overwrite the ERC-721 Transfer Mechanism s.t. a transfer can neither be initiated by the current owner, approved addresses or other authorized operators of the current owner of an NFT. Transfers are solely initiated through the smart-contract under the pre-condition of an oracle verifying the presence of the physical object at the device specifying the `to` address. Transfers shall not require signature or approval from neither the `from` nor `to` account, i.e. making transfers permissionless. 

Thus - and this may be counter-intuitive - the anchored NFT can only be transfered through transfering the physical object. This can be seen as an extreme decentralized/self-custody approach, as it extends to the physical world. Phygitals implemented with the proposed standard can be traded physically in any traditionally known way, including trading against FIAT, gifting or just swapping for other physical goods (which do not necessarly need to be phygital).  

Lastly, the proposed transfer-mechanism has two major side-benefits, which drastically lower hurdles for onboarding web2 users and increase their security; 
- New users can participate in dApps/DeFi without ever owning crypto currency
- Users cannot get scammed digitally, since common attacks (e.g. wallet-drainer scams) are no longer possible. Also mishaps like transferring the NFT to the wrong account, losing access to once account etc can easily be mitigated by initiating another transaction based on the physical object.

This comes with the only "disadvantage" we see; funding for all transactions need to be provided through the issuing/transferring smart contract.


**CONCEPT IDEA; Limit transfers of Tokens, with each attestation granting you one transfer. For strictly Digital Soul (TM) settings, no messing with transfersLeftPerToken[tokenId]**

Benefit of current solution; transferAnchor no longer access-controlled, hence, the transferrer can pay for gas!

## Specification

<!--
  The Specification section should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (besu, erigon, ethereumjs, go-ethereum, nethermind, or others).

  It is recommended to follow RFC 2119 and RFC 8170. Do not remove the key word definitions if RFC 2119 and RFC 8170 are followed.

  TODO: Remove this comment before submitting
-->

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions

- `ASSET` refers to the "thing", being it physical or digital, which is represented through NFTs according to the proposed standard.
- `CONTROLLING THE ASSET` ... TODO [_in physical proximity to the physical asset_]
- An `ANCHOR` uniquely identifies an off-chain asset, being it physical (Refer Specification for Phygitals) or digital.
- An `ORACLE` has signing capabilities and one or more `ORACLES` are trusted by the Smart Contract.


### ORACLE
- MUST provide an `ATTESTATION`. Below we define the format (the `ATTESTATION`), how the oracle testifies that the `to` address of a transfer has been specified under the pre-condition of `CONTROLLING` the asset associated with the particular `ANCHOR` that is being transferred.
- The `ATTESTATION` MUST contain 
  - `to`, MUST be address 
  - `anchor`, MUST be 1:1 mappable to the `ASSET`
  - `attestationTime`, (MUST be UTC milliseconds)
  - `expireTime`, (MUST be UTC milliseconds)
  - OPTIONAL additional data

### Smart contract
- MUST implement ERC-721 interface
- RECOMMENDED to implement the ERC-721 Enumerable interface
- MUST ensure tokens only eixist for valid `ANCHOR` exists.
- MUST define a `MAX_ATTESTATION_EXPIRE_TIME`, which is enforced in case an ORACLE's expireTime is bigger.
- MUST have bidirectional mapping `tokenPerAnchor[anchor]` and `anchorPerToken[token]`. This implies that a maximum of one token per `ANCHOR` exists.
- MUST have a `transfersPerAnchor[anchor]`, recording how often a particular `ANCHOR` has been transferred. This counter needs to be prevailed, even if the `ÀNCHOR` is wrapped into different tokens (e.g. when burning and re-issuing a token)
- MUST have a `unboundTransfersLeft[tokenId]`, indiciating how often a token can be transferred independently of an anchor, i.e. without ATTESTATION. 
  - 0 for each tokenId per default. 
  - This may also be used to implement a "temporary" decoupling of tokens, which is not subject to this standard.
- MUST implement a mechanism `validAnchor(anchor, ...)` to ensure an ANCHOR passed through attestation is valid, i.e. is on the "list" of valid anchors. RECOMMENDED to implement this through Merkle-Trees, i.e. `validAnchor(anchor, proof)`.
- MUST implement `validAttestation(...)`, which MUST only return `true` when
  - `ATTESTATION` originates from a trusted `ORACLE`. It is RECOMMENDED to verify this by using access control to specify a trusted `ORACLE` and gating `validAttestation()` with those access control mechanism. e.g. use any of the well known `onlyOwner()`, `onlyRole(ORACLE_ROLE)`, ... modifiers.
  - `ATTESTATION` has not expired yet, computed as `curTime() - ATTESTATION.attestationTime <= MIN(MAX_ATTESTATION_EXPIRE_TIME, ATTESTATION.expireTime)`
  - `ATTESTATION` has not already been used. "Used" being defined in a transfer has been made using an `ATTESTATION` with the same `attestationId`
  - `validAnchor(anchor, ...) == True`
- MUST implement `transferLimit(anchor)`, specifying how often an `ANCHOR` can be transferred in total. The contract
  - SHALL support different transfer limit update modes, namely FIXED, INCREASABLE, DECREASABLE, FLEXIBLE (= INCREASABLE and DECREASABLE) 
  - MUST immutably define one of the above listed modes expose it via `transferLimitUpdateMode()`
  - RECOMMENDED to have a global transfer limit, which can be overwritten on a token-basis (when `transferLimitUpdateMode() != FIXED`)
- MUST implement `transfersLeft(anchor)`, returning the number of transfers left (i.e. `transferLimit(anchor)-transfersPerAnchor[anchor]`) for a particular anchor
- MUST implement `isNonTransferable(tokenId)` (from IERC6454) which MUST return true when 
  - unboundTransfersLeft[tokenId]<= 0, indicating ANCHOR-independent transferrability of the token.
  - `transferBlocked[anchorPerToken[tokenId]] == true`
  - OR any other OPTIONAL blocking condition applies
- MAY overload `transferBlocked(tokenId)` with `transferBlocked(anchor)`
- MUST extend ERC-721 token transfer mechanisms by adding additional conditions to i.e. `transferFrom`, `safeTransferFrom` and RECOMMENDED to implement that through ERC721 `_beforeTokenTransfer` hook which
  - MUST throw when `isNonTransferable(anchor[tokenId])` returns `true`.
  - MUST decrement `allowedUnanchoredTransfers[tokenId]`
- MUST implement `transferAnchor(anchor, to, {attestation})` which
  - MUST store the `attestationId` used to authorize each token transfer
  - MUST throw when `validAttestation(..) == false`
   - MUST increment `transfersPerAnchor[anchor]`, whenever an token associated `token[anchor]` has been transferred through this method
  - RECOMMENDED (when using the recommended `_beforeTokenTransfer` hook) to increment `allowedUnanchoredTransfers[tokenId]` allowing to pass the hook (which will decrease it again, hence maintaining the status quo)
  - MUST either
    - call `_safeTransferFrom(ownerOf(tokenPerAnchor[anchor]), to, tokenPerAnchor[anchor])` when `tokenPerAnchor[anchor]` exists
    - or create a new token wrapping the `ANCHOR` through calling the de-facto standard `_safeMint(to, newTokenId)` if `token[anchor]` does not exist. It is RECOMMENDED use the ERC721-Enumerable mechanics to acquire `newTokenId`.

- RECOMMENDED to implement transferable(tokenId), isSoulbound(tokenId), ... indicating the UNANCHORED Transferability. TODO reference ERCs from Discord.



## Specification for Phygitals
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

















-------------------------- TODO WORDING AND CONSIDERING  ------- 

- MUST implement burn mechanics for current owner to destroy tokens, e.g. when received unwantedly, RECOMMENDED similar to EIP-5484. TODO check how to  marry to blockTransfer
- SHALL implement a transfer limit per ANCHOR
  - SHALL be immutably configureable (at deploytime), wheter transfer limit is FIXED, INCREASABLE, DECREASABLE, FLEXIBLE (= INCREASABLE and DECREASABLE) 
  - RECOMMENDED to have a global transfer limit, which can be overwritten on a token-basis (if not configured as FIXED)
- SHALL check whether an ANCHOR is valid, MerkleTrees RECOMMENDED (consider a salt-leave to avoid reconstructions when all anchors are dropped)
- SHALL NOT expose anchors before first drop.
- SHALL have `anchorDropable(anchor, proof)`, checking whether an anchor is valid, has not exceeded maxDropCount and is not blocked

- OPTIONAL implement a `blockTransfer(anchor)` mechanism, which allows to block transfers entirely. This has applications in e.g. DeFi, Lending, ..
  - current owner of a particular token MUST give "permission to block" to a third party
  - *TODO: Do we need to ensure via this contract that when third party is malicious and current owner holds up his side of the deal, that the block is enforced to be relieved? IMHO not part of this standard*
- MUST have a `tokenURI(tokenId)`, which returns an anchorBased-URI, i.e. `baseURI/anchor`. (= Anchoring metadata to physical object). So even if there are different tokens in time, which represent the same anchor, the same tokenURI needs to be returned for all those tokens (granted baseURI etc does not change).  


*Alternatives considered*: Consensual Soulbound Tokens (EIP-5484)

TODO:
- Instead of burn, maybe better to return tokens to this smart contract? otherwise, when a user burns, a new token is issued representing an anchor that was wrapped into a previous token before. Not an issue for most use-cases, but strictly speaking breaks historic "1:1" relation.


## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TODO not really started

The ORACLE can be seen as an "authorized operator" in ERC-721 terms, with authorization being implicitely granted by receiving an NFT through use of the ORACLE *(CAVEAT to be clarified: If I use the oracle and specify to drop an NFT to a foreign account, this account certainly did not implicitely agree to the authorization)*

Why 1:1? For N:1 etc, use a contract to proxy or wrap this contract.

Gas fees are paid through oracle. Contract may implement a different mechanic (payable etc?) from and to certainly are not paying.. 

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

Kind of, but still with EIP-5484: https://mumbai.polygonscan.com/address/0xd04c443913f9ddcfea72c38fed2d128a3ecd719e

## Security Considerations

<!--
  All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. For example, include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

Needs discussion.

## Copyright

TBD (copyright and related rights will be waved somehow)
