---
eip: 7390
title: Vanilla Options
description: An Interface for Vanilla Options
author: Ewan Humbert (@Xeway) <xeway@protonmail.com>, Lassi Maksimainen (@mlalma) <lassi.maksimainen@gmail.com>
discussions-to: https://ethereum-magicians.org/t/erc-7390-vanilla-option-standard/15206
status: Draft
type: Standards Track
category: ERC
created: 2022-09-02
requires: 20
---

## Abstract

This ERC defines a comprehensive set of functions and events facilitating seamless interactions (creation, management, exercising, etc.) for vanilla options. This standard ensures that options contracts conform to a common interface, facilitating the development of robust options trading platforms and enabling interoperability between dApps and protocols.

## Motivation

Options are widely used financial instruments that provide users with the right, but not the obligation, to buy or sell an underlying asset at a predetermined price within a specified timeframe. By introducing a standard interface for options contracts, we aim to foster a more inclusive and interoperable derivatives ecosystem on Ethereum. This standard will enhance the user experience and facilitate the development of decentralized options platforms, enabling users to seamlessly trade options across different applications.

## Specification

### Interface

```solidity
interface IERC7390 {
    enum Side {
        Call,
        Put
    }

    struct VanillaOptionData {
        Side side;
        address underlyingToken;
        uint256 amount;
        address strikeToken;
        uint256 strike;
        address premiumToken;
        uint256 premium;
        uint256 exerciseWindowStart;
        uint256 exerciseWindowEnd;
        bytes data;
    }

    event Created(uint256 indexed id);
    event Bought(uint256 indexed id, uint256 amount, address indexed buyer);
    event Exercised(uint256 indexed id, uint256 amount);
    event Expired(uint256 indexed id);
    event Canceled(uint256 indexed id);
    event PremiumUpdated(uint256 indexed id, uint256 amount);

    function create(VanillaOptionData calldata optionData) external returns (uint256);

    function buy(uint256 id, uint256 amount) external;

    function exercise(uint256 id, uint256 amount) external;

    function retrieveExpiredTokens(uint256 id) external;

    function cancel(uint256 id) external;

    function updatePremium(uint256 id, uint256 amount) external;
}

```

### State Variable Descriptions

At creation time, user must provide filled instance of `VanillaOptionData` structure that contains all the key information for initializing the option issuance.

#### `side`

**Type: `enum`**

Side of the option. Can take the value `Call` or `Put`. `Call` option gives the option buyer right to exercise any acquired option tokens to buy the `underlying` token at given `strike` price using `strikeToken` from option seller. Similarly, `Put` option gives the option buyer right to sell the `underlying` token to the option seller at `strike` price.

#### `underlyingToken`

**Type: `address` (`IERC20`)**

Underlying token.

#### `amount`

**Type: `uint256`**

Maximum amount of the underlying tokens that can be exercised.

> Be aware of token decimals!

#### `strikeToken`

**Type: `address` (`IERC20`)**

Token used as a reference to determine the strike price.

#### `strike`

**Type: `uint256`**

Strike price. The option buyer may be (depending on the contract implementation) able to exercise only fraction of the options and the paid strike price must be adjusted by the contract to reflect it.

Note that `strike` is set for exercising the total `amount` of options.

> Be aware of token decimals!

#### `premiumToken`

**Type: `address` (`IERC20`)**

Premium token. 

#### `premium`

**Type: `uint256`**

Premium price is the price that option buyer has to pay to option seller to compensate for the risk that the seller takes for issuing the options. Option premium changes depending on various factors, most important ones being the volatility of the underlying token, strike price and the time left for exercising the options.

Note that the premium price is set for exercising the total `amount` of options. The option buyer may be (depending on the contract implementation) able to buy only fraction of the option tokens and the paid premium price must be adjusted by the contract to reflect it.

> Be aware of token decimals!

#### `exerciseWindowStart`

**Type: `uint256`**\
**Format: *timestamp as seconds since unix epoch***

Option exercising window start time. When current time is greater or equal to `exerciseWindowStart` and below or equal to `exerciseWindowEnd`, owner of option(s) can exercise them. 

#### `exerciseWindowEnd`

**Type: `uint256`**\
**Format: *timestamp as seconds since unix epoch***

Option exercising window end time. When current time is greater or equal to `exerciseWindowStart` and below or equal to `exerciseWindowEnd`, owner of option(s) can exercise them. When current time is greater than `exerciseWindowEnd`, option holder can't exercise and writer can retrieve remaining underlying (call) or strike (put) tokens.

#### `data`

**Type: `bytes`**

Additional data that can be passed to contract function as a part of option issuance to add flexibility. For standard vanilla options this field is zero-sized array.

### Function Descriptions

#### `create`

```solidity
function create(VanillaOptionData calldata optionData) external returns (uint256);
```

Option writer creates new option tokens and defines the option parameters using `create()`. As an argument, option writer needs to fill `VanillaOptionData` data structure instance and pass it to the method. As a part of creating the option tokens, the function transfers the collateral from option seller to the contract.

It is highly preferred that as a part of calling `create()` the option issuance becomes fully collateralized to prevent increased counterparty risk. For creating a call (put) option issuance, writer needs to allow the amount of `amount` (`strike`) tokens of `underlyingToken` (`strikeToken`) to be transferred to the option contract before calling `create()`. 

Note that this standard does not define functionality for option seller to "re-up" the collateral in case the option contract allows under-collateralization. The contract needs to then adjust its API and implementation accordingly.

*Returns an id value that refers to the created option issuance in option contract if option issuance was successful.*

*Emits `Created` event if option issuance was successful.*

#### `buy`

```solidity
function buy(uint256 id, uint256 amount) external;
```

Allows the option buyer to buy `amount` of options from option issuance with the defined `id`. 

The buyer has to allow the token contract to transfer the (fraction of total) `premium` in the specified `premiumToken` to option seller. During the call of the function, the premium is be directly transferred to the seller.

*Emits `Bought` event if buying was successful.*

#### `exercise`

```solidity
function exercise(uint256 id, uint256 amount) external;
```

Allows the buyer to exercise `amount` of option tokens from option issuance with the defined `id`.

- If the option is a call, buyer pays seller at the specified strike price and gets the specified underlying tokens.
- If the option is a put, buyer transfers to seller the underlying tokens and gets paid at the specified strike price.

The buyer has to allow the spend of either `strikeToken` or `underlyingToken` before calling `exercise()`.

Exercise can only take place when `exerciseWindowStart` <= current time <= `exerciseWindowEnd`

*Emits `Exercised` event if the option exercising was successful.*

#### `retrieveExpiredTokens`

```solidity
function retrieveExpiredTokens(uint256 id) external;
```

Allows option seller to retrieve the collateral tokens that were not exercised. Seller can execute this function succesfully only after current time is greater than `exerciseWindowEnd`.

*Emits `Expired` event if the retrieval was successful.*

#### `cancel`

```solidity
function cancel(uint256 id) external;
```

Allows the seller to cancel the option and retrieve tokens used as collateral. Seller can only execute this function if not a single option has been purchased. If even a single option token is bought then this function will revert.

*Emits `Canceled` event if the cancelation was successful.*

#### `updatePremium`

```solidity
function updatePremium(uint256 id, uint256 amount) external;
```

Allows the seller to update the premium that option buyer will need to provide for buying the options. Note that the `amount` will be for the whole underlying amount, not only for the options that might still be available for purchase.

*Emits `PremiumUpdated` event when the function call was handled successfully.*

### Events

#### `Created`

```solidity
event Created(uint256 id);
```

Emitted when the writer has provided option issuance data successfully (and locked down the collateral to the contract). The given `id` identifies the particualr option issuance.

#### `Bought`

```solidity
event Bought(uint256 indexed id, uint256 amount, address indexed buyer);
```

Emitted when options have been bought. Provides information about the option issuance `id`, the address of `buyer` and the `amount` of options bought.

#### `Exercised`

```solidity
event Exercised(uint256 indexed id, uint256 amount);
```

Emitted when the option has been exercised from the option issuance with given `id` and the given `amount`.

#### `Expired`

```solidity
event Expired(uint256 indexed id);
```

Emitted when the seller of the option issuance with `id` has retrieved the un-exercised collateral.

#### `Canceled`

```solidity
event Canceled(uint256 indexed id);
```

Emitted when the option issuance with given `id` has been cancelled by the seller.

#### `PremiumUpdated`

```solidity
event PremiumUpdated(uint256 indexed id, uint256 amount);
```

Emitted when seller updates the premium to `amount` for option issuance with given `id`. Note that the updated premium is for the total issuance.

### Concrete Examples

#### Call Option

Let's say Bob sells an **call** option that Alice wants to buy.\
He gives the right to Alice to buy **8 LINK** tokens at **25 USDC** each between **14th of July 2023** and **16th of July 2023**.\
For such a contract, he asks Alice to give him **10 DAI** as a premium.\

To create the contract, he will give the following parameters:

- `side`: **Call**
- `underlyingToken`: **0x514910771AF9Ca656af840dff83E8264EcF986CA** *(LINK's address)*
- `amount`: **8000000000000000000** *(8 \* 10^(LINK's decimals))*
- `strikeToken`: **0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48** *(USDC's address)*
- `strike`: **200000000** *(8 * 25 \* 10^(USDC's decimals))*
- `premiumToken`: **0x6B175474E89094C44Da98b954EedeAC495271d0F** *(DAI's address)*
- `premium`: **10000000000000000000** *(10 \* 10^(DAI's decimals))*
- `exerciseWindowStart`: **1689292800** *(2023-07-14 timestamp)*
- `exerciseWindowEnd`: **1689465600** *(2023-07-16 timestamp)*
- `data`: **[]**

Once the contract created, Bob has to transfer the collateral to the contract. This collateral corresponds to the tokens he will have to give Alice if she decides to exercise the option. For this option, he has to give as collateral 8 LINK. He does that by calling the function `approve(address spender, uint256 amount)` on the LINK's contract and as parameters the contract's address (`spender`) and for `amount`: **8000000000000000000**. Then Bob can execute `create` on the contract for issuing the options.

Alice for its part, has to allow the spending of his 10 DAI by calling `approve(address spender, uint256 amount)` on the DAI's contract and give as parameters the contract's address (`spender`) and for `amount`: **10000000000000000000**. She can then execute `buy` on the contract in order to buy the option.

We're on the 15th of July and Alice wants to exercise her options because 1 LINK is traded at 50 USDC! She needs to allow the contract to transfer **8 * 25000000** USDCs from her account to match the required strike funding. When she calls `exercise` on the contract, the contract will transfer the strike funding to Bob and the LINK tokens that Bob gave as collateral during `create` call to Alice.

If she decides to sell the LINK tokens, she just made a profit of 8\*50 - 8\*25 = 200 USDC!

#### Put Option

Let's say Bob sells a put option to Alice.\
He gives the right to Alice to sell **8 LINK** tokens at **25 USDC** each between **14th of July 2023** and **16th of July 2023**.\
For such a contract, he asks Alice to give him **10 DAI** as a premium.\

To create the contract, he will give the following parameters:

- `side`: **Put**
- `underlyingToken`: **0x514910771AF9Ca656af840dff83E8264EcF986CA** *(LINK's address)*
- `amount`: **8000000000000000000** *(8 \* 10^(LINK's decimals))*
- `strikeToken`: **0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48** *(USDC's address)*
- `strike`: **200000000** *(8 \* 25 \* 10^(USDC's decimals))*
- `premiumToken`: **0x6B175474E89094C44Da98b954EedeAC495271d0F** *(DAI's address)*
- `premium`: **10000000000000000000** *(10 \* 10^(DAI's decimals))*
- `exerciseWindowStart`: **1689292800** *(2023-07-14 timestamp)*
- `exerciseWindowEnd`: **1689465600** *(2023-07-16 timestamp)*
- `data`: **[]**

Bob has to transfer collateral to the contract. This collateral corresponds to the funds he will have to give to Alice if she decides to exercise all the options. He has to give as collateral 200 USDC (8 \* 25) and does that by calling the function `approve(address spender, uint256 amount)` on the USDC's contract. As parameters he will give the contract's address (`spender`) and for `amount`: **200000000** *(`strike`\*`amount` / 10^(LINK's decimals))*. Then he can execute `create` on the contract for issuing the options.

Alice for her part has to allow the spending of **10 DAI** by calling `approve(address spender, uint256 amount)` on the DAI's contract, with as parameters the contract's address (`spender`) and for `amount`: **10000000000000000000**. Then, she can execute `buy` on the contract in order to buy all the options.

We're on the 15th of July, and Alice wants to exercise her options because 1 LINK is traded at only 10 USDC! To exercise she has to approve the transferring of **8 LINK** tokens and call `exercise` on the contract. Bob receives 8 LINK tokens, and Alice 200 USDC (8 LINK \* 25 USDC). She just made a profit of 200 - 8\*10 = 120 USDC!

#### Retrieve collateral

Let's say Alice never exercised his option because it wasn't profitable enough for her. To retrieve his collateral, Bob would have to wait for the current time to be greater than `exerciseWindowEnd`. In the examples, this characteristic is set to 2 days, so he would be able to get back his collateral from the 16th of July by simply calling `retrieveExpiredTokens`.

## Rationale

The proposed ERC option standard provides a simple yet powerful interface for options contracts on Ethereum. By standardizing the interface, it becomes easier for developers to build applications and platforms that support options trading, and users can seamlessly interact with different options contracts across multiple dApps.

This contract's concept is oracle-free, because we assume that a rational buyer will exercise his option only if it's profitable for him.

The premium is to be determined by the option seller. Seller is free to choose how to calculate the premium, e.g. by using *Black-Scholes model* or something else. Seller can update the premium price at will in order to adjust it according to changes on the underlying's price, volatility, time to option expiry and other such factors. Computing the premium off-chain is better for gas costs purposes.

This ERC is intended to represent **vanilla** options. However, exotic options can be built on top of this ERC.

## Security Considerations

Contract contains `exerciseWindowStart` and `exerciseWindowEnd` data points. These define the determined time range for the buyer to exercise options. When the current time is greater than `exerciseWindowEnd`, the buyer won't be able to exercise and the seller will be able to retrieve any remaining collateral. 

For preventing clear arbitrage cases when option seller considers the issuance to be of European options, we would strongly advice the option seller to use `updatePremium` call to considerably increase the premium price when exercise window opens. This will make sure that the bots won't be able to buy any remaining options and immediately exercise them for quick profit. If the option issuance is considered to be American, such adjustment is of course not needed. 

Once again, we advise writers to frequently check the underlying token price, and take the best decision for them.

**Improvement idea:** if two users agreed for an option off-chain and they want to create it on-chain, there is a risk that between the creation of the contract and the purchase by the second user, an on-chain user has already bought the contract. An implementation of ERC-7390 interface might want to add the allowed addresses e.g. to `data` variable or via a separate function call to define the allowed addresses that can buy options.

## Copyright

Copyright and related rights waived via [CC0](https://eips.ethereum.org/LICENSE).
