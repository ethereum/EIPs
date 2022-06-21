---
eip: eip-nfr.md
title: NFT Future Rewards (nFR) Standard
description: In this EIP, we propose a multigenerational reward mechanism that rewards‌ all ‌owners of non-fungible tokens (NFT).
author: Yale ReiSoleil <yale@iob.fi>, dRadiant (@dRadiant), D Wang, PhD <david@iob.fi>
discussions-to: https://ethereum-magicians.org/t/non-fungible-future-rewards-token-standard/9203
type: Standards Track
category: ERC
status: Draft
created: 2022-05-08
requires: 165, 721
---

## Simple Summary

This proposal outlines the interface of a new ERC721 standard extension. NFTs can then define, process, and distribute rewards based on the realized profit to former owners.

## Abstract

In this Ethereum Improvement Proposal (EIP), we propose the implementation of a Future Rewards (FR) extension which will enable owners of ERC721 tokens (NFTs) to participate in future price increases after they sell their tokens.

Owners of NFTs can expect to make money in two ways:

1. An increase in price during their holding period;
2. They receive Future Rewards (FRs) in the form of proceeds of the realized profits from the subsequent new owners after they have sold it. 

In the event the seller is not the first owner, the original minter, the profits gained when selling an NFT will be shared with the previous owners. The same person will receive the same FR distributions under the nFR system as the next generation of new owners after them. 

## Motivation

Are you interested in finding something that may prove valuable in the future and acquiring it early? Excellent! In reality, you often find yourself in a predicament where it does not matter whether you are a paper hand trader or a diamond hand hodler, the price keeps rising. 

Imagine if you were also rewarded with future price increases following the sale of your NFT?

In addition to being desired, a feature such as this is also justified in its existence. The value of a collectible is often determined by its provenance and its ownership history. The history of ownership plays an important role in determining its value. Consequently, all parties should be compensated retrospectively for their community status, reputations, and early contributions to the price discovery process. 

NFTs, in contrast to physical art and collectibles in the physical world, are not currently reflecting the contributions of their owners to their value. Since the ERC721 token can be tracked individually, and may be modified to record every change in price of any specific NFT token, there is no reason that a Future Rewards program of this type should not be established.

This EIP establishes a standard interface for a profit sharing structure in all stages of the token's ownership history desired by all market participants.

Additionally, as we will explain later, it discourages any "under-the-table" deals that may circumvent the rules set forth by artists and marketplaces.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

We are implementing this extension using the [Open Zeppelin ERC721 set of interfaces, contracts, and utilities](https://docs.openzeppelin.com/contracts/4.x/api/token/erc721).

ERC721-compliant contracts MAY implement this EIP for rewards to provide a standard method of rewarding future buyers and previous owners with realized profits in the future.

Implementers of this standard MUST have all of the following functions:

```solidity

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the Future Rewards Token Standard.
 *
 * A standardized way to receive future rewards for non-fungible tokens (NFTs.)
 *
 */
interface InFR is IERC165 {

    event FRClaimed(address indexed account, uint256 indexed amount);

    event FRDistributed(uint256 indexed tokenId, uint256 indexed soldPrice, uint256 indexed allocatedFR);

    function transferFrom(address from, address to, uint256 tokenId, uint256 soldPrice) external payable;

    function releaseFR(address payable account) external;

    function retrieveFRInfo(uint256 tokenId) external returns(uint8, uint256, uint256, uint256, uint256, address[] memory);

    function retrieveAllottedFR(address account) external returns(uint256);

}

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

```

An nFR contract MUST implement and update for each Token ID. The data in the `FRInfo` struct MAY either be stored wholly in a single mapping, or MAY be broken down into several mappings. The struct MUST either be exposed in a public mapping or mappings, or MUST have public functions that access the private data. This is for client-side data fetching and verification.

```solidity

struct FRInfo {
        uint8 numGenerations; //  Number of generations corresponding to that Token ID
        uint256 percentOfProfit; // Percent of profit allocated for FR, scaled by 1e18
        uint256 successiveRatio; // The common ratio of successive in the geometric sequence, used for distribution calculation
        uint256 lastSoldPrice; // Last sale price in ETH mantissa
        uint256 ownerAmount; // Amount of owners the Token ID has seen
        address[] addressesInFR; // The addresses currently in the FR cycle
}

```
 
An nFR smart contract MUST also store and update the amount of Ether allocated to a specific address using the `_allotedFR` mapping. The `_allottedFR` mapping MUST either be public or have a function to fetch the FR payment allotted to a specific address.

### Percent Fixed Point

The `allocatedFR` MUST be calculated using a percentage fixed point with a scaling factor of 1e18 (X/1e18) - such as "5e16" - for 5%. This is REQUIRED to maintain uniformity across the standard. The max and min values would be - 1e18 - 1.

### Default FR Info

A default `FRInfo` MUST be stored in order to be backwards compatible with ERC721 mint functions. It MAY also have a function to update the `FRInfo`, assuming it has not been hard-coded.

### ERC721 Overrides

An nFR smart contract MUST override the ERC721 `_mint`, `_transfer`, and `_burn` functions. When overriding the `_mint` function, a default FR model is REQUIRED to be established if the mint is to succeed when calling the ERC721 `_mint` function and not the nFR `_mint` function. It is also to update the owner amount and directly add the recipient address to the FR cycle. When overriding the `_transfer` function, the smart contract SHALL consider the NFT as sold for 0 wei, and update state accordingly after a successful transfer. This is to prevent FR circumvention. Finally, when overriding the `_burn` function, the smart contract SHALL delete the `FRInfo` corresponding to that Token ID after a successful burn.

Additionally, the ERC721 `_checkOnERC721Received` function MAY be explicitly called after mints and transfers if the smart contract aims to have safe transfers and mints.

### Safe Transfers

If the wallet/broker/auction application will accept safe transfers, then it MUST implement the ERC721 wallet interface.

### Future Rewards `transferFrom` Function

The FR `transferFrom` function MUST be called by all nFR-supporting smart contracts, though the accommodations for non-nFR-supporting contracts MAY also be implemented to ensure backwards compatibility.

```solidity

function transferFrom(address from, address to, uint256 tokenId, uint256 soldPrice) public virtual override payable {
       //...
}

```

The FR `transferFrom` function MUST be payable and the amount the NFT sold for MUST match the `msg.value` provided to the function. This is to ensure the values are valid and will also allow for the necessary FR to be held in the contract. Based on the stored `lastSoldPrice`, the smart contract will determine whether the sale was profitable after calling the ERC721 transfer function and transferring the NFT. If it was not profitable, the smart contract SHALL update the last sold price for the corresponding Token ID, increment the owner amount, shift the generations, and return all of the  `msg.value` to the `msg.sender` or `tx.origin` depending on the implementation. Otherwise, if the transaction was profitable, the smart contract SHALL call the `_distributeFR` function, then update the `lastSoldPrice`, increment the owner amount, and finally shift generations. The `_distributeFR` function MUST return the difference between the allocated FR that is to be distributed amongst the `_addressesInFR` and the `msg.value` to the `msg.sender` or `tx.origin`.

### Future Rewards Calculation

Marketplaces that support this standard MAY implement various methods of calculating or transferring Future Rewards to the previous owners.

```solidity

function _calculateFR(uint256 totalProfit, uint256 buyerReward, uint256 successiveRatio, uint256 ownerAmount, uint256 windowSize) pure internal virtual returns(uint256[] memory) {
    //...        
}

```

In this example (*Figure 1*), a seller is REQUIRED to share a portion of their net profit with 10 previous holders of the token. Future Rewards will also be paid to the same seller as the value of the token increases from up to 10 subsequent owners. 

When an owner loses money during their holding period, they MUST NOT be obligated to share Future Rewards distributions, since there is no profit to share. However, he SHALL still receive a share of Future Rewards distributions from future generations of owners, if they are profitable.

![Figure 1: Geometric sequence distribution](https://raw.githubusercontent.com/dRadiant/EIPs/master/assets/eip-nfr/Total_FR_Payout_Distribution-geo.png) 

*Figure 1: Geometric sequence distribution*

The buyers/owners receive a portion ( r ) of the realized profit  (P ) from an NFT transaction. The remaining proceeds go to the seller.

As a result of defining a sliding window mechanism ( n ), we can determine which previous owners will receive distributions. The owners are arranged in a queue, starting with the earliest owner and ending with the owner immediately before the current owner (the Last Generation). The First Generation is the last of the next n generations. There is a fixed-size profit distribution window from the First Generation to the Last Generation. 

The profit distribution SHALL be only available to previous owners who fall within the window. 

In this example, there SHALL be a portion of the proceeds awarded to the Last Generation owner (the owner immediately prior to the current seller) based on the geometric sequence in which profits are distributed. The larger portion of the proceeds SHALL go to the Mid-Gen owners, the earlier the greater, until the last eligible owner is determined by the sliding window, the First Generation. Owners who purchase earlier SHALL receive a greater reward, with first-generation owners receiving the greatest reward.

### Future Rewards Distribution

![Figure 2: NFT Owners' Future Rewards (nFR)](https://raw.githubusercontent.com/dRadiant/EIPs/master/assets/eip-nfr/nFR%20Standard%20Outline%20-%20blue.jpeg) 

*Figure 2: NFT Owners' Future Rewards (nFR)*

*Figure 2* illustrates an example of a five-generation Future Rewards Distribution program based on an owner's realized profit.

```solidity

function _distributeFR(uint256 tokenId, uint256 soldPrice) internal virtual {
       //...

        emit FRDistributed(tokenId, soldPrice, allocatedFR);
 }
 
```

The `_distributeFR` function MUST be called in the FR `transferFrom` function if there is a profitable sale. The function SHALL calculate the difference between the current sale price and the `lastSoldPrice`, then it SHALL call the `_calculateFR` function to receive the proper distribution of FR. Then it SHALL distribute the FR accordingly, making order adjustments as necessary. Then, the contract SHALL calculate the total amount of FR that was distributed (`allocatedFR`), in order to return the difference of the `soldPrice` and `allocatedFR` to the `msg.sender` or `tx.origin`. Finally, it SHALL emit the `FRDistributed` event. 

### Future Rewards Claiming

The future Rewards payments SHOULD utilize a pull-payment model, similar to that demonstrated by OpenZeppelin with their PaymentSplitter contract. The event  FRClaimed would be triggered after a successful claim has been made. 

```solidity

function releaseFR(address payable account) public virtual override {
        //...
}

```

### Owner Generation Shifting

The `_shiftGenerations` function MUST be called regardless of whether the sale was profitable or not. As a result, it will be called in the `_transfer` ERC721 override function and the FR `transferFrom` function. The function SHALL remove the oldest account from the corresponding `_addressesInFR` array. This calculation will take into account the current length of the array versus the total number of generations for a given token ID.

## Rationale

### Is This Just a Ponzi Scheme? 

No, it is not. Ponzi schemes promise profits that are impossible to keep. 

As opposed to fixed-yield schemes, our proposal only distributes future profits when those profits are achieved rather than guaranteeing them. Should later holders fail to make a profit, future return shares will not be distributed. 

The early participants in price discovery will receive a share of profits as part of the FR implementation only and if a later owner has accumulated profits during their holdings of the token.

### Fixed Percentage to 10^18

Considering Fixed-Point Arithmetic is to be enforced, it is logical to have 1e18 represent 100% and 1e16 represent 1% for Fixed-Point operations. This method of handling percents is also commonly seen in many Solidity libraries for Fixed-Point operations.

### Emitting Event for Payment

Since each NFT contract is independent, and while a marketplace contract can emit events when an item is sold, choosing to emit an event for payment is important. As the royalty and FR recipient may not be aware of/watching for a secondary sale of their NFT, they would never know that they received a payment except that their ETH wallet has been increased randomly. 

The recipient can therefore check on the payments received by their secondary sales by calling a function on the parent contract of the NFT that is being sold [1]:.

### Number of Generations of All Owners ( n ) vs Number of Generations of Only Profitable Owners

It is the number of generations of all owners, not just those who are profitable, that determines the number of owners from which the subsequent owners' profits will be shared, see *Figure 3*. As part of the effort to discourage "ownership hoarding," Future Rewards distributions will not be made to the current owner/purchaser if all the owners lose money holding the NFT. Further information can be found under Security Considerations.

![Figure 3: Losing owners](https://raw.githubusercontent.com/dRadiant/EIPs/master/assets/eip-nfr/Losing_owners.jpeg)

*Figure 3: Losing owners*

### Single vs Multigenerations

In a single generation reward, the new buyer/owner receives a share of the next single generation's realized profit only. In a multigenerational reward system, buyers will have future rewards years after their purchase. The NFT should have a long-term growth potential and a substantial dividend payout would be possible in this case. 

We propose that the marketplace operator can choose between a single generational distribution system and a multigenerational distribution system.

### Direct FR Payout by the Seller vs Smart Contract-managed Payout

FR payouts directly derived from the sale proceeds are immediate and final. As part of the fraud detection detailed later in the Security Considerations section, we selected a method in which the smart contract calculates all the FR amounts for each generation of previous owners, and handles payout according to other criteria set by the marketplace, such as reduced or delayed payments for wallet addresses with low scores, or a series of consecutive orders detected using a time-heuristic analysis. 

### Equal vs Linear Reward Distributions
#### Equal FR Payout

![Figure 4: Equal, linear reward distribution](https://github.com/dRadiant/EIPs/blob/master/assets/eip-nfr/Total_FR_Payout_Distribution-flat.png?raw=true)

*Figure 4: Equal, linear reward distribution*

FR distributions from the realization of profits by later owners are distributed equally to all eligible owners (*Figure 4*). The exponential reward curve, however, may be more desirable, as it gives a slightly larger share to the newest buyer. Additionally, this distribution gives the earliest generations the largest portions as their FR distributions near the end, so they receive higher rewards for their early involvement, but the distribution is not nearly as extreme as one based on arithmetic sequences (*Figure 5*). 

This system does not discriminate against any buyer because each buyer will go through the same distribution curve.

#### Straight line arithmetic sequence FR payout

![Figure 5: Arithmetic sequence distribution](https://github.com/dRadiant/EIPs/blob/master/assets/eip-nfr/Arithmetic_Sequence_FR_Payout_Distribution.png?raw=true)

*Figure 5: Arithmetic sequence distribution*

The profit is distributed according to the arithmetic sequence, which is 1, 2, 3, ... and so on. The first owner will receive 1 portion, the second owner will receive 2 portions, the third owner will receive 3 portions, etc. 

## Backwards Compatibility

This proposal is fully compatible with current ERC721 standards and EIP-2981. It can also be easily adapted to work with EIP-1155.

## Test Cases

[Following](https://github.com/dRadiant/nfr-reference-implementation) is a contract that detects which interfaces other contracts implement, from iob.fi DAO by @dRadiant

The repository with the reference implementation contains all the tests.

[Here is an illustration of a test case](https://github.com/dRadiant/EIPs/blob/master/assets/eip-nfr/animate-1920x1080-1750-frames.gif?raw=true). 

## Reference Implementations

This implementation uses [OpenZeppelin contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) and the [PRB Math library created by Paul R Berg for fixed-point arithmetic](https://github.com/paulrberg/prb-math/tree/main). It demonstrates the interface for the nFR standard, an nFR standard-compliant extension, and an ERC721 implementation using the extension.

GitHub Link: https://github.com/dRadiant/nfr-reference-implementation

### Distribution of NFT Royalties to Artists and Creators

We agree that artists’ royalties should be uniform and on-chain. We support both [EIP-4910](https://github.com/ethereum/EIPs/pull/4910/commits/8fd87b4ec3dbfce40e38325f3b8a69f337368661) and [EIP-2981](https://eips.ethereum.org/EIPS/eip-2981) proposals.

All platforms can support royalty rewards for the same NFT based on on-chain parameters and functions:

- No profit, no profit sharing, no cost;
- The question of "who owned it" is often crucial to the provenance and value of a collectible;
- The previous owner should be re-compensated for their ownership;
- And the buyer/owner incentive in FR eliminates any motive to circumvent the royalty payout schemes;

### Distribution of NFT Owners’ Future Rewards (FRs)

#### Future Rewards calculation

Any realized profits (P) when an NFT is sold are distributed among the buyers/owners. The previous owners will take a fixed portion of the profix (P), and this portion is called Future Rewards (FRs). The seller takes the rest of the profits.

We define a sliding window mechanism to decide which previous owners will be involved in the profit distribution. Let's imagine the owners as a queue starting from the first hand owner to the current owner. The profit distribution window starts from the previous owner immediately to the current owner and extends towards the first owner, and the size of the windows is fixed. Only previous owners located inside the window will join the profit distribution.  

![Future Rewards calculation formula](https://github.com/dRadiant/EIPs/blob/master/assets/eip-nfr/nFR_distribution_formula.png?raw=true)

In this equation:

- P is the total profit, the difference between the selling price minus the buying price;
- r is buyer reward ratio of the total P;
- g is the common ratio of successive in the geometric sequence;
- n is the actual number of owners eligible and participating in the future rewards sharing. To calculate n, we have n = min(m, w), where m is the current number of owners for a token, and w is the window size of the profit distribution sliding window algorithm

#### Converting into Code

```solidity

pragma solidity ^0.8.0;
//...

/* Assumes usage of a Fixed Point Arithmetic library (prb-math) for both int256 and uint256, and OpenZeppelin Math utils for Math.min. */
function _calculateFR(uint256 P, uint256 r, uint256 g, uint256 m, uint256 w) pure internal virtual returns(uint256[] memory) {
        uint256 n = Math.min(m, w);
        uint256[] memory FR = new uint256[](n);

        for (uint256 i = 1; i < n + 1; i++) {
            uint256 pi = 0;

            if (successiveRatio != 1e18) {
                int256 v1 = 1e18 - int256(g).powu(n);
                int256 v2 = int256(g).powu(i - 1);
                int256 v3 = int256(P).mul(int256(r));
                int256 v4 = v3.mul(1e18 - int256(g));
                pi = uint256(v4 * v2 / v1);
            } else {
                pi = P.mul(r).div(n);
            }

            FR[i - 1] = pi;
        }

        return FR;
}

```
The complete implementation code can be found [here](https://github.com/dRadiant/nfr-reference-implementation).

## Security Considerations

### Payment Attacks

As this EIP introduces royalty and realized profit rewards collection, distribution, and payouts to the ERC721 standard, the attack vectors increase. We recommend reentrancy protection on all payment functions to reduce the most significant attack vector categories for payments and payouts [2].

EIP-4910 proposes some mitigations to phishing attacks by Andreas Freund.

### Royalty Circumventing

Many methods are being used to avoid paying royalties to creators under the current ERC721 standard. Through an under-the-table transaction, the new buyer's cost basis will be reduced to zero, increasing their FR liability to the full selling price. Everyone, either the buyer or seller, would pay a portion of the previous owner's net realized profits ( P x r ). Acting in his or her own interests, the buyer rejects any loyalty circumventing proposal.

### FR Hoarding through Wash Sales

All unregulated cryptocurrency trading platforms and NFT marketplaces experience widespread wash trading [3] [4]. In addition to inflating prices and laundering money, dishonest actors may use wash trading to gain an unfair advantage. The validity of the system is undermined when a single entity becomes multiple generations of owners to accumulate more future rewards.

#### Wash trading by users
Using a different wallet address, an attacker can "sell" the NFT to themselves at a loss. It is possible to repeat this process n times in order to maximize their share of the subsequent FR distributions (*Figure 6*). A wallet ranking score can partially alleviate this problem. It is evident that a brand new wallet is a red flag, and the marketplace may withhold FR distribution from it if it has a short transaction history (i.e. fewer than a certain number of transactions).

We do not want a large portion of future rewards to go to a small number of wash traders. Making such practices less profitable is one way to discourage wash trading and award hoarding. It can be partially mitigated, for example, by implementing a wallet-score and holding period-based incentive system. The rewards for both parties are reduced if a new wallet is used or if a holding period is less than a certain period. 

![Figure 6: Same owner using different wallets](https://github.com/dRadiant/EIPs/blob/master/assets/eip-nfr/5%20losing.jpeg?raw=true)

*Figure 6: Same owner using different wallets*

#### Wash trading by the marketplace operator

But the biggest offender is the marketplace, which engages in wash trading a lot, or simply does not care about it [5]. At a mid-night drinking session in 2018, a top-level executive of a top-5 cryptocurrency exchange boasted how they "brushed" (wash-traded) certain newly listed tokens, which they called "marketmaking." [6]

Many of these companies engage in wash trading on their own or collude with certain users, and royalties and FR payments are reimbursed under the table. It is crucial that all exchanges have robust features to prevent self-trading. Users should be able to observe watchers transparently. Marketplaces should provide their customers with free access to an on-chain transaction monitoring service like Chainalysis Reactor.

### Long/Cyclical FR-Entitled Owner Generations

Malicious actors are most likely to create excessively long or cyclical Future Rewards Owner Generations, resulting in applications that attempt to distribute FR or shift generations running out of gas and unable to function 7. As a result, clients are responsible for verifying that the contract they interact with has an appropriate number of generations, which will not deplete the gas by looping over.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).

## Citation

Please cite this document as:

Yale ReiSoleil, @dRadiant, D Wang, PhD, et al., "EIP-nFR.md: NFT Future Rewards (nFR) Standard," Ethereum Improvement Proposals, no. xxx, May 2022. [Online serial]. Available: https://eips.ethereum.org/EIPS/eip-nFR.md.

## Endnotes

1.  Zach Burks, James Morgan, [EIP-2981](https://github.com/VexyCats/EIPs/blob/master/EIPS/eip-2981.md)
2.  Andreas Freund, [EIP-4910](https://github.com/ethereum/EIPs/pull/4910/commits/8fd87b4ec3dbfce40e38325f3b8a69f337368661): Proposal for a standard for onchain Royalty Bearing NFTs
3.  Quantexa, https://www.quantexa.com/blog/detect-wash-trades/
4.  https://beincrypto.com/95-trading-volume-looksrare-linked-wash-trading/
5.  https://decrypt.co/91847/significant-wash-trading-money-laundering-nft-market-chainalysis
6.  It is still one of the top-5 crypto exchanges today.
