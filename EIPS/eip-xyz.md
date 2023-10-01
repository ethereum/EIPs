---
eip: xyz
title: Resolving Staked ERC721 Ownership Recognition
description: A gas-efficient approach to lockable ERC-721 tokens
author: Francesco Sullo (@sullof)
discussions-to: https://ethereum-magicians.org/t/eip-xxxx-resolving-staked-erc721-ownership-recognition/15967
status: Draft
type: Standards Track
category: ERC
created: 2023-10-01
requires: 165, 721
---

## Abstract
The ownership of ERC721 tokens when staked in a pool presents challenges, particularly when it involves older, non-lockable NFTs like, for example, Crypto Punks or Bored Ape Yacht Club (BAYC) tokens. This proposal introduces an interface to address these challenges by allowing staked NFTs to be recognized by their original owners, even after they've been staked.

## Motivation 
Recent solutions involve retaining the ownership of the NFT while "locking" it. However, this presupposes that all NFTs are "lockable". For vintage or previously minted NFTs, like BAYC, this poses an issue. Once staked in a pool, the NFT's ownership transfers to the staking pool, preventing, for example, original owners from accessing privileges or club memberships associated with those NFTs.

To circumvent this limitation, we propose an interface that retains a record of the original owner even after the token is staked, thus providing a way for other apps and contracts to recognize the original owner.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

The interface is defined as follows:

```solidity
// ERC165 interfaceId 0x6b61a747
interface IERCxyz {
  
  function ownerOf(address tokenAddress, uint256 tokenId) external view returns(address);
}
```

## Rationale

This approach provides a workaround for the challenges posed by non-lockable NFTs. By maintaining a record of the original owner and exposing this through the `ownerOf` method, we ensure that staking does not hinder the utility or privileges tied to certain NFTs.

## Backwards Compatibility

This standard is fully backwards compatible with existing [ERC-721](./eip-721.md) contracts. It can seamlessly integrate with existing upgradeable staking pools, provided they choose to adopt it. It does not require changes to the [ERC-721](./eip-721.md) standard but acts as an enhancement for staking pools.

## Security Considerations

This EIP does not introduce any known security considerations.

## Conclusion

The proposed interface offers a streamlined solution for recognizing the ownership of staked NFTs, especially those that are non-lockable. Adopting this proposal will ensure that NFT holders do not lose out on associated benefits when they stake their tokens.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
