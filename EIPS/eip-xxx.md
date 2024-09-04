```
EIP: 
Title: Buyer-Seller Negotiable Pricing Mechanism
description: Allows buyers and sellers to freely negotiate and determine transaction prices on the Ethereum network. The seller sets the initial price, and the buyer can propose a new price through negotiation with the seller, and eventually both parties can reach an agreement and complete the transaction.
Author: S7iter(@admi-n) <s7@gmail.com>
Status: Draft
Type: Standards Track 
Category: ERC
Created: 2024-09-04
```



## Introduction

This proposal introduces a new smart contract mechanism that allows buyers and sellers to freely negotiate and determine transaction prices on the Ethereum network. A new trading mode is added, where goods can be negotiated rather than only priced. This mechanism allows the seller to set an initial price, and the buyer can propose a new price through negotiation with the seller. Ultimately, both parties can reach an agreement and complete the transaction.

## Motivation

Current smart contracts and decentralized applications (DApps) typically use a fixed-price model, where prices are set rather than negotiated. This model has many disadvantages, which may limit market flexibility and liquidity. A free price negotiation mechanism between buyers and sellers can better reflect market demand. This proposal introduces the most critical party in the transaction: the buyer's personal needs and pricing intentions. It can promote more transaction functionalities and models, expand markets, facilitate transactions, and increase user participation and satisfaction.

## Specification

### Structure

The contract consists of the following main structures:

- **Offer**: Represents the item or token listed by the seller and its initial price.
- **Negotiation**: Represents the new price proposed by the buyer and whether it is accepted by the seller.

### State Variables

- `mapping(uint256 => Offer) public offers;`: Stores detailed information on all listed items or tokens.
- `mapping(uint256 => Negotiation) public negotiations;`: Stores detailed information on all price negotiations.
- `uint256 public nextOfferId;`: Used to generate new `offerId`.

### Functions

- `function createOffer(uint256 price) external returns (uint256)`:
  The seller creates a new listing for an item or token and sets an initial price. Returns the `offerId`.
- `function proposePrice(uint256 offerId, uint256 proposedPrice) external`:
  The buyer proposes a new price for a specific `offerId`. The new price is stored in the `negotiations` mapping.
- `function acceptProposedPrice(uint256 offerId) external`:
  The seller accepts the new price proposed by the buyer. The transaction is completed, and the new price becomes the final transaction price.

### Events

- `event OfferCreated(uint256 offerId, address indexed seller, uint256 price)`:
  Triggered when the seller creates a new listing for an item or token.
- `event PriceProposed(uint256 offerId, address indexed buyer, uint256 proposedPrice)`:
  Triggered when the buyer proposes a new price.
- `event PriceAccepted(uint256 offerId, address indexed seller, uint256 acceptedPrice)`:
  Triggered when the seller accepts the price proposed by the buyer.

## Rationale

This proposal adopts a simple and flexible structure that enables buyers and sellers to negotiate prices at low cost and high efficiency. This mechanism can be applied to various scenarios, such as decentralized marketplaces and auction platforms.

## Backwards Compatibility

This EIP introduces new functionality without affecting existing smart contract standards. It can be seamlessly integrated as an extension to existing markets and DApps.

## Implementation

Below is a sample Solidity smart contract that implements the core functionality of this proposal:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NegotiablePricing {

    struct Offer {
        address seller;
        uint256 price;
        bool isActive;
    }

    struct Negotiation {
        address buyer;
        uint256 proposedPrice;
        bool isAccepted;
    }

    mapping(uint256 => Offer) public offers;
    mapping(uint256 => Negotiation) public negotiations;
    uint256 public nextOfferId;

    event OfferCreated(uint256 offerId, address indexed seller, uint256 price);
    event PriceProposed(uint256 offerId, address indexed buyer, uint256 proposedPrice);
    event PriceAccepted(uint256 offerId, address indexed seller, uint256 acceptedPrice);

    function createOffer(uint256 price) external returns (uint256) {
        uint256 offerId = nextOfferId++;
        offers[offerId] = Offer({
            seller: msg.sender,
            price: price,
            isActive: true
        });
        emit OfferCreated(offerId, msg.sender, price);
        return offerId;
    }

    function proposePrice(uint256 offerId, uint256 proposedPrice) external {
        require(offers[offerId].isActive, "Offer is not active");
        require(proposedPrice > 0, "Price must be greater than 0");

        negotiations[offerId] = Negotiation({
            buyer: msg.sender,
            proposedPrice: proposedPrice,
            isAccepted: false
        });

        emit PriceProposed(offerId, msg.sender, proposedPrice);
    }

    function acceptProposedPrice(uint256 offerId) external {
        require(offers[offerId].isActive, "Offer is not active");
        require(offers[offerId].seller == msg.sender, "Only the seller can accept a price");

        negotiations[offerId].isAccepted = true;
        offers[offerId].price = negotiations[offerId].proposedPrice;
        offers[offerId].isActive = false;

        emit PriceAccepted(offerId, msg.sender, offers[offerId].price);
    }
}
```

