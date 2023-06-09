---
title: ERC721 Multi-Metadata Extension
description: "This EIP proposes an extension to the ERC721 standards to support multiple metadata URIs per token via a new tokenURIs method that returns the pinned metadata index and a list of metadata URIs."
author: 0xG (@0xGh)
discussions-to: https://ethereum-magicians.org/t/erc721-multi-metadata-extension/14629
status: Draft
type: Standards Track
category: ERC
created: 2023-06-09
requires: EIP-165, EIP-721
---

## Abstract

This EIP proposes an extension to the ERC721 standards to support multiple metadata URIs per token. It introduces a new interface, IERC721MultiMetadata, which provides methods for accessing the metadata URIs associated with a token, including a pinned URI index and a list of all metadata URIs. The extension is designed to be backward compatible with existing ERC721Metadata implementations.

## Motivation

The current ERC721 standards allow for a single metadata URI per token. However, there are use cases where multiple metadata URIs are desirable, such as when a token represents a collection of (cycling) assets with individual metadata, historic token metadata, collaborative and multi-artist tokens, evolving tokens. This extension enables such use cases by introducing the concept of multi-metadata support.

## Specification

The IERC721MultiMetadata interface extends the existing IERC721 interface and introduces two additional methods:

```solidity
interface IERC721MultiMetadata is IERC721 {
  function tokenURIs(uint256 tokenId) external view returns (uint256 index, string[] memory uris);
  function pinTokenURI(uint256 tokenId, uint256 index) external;
  function unpinTokenURI(uint256 tokenId) external;
  function isPinnedTokenURI(uint256 tokenId) external view returns (bool pinned);
}
```

The `tokenURIs` function returns a tuple containing the pinned URI index and a list of all metadata URIs associated with the specified token. The `pinTokenURI` function allows the contract owner to designate a specific metadata URI as the pinned URI for a token.

The `tokenURI` function defined in the ERC721 standard can be modified to return the pinned URI or the last URI in the list returned by `tokenURIs` when there is not pinned URI. This ensures backward compatibility with existing contracts and applications that rely on the single metadata URI.

See the [Implementation](#Implementation) section for an example.

## Rationale

The `tokenURIs` function returns both the pinned URI index and the list of all metadata URIs to provide flexibility in accessing the metadata. The pinned URI can be used as a default or primary URI for the token, while the list of metadata URIs can be used to access individual assets' metadata within the token. Marketplaces could present these as a gallery or media carousels.

Depending on the implementation, the `pinTokenURI` function allows the contract owner or token owner to specify a particular metadata URI index for a token. This enables the selection of a preferred URI by index from the list of available metadata.

## Backward Compatibility

This extension is designed to be backward compatible with existing ERC721 contracts. The modified `tokenURI` function can either return the last URI in the list returned by tokenURIs or the pinned URI, depending on the implementation.

## Security Considerations

Care should be taken when implementing the extension to ensure that the metadata URIs are properly handled and validated. It is crucial to prevent malicious actors from manipulating or injecting harmful metadata.

## Test Cases

Test cases should be provided to cover the functionality of the IERC721MultiMetadata interface, including retrieving the pinned URI, retrieving the list of metadata URIs, and pinning/unpinning a specific metadata URI for a token. Additionally, tests should be performed to validate the backward compatibility of existing ERC721 contracts.

## Implementation

An open-source reference implementation of the IERC721MultiMetadata interface can be provided, demonstrating how to extend an existing ERC721 contract to support multi-metadata functionality. This reference implementation can serve as a guide for developers looking to implement the extension in their own contracts.

```solidity
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC721MultiMetadata.sol";

contract MultiMetadata is Ownable, ERC721, IERC721MultiMetadata {
  mapping(uint256 => string[]) _tokenURIs;
  mapping(uint256 => uint256) _pinnedURIIndices;
  mapping(uint256 => bool) _isPinnedTokenURI;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  // Returns the pinned URI index or the last token URI index (length - 1).
  function _getTokenURIIndex(uint256 tokenId) internal view returns (uint256) {
    return _isPinnedTokenURI[tokenId] ? _pinnedURIIndices[tokenId] : _tokenURIs[tokenId].length - 1;
  }

  // Implementation of ERC721.tokenURI for backwards compatibility.
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory uri = _tokenURIs[_getTokenURIIndex(tokenId)];

    // Revert if no URI is found for the token.
    require(bytes(uri).length > 0, "ERC721: not URI found");
    return uri;
  }

  // Retrieves the pinned URI index and the list of all metadata URIs associated with the specified token.
  function tokenURIs(uint256 tokenId) external view returns (uint256 index, string[] memory uris) {
    _requireMinted(tokenId);
    return (_getTokenURIIndex(tokenId), _tokenURIs[tokenId]);
  }

  // Sets a specific metadata URI as the pinned URI for a token.
  function pinTokenURI(uint256 tokenId, uint256 index) external {
    require(msg.sender == ownerOf(tokenId), "Unauthorized");
    _pinnedURIIndices[tokenId] = index;
    _isPinnedTokenURI[tokenId] = true;
    // Optionally emit token uri update (see EIP-4906)
  }

  // Unsets the pinned URI for a token.
  function unpinTokenURI(uint256 tokenId) external {
    require(msg.sender == ownerOf(tokenId), "Unauthorized");
    _pinnedURIIndices[tokenId] = 0;
    _isPinnedTokenURI[tokenId] = false;
    // Optionally emit token uri update (see EIP-4906)
  }

  // Checks if a token has a pinned URI.
  function isPinnedTokenURI(uint256 tokenId) external view returns (bool isPinned) {
    require(msg.sender == ownerOf(tokenId), "Unauthorized");
    return _isPinnedTokenURI[tokenId];
  }

  // Sets a specific metadata URI for a token at the given index.
  function setUri(uint256 tokenId, uint256 index, string calldata uri) external onlyOwner {
    _tokenURIs[tokenId][index] = uri;
    // Optionally emit token uri update (see EIP-4906)
  }

  // Overrides supportsInterface to include IERC721MultiMetadata interface support.
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
    return (
      interfaceId == type(IERC721MultiMetadata).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }
}
```

## Copyright

This work is licensed under the MIT License.
