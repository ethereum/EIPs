---
title: Collateralized NFT Standard
description: EIP-721 Extension to enable collateralization with EIP-20 based tokens.
author: 571nKY (@571nKY), Cosmos (@Cosmos4k), f4t50 (@f4t50), Harpocrates (@harpocrates555)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-03-13
requires: 20, 721
---

## Abstract

This proposal recommends an extension of [EIP-721](https://github.com/ethereum/ercs/blob/master/ERCS/erc-721.md) to allow for collateralization using a list of [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) based tokens. The proprietor of this EIP collection could hold both the native coin and [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) based tokens, with the tokenId acting as the access key to unlock the associated portion of the underlying [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) balance.

## Motivation

“NFTfi” focuses on the NFT floor price to enable the market value of the NFT serve as a collateral in lending protocols. The NFT floor price is susceptible to the supply-demand dynamics of the NFT market, characterized by higher volatility compared to the broader crypto market. Furthermore, potential price manipulation in specific NFT collections can artificially inflate NFT market prices, impacting the floor price considered by lending protocols. Relying solely on the NFT floor price based on market value is both unpredictable and unreliable.

This EIP addresses various challenges encountered by the crypto community with [EIP-721](https://github.com/ethereum/ercs/blob/master/ERCS/erc-721.md) based collections and assets. This EIP brings forth advantages such as sustainable NFT royalties supported by tangible assets, an on-chain verifiable floor price, and the introduction of additional monetization avenues for NFT collection creators.

### Presets

* The Basic Preset allows for the evaluation of an on-chain verifiable price floor for a specified NFT asset.

* The Dynamic Preset facilitates on-chain modification of tokenURI based on predefined collateral rules for a specified NFT asset.

* With the Royalty Preset, NFT collection creators can receive royalty payments for each transaction involving asset owners and Externally Owned Accounts (EOA), as well as transactions with smart contracts.

* The VRF Preset enables the distribution of collateral among multiple NFT asset holders using the Verifiable Random Function (VRF) by Chainlink.

### Extension to Existing EIP 721 Based Collections

For numerous [EIP-721](https://github.com/ethereum/ercs/blob/master/ERCS/erc-721.md) based collections that cannot be redeployed, we propose the implementation of an abstraction layer embodied by a smart contract. This smart contract would replicate all the functionalities of this EIP standard and grant access to collateral through mapping.

## Specification

### EIP standard for new NFT collections

```solidity

interface IERC721Envious is IERC721 {
	event Collateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Uncollateralized(uint256 indexed tokenId, uint256 amount, address tokenAddress);
	event Dispersed(address indexed tokenAddress, uint256 amount);
	event Harvested(address indexed tokenAddress, uint256 amount, uint256 scaledAmount);

	/**
	 * @dev An array with two elements. Each of them represents percentage from collateral
	 * to be taken as a commission. First element represents collateralization commission.
	 * Second element represents uncollateralization commission. There should be 3 
	 * decimal buffer for each of them, e.g. 1000 = 1%.
	 *
	 * @param uint 256 index of value in array.
	 */
	function commissions(uint256 index) external view returns (uint256);

	/**
	 * @dev 'Black hole' is any address that guarantees that tokens sent to it will not be 
	 * retrieved from it. Note: some tokens revert on transfer to zero address.
	 *
	 * @return address address of black hole.
	 */
	function blackHole() external view returns (address);

	/**
	 * @dev Token that will be used to harvest collected commissions.
	 *
	 * @return address address of token.
	 */
	function communityToken() external view returns (address);

	/**
	 * @dev Pool of available tokens for harvesting.
	 *
	 * @param uint256 index in array.
	 * @return address address of token.
	 */
	function communityPool(uint256 index) external view returns (address);

	/**
	 * @dev Token balance available for harvesting.
	 *
	 * @param address address of token.
	 * @return uint256 token balance.
	 */
	function communityBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Array of tokens that have been dispersed.
	 *
	 * @param uint256 index in array.
	 * @return address address of dispersed token.
	 */
	function disperseTokens(uint256 index) external view returns (address);

	/**
	 * @dev Amount of tokens that has been dispersed.
	 *
	 * @param address address of token.
	 * @return uint256 token balance.
	 */
	function disperseBalance(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of tokens that was already taken from the disperse.
	 *
	 * @param address address of token.
	 * @return uint256 total amount of tokens already taken.
	 */
	function disperseTotalTaken(address tokenAddress) external view returns (uint256);

	/**
	 * @dev Amount of disperse already taken by each tokenId.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param address address of token.
	 * @return uint256 amount of tokens already taken.
	 */
	function disperseTaken(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Mapping of `tokenId`s to token addresses that have collateralized before.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return address address of token.
	 */
	function collateralTokens(uint256 tokenId, uint256 index) external view returns (address);

	/**
	 * @dev Token balances that are stored under `tokenId`.
	 *
	 * @param tokenId unique identifier of unit.
	 * @param address address of token.
	 * @return uint256 token balance.
	 */
	function collateralBalances(uint256 tokenId, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Calculator function for harvesting.
	 *
	 * @param amount of `communityToken`s to spend
	 * @param address address of token to be harvested
	 * @return amount to harvest based on inputs
	 */
	function getAmount(uint256 amount, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Collect commission fees gathered in exchange for `communityToken`.
	 *
	 * @param amounts[] array of amounts to collateralize
	 * @param address[] array of token addresses
	 */
	function harvest(uint256[] memory amounts, address[] memory tokenAddresses) external;

	/**
	 * @dev Collateralize NFT with different tokens and amounts.
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts[] array of amounts to collateralize
	 * @param address[] array of token addresses
	 */
	function collateralize(
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;

	/**
	 * @dev Withdraw underlying collateral.
	 *
	 * Requirements:
	 * - only owner of NFT
	 *
	 * @param tokenId unique identifier for specific NFT
	 * @param amounts[] array of amounts to collateralize
	 * @param address[] array of token addresses
	 */
	function uncollateralize(
		uint256 tokenId, 
		uint256[] memory amounts, 
		address[] memory tokenAddresses
	) external;

	/**
	 * @dev Split collateral among all existent tokens.
	 *
	 * @param amounts[] to be dispersed among all NFT owners
	 * @param address[] address of token to be dispersed
	 */
	function disperse(uint256[] memory amounts, address[] memory tokenAddresses) external payable;
}
```

### Abstraction layer for already deployed NFT collections

```solidity

interface IEnviousHouse {
	event Collateralized(
		address indexed collection,
		uint256 indexed tokenId,
		uint256 amount,
		address tokenAddress
	);
	
	event Uncollateralized(
		address indexed collection,
		uint256 indexed tokenId,
		uint256 amount,
		address tokenAddress
	);
	
	event Dispersed(
		address indexed collection,
		address indexed tokenAddress,
		uint256 amount
	);
	
	event Harvested(
		address indexed collection,
		address indexed tokenAddress,
		uint256 amount,
		uint256 scaledAmount
	);

	/**
	 * @dev totalCollections function returns the total count of registered collections.
	 *
	 * @return uint256 number of registered collections.
	 */
	function totalCollections() external view returns (uint256);

	/**
	 * @dev 'Black hole' is any address that guarantees that tokens sent to it will not be 
	 * retrieved from it. Note: some tokens revert on transfer to zero address.
	 *
	 * @param address collection address.
	 * @return address address of black hole.
	 */
	function blackHole(address collection) external view returns (address);

	/**
	 * @dev collections function returns the collection address based on the collection index input.
	 *
	 * @param uint256 index of a registered collection.
	 * @return address address collection.
	 */
	function collections(uint256 index) external view returns (address);

	/**
	 * @dev collectionIds function returns the collection index based on the collection address input.
	 * 
	 * @param address collection address.
	 * @return uint256 collection index.
	 */
	function collectionIds(address collection) external view returns (uint256);
	
	/**
	 * @dev specificCollections function returns whether a particular collection follows the ERC721 standard or not.
	 * 
	 * @param address collection address.
	 * @return bool specific collection or not.
	 */
	function specificCollections(address collection) external view returns (bool);
	
	/**
	 * @dev An array with two elements. Each of them represents percentage from collateral
	 * to be taken as a commission. First element represents collateralization commission.
	 * Second element represents uncollateralization commission. There should be 3 
	 * decimal buffer for each of them, e.g. 1000 = 1%.
	 *
	 * @param address collection address.
	 * @param uint256 index of value in array.
	 * @return uint256 collected commission.
	 */
	function commissions(address collection, uint256 index) external view returns (uint256);
	
	/**
	 * @dev Token that will be used to harvest collected commissions.
	 *
	 * @param address collection address.
	 * @return address address of token.
	 */
	function communityToken(address collection) external view returns (address);

	/**
	 * @dev Pool of available tokens for harvesting.
	 *
	 * @param address collection address.
	 * @param uint256 index in array.
	 * @return address address of token.
	 */
	function communityPool(address collection, uint256 index) external view returns (address);
	
	/**
	 * @dev Token balance available for harvesting.
	 *
	 * @param address collection address.
	 * @param address address of token.
	 * @return uint256 token balance.
	 */
	function communityBalance(address collection, address tokenAddress) external view returns (uint256);

	/**
	 * @dev Array of tokens that have been dispersed.
	 *
	 * @param address collection address.
	 * @param uint256 index in array.
	 * @return address address of dispersed token.
	 */
	function disperseTokens(address collection, uint256 index) external view returns (address);
	
	/**
	 * @dev Amount of tokens that has been dispersed.
	 *
	 * @param address collection address.
	 * @param address address of token.
	 * @return uint256 token balance.
	 */
	function disperseBalance(address collection, address tokenAddress) external view returns (uint256);
	
	/**
	 * @dev Amount of tokens that was already taken from the disperse.
	 *
	 * @param address collection address.
	 * @param address address of token.
	 * @return uint256 total amount of tokens already taken.
	 */
	function disperseTotalTaken(address collection, address tokenAddress) external view returns (uint256);
	
	/**
	 * @dev Amount of disperse already taken by each tokenId.
	 *
	 * @param address collection address.
	 * @param tokenId unique identifier of unit.
	 * @param address address of token.
	 * @return uint256 amount of tokens already taken.
	 */
	function disperseTaken(address collection, uint256 tokenId, address tokenAddress) external view returns (uint256);
	
	/**
	 * @dev Mapping of `tokenId`s to token addresses that have collateralized before.
	 *
	 * @param address collection address.
	 * @param tokenId unique identifier of unit.
	 * @param index in array.
	 * @return address address of token.
	 */
	function collateralTokens(address collection, uint256 tokenId, uint256 index) external view returns (address);

	/**
	 * @dev Token balances that are stored under `tokenId`.
	 *
	 * @param address collection address.
	 * @param tokenId unique identifier of unit.
	 * @param address address of token.
	 * @return uint256 token balance.
	 */
	function collateralBalances(address collection, uint256 tokenId, address tokenAddress) external view returns (uint256);
	
	/**
	 * @dev Calculator function for harvesting.
	 *
	 * @param address collection address.
	 * @param amount of `communityToken`s to spend.
	 * @param address address of token to be harvested.
	 * @return amount to harvest based on inputs.
	 */
	function getAmount(address collection, uint256 amount, address tokenAddress) external view returns (uint256);
	
	/**
	 * @dev setSpecificCollection function enables the addition of any collection that is not compatible with the ERC721 standard to the list of exceptions.
	 *
	 * @param address collection address.
	 */
	function setSpecificCollection(address collection) external;
	
	/**
	 * @dev registerCollection function grants Envious functionality to any ERC721-compatible collection and streamlines
	 * the distribution of an initial minimum disbursement to all NFT holders.
	 *
	 * @param address collection address.
	 * @param address address of `communityToken`.
	 * @param uint256 collateralization fee, incoming / 1e5 * 100%.
	 * @param uint256 uncollateralization fee, incoming / 1e5 * 100%.
	 */
	function registerCollection(
		address collection,
		address token,
		uint256 incoming,
		uint256 outcoming
	) external payable;	

	/**
	 * @dev Collect commission fees gathered in exchange for `communityToken`.
	 *
	 * @param address collection address.
	 * @param amounts[] array of amounts to collateralize.
	 * @param address[] array of token addresses.
	 */
	function harvest(
		address collection,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external;
	
	/**
	 * @dev Collateralize NFT with different tokens and amounts.
	 *
	 * @param address collection address.
	 * @param tokenId unique identifier for specific NFT.
	 * @param amounts[] array of amounts to collateralize.
	 * @param address[] array of token addresses.
	 */
	function collateralize(
		address collection,
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;
	
	/**
	 * @dev Withdraw underlying collateral.
	 *
	 * Requirements:
	 * - only owner of NFT
	 *
	 * @param address collection address.
	 * @param tokenId unique identifier for specific NFT.
	 * @param amounts[] array of amounts to collateralize.
	 * @param address[] array of token addresses.
	 */
	function uncollateralize(
		address collection,
		uint256 tokenId,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external;
	
	/**
	 * @dev Split collateral among all existent tokens.
	 *
	 * @param address collection address.
	 * @param amounts[] to be dispersed among all NFT owners.
	 * @param address[] address of token to be dispersed.
	 */
	function disperse(
		address collection,
		uint256[] memory amounts,
		address[] memory tokenAddresses
	) external payable;
}
```

## Rationale

### “ERC721Envious” Term Choice
We propose adopting the term "ERC721Envious" to describe any NFT collection minted using this EIP standard or any [EIP-721](https://github.com/ethereum/ercs/blob/master/ERCS/erc-721.md) based NFT collection that utilized the EnviousHouse abstraction layer.

### NFT Collateralization with Multiple Tokens
Some Web3 projects primarily collateralize a specific NFT asset with one [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) based token, resulting in increased gas fees and complications in User Experience (UX).

This EIP has been crafted to enable the collateralization of a designated NFT asset with multiple [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) based tokens within a single transaction.

### NFT Collateralization with the Native Coin
Each [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) based token possesses a distinct address. However, a native coin does not carry an address. To address this, we propose utilizing a null address (`0x0000000000000000000000000000000000000000`) as an identifier for the native coin during collateralization, as it eliminates the possibility of collisions with smart contract addresses.

### Disperse Functionality
We have implemented the capability to collateralize all assets within a particular NFT collection in a single transaction. The complete collateral amount is deposited into a smart contract, enabling each user to claim their respective share of the collateral when they add or redeem collateral for that specific asset.

### Harvest Functionality
Each ERC721Envious NFT collection provides an option to incorporate a community [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) based token, which can be exchanged for commissions accrued from collateralization and uncollateralization activities.

### BlackHole Instance
Some [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) based token implementations forbid transfers to the null address, it is necessary to have a reliable burning mechanism in the harvest transactions. blackHole smart contract removes [EIP-20](https://github.com/ethereum/ercs/blob/master/ERCS/erc-20.md) communityTokens from the circulating supply in exchange for commission fees withdrawn.

blackHole has been designed to prevent the transfer of any tokens from itself and can only perform read operations. It is intended to be used with the ERC721Envious extension in implementations related to commission harvesting.

## Backwards Compatibility

EnviousHouse abstraction layer is suggested for already deployed [EIP-721](https://github.com/ethereum/ercs/blob/master/ERCS/erc-721.md) based NFT collections.

## Test Cases

Tests can be found [here](https://github.com/realGhostChain/ERC721Envious/tree/main/test).

## Reference Implementation

ERC721Envious standard has been utilized by [ghostNFT DApp](https://nft.ghostchain.io/) and [ghostAidrop DApp](https://airdrop.ghostchain.io/) leading to 1,000,000+ on-chain NFT claims across 20+ EVM chains.

The JML NFT Collection was deployed using the Dynamic Preset, where the rarity of each NFT is directly linked to the quantity of a specified ERC-20 token.

## Security Considerations

ERC721Envious may share security concerns similar to those found in [EIP-721](https://github.com/ethereum/ercs/blob/master/ERCS/erc-721.md), such as hidden logic within functions like burn, add resource, accept resource, etc.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
