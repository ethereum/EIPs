---
eip: <to be assigned>
title: Lockable Extension for EIP-721
description: Interface for locking and unlocking EIP-721 tokens.
author: Filipp Makarov (@filmakarov)
discussions-to: https://ethereum-magicians.org/t/lockable-nfts-extension/8800
status: Draft
type: Standards Track
category: ERC
created: 2022-10-05
requires: 165, 721
---

## Abstract
This standard is an extension of [EIP-721](./eip-721.md). It introduces lockable NFTs. The locked asset can be used in any way except selling and/or transferring it. Owner or operator can lock the token. When a token is being locked, the unlocker address (an EOA or a contract) is set. Only unlocker is able to `unlock` the token. 

## Motivation
With NFTs, digital objects become digital goods. Verifiably ownable, easily tradable, immutably stored on the blockchain. However, the usability of NFT presently is quite limited. Existing use cases often have poor UX as they are inherited from ERC20 (fungible tokens) world.

In DeFi you mostly deal with ERC20 tokens. There is a UX pattern when you lock your tokens on a service smart contract. For example, if you want to borrow some $DAI, you have to provide some $ETH as collateral for a loan. During the loan period $ETH is being locked into the lending service contract. And it's ok for $ETH and other fungible tokens.

It's different for NFTs. NFTs have plenty of use cases, that require for the NFT to stay on the holder's wallet even when it is used as collateral for a loan. You may want to keep using your NFT as a verified PFP on Twitter. You may want to use it to authorize on Discord server through Collab.land. You may want to use your NFT in a P2E game. And you should be able to do all of this even during the lending period like you are able to live in your house even it is mortgaged.

The initial idea was to just make NFTs that will feature better UX used as collateral. Then it became obvious, that one single locking feature allows for plenty of other use cases, such as:
* Lending/borrowing NFT without a need for collateral
* Paying for NFT by installments
* Safe and convenient usage with hot wallets
* Non-custodial staking and much more. 
Every use case can (and some of them are already) be implemented one at a time. My aim however was to come up with a standardized implementation.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

`ERC-721` compliant contracts MAY implement this ERC to provide standard methods of locking and unlocking the token at it's current owner address. 
If the token is locked, the `getLocked` function MUST return an address, that is able to unlock the token.
For the tokens that are not locked the `getLocked` function MUST return `address(0)`.
The user MAY permanently lock the token by stating a smart-contract that does not implement interface to `unlock` function as unlocker.

When the token is locked, all the [EIP-721](./eip-721.md) transfer functions MUST revert, except the msg.sender for the transfer tx is stated as unlocker for this token.
When the token is locked, [EIP-721](./eip-721.md) `approve` method MUST revert.
When the locked token is transferred by an unlocker, the token MUST be unlocked (unlocker set to `address(0)`) after trasnfer.

Marketplaces that aim to support this standard SHOULD implement method to call `getLocked` method to understand if the token is locked or not. Locked tokens SHOULD NOT be available for listings. Locked tokens listings SHOULD be hidden.  

### Contract Interface
```solidity
pragma solidity >=0.8.0;

/// @dev Interface for the Lockable extension

interface ILockable {

    /**
     * @dev Emitted when `id` token is locked, and `unlocker` is stated as unlocking wallet.
     */
    event Lock (address indexed unlocker, uint256 indexed id);

    /**
     * @dev Emitted when `id` token is unlocked.
     */
    event Unlock (uint256 indexed id);

    /**
     * @dev Locks the `id` token and states `unlocker` wallet as unlocker.
     */
    function lock(address unlocker, uint256 id) external;

    /**
     * @dev Unlocks the `id` token.
     */
    function unlock(uint256 id) external;

    /**
     * @dev Returns the wallet, that is stated as unlocking wallet for the `tokenId` token.
     * If address(0) returned, that means token is not locked. Any other result means token is locked.
     */
    function getLocked(uint256 tokenId) external view returns (address);

}
```

The `supportsInterface` method MUST return `true` when called with `0x72b68110`.

## Rationale

This approach proposes a solution that is designed to be as minimal as possible. At the same time, it is a generalized implementation, that allows for a lot of extensibility and potential use cases. It only allows to lock the item (stating who will be able to unlock it) and unlock it when needed if a user has permission to do it.

Following use cases are available by just implementing the proposed specification. 

- **NFT-collateralised loans** Use your NFT as collateral for a loan without locking it on the lending protocol contract. Lock it on your wallet instead and continue enjoying all the utility of your NFT.
- **No collateral rentals of NFTs** Borrow NFT for a fee, without a need for huge collateral. You can use NFT, but not transfer it, so the lender is safe. The borrowing service contract automatically transfers NFT back to the lender as soon as the borrowing period expires.
- **Primary sales** Mint NFT for only the part of the price and pay the rest when you are satisfied with how the collection evolves.
- **Secondary sales** Buy and sell your NFT by installments. Buyer gets locked NFT and immediately starts using it. At the same time he/she is not able to sell the NFT until all the installments are paid. If full payment is not received, NFT goes back to the seller together with a fee.
- **S is for Safety** Use your exclusive blue chip NFTs safely and conveniently. The most convenient way to use NFT is together with MetaMask. However, MetaMask is vulnerable to various bugs and attacks. With `Lockable` extension you can lock your NFT and declare your safe cold wallet as an unlocker. Thus, you can still keep your NFT on MetaMask and use it conveniently. Even if a hacker gets access to your MetaMask, they won’t be able to transfer your NFT without access to the cold wallet. That’s what makes `Lockable` NFTs safe. This use case is also [described](https://github.com/OwlOfMoistness/erc721-lock-registry) by OwlOfMoistness.
- **Metaverse ready** Locking NFT tickets can be useful during huge Metaverse events. That will prevent users, who already logged in with an NFT, from selling it or transferring it to another user. Thus we avoid double usage of one ticket.
- **Non-custodial staking** Using locking of NFTs for the staking protocols that do not transfer your NFT from your wallet to the staking contract is thoroughly described [here](https://github.com/OwlOfMoistness/erc721-lock-registry) and [here](https://github.com/samurisenft/erc721nes-contracts). However, my approach to this is a little bit different. I think staking should be done in one place only like you can not deposit money in two bank accounts simultaneously. 
Another approach to the same concept is using locking to provide proof of HODL. You can lock your NFTs from selling as a manifestation of loyalty to the community and start earning rewards for that. It is better version of the rewards mechanism, that was originally introduced by [The Hashmasks](https://www.thehashmasks.com/nct) and their $NCT token. 
- **Safe and convenient co-ownership and co-usage** Extension of safe co-ownership and co-usage. For example, you want to purchase an expensive NFT asset together with friends, but it is not handy to use it with multisig, so you can safely rotate and use it between wallets. The NFT will be stored on one of the co-owners' wallet and he will be able to use it in any way (except transfers) without requiring multi-approval. Transfers will require multi-approval.

More of use cases may be introduced as soon as the community starts to explore `Lockable` NFTs.

## Backwards Compatibility
This standard is compatible with current ERC-721 standards.

## Reference Implementation
Implementation:
```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0;

import '../ILockable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

/// @title Lockable Extension for ERC721

abstract contract ERC721Lockable is ERC721, ILockable {

    /*///////////////////////////////////////////////////////////////
                            LOCKABLE EXTENSION STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal unlockers;

    /*///////////////////////////////////////////////////////////////
                              LOCKABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Public function to lock the token. Verifies if the msg.sender is the owner
     *      or approved party.
     */

    function lock(address unlocker, uint256 id) public virtual {
        address tokenOwner = ownerOf(id);
        require(msg.sender == tokenOwner || isApprovedForAll(tokenOwner, msg.sender)
        , "NOT_AUTHORIZED");
        require(unlockers[id] == address(0), "ALREADY_LOCKED"); 
        unlockers[id] = unlocker;
        _approve(unlocker, id);
    }

    /**
     * @dev Public function to unlock the token. Only the unlocker (stated at the time of locking) can unlock
     */
    function unlock(uint256 id) public virtual {
        require(msg.sender == unlockers[id], "NOT_UNLOCKER");
        unlockers[id] = address(0);
    }

    /**
     * @dev Returns the unlocker for the tokenId
     *      address(0) means token is not locked
     *      reverts if token does not exist
     */
    function getLocked(uint256 tokenId) public virtual view returns (address) {
        require(_exists(tokenId), "Lockable: locking query for nonexistent token");
        return unlockers[tokenId];
    }

    /**
     * @dev Locks the token
     */
    function _lock(address unlocker, uint256 id) internal virtual {
        unlockers[id] = unlocker;
    }

    /**
     * @dev Unlocks the token
     */
    function _unlock(uint256 id) internal virtual {
        unlockers[id] = address(0);
    }

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function approve(address to, uint256 tokenId) public virtual override {
        require (getLocked(tokenId) == address(0), "Can not approve locked token");
        super.approve(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // if it is a Transfer or Burn
        if (from != address(0)) { 
            // token should not be locked or msg.sender should be unlocker to do that
            require(getLocked(tokenId) == address(0) || msg.sender == getLocked(tokenId), "LOCKED");
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // if it is a Transfer or Burn, we always deal with one token, that is startTokenId
        if (from != address(0)) { 
            // clear locks
            delete unlockers[tokenId];
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Lockable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}
```

More implementations can be found [here](https://github.com/filmakarov/erc721-lockable).

## Security Considerations
The callers of `lock` function should always consider if there's an unlocking function in the contract, that is stated as an unlocker, unless they want to lock the NFT from transfers forever.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).