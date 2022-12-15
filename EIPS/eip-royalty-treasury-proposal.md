---
eip: royalty-treasury-proposal
title: Hashtag NFT Collective Royalty Treasury
description: A method to deposit and retrieve royalties from an Ethereum Address
author: Ashley Turing (@livetreetech)
discussions-to: https://ethereum-magicians.org/t/eip-proposal-hashtag-nft-collective-royalty-treasury/12152/5
status: Draft
type: Standards Track
category: ERC
created: 2022-12-15
---

## Abstract
This standard allows social media networks, NFT marketplaces and other websites to deposit royalties associated with an Ethereum address. The Ethereum address may be associated with a human readable name (e.g. a hashtag), to pay-out royalties and retrieve royalty payment information. The standard is loosely coupled and generic to maximise the potential use cases.  Unlike other EIP proposals ([EIP-2981](https://github.com/ethereum/EIPs/blob/9e393a79d9937f579acbdcb234a67869259d5a96/EIPS/eip-2981.md) or [EIP-4910](https://github.com/ethereum/EIPs/blob/7bba1e7b146ed74b0c5884e60dec815fd56a07e3/EIPS/eip-4910.md)) which embody mechanisms for calculating royalties, this standard sets out the mechanism for depositing and paying out royalties. The goal is to increase the earning potential for creators rather than defining the business logic for royalty payments.
Royalties derived from a human readable name could be associated with NFTs, ERC20 contracts or any number of different sources; this standard does not dictate or define how the royalties are generated or how much the royalty amount should be.  Its purpose is to provide a simple mechanism for creators to receive royalties associated with a particular Ethereum address. The standard facilitates that Ethereum address can be associated with a human readable name, if the social network or platform so facilitates creators to register and associate a name. Its usage therefore can be expanded and built upon to encompass a variety of highly complex royalty or payment attribution systems. The standard defines an interface to deposit royalties en mass which is intended to optimise gas costs. The Ethereum Address could, of course, be another smart contract such as a governor contract, NFT or simple wallet. The standard does not define what the payout should be, or the mechanism for payout, this would be the responsibility of the caller such as the social network or NFT marketplace to implement.

## Motivation
The #Hashtag NFT Collective Royalty Treasury standard comes about as a result of many years of work to help realise the overarching ambition of Web 3.0 decentralisation, namely, to empower people to collectively address some of the world’s most challenging problems such as climate change, global inequality to domestic abuse.  Hash-tagging (#) media has become a defacto standard across Web 2.0 social networks for not only garnering support (e.g. #BLM, etc). The introduction of a decentralised hashtag standard aims to harness the power of social media in a decentralised fashion to bring about the change Web 3.0 promises, fundamentally giving creators the potential to earn income (“royalties”) from content they post and are tagged from a variety of social networks. The first implementation of this standard can be downloaded via [www.livetree.com](http://www.livetree.com). The generic design facilitates additional royalties to be attributed to NFTs or any smart contract or wallet address.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

## Rationale
A standardized way to deposit, withdraw and retrieve creator fee (“royalty”) information associated with a human readable name - this standard enables universal support for royalty payments across social networks, NFT marketplaces and ecosystem participants, its generic design can be implemented on any EVM compatible blockchain and its specific implementation is intended to associate royalties with a hashtag (#) name, however, it is highly versatile and can be used to attribute royalties for any Ethereum address, for example, an NFT.

## Backwards Compatibility
The standard contracts in implementation may be made upgradable to help ensure backward compatibliity

### Overview
| # | Smart Contract | Description |
|---|----------------|-------------|
| 1 | HashtagNFTCollectiveTreasury | The royalty treasury holds the creator fees payable in the EVM’s blockchain native token associated with a particular set of Ethereum addresses. |
| 2 | HashtagNFTCollectiveResolver | Provides naming resolution functionality to retrieve Ethereum addresses from human readable names (e.g. “hashtags”). |

### HashtagNFTCollectiveTreasury
| # | Function | Input / Output | Description |
|---|----------|----------------|-------------|
| 1 | DepositRoyalty<br/>_(payable)_ | **Inputs**<br/>_address[] calldata tokenAddresses_ - Array of Ethereum addresses<br/>_uint256[] calldata tokenRoyalties_ - Matching array of royalty deposit amounts for each Ethereum Address<br/><br/>**Outputs**<br/>none<br/><br/>emits **Deposit** event<br/>_event Deposit(senderAddr, address[] tokenAddresses, uint256[] tokenRoyalties);_ | This method optimises the gas costs relating to the deposit of royalties for a number of different associated Ethereum addresses. It takes an array of tokenAddresses (Ethereum addresses) associated with an array of tokenRoyalties (Royalty amounts).<br/> tokenAddresses array **MUST** be paired equally and **MUST** be in the same order as tokenRoyalties.<br/>The deposit payable amount sent to this function **MUST** be in the blockchain’s native token (for example: ETH, GLMR, MOVR, CELO, UNQ etc). The payable amount of the native token **MUST** equal the sum of all tokenRoyalties. A human readable name registered in the naming service **MAY** be associated with the Ethereum address(es) provided in tokenAddresses.<br/>The implementation of this method stores the sender address in a “whitelist” along with the quantity of the blockchain’s native token deposited which is in turn is used to permission the method WithdrawFromTreasuryToAddress. |
| 2 | GetHashtagNFTBalances<br/>_(view)_ | **Inputs**<br/>_address tokenAddress_ - An Ethereum address<br/>**Outputs**<br/>uint256 - Returns sum of the royalties for given Ethereum address | Facilitates querying an Ethereum address and returning the royalties associated to the Ethereum address.<br/>The method **MUST** be called with an Ethereum address. |
| 3 | WithdrawFromTreasuryToAddress | **Inputs**<br/>_address tokenAddress_ - Address royalty was associated in the deposit<br/>_address receiver_ - Royalty payout Ethereum address<br/>_uint256 amount_ - Royalty amount to be withdrawn to the receiver<br/>**Outputs**<br/>none<br/>emits **Withdraw** event<br/>_Withdraw(senderAddr, receiver, amount, tokenAddr);_ | Withdraws the given amount of the royalty (blockchain native token) associated with the Ethereum address to the receiver. The receiver **MAY** be a wallet, smart contract or other Ethereum address.<br/> The tokenAddress **MUST** be an address the sender has deposited associated tokenAddress. The implementation of this method **SHOULD** restrict the caller and amount of withdrawal through the use of a whitelist defined in DepositRoyalty.

### HashtagNFTCollectiveResolver
| # | Function | Input / Output | Description |
|---|----------|----------------|-------------|
| 1 | AddNftURIRecord | **Inputs**<br/>_string calldata nftURI_ - human readable name<br/>_address ethereumAddr_ - Ethereum address<br/>**Outputs**<br/>none<br/>emits **HashtagNFTCollectiveRecord** event (senderAddr, nftURI, contractAddress, tokenId) | Adds a keccak256 hash mapping of a human readable name (e.g. "hashtag" or "nftURI") to an Ethereum address.<br/>A human readable name is here defined as case insensitive and **MUST** contain 1 or more non-white space characters.<br/>The implementation of this method enforces the nftURI **MUST** be unique otherwise the transaction will be reverted. |
| 2 | ResolveURI | **Inputs**<br/>_string calldata nftURI_ - human readable name<br/>**Outputs**<br/>address - Ethereum address. | Returns the Ethereum address associated with a human readable name. |
| 3 | ResolveAddress | **Inputs**<br/>_address ethereumAddr_ - Ethereum address<br/>**Outputs**<br/>string calldata - Human readable name | Returns the human readable name associated with the Ethereum address. |

## Reference Implementation
We have implemented this proposed standard on the following blockchains.

| # | Contract Name | Blockchain | Address |
|---|---------------|------------|---------|
| 1 | HashtagNFTCollectiveTreasury | Ethereum  | 0xe4E9ae2D65008d171A07C12F20D5a5d62Fb31776 |
|   |                              | Moonbeam  | 0xA50e98f9cb301c04B9BB34d1BD95c2Dc8F3e8Ff3 |
|   |                              | Moonriver | 0xA50e98f9cb301c04B9BB34d1BD95c2Dc8F3e8Ff3 |
|   |                              | Celo      | 0x72824902d75F9832002c7907DF61a60A4AB801C9 |
|   |                              | Unique    | 0xA50e98f9cb301c04B9BB34d1BD95c2Dc8F3e8Ff3 |
|   |                              | Quartz    | 0xA50e98f9cb301c04B9BB34d1BD95c2Dc8F3e8Ff3 |
| 2 | HashtagNFTCollectiveResolver | Ethereum  | 0xA50e98f9cb301c04B9BB34d1BD95c2Dc8F3e8Ff3 |
|   |                              | Moonbeam  | 0x9a6Cba29cc0cA4f18990F32De15aae08819F4cD0 |
|   |                              | Moonriver | 0x9a6Cba29cc0cA4f18990F32De15aae08819F4cD0 |
|   |                              | Celo      | 0xdEc0F21665065e0c67b8eD107b1767c95cC4A763 |
|   |                              | Unique    | 0x9a6Cba29cc0cA4f18990F32De15aae08819F4cD0 |
|   |                              | Quartz    | 0x9a6Cba29cc0cA4f18990F32De15aae08819F4cD0 |

Further implementation details may be found in the Livetree repository [here](https://github.com/livetreetech/LivetreeCollective).

## Security Considerations
Important for security discussions, surfaces risks and could be the use of a whitelist described in the HashtagNFTCollectiveResolver DepositRoyalty method

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).