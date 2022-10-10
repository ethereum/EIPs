---
eip: <to be assigned>
title: Multi-Resource Token standard
description: A standard interface for Multi-Resource tokens.
author: Bruno Škvorc (@Swader), Cicada (@CicadaNCR), Steven Pineda (@steven2308), Stevan Bogosavljevic (@stevyhacker), Jan Turk (@ThunderDeliverer)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-10-10
requires: [165](./eip-165.md), [721](./eip-721.md)
---

## Abstract

The Multi-Resource NFT standard allows for the construction of a new primitive: context-dependent output of multimedia information per single NFT.

An NFT can have multiple resources (outputs), and orders them by priority. They do not have to match in mimetype or tokenURI, nor do they depend on one another. Resources are not standalone entities, but should be thought of as “namespaced tokenURIs” that can be ordered at will by the NFT owner, but only modified, updated, added, or removed if agreed on by both the owner of the token and the issuer of the token.

## Motivation

In the four years since the original [EIP-721](./eip-721.md) was published, the need for additional utility resulted in countless implementations on how to provide it. The Multi-Resource Non-Fungible Token standard improves upon it in the following areas:

- [Cross-metaverse compatibility](#cross-metaverse-compatibility)
- [Multi-media output](#multi-media-output)
- [Media redundancy](#media-redundancy)
- [NFT evolution](#nft-evolution)

### Cross-metaverse compatibility

Cross-metaverse compatibility could also be referred to as cross-engine compatibility and (for example) solves the issue where cosmetic item for game A is not portable into game B because the engines are different - it is not a simple matter of just having said cosmetic item, or an NFT.

With Multi-Resource NFTs, it is.

One resource is a cosmetic item for game A, an actual cosmetic item file. Another is a cosmetic item file for game B. A third is a generic resource intended to be shown in catalogs, marketplaces, portfolio trackers - a representation, stylized thumbnail, or animated demo or trailer of the cosmetic item that renders outside of any of the two games.

When using the NFT in such a game, not only don't the game developers need to pre-build the asset into the game and then allow it based on NFT balance in the logged in web3 account, but the NFT has everything it needs in its cosmetic item file, making storage and ownership of this cosmetic item decentralized and not reliant on the game development team.

After the fact, this NFT can be given further utility by means of new additional resources: more games, more cosmetic items, appended to the same NFT. Thus, a game cosmetic item as an NFT becomes an ever-evolving NFT of infinite utility.

### Multi-media output

An NFT that is an eBook can be both a PDF and an audio file at the same time, and depending on which software loads it, that is the media output that gets consumed: PDF if loaded into an eBook reader, audio if loaded into an audio book application. Additionally, an extra resource that is a simple image can be present in the NFT, intended for showing on the various marketplaces, SERP pages, portfolio trackers and others - perhaps the book’s cover image.

### Media redundancy

Many NFTs are minted hastily without best practices in mind - specifically, many NFTs are minted with metadata centralized on a server somewhere or, in some cases, a hardcoded IPFS gateway which can also go down, instead of just an IPFS hash.

By adding the same metadata file as different resources, e.g., one resource of a metadata and its linked image on Arweave, one resource of this same combination on Sia, another of the same combination on IPFS, etc., the resilience of the metadata and its referenced media increases exponentially as the chances of all the protocols going down at once become less likely.

### NFT evolution

Many NFTs, particularly game related ones, require evolution. This is especially the case in modern metaverses where no metaverse is actually a metaverse - it is just a multiplayer game hosted on someone’s server which replaces username/password logins with reading an account's NFT balance.

When the server goes down or the game shuts down, the player ends up with nothing (loss of experience) or something unrelated (resources or accessories unrelated to the game experience, spamming the wallet, incompatible with other “verses” - see [cross-metaverse](#cross-metaverse-compatibility) compatibility above).

With Multi-Resource NFTs, a minter or another pre-approved entity is allowed to suggest a new resource to the NFT owner who can then accept it or reject it. The resource can even target an existing resource which is to be replaced.

This allows level-up mechanics where, once enough experience has been collected, a user can accept the level-up. The level-up consists of a new resource being added to the NFT, and once accepted, this new resource replaces the old one.

As a concrete example, think of Pokemon™️ evolving - once enough experience has been attained, a trainer can choose to evolve their monster. With Multi-Resource NFTs, it is not necessary to have centralized control over metadata to replace it, nor is it necessary to airdrop another NFT into the user’s wallet - instead, a new Raichu resource is minted onto Pikachu, and if accepted, the Pikachu resource is gone, replaced by Raichu, which now has its own attributes, values, etc.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

````solidity
/// @title ERC-**** Multi-Resource Token Standard
/// @dev See https://eips.ethereum.org/EIPS/********
///  Note: the ERC-165 identifier for this interface is 0x********.
pragma solidity ^0.8.9;

interface IMultiResource {

    struct Resource {
      uint64 id;
      string metadataURI;
    }

    /// @dev This emits whenever a resource is set.
    event ResourceSet(uint64 id);

    /// @dev This emits whenever a pending resource has been added to a token's pending resources.
    event ResourceAddedToToken(uint256 indexed tokenId, uint64 resourceId);

    /// @dev This emits whenever a resource has been accepted by the token owner.
    event ResourceAccepted(uint256 indexed tokenId, uint64 resourceId);

    /// @dev This emits whenever a pending resource has been dropped from the pending resources array.
    event ResourceRejected(uint256 indexed tokenId, uint64 resourceId);

    /// @dev This emits whenever a token's resource's priority has been set.
    event ResourcePrioritySet(uint256 indexed tokenId);

    /// @dev This emits whenever a pending resource also proposes to overwrite an existing resource.
    event ResourceOverwriteProposed(uint256 indexed tokenId, uint64 resourceId, uint64 overwrites);

    /// @dev This emits whenever a pending resource overwrites an existing resource.
    event ResourceOverwritten(uint256 indexed tokenId, uint64 overwritten);

    /// @notice Accepts the resource from pending resources.
    /// @dev Moves the resource from the pending array to the accepted array. Array
    ///  order is not preserved.
    /// @param tokenId The ID of the token to accept a resource
    /// @param index The index of the resource in the pending resources array to accept
    function acceptResource(uint256 tokenId, uint256 index) external;

    /// @notice Rejects a resource, dropping it from the pending array.
    /// @dev Drops the resource from the pending array. Array order is not preserved.
    /// @param tokenId The ID of the token to reject a resource
    /// @param index The index of the resource in the pending resources array to reject
    function rejectResource(uint256 tokenId, uint256 index) external;

    /// @notice Rejects all resources, clearing the pending array.
    /// @dev Sets the pending array to empty.
    /// @param tokenId The ID of the token to reject all resources from
    function rejectAllResources(uint256 tokenId) external;

    /// @notice Sets the priority of the active resources array.
    /// @dev Priorities have a 1:1 relationship with their corresponding index in
    ///  the active resources array. E.g., a priority array of [1, 3, 2] indicates
    ///  that the the active resource at index 1 of the active resource array
    ///  has a priority of 1, index 2 has a priority of 3, and index 3 has a priority
    ///  of 2. There is no validation on priority value input; out of order indexes
    ///  must be handled by the frontend.
    /// @dev The length of the priorities array MUST
    ///  be equal to the present length of the active resources array.
    /// @param tokenId the ID of the token of the resource priority to set
    /// @param priorities An array of priorities to set.
    function setPriority(uint256 tokenId, uint16[] memory priorities) external;

    /// @notice Returns an array of uint64 identifiers from the active resources
    ///  array for resource lookup.
    /// @dev Each uint64 resource corresponds to the ID of the relevant resource
    ///  in the storage.
    /// @param tokenId The ID of the token of which to retrieve the active resource set
    /// @return An array of uint64 resource IDs corresponding to active resources
    function getActiveResources(uint256 tokenId) external view returns(uint64[] memory);

    /// @notice Returns an array of uint64 identifiers from the pending resources
    ///  array for resource lookup.
    /// @dev Each uint64 resource corresponds to the ID of the relevant resource
    ///  in the storage.
    /// @param tokenId The ID of the token of which to retrieve the pending resource set
    /// @return An array of uint64 resource IDs corresponding to pending resources
    function getPendingResources(uint256 tokenId) external view returns(uint64[] memory);

    /// @notice Returns an array of uint16 resource priorities.
    /// @dev No validation is done on resource priority ranges, sorting MUST be
    ///  handled by the frontend.
    /// @param tokenId The ID of the token of which to retrieve the active resource set
    ///  priorities
    /// @return An array of uint16 resource priorities corresponding to active resources
    function getActiveResourcePriorities(uint256 tokenId) external view returns(uint16[] memory);

    /// @notice Returns the uint64 resource ID that would be overwritten when accepting the
    ///  pending resource with ID resId on token.
    /// @param tokenId The ID of the token of which we want to overwrite the pending resource
    /// @param resId The resource ID which MAY overwrite another
    /// @return A uint64 corresponding to the resource ID of the resource that would be overwritten
    function getResourceOverwrites(uint256 tokenId, uint64 resId) external view returns(uint64);

    /// @notice Returns raw bytes of `customResourceId` of `resourceId`
    /// @dev Raw bytes are stored by reference in a double mapping structure of
    ///  `resourceId` => `customResourceId`.
    /// @dev Custom data is intended to be stored as generic bytes and decode by
    ///  various protocols on an as-needed basis.
    /// @param resourceId The ID of the resource for which we are trying to retrieve the
    ///  resource meta
    /// @return The raw bytes of `customResourceId`
    function getResourceMeta(uint64 resourceId) external view returns (string memory);

    /// @notice Fetches resource data for the token's active resource with the given index.
    /// @dev Resources are stored by reference mapping _resources[resourceId].
    /// @dev MAY be overridden to implement enumerate, fallback or other custom logic.
    /// @param tokenId The ID of the token for which we are getting the resource data for
    /// @param resourceIndex The index of the active resource in the token
    /// @return The metadata URI for the the resource we are fetching
    function getResourceMetaForToken(uint256 tokenId, uint64 resourceIndex) external view returns (string memory);

    /// @notice Returns the IDs of all of the stored resources.
    function getAllResources() external view returns (uint64[] memory);

    /// @notice Change or reaffirm the approved address for resources for an .
    /// @dev The zero address indicates there is no approved address.
    /// @dev MUST revert unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @dev MUST emit ApprovalForResources event.
    /// @param to The new approved token controller
    /// @param tokenId The ID of the token to approve
    function approveForResources(address to, uint256 tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  resources for all of the `msg.sender`'s assets.
    /// @dev MUST emit the ApprovalForAllForResources event.
    /// @dev The contract MUST allow multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True if the operator is approved, false to revoke approval
    function setApprovalForAllForResources(address operator, bool approved) external;

    /// @notice Get the approved address for resources for a single token.
    /// @dev MUST revert if `tokenId` is not a valid token ID.
    /// @param tokenId The ID of the token to find the approved address for
    /// @return The approved address for this token, or the zero address if there is none
    function getApprovedForResources(uint256 tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for resources of
    ///  another address.
    /// @param owner The address that owns the tokens
    /// @param operator The address that acts on behalf of the owner
    /// @return True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAllForResources(address owner, address operator) external view returns (bool);

}

interface ERC165 {

    function supportsInterface(bytes4 interfaceID) external view returns (bool);

}
````

## Rationale

With NFTs being a widespread form of tokens in the Ethereum ecosystem and being used for a variety of use cases, it is time to standardize additional utility for them. Having multiple resources associated with a single NFT allows for greater utility and usability.

### Resource fields

The MultiResource token standard supports two resource fields:

- `id`: a `uint64` resource identifier
- `metadataURI`: a `string` pointing to the metadata URI associated with the resource

### Multi-Resource Storage Schema

Resources are stored within a token as an array of `uint64` identifiers.

In order to reduce redundant on-chain string storage, multi resource tokens store resources by reference via inner storage. A resource entry on the storage is stored via a `uint64` mapping to resource data.

A resource array is an array of these `uint64` resource ID references.

Such a structure allows that, a generic resource can be added to the storage one time, and a reference to it can be added to the token contract as many times as we desire. Implementers can then use string concatenation to procedurally generate a link to a content-addressed archive based on the base *SRC* in the resource and the *token ID*. Storing the resource in a new token will only take 16 bytes of storage in the resource array per token for recurrent as well as `tokenId` dependent resources.

Structuring token's resources in such a way allows for URIs to be derived programmatically through concatenation, especially when they differ only by `tokenId`.

### Propose-Commit pattern for resource addition

Adding resources to an existing token MUST be done in the form of a propose-commit pattern to allow for limited mutability by a 3rd party. When adding a resource to a token, it is first placed in the *"Pending"* array, and MUST be migrated to the *"Active"* array by the token's owner. The *"Pending"* resources array SHOULD be limited to 128 slots to prevent spam and griefing.

### Resource management

Several functions for resource management are included. In addition to permissioned migration from "Pending" to "Active", the owner of a token MAY also drop resources from both the active and the pending array -- an emergency function to clear all entries from the pending array MUST also be included.

## Backward compatibility

The MultiResource token standard has been made compatible with [EIP-721](./eip-721.md) in order to take advantage of the robust tooling available for implementations of EIP-721 and to ensure compatibility with existing EIP-721 infrastructure.

## Test cases

The RMRK MultiResource lego block implementation includes test cases written using Hardhat.

## Reference implementations

[RMRK MultiResource lego block](https://github.com/rmrk-team/MultiResourceEIP) and [documentation](https://docs.rmrk.app/lego2-multi-resource)

- Compatible with the original version of the standard

Neon Crisis, by [CicadaNCR](https://github.com/CicadaNCR)

- A NFT game utilizing RMRK MultiResource lego block

Snake Soldiers, by [Steven Pineda](https://github.com/steven2308)

- A NFT game utilizing RMRK MultiResource lego block

### Implementation extras

We designed additional **internal** implementations of methods to be used to add resource entries and add resources to tokens, but these were not considered crucial for the proposal to be functional. We expect these functions to only be callable by an issuer or an administrator. This is achieved with an `onlyIssuer` modifier of the following example:

````solidity
pragma solidity ^0.8.15;

contract Issued {
    address private _issuer;

    constructor(){
        _setIssuer(_msgSender());
    }

    modifier onlyIssuer() {
        require(_msgSender() == _issuer, "RMRK: Only issuer");
        _;
    }

    function setIssuer(address issuer) external onlyIssuer {
        _setIssuer(issuer);
    }

    function getIssuer() external view returns (address) {
        return _issuer;
    }

    function _setIssuer(address issuer) private {
        _issuer = issuer;
    }
}
````

A `RenderUtils` utility smart contract was developed to aid in getting the metadata URIs for different use cases. Such utility smart contract can be deployed once per chain and provide services to all MultiResource NFT compatible smart contracts:

````solidity
interface IRenderUtils {
    /// @notice Returns resource metadata at `index` of active resource array on `tokenId`.
    /// @param target The address of the smart contract that we want to get the resource metadata
    /// @param tokenId The token ID of the token to which belongs the resource 
    /// @param index Index of the resource. It must be inside the range of active resource array
    /// @return A stringified metadata URI of the resource
    function getResourceByIndex(
        address target,
        uint256 tokenId,
        uint256 index
    ) external view returns (string memory);

    /// @notice Returns resource metadata at `index` of pending resource array on `tokenId`.
    /// @param target The address of the smart contract that we want to get the resource metadata
    /// @param tokenId The token ID of the token to which belongs the pending resource array
    /// @param index Index of the resource in the pending resources array. It must be inside the range of pending
    ///  resource array
    /// @return A stringified metadata URI of the pending resource
    function getPendingResourceByIndex(
        address target,
        uint256 tokenId,
        uint256 index
    ) external view returns (string memory);

    /// @notice Returns resource metadata for the given IDs.
    /// @param target The address of the smart contract that we want to get the resource metadata
    /// @param resourceIds Resource IDs for which to retrieve the metadata strings
    /// @return An array of metadata URIs for the requested resources
    function getResourcesById(address target, uint64[] calldata resourceIds)
        external
        view
        returns (string[] memory);

    /// @notice Returns the resource metadata with the highest priority for the given token.
    /// @param target The address of the smart contract that we want to get the resource metadata
    /// @param tokenId Token ID of which we are retrieving the metadata
    /// @return Metadata URI with the highest priority
    function getTopResourceMetaForToken(address target, uint256 tokenId)
        external
        view
        returns (string memory);
}
````

Example implementation of such utility can be found in the [RMRK's MultiResource lego block implementation](https://github.com/rmrk-team/MultiResourceEIP/blob/master/contracts/MultiResource_EIP/utils/RenderUtils.sol).

## Security considerations

The same security considerations as with [EIP-721](./eip-721.md) apply: hidden logic may be present in any of the functions, including burn, add resource, accept resource, and more.

Caution is advised when dealing with non-audited contracts.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).