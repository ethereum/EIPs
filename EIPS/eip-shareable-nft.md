---
eip: to-be-numberd
title: Shareable non-transferable non-fungible token standard
description: A standard interface for shareable non-transferable NFTs
author: ATARCA team
discussions-to: https://ethereum-magicians.org/t/new-nft-concept-shareable-nfts/8681
status: Draft
type: Standards Track
category: ERC
created: 2022-01-28
requires: 165
---

## Abstract

The following defines a standard interface for shareable tokens used in [ATARCA project](https://atarca.eu/) (Grant agreement 964678) to create shareable non-transferable non-fungible tokens. The standard allows creation of tokens that can hold value, but cannot be exchanged for rival goods such as money, cryptocurrencies or other goods that hold monetary value. Shareability of tokens can be understood as re-minting of a token for a new recipient e.g. by making a copy of the token and by giving it away while retaining the original one. The sharing and its associated events allow construction of a graph describing who has shared what to which party.

## Motivation

Traditional NFT standards such as ERC-721 and ERC-1155 have been developed to introduce artificial digital scarcity and to capture rival value. NFT standards and implementations don't necessarily have to be exhibit scarcity and in certain use cases such as in ATARCA project we wish to avoid introduction of deliberate scarcity. 

In ATARCA project we attempt to capture positive externalities in ecosystems with new types of incentive mechanisms that exhibit anti-rival logic, serve as an unit of accounting and function as medium of sharing. We envision that shareable tokens can work both as incentives but also as representations of items that are typically digital in their nature and gain more value as they are shared.

These requirements have set us to define shareable non-transferable NFTs. These shareable NFTs can be “shared” in the same way digital goods can be shared, at an almost zero technical transaction cost. They are used to instantiate quantified anti-rival value, a medium of sharing. Hence, they work somewhat as money, being a store of value and a unit of account, but instead of being a medium of exchange, they are a medium of sharing.

Typical NFT standards such as ERC-721 and ERC-1155 do not define a sharing modality. Instead ERC standards define user interfaces for typical rival use cases such as token minting and token transactions that the NFT contract implementations should fulfil. The ‘standard’ contract implementations may extend the functionalities beyond the definition of interfaces. The tokens developed in the ATARCA experiments are designed to be token standard compatible at the interface level. However the implementation of token contracts may contain extended functionalities to match the requirements of the experiments such as the requirement of 'shareability'. In reflection to standard token definitions, shareability of a token could be thought of as re-mintability of an existing token. Contracts define re-mintable non-transferable tokens which retain some reference to previous tokens upon and after re-minting.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

```solidity
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERCsntNFT is IERC165 {

  /// @dev This emits when a token is shared, reminted and given to another wallet that isn't function caller
  event Share(address indexed from, address indexed to, uint256 indexed tokenId, uint256 derivedFromtokenId);

  /// @dev Shares, remints an existing token, gives a newly minted token a fresh token id, keeps original token at function callers possession and transfers newly minted token to receiver which should be another address than function caller. 
  function share(address to, uint256 tokenIdToBeShared, uint256 newTokenId) external virtual;

} 
```

## Rationale

Current NFT standards define transferable non-fungible tokens. However to be able to create shareable NFTs we see that existing NFT contracts could be extended with an interface which defines the basic principles of sharing, namely the Event of sharing and the function method of sharing. In ATARCA we have chosen to go with shareable non-transferable NFTs which in our use case denote an award or merit for done effort. 

Shareable tokens can be transferable or non-transferable as it is up to implementation details of the token contract. In the reference implementation we have a general case distilled from the ATARCA case that defines a shareable non-transferable NFTs using the shareable NFT interface.



## Backwards Compatibility

TBD

## Reference Implementation

Following reference implementation demonstrates a general use case of one of our pilots. In this case a shareable non-transferable token represents a contribution done to a community that the contract owner has decided to merit with a token. Contract owner can mint a merit token and give it to a person. This token can be further shared by the receiver to other parties for example to share the received merit to others that have participated or influenced his contribution.

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERCsntNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShareableERC721 is ERC721URIStorage, Ownable, IERCsntNFT {

  string baseURI;
    
  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

  function mint(
        address account,
        uint256 tokenId
    ) external onlyOwner {
        _mint(account, tokenId);
  }

  function setTokenURI(
        uint256 tokenId, 
        string memory tokenURI
    ) external {
        _setTokenURI(tokenId, tokenURI);
  }

  function setBaseURI(string memory baseURI_) external {
        baseURI = baseURI_;
  }
    
  function _baseURI() internal view override returns (string memory) {
        return baseURI;
  }

  function share(address to, uint256 tokenIdToBeShared, uint256 newTokenId) external virtual {
      require(to != address(0), "ERC721: mint to the zero address");
      require(_exists(tokenIdToBeShared), "ShareableERC721: token to be shared must exist");
      require(!_exists(newTokenId), "token with given id already exists");
      
      require(msg.sender == ownerOf(tokenIdToBeShared), "Method caller must be the owner of token");

      string memory _tokenURI = tokenURI(tokenIdToBeShared);
      _mint(to, newTokenId);
      _setTokenURI(newTokenId, _tokenURI);

      emit Share(msg.sender, to, newTokenId, tokenIdToBeShared);
  }

  function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert('In this reference implementation tokens are not transferrable');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert('In this reference implementation tokens are not transferrable');
    }
}



```
## Security Considerations

TBD

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
