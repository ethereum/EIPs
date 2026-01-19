---
eip: <to be assigned>
title: Non-Transferable Token Standard
description: A minimal standard for tokens that are permanently bound to an address
author: Ivan Zemko (@Vantana1995)
discussions-to: https://ethereum-magicians.org/t/soulbound-nft-as-separate-standard/27407
status: Draft
type: Standards Track
category: ERC
created: 2026-01-19
requires: [165], [721]
---

## Abstract

This EIP proposes a minimal standard for non-transferable tokens (commonly known as "Soulbound tokens"). Unlike existing approaches that extend ERC-721 and disable transfer functionality, this standard defines tokens that are non-transferable by design, eliminating transfer-related functions entirely from the interface.

## Motivation

Current Soulbound token implementations ([ERC-5192](./eip-5192.md), [ERC-4973](./eip-4973.md), [ERC-5484](./eip-5484.md)) are built as extensions of [ERC-721](./eip-721.md), inheriting its complete transfer infrastructure and then blocking or restricting these capabilities. This approach creates several problems:

1. **Semantic Mismatch**: ERC-721 is fundamentally designed around transferability. Tokens that should never be transferred still carry the conceptual and technical baggage of a transferable token standard.

2. **Bytecode Bloat**: Inheriting from ERC-721 includes functions like `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, and `isApprovedForAll` in the contract bytecode, even when these functions will never execute successfully. This increases deployment costs and reduces available space for actual token functionality.

3. **Interface Confusion**: External contracts and interfaces that detect ERC-721 compliance may incorrectly assume transfer capabilities exist, leading to integration issues and user confusion.

4. **Not Truly Non-Transferable**: Existing implementations block transfers through restrictions, but the transfer logic exists in the codebase. This creates potential attack vectors and unclear semantics about what the token fundamentally is.

Non-transferable tokens represent credentials, achievements, certifications, memberships, and identity attestations - assets that by their nature should be permanently bound to their owner. These use cases deserve a dedicated standard that explicitly communicates non-transferability through the absence of transfer functions, not their restriction.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Core Interface

Every compliant contract MUST implement the `IERC_NTT` (Non-Transferable Token) interface:

```solidity
pragma solidity ^0.8.0;

/// @title ERC-NTT Non-Transferable Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-xxxx
interface IERC_NTT {
    /// @dev Emitted when a token is minted and bound to an address
    /// @param to The address the token is bound to
    /// @param tokenId The identifier of the minted token
    event Mint(address indexed to, uint256 indexed tokenId);

    /// @dev Emitted when a token is burned
    /// @param from The address the token was bound to
    /// @param tokenId The identifier of the burned token
    event Burn(address indexed from, uint256 indexed tokenId);

    /// @notice Mint a new non-transferable token to a specified address
    /// @dev The token MUST be bound to the address specified in the 'to' parameter
    /// @param to The address to bind the token to
    /// @return tokenId The identifier of the newly minted token
    function mint(address to) external returns (uint256 tokenId);

    /// @notice Burn a non-transferable token
    /// @dev MUST revert if msg.sender is not the owner of tokenId
    /// @param tokenId The identifier of the token to burn
    function burn(uint256 tokenId) external;

    /// @notice Get the owner of a token
    /// @dev MUST revert if tokenId does not exist
    /// @param tokenId The identifier of the token
    /// @return owner The address that owns the token
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
```

### Metadata Interface (Required)

Compliant contracts MUST implement the ERC-721 metadata interface for human-readable token information:

```solidity
/// @title ERC-721 Metadata Interface (from EIP-721)
/// @dev This is a REQUIRED part of the standard
interface IERC721Metadata {
    /// @notice A descriptive name for the token collection
    function name() external view returns (string memory);

    /// @notice An abbreviated name for the token collection
    function symbol() external view returns (string memory);

    /// @notice A URI pointing to metadata for a specific token
    /// @dev MUST revert if tokenId does not exist
    /// @param tokenId The identifier of the token
    /// @return The URI string
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
```

All compliant contracts MUST implement both `IERC_NTT` and `IERC721Metadata` interfaces.

### Behavior Specification

1. **Minting**:

   - Tokens MUST be minted directly to an address
   - The minting function MUST emit the `Mint` event
   - Each token MUST have a unique identifier

2. **Burning**:

   - Only the token owner MUST be able to burn their token
   - The burning function MUST emit the `Burn` event
   - After burning, `ownerOf(uint256 tokenId)` for that token MUST revert 

3. **Non-Transferability**:

   - Compliant contracts MUST NOT implement any transfer functionality
   - There MUST be no mechanism to change the owner of an existing token
   - The only way to move token ownership is through burn and mint operations by authorized parties

4. **Owner Queries**:
   - `ownerOf(uint256 tokenId)` MUST return the address that owns the specified token
   - `ownerOf(uint256 tokenId)` MUST revert for non-existent tokens

### ERC-165 Interface Identification

Contracts implementing this standard MUST implement the ERC-165 `supportsInterface` function and MUST return `true` for:

- The `IERC_NTT` interface ID `0xXXXXXXXX` (to be calculated)
- The `IERC721Metadata` interface ID `0x5b5e139f`
- The ERC-165 interface ID `0x01ffc9a7`

## Rationale

### Why Not Extend ERC-721?

ERC-721 is architecturally designed around transferability. Every aspect of its interface assumes tokens can move between addresses. Attempting to create non-transferable tokens by blocking these functions creates an architectural mismatch:

- Transfer functions exist but always revert
- Approval mechanisms serve no purpose
- Events like `Transfer` and `Approval` create confusion
- Storage slots for approvals and operators are unused

A dedicated standard removes this baggage entirely.

### Minimal Interface Design

The core interface contains only what is essential for non-transferable tokens:

- `mint(address to)`: Create and bind token to specified address
- `burn(uint256 tokenId)`: Destroy token
- `ownerOf(uint256 tokenId)`: Verify ownership

Additionally, the standard REQUIRES ERC-721 Metadata interface (`name()`, `symbol()`, `tokenURI(uint256 tokenId)`) for compatibility with existing wallet and indexer infrastructure while maintaining minimalism.

### Why Allow Burning?

While tokens cannot be transferred, allowing the owner to burn their token provides:

- User autonomy to remove unwanted credentials
- Mechanisms for credential revocation
- Compatibility with credential lifecycle management

### Comparison with Existing Standards

| Feature             | ERC-721 + Extensions           | This Standard    |
| ------------------- | ------------------------------ | ---------------- |
| Transfer functions  | Present but blocked            | Absent by design |
| Approval mechanisms | Present but unused             | Absent           |
| Deployment bytecode | ~500+ lines                    | ~100 lines       |
| Semantic clarity    | Transferable with restrictions | Non-transferable |
| Interface detection | Can be misleading              | Explicit         |

## Backwards Compatibility

This standard is not backwards compatible with ERC-721. This is intentional - tokens that are fundamentally non-transferable should not masquerade as transferable tokens.

Wallets and marketplaces can detect this standard via ERC-165 and treat these tokens appropriately (e.g., not showing transfer or listing options).

## Reference Implementation

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC_NTT.sol";
import "./IERC721Metadata.sol";

contract NonTransferableToken is IERC_NTT, IERC721Metadata {
    uint256 private _tokenIdCounter;
    string private _name;
    string private _symbol;
    string private _baseURI;

    mapping(uint256 => address) private _owners;

    error NotOwner();
    error TokenNotFound();

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
    }

    function mint(address to) external override returns (uint256) {
        _tokenIdCounter++;
        uint256 tokenId = _tokenIdCounter;
        _owners[tokenId] = to;

        emit Mint(to, tokenId);
        return tokenId;
    }

    function burn(uint256 tokenId) external override {
        if (_owners[tokenId] != msg.sender) revert NotOwner();

        address owner = _owners[tokenId];
        delete _owners[tokenId];

        emit Burn(owner, tokenId);
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenNotFound();
        return owner;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        if (_owners[tokenId] == address(0)) revert TokenNotFound();
        return _baseURI;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC_NTT).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == 0x01ffc9a7; // ERC-165
    }
}
```

## Security Considerations

### Private Key Compromise

If a user's private key is compromised, the attacker gains access to all non-transferable tokens bound to that address. Unlike transferable tokens, there is no way to recover these credentials by moving them to a secure address.

Mitigation: Applications should consider:

- Multi-signature schemes for high-value credentials
- Time-locked or conditional burning mechanisms
- Off-chain verification in addition to on-chain ownership

### Permanent Binding

Tokens are permanently bound to their initial recipient address. If that address becomes inaccessible (lost keys, smart contract bugs), the token cannot be recovered.

Mitigation: Consider implementing optional issuer-controlled burning for recovery scenarios, clearly documented in token metadata.

### Interface Detection

External contracts MUST NOT assume transfer capabilities based solely on the presence of metadata functions. Always check ERC-165 interface support.

### Reentrancy

The minimal interface reduces reentrancy attack surface, but implementations should still follow checks-effects-interactions pattern, especially if `mint(address to)` or `burn(uint256 tokenId)` trigger external calls.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
