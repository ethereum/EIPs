---
eip: to be assigned
title: ERC1155 asset backed NFT extension
description: Extends ERC1155 to support crucial operations for asset backed NFTs.
author: liszechung (@liszechung)
discussions-to: https://ethereum-magicians.org/t/eip-draft-erc1155-asset-backed-nft-extension/10437
status: Draft 
type: Standards Track
category: ERC
created: 2022-08-18
requires: 1155
---

## Abstract
To propose an extension of smart contract interfaces for asset-backed, fractionalized projects using ERC1155 standard such that total acquisition will become possible. This EIP focuses on In-Real-Life asset, where total acquisition should be able to happen.

## Motivation
Fractionalized, physical asset projects face difficulty when someone wants to acquire 100% of the asset. For example, if someone wants to acquire the whole asset, he needs to buy all NFT pieces so he will become the 100% owner. However he could not do so as it is publicly visible that someone is trying to perform a total acquisition in an open environment like Ethereum, seller will take advantage to set unreasonable high price which hinders the acquisition. Or in other cases, NFTs are owned by wallets with lost keys, such that the ownership will never be at whole. We need a way to enable potential total acquisition.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

ERC-1155 compliant contracts MAY implement this ERC for adding functionalities to support total acquisition.
```
//set the percentage required for any acquirer to trigger a forced sale
//set also the payment token to settle for the acquisition

function setForcedSaleRequirement(
	uint128 requiredBP,
	address erc20Token
) public onlyOwner

//set the unit price to acquire the remaining NFTs (100% - requiredBP)
//suggest to use a Time Weighted Average Price for a certain period before reaching the requiredBP
//emit ForcedSaleSet

function setForcedSaleTWAP(
	uint256 amount
) public onlyOwner

//acquirer deposit remainingQTY*TWAP
//emit ForcedSaleFinished
//after this point, the acquirer is the new owner of the whole asset

function execForcedSale (
	uint256 amount
) public external payable

//burn ALL NFTs and collect funds
//emit ForcedSaleClaimed

function claimForcedSale()
public

event ForcedSaleSet(
	bool isSet
)
event ForceSaleClaimed(
	uint256 qtyBurned,
	uint256 amountClaimed,
	address claimer
)
```


## Rationale
Native ETH is supported by via WETH (ERC20).
After forcedSale is set, the remaining NFTs metadata should be updated to reflect the NFTs are at most valued at the previously set TWAP price.

## Backwards Compatibility
Needs discussion.

## Test Cases
Test cases (TODO)

## Reference Implementation
Implementation (TODO)

## Security Considerations
Needs discussion.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
