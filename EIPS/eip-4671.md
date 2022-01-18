---
eip: 4671
title: Non-Tradable Tokens
description: A standard interface for non-tradable tokens.
author: Omar Aflak (@omaraflak), Pol-Malo Le Bris, Marvin Martin (@MarvinMartin24)
discussions-to: https://ethereum-magicians.org/t/eip-4671-non-tradable-token/7976?u=omaraflak
status: Draft
type: Standards Track
category: ERC
created: 2022-01-13
requires: 165
---

# Non-Tradable Token Standard

<!-- AUTO-GENERATED-CONTENT:START (TOC) -->
- [Simple Summary](#simple-summary)
- [Abstract](#abstract)
- [Motivation](#motivation)
- [Specification](#specification)
  - [Extensions](#extensions)
    - [Metadata](#metadata)
    - [Delegation](#delegation)
- [Rationale](#rationale)
  - [On-chain vs Off-chain](#on-chain-vs-off-chain)
- [Implementation](#implementation)
  - [NTT](#ntt)
  - [NTTDelegate](#nttdelegate)
- [NTT for EIP ?](#ntt-for-eip-)
- [Copyright](#copyright)
<!-- AUTO-GENERATED-CONTENT:END -->

## Simple Summary

A standard interface for <u>**non-tradable tokens**</u>, aka <u>**NTT**</u>s.

## Abstract

NTTs represent inherently personal possessions (material or immaterial), such as university diploma, online training certificates, government issued documents (national id, driving licence, visa, wedding, etc.), badges, labels, and so on.

As the name implies, NTTs are not made to be traded or transfered. They don't have monetary value. They are personally delivered to **you**, and they only serve as a **proof of possession**.

## Motivation

US, 2017, MIT published 111 diplomas on a blockchain. France, 2018, Carrefour multinational retail corporation used blockchain technology to certify the provenance of its chickens. South Korea, 2019, the state published 1 million driving licences on a blockchain-powered platform.

Each of them made their own smart contracts, with different implementations. We think diplomas, food labels, or driving licences are just a subset of a more general type of tokens: **non-tradable tokens**. Tokens that represent certificates or labels that were granted to you by some authority.

By providing a common interface for this type of tokens, we allow more applications to be developed and we position blockchain technology as a standard gateway for verification of personal possessions.

## Specification

A single NTT contract, is seen as representing one type of badge by one authority. For instance, one NTT contract for PSN achievements, another for Ethereum EIP creators, and so on...

* An address might possess multiple tokens, which are indexed.
* An authority who delivers a certificate should be in position to invalidate it. Think of driving licences or weddings. However, it cannot delete your token.
* The issuer of a token might be someone else than the contract creator.

<!-- AUTO-GENERATED-CONTENT:START (CODE:syntax=solidity&src=./contracts/INTT.sol) -->
<!-- The below code snippet is automatically added from ./contracts/INTT.sol -->
```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INTT is IERC165 {
    /// Event emitted when a token is minted by `issuer` to `owner`
    event Minted(address issuer, address owner, uint256 index);

    /// Event emitted when token `index` of `owner` is invalidated by `operator`
    event Invalidated(address operator, address owner, uint256 index);

    /// @notice Count all tokens assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of tokens owned by `owner`
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Check if a token hasn't been invalidated
    /// @param owner Address for whom to check the token validity
    /// @param index Index of the token
    /// @return True if the token is valid, False otherwise
    function isValid(address owner, uint256 index) external view returns (bool);

    /// @notice Get the issuer of a token
    /// @param owner Address for whom to check the token issuer
    /// @param owner Index of the token
    /// @return Address of the issuer
    function issuerOf(address owner, uint256 index) external view returns (address);
}
```
<!-- AUTO-GENERATED-CONTENT:END -->

### Extensions

#### Metadata

An interface allowing to add metadata linked to each token, as in ERC721.

<!-- AUTO-GENERATED-CONTENT:START (CODE:syntax=solidity&src=./contracts/INTTMetadata.sol) -->
<!-- The below code snippet is automatically added from ./contracts/INTTMetadata.sol -->
```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INTTMetadata {
    /// @return Descriptive name of the tokens in this contract
    function name() external view returns (string memory);

    /// @return An abbreviated name of the tokens in this contract
    function symbol() external view returns (string memory);

    /// @notice URI to query to get the token's metadata
    /// @param owner Address of the token's owner
    /// @param index Index of the token
    /// @return URI for the token
    function tokenURI(address owner, uint256 index) external view returns (string memory);

    /// @return Total number of tokens emitted by the contract
    function total() external view returns (uint256);
}
```
<!-- AUTO-GENERATED-CONTENT:END -->

#### Delegation

An interface to standardize delegation rights of token minting.

<!-- AUTO-GENERATED-CONTENT:START (CODE:syntax=solidity&src=./contracts/INTTDelegate.sol) -->
<!-- The below code snippet is automatically added from ./contracts/INTTDelegate.sol -->
```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INTTDelegate {
    /// @notice Grant one-time minting right to `operator` for `owner`
    /// An allowed operator can call the function to transfer rights.
    /// @param operator Address allowed to mint a token
    /// @param owner Address for whom `operator` is allowed to mint a token
    function delegate(address operator, address owner) external;

    /// @notice Grant one-time minting right to a list of `operators` for a corresponding list of `owners`
    /// An allowed operator can call the function to transfer rights.
    /// @param operators Addresses allowed to mint
    /// @param owners Addresses for whom `operators` are allowed to mint a token
    function delegateBatch(address[] memory operators, address[] memory owners) external;

    /// @notice Mint a token. Caller must have the right to mint for the owner.
    /// @param owner Address for whom the token is minted
    function mint(address owner) external;

    /// @notice Mint tokens to multiple addresses. Caller must have the right to mint for all owners.
    /// @param owners Addresses for whom the tokens are minted
    function mintBatch(address[] memory owners) external;
}
```
<!-- AUTO-GENERATED-CONTENT:END -->

## Rationale

### On-chain vs Off-chain

A decision was made to keep the data off-chain (via `tokenURI()`) for two main reasons: 
* Non-Tradable Tokens represent personal possessions. Therefore, there might be cases where the data should be encrypted. The standard should not outline decisions about encryption because there are just so many ways this could be done, and every possibility is specific to the use-case.
* Non-Tradable Tokens must stay generic. There could have been a possibility to make a `MetadataStore` holding the data of NTTs in an elegant way, unfortunately we would have needed a support for generics in solidity (or struct inheritance), which is not available today.

## Implementation

### NTT

<!-- AUTO-GENERATED-CONTENT:START (CODE:syntax=solidity&src=./contracts/NTT.sol) -->
<!-- The below code snippet is automatically added from ./contracts/NTT.sol -->
```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./INTT.sol";
import "./INTTMetadata.sol";

abstract contract NTT is INTT, INTTMetadata, ERC165 {
    // Token data
    struct Token {
        address issuer;
        bool valid;
    }

    // Mapping from owner to tokens
    mapping (address => Token[]) private _balances;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Total number of tokens emitted
    uint256 private _total;

    // Contract creator
    address private _creator;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _creator = msg.sender;
    }

    /// @notice Count all tokens assigned to an owner
    /// @param owner Address for whom to query the balance
    /// @return Number of tokens owned by `owner`
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "balance query for the zero address");
        return _balances[owner].length;
    }

    /// @notice Check if a token is hasn't been invalidated
    /// @param owner Address for whom to check the token validity
    /// @return True if the token is valid, false otherwise
    function isValid(address owner, uint256 index) public view virtual override returns (bool) {
        return _getTokenOrRevert(owner, index).valid;
    }

    /// @notice Get the issuer of a token
    /// @param owner Address for whom to check the token issuer
    /// @param owner Index of the token
    /// @return Address of the issuer
    function issuerOf(address owner, uint256 index) public view virtual override returns (address) {
        return _getTokenOrRevert(owner, index).issuer;
    }

    /// @notice Get all the tokens of an account
    /// @param owner Address for whom to get the tokens
    /// @return Array of tokens
    function tokensOf(address owner) public view virtual returns (Token[] memory) {
        return _balances[owner];
    }

    /// @return Descriptive name of the tokens in this contract
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @return An abbreviated name of the tokens in this contract
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @notice URI to query to get the token's metadata
    /// @param owner Address of the token's owner
    /// @param index Index of the token
    /// @return URI for the token
    function tokenURI(address owner, uint256 index) public view virtual override returns (string memory) {
        _getTokenOrRevert(owner, index);
        bytes memory baseURI = bytes(_baseURI());
        if (baseURI.length > 0) {
            return string(abi.encodePacked(baseURI, tokenId(owner, index)));
        }
        return "";
    }

    /// @return Total number of tokens emitted by the contract
    function total() public view virtual override returns (uint256) {
        return _total;
    }

    /// @param owner Address of the token's owner
    /// @param index Index of the token
    /// @return A unique identifier for that token
    function tokenId(address owner, uint256 index) public pure virtual returns (string memory) {
        return string(abi.encodePacked(
            Strings.toHexString(uint256(uint160(owner)), 20),
            Strings.toHexString(index, 32)
        ));
    }

    /// @notice Check if a given address owns a valid token
    /// @param owner Address for whom to check
    /// @return True if `owner` has a valid token, false otherwise
    function hasValidToken(address owner) external view virtual returns (bool) {
        Token[] storage tokens = _balances[owner];
        for (uint i=0; i<tokens.length; i++) {
            if (tokens[i].valid) {
                return true;
            }
        }
        return false;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(INTT).interfaceId ||
            interfaceId == type(INTTMetadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Prefix for all calls to tokenURI
    /// @return Common base URI for all token
    function _baseURI() internal pure virtual returns (string memory) {
        return "";
    }

    /// @notice Mark the token as invalidated
    /// @param owner Address for whom to invalidate the token
    function _invalidate(address owner, uint256 index) internal virtual {
        Token storage token = _getTokenOrRevert(owner, index);
        token.valid = false;
        emit Invalidated(msg.sender, owner, index);
    }

    /// @notice Mint a new token
    /// @param owner Address for whom to assign the token
    function _mint(address owner) internal virtual {
        Token[] storage tokens = _balances[owner];
        tokens.push(Token(msg.sender, true));
        _total += 1;
        emit Minted(msg.sender, owner, tokens.length);
    }

    /// @return True if the caller is the contract's creator, false otherwise
    function _isCreator() internal view virtual returns (bool) {
        return msg.sender == _creator;
    }

    /// @notice Retrieve a Token or revert if it does not exist
    /// @param owner Address of the token's owner
    /// @param index Index of the token
    /// @return The Token struct
    function _getTokenOrRevert(address owner, uint256 index) private view returns (Token storage) {
        Token[] storage tokens = _balances[owner];
        require(index < tokens.length, "NTT does not exist");
        return tokens[index];
    }
}
```
<!-- AUTO-GENERATED-CONTENT:END -->

### NTTDelegate

<!-- AUTO-GENERATED-CONTENT:START (CODE:syntax=solidity&src=./contracts/NTTDelegate.sol) -->
<!-- The below code snippet is automatically added from ./contracts/NTTDelegate.sol -->
```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./INTTDelegate.sol";
import "./NTT.sol";

abstract contract NTTDelegate is NTT, INTTDelegate {
    // Mapping from operator to list of owners
    mapping (address => mapping(address => bool)) _allowed;

    /// @notice Grant one-time minting right to `operator` for `owner`
    /// An allowed operator can call the function to transfer rights.
    /// @param operator Address allowed to mint a token
    /// @param owner Address for whom `operator` is allowed to mint a token
    function delegate(address operator, address owner) public virtual override {
        _delegateAsDelegateOrCreator(operator, owner, _isCreator());
    }

    /// @notice Grant one-time minting right to a list of `operators` for a corresponding list of `owners`
    /// An allowed operator can call the function to transfer rights.
    /// @param operators Addresses allowed to mint a token
    /// @param owners Addresses for whom `operators` are allowed to mint a token
    function delegateBatch(address[] memory operators, address[] memory owners) public virtual override {
        require(operators.length == owners.length, "operators and owners must have the same length");
        bool isCreator = _isCreator();
        for (uint i=0; i<operators.length; i++) {
            _delegateAsDelegateOrCreator(operators[i], owners[i], isCreator);
        }
    }

    /// @notice Mint a token. Caller must have the right to mint for the owner.
    /// @param owner Address for whom the token is minted
    function mint(address owner) public virtual override {
        _mintAsDelegateOrCreator(owner, _isCreator());
    }

    /// @notice Mint tokens to multiple addresses. Caller must have the right to mint for all owners.
    /// @param owners Addresses for whom the tokens are minted
    function mintBatch(address[] memory owners) public virtual override {
        bool isCreator = _isCreator();
        for (uint i=0 ; i<owners.length; i++) {
            _mintAsDelegateOrCreator(owners[i], isCreator);
        }
    }

    /// @notice Check if an operator is a delegate for a given address
    /// @param operator Address of the operator
    /// @param owner Address of the token's owner
    /// @return True if the `operator` is a delegate for `owner`, false otherwise
    function isDelegate(address operator, address owner) public view returns (bool) {
        return _allowed[operator][owner];
    }

    /// @notice Check if you are a delegate for a given address
    /// @param owner Address of the token's owner
    /// @return True if the caller is a delegate for `owner`, false otherwise
    function isDelegateOf(address owner) public view returns (bool) {
        return isDelegate(msg.sender, owner);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(NTT) returns (bool) {
        return 
            interfaceId == type(INTTDelegate).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _delegateAsDelegateOrCreator(address operator, address owner, bool isCreator) private {
        require(
            isCreator || _allowed[msg.sender][owner],
            "Only contract creator or allowed operator can delegate"
        );
        if (!isCreator) {
            _allowed[msg.sender][owner] = false;
        }
        _allowed[operator][owner] = true;
    }

    function _mintAsDelegateOrCreator(address owner, bool isCreator) private {
        require(
            isCreator || _allowed[msg.sender][owner],
            "Only contract creator or allowed operator can mint"
        );
        if (!isCreator) {
            _allowed[msg.sender][owner] = false;
        }
        _mint(owner);
    }
}
```
<!-- AUTO-GENERATED-CONTENT:END -->

## NTT for EIP ?

As a first NTT, why not create the **EIP Creator Badge** ? An NTT created by the Ethereum foundation, and attributed to EIP-standard creators ? 🙂

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NTT.sol";

contract EIPCreatorBadge is NTT {
    constructor() NTT("EIP Creator Badge", "EIP") {}

    function giveThatManABadge(address owner) external {
        require(_isCreator(), "You must be the contract creator");
        _mint(owner);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://eips.ethereum.org/ntt/";
    }
}
```

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
