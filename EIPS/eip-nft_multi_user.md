---
title: Multi-User NFT Extension
description: An extension of EIP-721 to allow multiple users to a token with restricted permissions.
author: Zheng Han <robin@comoco.xyz>, Ming Jiang <ming@comoco.xyz>, Fan Yang <jack@comoco.xyz>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-08-24
---

## Abstract

This standard is an extension of EIP-721. It proposes a new role `user` in addition to `owner` for a token. A token can have multiple users under separate expiration time. It allows the subscription model where an NFT can be subscribed non-exclusively by different users.

## Motivation

Some NFTs represent IP assets, and IP assets have the need to be licensed for access without transferring ownership. The subscription model is a very common practice for IP licensing where multiple users can subscribe to an NFT to obtain access. Each subscription is usually time limited and will thus be recorded with an expiration time.

Existing [EIP-4907](https://eips.ethereum.org/EIPS/eip-4907) introduces a similar feature, but does not allow for more than one user. It is more suitable in the rental scenario where a user gains an exclusive right of use to an NFT before the next user. This rental model is common for NFTs representing physical assets like in games, but not very useful for shareable IP assets.

## Specification

```solidity
interface IUtilizable {

    /// @notice Emitted when the expires of a user for an NFT is changed
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice Get the user expires of an NFT
    /// @param tokenId The NFT to get the user expires for
    /// @param user The user to get the expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId, address user) external view returns(uint256);

    /// @notice Set the user expires of an NFT
    /// @param tokenId The NFT to set the user expires for
    /// @param user The user to set the expires for
    /// @param expires The user could use the NFT before expires in UNIX timestamp
    function setUser(uint256 tokenId, address user, uint64 expires) external;

}
```

## Rationale

This standard complements [EIP-4907](https://eips.ethereum.org/EIPS/eip-4907) to support multi-user feature. Therefore the proposed interface tries to keep consistent using the same naming for functions and parameters.

However, we didn't include the corresponding `usersOf(uint256 tokenId)` function as that would imply the implemention has to support enumerability over multiple users. It is not always necessary, for example, in the case of open subscription. So we decide not to add it to the interface and leave the choice up to the implementers.

## Backwards Compatibility

No backwards compatibility issues found.

## Test Cases

Test cases available in the repository: [comoco-labs/laicense-contracts](https://github.com/comoco-labs/laicense-contracts)

## Reference Implementation

Reference implementation available in the repository: [comoco-labs/laicense-contracts](https://github.com/comoco-labs/laicense-contracts)

## Security Considerations

No security considerations found.

## Copyright

Copyright and related rights waived via [CC0](https://github.com/ethereum/EIPs/blob/master/LICENSE.md).
