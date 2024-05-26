---
eip: <to be assigned>
title: "Embedded Semi-Fungible Token Standard"
description: "A proposal for embedding FTs within NFTs to achieve dual characteristics and functional interplay."
author: Zad Behzadi (@behzadz1), Zad Behzadi <zad.behzadi@opencred.xyz>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2024-05-24

---

## Abstract
This EIP proposes a new way of combining NFTs and FTs by nesting FTs within NFTs, creating a unique bonding and splitting mechanism. Based on this structure, NFTs and FTs can be functionally bound together. This structure allows NFTs and FTs to leverage their respective characteristics, achieving complementary traits and functional interplay, catering to single-token attribute use in specific scenarios or fulfilling both FT and NFT dual attributes.

## Motivation
Presently, asset types mainly include homogeneous assets represented by ERC-20, non-fungible assets represented by ERC-721, and semi-fungible assets represented by ERC-3475 and ERC-3525. However, these assets have not been able to demonstrate the use of the same token in different scenarios or clearly exhibit dual characteristics. While FTs (ERC-20) can be divided to enhance liquidity but lack the ability to express differentiation, NFTs (ERC-721 and ERC-1155) can express diversity but lack calculability and liquidity.

We propose a nested structure of NFTs and FTs that can:
- Achieve dual characteristics: NFT characteristics can be used for representation and differentiation, while FT characteristics can be used for scalar representation and liquidity enhancement. This structure can address NFT liquidity issues without splitting NFTs.
- Enable functional combinations: It allows for functional combinations between NFTs and FTs, such as synchronous transfers and functional controls (e.g., transferability control).

The "nesting" model of assets brings more usability and playability to Web3, for example:
- In the context of fan economies, different gifts can exist as outer assets, each embedding varying amounts of standard assets (such as "coins" or "support points"), where recipients may need to retain the gift's uniqueness (non-fungible) while extracting and utilizing its value (fungible).
- In another scenario, when building social relationships, there is a need to record unique relationships between different users (non-fungible), but a common measure (fungible) is required to assess the degree of the relationship.

Additionally, in contexts like art collection, in-game item exchanges, and other scenarios requiring the distinction of item uniqueness while trading or evaluating based on a common value, the nested token model defined in this proposal can play a significant role.

Quantifying NFT Value:
NFT value can be quantified by the number of FTs contained within it, representing its value and scarcity, rather than relying solely on metadata or simple numerical values.

Addressing NFT Liquidity Issues:
By binding the utility value of FTs with NFTs, where FTs represent the exchange value of NFTs, this proposal aims to address NFT liquidity issues. During transactions, extracting the FTs contained within an NFT (after extraction, the NFT is in an ownerless state and belongs to the contract) allows FTs to be used for transactions. Upon acquiring enough FTs, buyers can inject them into the target NFT to obtain it.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

### FT Contract
The FT contract must be associated with the NFT contract and ensure only the NFT contract can mint FTs.

```solidity
constructor(address nftAddress) ERC20("TOKEN", "TOKEN") {
    _nftAddress = nftAddress;
}

function mint(address account, uint256 amount) external {
    if (msg.sender != _nftAddress) revert InvalidOwner();
}

function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    uint256 fromBalance = balanceOf(from);
    require(NFT(_nftAddress).getTokenValue(from) + amount >= fromBalance, "transfer amount exceeds balance");
}

function transferFromNFT(address from, address to, uint256 amount) external {
    if (msg.sender != _nftAddress) revert InvalidOwner();
    _transfer(from, to, amount);
}
```

### NFT Contract
The NFT contract must inherit from ERC721 and implement specific interfaces to manage the binding and unbinding of FTs.

```solidity
contract NFT is ERC721, IERC {
    address tokenAddress;

    function setRelationship(address _tokenAddress) external {
        tokenAddress = _tokenAddress;
    }

    function splitNFT(uint256 tokenId) external;
    function bindNFT(uint256 tokenId) external;
    function getTokenValue(address owner) external view returns (uint256);
    function getNFTValue(uint256 tokenId) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(from != address(this), "address cannot be this contract address");
        beforeTransferFrom(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(from != address(this), "address cannot be this contract address");
        beforeTransferFrom(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function beforeTransferFrom(address from, address to, uint256 tokenId) internal {
        unchecked {
            _ownerTokenValue[from] -= _nftValue[tokenId];
            _ownerTokenValue[to] += _nftValue[tokenId];
        }

        (bool success,) = tokenAddress.call(
            abi.encodeWithSignature("transferFromNFT(uint256,uint256,uint256)", from, to, tokenId)
        );

        require(success);
    }
}
```

### Token Model
NFTs can be bound (nested) with FTs, directly representing the NFT and indirectly representing the FT. This structure can be described as the NFT being the shell and the FT being the content, enabling:
- Different NFTs to nest different quantities of FTs.
- Transfer of NFTs also transfers the nested FTs within them.
- Extraction and injection of FTs within NFTs to control NFT properties or functions, such as requiring a specific quantity of FTs for normal transfer.

## Rationale
The concept behind this EIP is to create a flexible token standard that captures the uniqueness of non-fungible tokens (NFTs) and the quantifiable value aspect of fungible tokens by nesting replaceable assets within semi-fungible tokens. By embedding replaceable assets within semi-fungible tokens, we support scenarios that require the combined use of both sets of properties.

## Backwards Compatibility

## Test Cases

## Reference Implementation

## Security Considerations

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
