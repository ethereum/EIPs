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
This standard allows to integrate physical and digital ASSETS without signing capabilities into dApps/web3 by extending ERC-721.

An `ASSET`, e.g. a physical object, is equipped with an `ANCHOR`. The `ANCHOR-TECHNOLOGY` must be chosen s.t. an ANCHOR allows to uniquely identify the ASSET. The ANCHOR-TECHNOLOGY must further allow to establish a `PROOF-OF-CONTROL` over the ASSET through an `ORACLE`. For physical ASSETS, PROOF-OF-CONTROL corresponds for example to proof of physical presence. 

The ANCHOR is mapped 1:1 to a tokenId on-chain, hence represents each individual ASSET 1:1.
Wrapping in a secure, inseperable manner requires the ORACLE to issue an off-chain signed `ATTESTATION`, which is on-chain-verifyable. Through the ATTESTATION, the ORACLE testifies that a particular ASSET associated with an ANCHOR has been `CONTROLLED` when defining a `to`-address, e.g. through a user-device.

This standard to proposes to use `ATTESTATIONS` as authorization for the following ERC721 mechanisms: `transfer`, `burn` and `approve`. The proposed `transferAnchor(attestation)`, `burnAnchor(attestation)` and `approveAnchor(attestation)` are permissionless, i.e. neither the sender/owner (`from`) nor the receiver (`to`) need to sign. Authorization is solely provided through the ORACLE's ATTESTATION. 

We also outline for optional use
- a `FLOATING`-concept (temporarily or permanently enabling "traditional" ERC-721 transfers without ATTESTATION)
- `ATTESTATION-LIMITS`, which are recommended to implement for security reasons, when gas is paid through a central account (see Figure 1)

Figure 1 below shows a the data flow of an asset-bound NFT transfer through a simplified example system employing ERC-XXXX. The system is utilizing a smartphone as user-device to interact with a physical ASSET.

![Figure 1: Sample system](../assets/eip-draft_asset-bound_non-fungible_token/img/concept_diagram.png)    


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

- New users, e.g `0xaa...aa` (Fig.1), can use gasless wallets, hence participate in Web3/dApps/DeFi and mint+transfer tokens without ever owning crypto currency. Gas-fees may be paid through a third-party account `0x..gasPayer` (Fig.1). The gas is typically covered by the ASSET issuer, who signs `transferAnchor()` transactions
- Users cannot get scammed. Common attacks (e.g. wallet-drainer scams) are no longer possible or easily reverted, since only the anchored NFT can be stolen, not the ASSET itself. Also mishaps like transferring the NFT to the wrong account, losing access to an account etc can be mitigated by executing another `transferAnchor()` transaction based on proofing control over the `ASSET`, i.e. the physical object.


### Related work
We primarily aim to onboard physical or digital ASSETS into dApps, which do not signing-capabilities of their own (contrary to EIP-5791's approach using crypto-chip based solutions). Note that we do not see any restrictions preventing to use EIP-5791 in combination with this standard, as the address of the crypto-chip qualifies as an ANCHOR.

--- TO BE EXTENDED ---


## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Definitions (alphabetical)

- `ANCHOR` uniquely identifies the off-chain ASSET, being it physical or digital. 
- `ANCHOR TECHNOLOGY` MUST ensure that
  - the ANCHOR is inseperable from the ASSET (physically or otherwise)
  - an ORACLE can establish beyond reasonable doubt that the ASSET is CONTROLLED.
  - For physical ASSETS, MUST fulfill [Specification for Physical Assets](#additional-specifications-for-physical-assets)

- `ASSET` refers to the "thing", being it physical or digital, which is represented through NFTs according to the proposed standard. Typically, an ASSET does not have signing capabilities.

- `ATTESTATION` is the confirmation that PROOF OF CONTROL was established when specifying the `to` (receiver, beneficiary) address. 

- `PROOF-OF-CONTROL` over the ASSET means owning or otherwise controlling an ASSET. How Proof of Control is established depends on the ASSET and may be implemented using technical, legal or other means. For physical ASSETS, CONTROL is typically verified by proofing physical proximity between a physical ASSET and an input device (e.g. a smartphone) used to specify the `to` address.

- An `ORACLE` has signing capabilities. MUST be able to sign ATTESTATIONS off-chain in a way s.t. signatures can be verified on-chain.

### ORACLE

- MUST provide an ATTESTATION. Below we define the format how an ORACLE testifies that the `to` address of a transfer has been specified under the pre-condition of PROOF-OF-CONTROL associated with the particular ANCHOR being transferred to `to`.
- The ATTESTATION MUST contain
  - `to`, MUST be address, specifying the beneficiary, e.g. the to-address, approved account etc.
  - `anchor`, aka the ASSET identifier, MUST have a 1:1 relation to the `ASSET`
  - `attestationTime`, UTC seconds, time when attestation was signed by ORACLE,
  - `validStartTime` UTC seconds, start time of the ATTESTATION's validity timespan
  - `validEndTime`, UTC seconds, end time of the ATTESTATION's validity timespan
  - `proof`, Data for proof-mechanism in checking an anchor's validity. Typically Merkle-Proof
  - `signature`, ETH-signature (65 bytes). Output of an ORACLE signing the `attestationHash = keccak256([to, anchor, attestationTime, validStartTime, validEndTime, proof])`. Values typically abi-encoded.
- How PROOF-OF-CONTROL is establish in detail through an ANCHOR-TECHNOLOGY is not subject to this standard. Minimal specification on ORACLE requirements and ANCHOR-TECHNOLOGY requirements when using Physical ASSETS is in  [Specification for Physical Assets](#additional-specifications-for-physical-assets).

Minimal Typescript sample using ethers library and OZ MerkleTrees:
```
export async function minimalAttestationExample() {
  // #################################### PRELIMINARIES
  const merkleTestAnchors = [
      ['0x' + createHash('sha256').update('TestAnchor123').digest('hex')],
      ['0x' + createHash('sha256').update('TestAnchor124').digest('hex')],
      ['0x' + createHash('sha256').update('TestAnchor125').digest('hex')],
      ['0x' + createHash('sha256').update('TestAnchor126').digest('hex')],
      ['0x' + createHash('sha256').update('SaltLeave').digest('hex')] // shall never be used on-chain!
      ]
  const merkleTree = StandardMerkleTree.of(merkleTestAnchors, ["bytes32"]);

  // #################################### ACCOUNTS
  // Alice shall get the NFT, oracle signs the attestation off-chain 
  const [alice, oracle] = await ethers.getSigners();

  // #################################### CREATE AN ATTESTATION
  const to = alice.address;
  const anchor = merkleTestAnchors[0][0];
  const proof = merkleTree.getProof([anchor]);
  const attestationTime = Math.floor(Date.now() / 1000.0); // Now in seconds UTC

  const validStartTime = 0;
  const validEndTime = attestationTime + 15 * 60; // 15 minutes valid from attestation

  // Hash and sign. In practice, oracle shall only sign when Proof-of-Control is established!
  const messageHash = ethers.utils.solidityKeccak256(["address", "bytes32", "uint256", 'uint256', "uint256", "bytes32[]"], [to, anchor, attestationTime, validStartTime, validEndTime, proof]);
  const sig = await oracle.signMessage(ethers.utils.arrayify(messageHash));
  // Encode
  return ethers.utils.defaultAbiCoder.encode(['address', 'bytes32', 'uint256', 'uint256', 'uint256', 'bytes32[]', 'bytes'], [to, anchor, attestationTime,  validStartTime, validStartTime, proof, sig]);
}
```


### ERC-XXXXContract

Every ERC-XXXX compliant contract must implement the IERCxxxx, ERC721 and ERC165 interfaces (subject to “caveats” below):
```
/**
 * @title IERCxxxx Asset-Bound Non-Fungible Tokens 
 * @author Thomas Bergmueller (@tbergmueller) <tb@authenticvision.com>
 * @notice Asset-bound Non-Fungible Tokens anchor a token 1:1 to a (physical or digital) asset and token transfers are authorized through attestation of control over the asset
 * @dev See EIP-XXXX (todo link) for details
 */
interface IERCxxxx {
    /// Used for several authorization mechansims, e.g. who can burn, who can set approval, ... 
    /// @dev Specifying the role in the ERC-XXX ecosystem. Used in conjunction with ERCxxxxAuthorization
    enum ERCxxxxRole {
        OWNER,  // =0, The owner of the digital token
        ISSUER, // =1, The issuer (ERC-XXXX contract) of the tokens, typically represented through a MAINTAINER_ROLE, the contract owner etc.
        ASSET,  // =2, The asset identified by the anchor
        INVALID // =3, Reserved, do not use.
    }

    /// @dev Authorization, typically mapped to authorizationMaps, where each bit indicates whether a particular ERCxxxxRole is authorized 
    ///      Typically used in constructor (hardcoded or params) to set burnAuthorization and approveAuthorization
    ///      Also used in optional ERC-XXXX updateBurnAuthorization, updateApproveAuthorization 
    enum ERCxxxxAuthorization {
        NONE,               // = 0,      // None of the above
        OWNER,              // = (1<<OWNER), // The owner of the token, i.e. the digital representation
        ISSUER,             // = (1<<ISSUER), // The issuer of the tokens, i.e. this smart contract
        ASSET,              // = (1<<ASSET), // The asset, i.e. via attestation
        OWNER_AND_ISSUER,   // = (1<<OWNER) | (1<<ISSUER),
        OWNER_AND_ASSET,    // = (1<<OWNER) | (1<<ASSET),
        ASSET_AND_ISSUER,   // = (1<<ASSET) | (1<<ISSUER),
        ALL                 // = (1<<OWNER) | (1<<ISSUER) | (1<<ASSET) // Owner + Issuer + Asset
    }

    event OracleUpdate(address indexed oracle, bool indexed trusted);
    event AnchorTransfer(address indexed from, address indexed to, bytes32 indexed anchor, uint256 tokenId);
    event AttestationUsed(address indexed to, bytes32 indexed anchor, bytes32 indexed attestationHash, uint256 totalUsedAttestationsForAnchor);
    event ValidAnchorsUpdate(bytes32 indexed validAnchorHash, address indexed maintainer);

    // state requesting methods
    function anchorByToken(uint256 tokenId) external view returns (bytes32 anchor);
    function tokenByAnchor(bytes32 anchor) external view returns (uint256 tokenId);
    function attestationsUsedByAnchor(bytes32 anchor) external view returns (uint256 usageCount);
    function decodeAttestationIfValid(bytes memory attestation) external view returns (address to, bytes32 anchor, bytes32 attestationHash);
    function anchorIsReleased(bytes32 anchor) external view returns (bool isReleased);


    /**
     * @notice Adds or removes a trusted oracle, used when verifying signatures in `decodeAttestationIfValid()`
     * @dev Emits OracleUpdate
     * @param _oracle address of oracle
     * @param _isTrusted true to add, false to remove
     */
    function updateOracle(address _oracle, bool _isTrusted) external;

    /**
     * @notice Transfers the ownership of an NFT mapped to attestation.anchor to attestation.to address. Uses ERC721 safeTransferFrom and safeMint.
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation. 
     *      When using centralized "transaction-signers" (paying for gas), implement IERCxxxxAttestationLimited!
     *      
     *      Throws when attestation invalid or already used, 
     *      Throws when attestation.to == ownerOf(tokenByAnchor(attestation.anchor)). See EIP-XXXX
     *      Emits AnchorTransfer and AttestationUsed  
     *  
     * @param attestation Attestation, refer EIP-XXXX for details
     * 
     * @return anchor The anchor, which is mapped to `tokenId`
     * @return to The `to` address, where the token with `tokenId` was transferd
     * @return tokenId The tokenId, which is mapped to the `anchor`     * 
     */
    function transferAnchor(bytes memory attestation) external returns (bytes32 anchor, address to, uint256 tokenId);

     /**
     * @notice Approves attestation.to the token mapped to attestation.anchor. Uses ERC721.approve(to, tokenId).
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *      When using centralized "transaction-signers" (paying for gas), implement IERCxxxxAttestationLimited!
     * 
     *      Throws when attestation invalid or already used
     *      Throws when ERCxxxxRole.ASSET is not authorized to approve
     * 
     * @param attestation Attestation, refer EIP-XXXX for details 
     */
    function approveAnchor(bytes memory attestation) external;

    /**
     * @notice Burns the token mapped to attestation.anchor. Uses ERC721._burn.
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *      When using centralized "transaction-signers" (paying for gas), implement IERCxxxxAttestationLimited!
     * 
     *      Throws when attestation invalid or already used
     *      Throws when ERCxxxxRole.ASSET is not authorized to burn
     * 
     * @param attestation Attestation, refer EIP-XXXX for details 
     */
    function burnAnchor(bytes memory attestation) external;

    
    /// @notice Update the Merkle root containing the valid anchors. Consider salt-leaves!
    /// @dev Proof (transferAnchor) needs to provided from this tree. 
    /// @dev The merkle-tree needs to contain at least one "salt leaf" in order to not publish the complete merkle-tree when all anchors should have been dropped at least once. 
    /// @param merkleRootNode The root, containing all anchors we want validated.
    function updateValidAnchors(bytes32 merkleRootNode) external;
}
```

#### Caveats

- MUST implement ERC-721 and ERC-165
- MUST ensure tokens only exist for valid `ANCHORS`
- MUST define a `maxAttestationValidTime`, which is enforced in case an `ATTESTATION`'s `expireTime` is bigger.
- MUST have bidirectional mapping `tokenPerAnchor[anchor]` and `anchorPerToken[token]`. This implies that a maximum of one token per `ANCHOR` exists.
- MUST have `anchorIsReleased[anchor]`, indicating which particular anchors are currently released, i.e. can be transfered or minted. 
  - This is the key mechanism for token transfer mechanism extension.
  - This MAY be used to implement FLOATING, a "temporary" decoupling between ASSET and tokens. See "FLOATING"
- MUST have a mechnism to determine whether an ANCHOR is valid for the contract. This is typically implemented via MerkleTrees.
  - MUST implement `validAnchor(anchor, proof)` which returns true when anchor is valid, i.e. MerkleProof is correct, false otherwise.
- MUST implement `decodeAttestationIfValid(attestation)`
  - Returns `attestation.to`, `attestation.anchor`, `attestation.attestationHash`
  - MUST throw when 
    - `ATTESTATION` originates from a non-trusted `ORACLE`.
    - `ATTESTATION` has expired, either when
      - WHEN `attestation.attestationTime + maxAttestationValidTime > block.timestamp`
      - OR when `block.timestamp > attestation.expireTime`
    - `ATTESTATION` has already been used. "Used" being defined in at least one transfer has been made using a particular `ATTESTATION`.
    - `validAnchor(attestation.anchor, attestation.proof)` returns `false`
  - RECOMMENDED to call a hook `_beforeAttestationUse(to, anchor)` before returning decoded data
  - MAY throw under OPTIONAL additional conditions, typically implemented by using the `_beforeAttestationUse`
- MUST extend ERC-721 token transfer mechanisms by adding additional throw conditions to `transferFrom`. 
  - MUST throw when `anchorIsReleased[anchorByToken[tokenId]] == false`
  - MUST throw when batchSize > 1, i.e. no batch transfers are supported with this contract.
  - RECOMMENDED to implement the above through ERC721 `_beforeTokenTransfer` hook
  - MUST emit `AnchorTransfer(from, to, anchorByToken[tokenId], tokenId)`

- MUST implement `attestationsUsedByAnchor(anchor)`, returning how many attestations have already been used for a specific anchor.

- MUST implement `transferAnchor(attestation)`, `burnAnchor(attestation)`, `approveAnchor(attestation)` which
  - MUST use the `decodeAttestationIfValid(attestation)` to determine `to`, `anchor` and `attestationHash`
  - MUST record each `attestation` used to authorize each token transfer. RECOMMENDED by storing each used `attestationHash`
  - MUST increment `attestationsUsedByAnchor[anchor]`, whenever an associated token has been transferred through this method
  - MUST emit `AttestationUsed`
  - `transferAnchor(attestation)`, corresponding to ERC721 `safeTransferFrom(from, to, tokenId)` and also responsible for minting further
    - MUST temporarily set `anchorIsReleased[anchor]=true` to allow a transfer or mint
    - MUST ensure `anchorIsReleased[anchor]` has the same state as before `transferAnchor()` has been invoked.
    - MUST either
      - call `_safeTransferFrom(ownerOf(tokenByAnchor[anchor]), to, tokenByAnchor[anchor])` when `tokenByAnchor[anchor]` exists
      - or create a new token wrapping the `ANCHOR` through calling the de-facto standard `_safeMint(to, newTokenId)` if `tokenByAnchor[anchor]` does not exist. It is RECOMMENDED use the ERC721-Enumerable mechanics to acquire `newTokenId`.
    - MUST emit `AnchorTransfer(from, to, anchor, tokenByAnchor[anchor])`
  - burnAnchor(attestation), corresponding to ERC721 `burn(tokenId)` 
    - TODO, see reference IMPL in the meantime
  - approveAnchor(attestation), corresponding to ERC721 `approve(to, tokenId)`
    - TODO, see reference IMPL in the meantime

- MUST implement ERC721 `burn()`

- RECOMMENDED to have a `tokenURI(tokenId)` implemented to return an anchorBased-URI, i.e. `baseURI/anchor`. (= Anchoring metadata to anchored ASSET). Before an anchor is not used for the first time, the ANCHOR's mapping to tokenId is unknown. Hence, using the anchor instead of the tokenId is preferred.

- RECOMMENDED to implement any or multiple of the following interfaces: transferable(tokenId), isSoulbound(tokenId), isNonTransferable (), `isNonTransferable(tokenId)` according to IERC6454.

- MAY implement the `IERCxxxxAttestationLimited` interface. This is a MUST when transaction-costs are provided through a central account, e.g. through the ORACLE (or associated authorities) itself to avoid fund-draining.

- MAY implement the `IERCxxxxFloatable` interface. 



### ERC-XXXX Attestation-limited (WIP!)
```
interface IERCxxxxAttestationLimited {
    enum AttestedTransferLimitUpdatePolicy {
        IMMUTABLE,
        INCREASE_ONLY,
        DECREASE_ONLY,
        FLEXIBLE
    }
    function updateGlobalAttestedTransferLimit(uint256 _nrTransfers) external;
    function attestatedTransfersLeft(bytes32 _anchor) external view returns (uint256 nrTransfersLeft);

    event GlobalAttestedTransferLimitUpdate(
        uint256 indexed transferLimit,
        address updatedBy
    );

    event AttestedTransferLimitUpdate(
        uint256 indexed transferLimit,
        bytes32 indexed anchor,
        address updatedBy
    );
}
```

- MUST extend ERC-XXXX
- MUST implement `transferLimit(anchor)`, specifying how often an `ANCHOR` can be transferred in total. The contract
  - SHALL support different transfer limit update modes, namely FIXED, INCREASABLE, DECREASABLE, FLEXIBLE (= INCREASABLE and DECREASABLE)
  - MUST immutably define one of the above listed modes expose it via `transferLimitUpdateMode()`
  - RECOMMENDED to have a global transfer limit, which can be overwritten on a token-basis (when `transferLimitUpdateMode() != FIXED`)
- MUST implement `transfersLeft(anchor)`, returning the number of transfers left (i.e. `transferLimit(anchor)-transfersPerAnchor[anchor]`) for a particular anchor
- MAY be immutably configureable (at deploytime), wheter transfer limit is FIXED, INCREASABLE, DECREASABLE, FLEXIBLE (= INCREASABLE and DECREASABLE)
- RECOMMENDED to have a global transfer limit, which can be overwritten on a token-basis (if not configured as FIXED)
- The above mechanism MAY be used for DeFi application, lending etc to temporarily block transferAnchor(anchor), e.g. over a renting or lending period.


### ERC-XXX Floatable (WIP!!)
```
interface IERCxxxxFloatable is IERCxxxx {
    function canStartFloating(ERCxxxxAuthorization op) external;
    function canStopFloating(ERCxxxxAuthorization op) external;

    function allowFloating(bytes32 anchor, bool _doFloat) external;
    function isFloating(bytes32 anchor) external view returns (bool);

    event AnchorFloatingState(
        bytes32 indexed anchor,
        uint256 indexed tokenId,
        bool indexed isFloating
    );

    event CanStartFloating(
        ERCxxxxAuthorization indexed authorization,
        address maintainer
    );

   event CanStopFloating(
        ERCxxxxAuthorization indexed authorization,
        address maintainer
    );
}
```

- MUST have an immutable `canFloat` boolean, indicating whether anchors can be released temporarily, i.e. the ASSET is floating. If `canFloat==false`, tokens can only be transferred with ATTESTATION. RECOMMENDED to set canFloat via constructor at deploy time.

## Additional Specifications for PHYSICAL ASSETS and ANCHOR-TECHNOLOGY

In case the `ASSET` is a physical object, good or property, the following ADDITIONAL specifications MUST be satisifed:

### ORACLE for Physical Anchors

- Issuing an `ATTESTATION` requires that the `ORACLE`
  - MUST proof physical proximity between an input device (e.g. smartphone) specifying the `to` address and a particular physical `ANCHOR` and it's associated physical object. Typical acceptable proximity is ranges between some millimeters to several meters.
  - The physical presence MUST be verified beyond reasonable doubt, in particular the employed method
    - MUST be robust against duplication or reproduction attempts of the physical `ANCHOR`,
    - MUST be robust against spoofing (e.g. presentation attacks) etc.
  - MUST be implemented under the assumption that the party defining the `to` address has malicious intent and to acquire false `ATTESTATION`, without currently or ever having access to the physical object comprising the physical `ANCHOR`.

### Physical ASSET

- MUST comprise an `ANCHOR`, acting as the unique physical object identifier, typically a serial number (plain (NOT RECOMMENDED) or hashed (RECOMMENDED))
- MUST comprise a physical security device, marking or any other feature that enables proofing physical presence for `ATTESTATION` through the `ORACLE`
- Is RECOMMENDED to employ ANCHOR-TECHNOLOGIES featuring irreproducible security features.
- In general it is NOT RECOMMENDED to employ ANCHOR-TECHNOLOGIES that can easily be replicated (e.g. barcodes, "ordinary" NFC chips, .. ). Replication includes physical and digital replication.

## Specification when using digital ASSETs

TODO - if any input?

## Alternatives Considered
- Soulbound burn+mint combination, e.g. through Consensual Soulbound Tokens (EIP-5484). Disregarded because appearance is highly dubious, when the same asset is represented through multiple tokens over time. An predecessor of this EIP has used this approach and can be found at [Mumbai Testnet](https://mumbai.polygonscan.com/address/0xd04c443913f9ddcfea72c38fed2d128a3ecd719e), in particular [this transaction](https://mumbai.polygonscan.com/tx/0xe5ff2c505c80249c60c84621ff6ee13432acf6f3d9a9dd5c065d5ea77ff7bc8e).



## Rationale

<!--
  The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

  The current placeholder is acceptable for a draft.

  TODO: Remove this comment before submitting
-->

TODO not really started

TODO make a point that NFTs today are often seen as asset and that decoupling the asset from the NFT has the benefit, of the token can being stolen, but this does not mean the asset is stolen. 

Why 1:1 support only? For N:1 etc, use a contract to proxy or wrap this contract.

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
TODO: Migrate from reference implementation and add to assets/eip-xxxx/

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
TODO: Find legal language for the following:
- Certain Systems, e.g. the one according to Figure 1, may be subject to patent-pending EPxxxxx / USxxxx (not published yet) and a license may be required. Check with (add way of contact here). 
- We do declare, that we explicitely waive copyright and XXX for the present EIP-xxxx and the provided ERC-xxxx reference implementation, i.e. we license the EIP under TODO SPDX-license string  
