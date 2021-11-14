---
eip: <to be assigned>
title: Permit for ERC712 NFTs
description: ERC712-singed approvals for ERC712 NFTs
author: Simon Fremaux (@dievardump), William Schwab (@wschwab)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
requires: 712, 721
---

## Abstract
The "Permit" approval flow outlined in [EIP-2612](./eip-2612.md) has proven a very valuable advancement in UX by creating gasless approvals for ERC20 tokens. This EIP extends the pattern to ERC721 NFTs.

This requires a separate EIP due to the difference in structure between ERC20 and ERC721 tokens. While ERC20 permits use value (the amount of the ERC20 token being approved) and a nonce based on the owner's address, ERC721 permits focus on the `tokenId` of the NFT and increment nonce based on the transfers of the NFT.

## Motivation
The permit structure outlined in [EIP-2612](./eip-2612.md) allows for a signed message (structured as outlined in [EIP-712](./eip-712.md)) to be used in order to create an approval. Whereas the normal approval-based pull flow generally involves two transactions, one to approve a contract and a second for the contract to pull the asset, which is poor UX and often confuses new users, a permit-style flow only requires signing a message and a transaction. Additional information can be found in [EIP-2612](./eip-2612.md).

[EIP-2612](./eip-2612.md) only outlines a permit architecture for ERC20 tokens. This ERC proposes an architecture for ERC721 NFTs, which also contain an approve architecture that would benefit from a signed message-based approval flow.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

Three new functions MUST be added to [ERC721](./eip-721.md):
```solidity
function permit(address owner, address spender, uint256 tokenId, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
function nonces(uint256 tokenId) external view returns(uint256);
function DOMAIN_SEPARATOR() external view returns(bytes32);
```
The semantics of which are as follows:

For all addresses `owner`, and `spender`, `uint256`s `tokenId, `deadline`, and `nonce`, `uint8` `v`, and `bytes32` `r` and `s`, a call to `permit(owner, spender, tokenId, deadline, v, r, s)` MUST set `spender` as approved on `tokenId` as long as `owner` remains in possession of it, and MUST emit a corresponding `Approval` event, if and only if the following conditions are met:

* the current blocktime is less than or equal to `deadline`
* owner is not the zero address
* `nonces[tokenId]` is equal to `nonce`
* `r`, `s`, and `v` is a valid `secp256k1` signature from `owner` of the message:
```
keccak256(abi.encodePacked(
   hex"1901",
   DOMAIN_SEPARATOR,
   keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"),
            owner,
            spender,
            tokenId,
            nonce,
            deadline))
));
```
where `DOMAIN_SEPARATOR` MUST be defined according to [EIP-712](./eip-712.md). The `DOMAIN_SEPARATOR` should be unique to the contract and chain to prevent replay attacks from other domains, and satisfy the requirements of EIP-712, but is otherwise unconstrained. A common choice for `DOMAIN_SEPARATOR` is:
```
DOMAIN_SEPARATOR = keccak256(
    abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        chainid,
        address(this)
));
```
In other words, the message is the following ERC-712 typed structure:
```json
{
  "types": {
    "EIP712Domain": [
      {
        "name": "name",
        "type": "string"
      },
      {
        "name": "version",
        "type": "string"
      },
      {
        "name": "chainId",
        "type": "uint256"
      },
      {
        "name": "verifyingContract",
        "type": "address"
      }
    ],
    "Permit": [{
      "name": "owner",
      "type": "address"
      },
      {
        "name": "spender",
        "type": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256"
      },
      {
        "name": "nonce",
        "type": "uint256"
      },
      {
        "name": "deadline",
        "type": "uint256"
      }
    ],
    "primaryType": "Permit",
    "domain": {
      "name": erc721name,
      "version": version,
      "chainId": chainid,
      "verifyingContract": tokenAddress
  },
  "message": {
    "owner": owner,
    "spender": spender,
    "value": value,
    "nonce": nonce,
    "deadline": deadline
  }
}}
```
In addition, the `nonce` of a particular `tokenId` (`nonces[tokenId]`) MUST be incremented upon any transfer of the `tokenId`.

Note that nowhere in this definition do we refer to `msg.sender`. The caller of the `permit` function can be any address.

## Rationale
The `permit` function is sufficient for enabling a `safeTransferFrom` transaction to be made without the need for an additional transaction.

The format avoids any calls to unknown code.

The `nonces` mapping is given for replay protection.

A common use case of permit has a relayer submit a Permit on behalf of the owner. In this scenario, the relaying party is essentially given a free option to submit or withhold the Permit. If this is a cause of concern, the owner can limit the time a Permit is valid for by setting deadline to a value in the near future. The deadline argument can be set to uint(-1) to create Permits that effectively never expire.

ERC-712 typed messages are included because of its use in [EIP-2612](./eip-2612.md), which in turn cites widespread adoption in many wallet providers.

While EIP-2612 focuses on the value being approved, this EIP focuses on the `tokenId` of the NFT being approved via `permit`. This enables a flexibility that cannot be achieved with ERC20 (or even ERC1155) tokens, enabling a single owner to give multiple permits on the same NFT. This is possible since each ERC721 token is discrete (oftentimes referred to as non-fungible), which allows assertion that this token is still in the possession of the `owner` simply and conclusively.

## Backwards Compatibility
There are already some ERC721 contracts implementing a `permit`-style architecture, most notably Uniswap v3. 

Their implementation differs from the specification here in that: 
 * the `permit` architecture is based on `owner`
 * the `nonce` is incremented at the time the `permit` is created
 * the `permit` function must be called by the NFT owner, who is set as the `owner`

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes.  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation
An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Security Considerations
All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
