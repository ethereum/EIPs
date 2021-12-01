---
title: "Non-Fungible Token with usage rights"
author: KKimos <bol@zju.edu.cn>
status: Draft
type: Standards Track
category: ERC
created: 2021-12-01
requires: 165, 721
---

## Simple Summary

Separation of Non-Fungible Token ownership and usage rights , Truly in line with real life.

## Abstract

This standard adds a new right of Non-Fungible Token that the right to use. Through this standard, you can achieve :

- Separation of the right to use and ownership of Non-Fungible Token
- Non-secured lease Non-Fungible Token
- You can continue to use it after you mortgage the Non-Fungible Token
- Metaverse sharing economy

It is precisely because of the separation of ownership and use right that the utilization rate of assets can be greater. You must distinguish between the rights of the user and the owner.

## Motivation

Uber, airbnb, and WeWork promote the development of the sharing economy. In the blockchain , the ERC721-based leasing system has encountered great bottlenecks. For example, excess assets need to be mortgaged for leasing, The increase in NFT prices will lead to defaults and mortgages,You cannot continue to use it during NFT. As a result, a new NFT standard is proposed, which is fully compatible with ERC721. Separate the right to use and own the NFT.

Different from 2615, we only added a right to use, so that we can get all the functions of 2615, and reduce many unnecessary operations in 2615. The explanation is as follows:

- The owner should not use some of the ownership rights when mortgage NFT, such as transfer, AXS-like breeding or weapon upgrade, because it is likely to change the status of the original NFT, so when the user mortgages the NFT, the ownership must be mortgaged in the contract middle.
- In the case of mortgage or transaction, the owner has the right to continue to use it before returning the ransom or selling it

## Specification

This standard adds the user role, and users can transfer their own usage rights.

### ERC-X Interface

```solidity
event TransferUser(address from,address to,uint256 tokenId);
event ApprovalUser(address indexed user, address indexed approved, uint256 indexed tokenId);
function balanceOfUser(address user) external view returns (uint256 balance);
function userOf(uint256 tokenId) external view returns (address user);  
function safeTransferUserFrom(
    address from,
    address to,
    uint256 tokenId
) external;
function safeTransferUserFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
) external;
function safeTransferAllFrom(
     address from,
     address to,
     uint256 tokenId
) external;    
function safeTransferAllFrom(
     address from,
     address to,
     uint256 tokenId,
     bytes calldata data
) external;
function approveUser(address to, uint256 tokenId) external;
function getApprovedUser(uint256 tokenId) external view returns (address operator);
```

### ERC-X Receiver

```solidity
function onERCXReceived(address operator, address from, uint256 itemId, uint256 layer, bytes memory data) public returns(bytes4);
```

### ERC-X Extensions

Extensions here are provided to help developers build with this standard.

#### 1. ERC-X Emurable	

```solidity
function tokenOfUserByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
function totalSupply() external view returns (uint256);
function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
function tokenByIndex(uint256 index) external view returns (uint256);
```

#### 2. ERC721

Fully compatible with ERC721

```solidity
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
```



## Rationale

#### 1 . Mortgage

When mortgage NFT, you only need to mortgage the right to use into the mortgage contract, leaving the right to use.The advantage of this is that you can still use your own NFT before delivery.

#### 2 . Rent 

Lease does not require any collateral. First, you mortgage the NFT ownership into the contract, and the tenantry leases the right to use.

This has the following benefits ：

- No need to mortgage assets
- Don't worry about the risk of default

## Backward compatibility

This protocol is fully backward compatible with ERC721.Refer to above Specification.



## Test Cases

When running the tests, you need to create a test network with Ganache-CLI:

```
ganache-cli -a 15  --gasLimit=0x1fffffffffffff -e 1000000000
```

And then run the tests using Truffle: 

```
truffle test -e development
```

Powered by Truffle and Openzeppelin test helper.

## Reference Implementation

[Github Reposotory](https://github.com/KKimos/ERCX).



## Security Considerations

When using the modified agreement, you must distinguish between the right of use and ownership. In theory, the right of use cannot change the NFT.



## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
