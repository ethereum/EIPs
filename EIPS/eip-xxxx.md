---
eip: <to be assigned>
title: Vanilla Option Standard
description: A Standard Interface for Vanilla Options on the Ethereum Blockchain
author: Ewan Humbert (@Xeway) <xeway@protonmail.com>
discussions-To: [Ethereum Magicians](https://ethereum-magicians.org/)
status: Draft
type: Standards Track
category: ERC
created: 2022-09-02
---

## Simple Summary

This proposal introduces a standard interface for creating and interacting with vanilla options contracts on the Ethereum blockchain. The ERC option standard provides a consistent way to represent and trade options, enabling interoperability between different decentralized applications (dApps) and platforms.

## Abstract

This ERC defines a set of functions and events that allow for the creation, management, and exercising of options contracts on Ethereum. This standard ensures that options contracts conform to a common interface, facilitating the development of robust options trading platforms and enabling interoperability between dApps and protocols.

## Motivation

Options are widely used financial instruments that provide users with the right, but not the obligation, to buy or sell an underlying asset at a predetermined price within a specified timeframe. By introducing a standard interface for options contracts, we aim to foster a more inclusive and interoperable options ecosystem on Ethereum. This standard will enhance the user experience and facilitate the development of decentralized options platforms, enabling users to seamlessly trade options across different applications.

## Specification

### Interface

```solidity
interface IOption {
    event Created(uint256 timestamp);
    event Bought(address indexed buyer, uint256 timestamp);
    event Exercised(uint256 timestamp);
    event Expired(uint256 timestamp);
    event Canceled(uint256 timestamp);

    function create() external returns (bool);
    function buy() external returns (bool);
    function exercise() external returns (bool);
    function retrieveExpiredTokens() external returns (bool);
    function cancel() external returns (bool);

    function side() external view returns (Side);
    function underlyingToken() external view returns (address);
    function amount() external view returns (uint256);
    function strikeToken() external view returns (address);
    function strike() external view returns (uint256);
    function expiration() external view returns (uint256);
    function exerciseDuration() external view returns (uint256);
    function premiumToken() external view returns (address);
    function premium() external view returns (uint256);
    function getType() external view returns (Type);
    function writer() external view returns (address);
    function buyer() external view returns (address);
    function state() external view returns (State);
}
```

### Creation (constructor)

At creation time, user must provide the following parameters:

- `side`
- `underlyingToken`
- `amount`
- `strikeToken`
- `strike`
- `expiration`
- `exerciseDuration`
- `premiumToken`
- `premium`
- `type`

### State Variable Descriptions

#### `side`
**Type: `enum`**

Side of the option. Can take the value `Call` or `Put`.

#### `underlyingToken`
**Type: `address` (`IERC20`)**

Underlying token.

#### `amount`
**Type: `uint256`**

Amount of the underlying token.

> Be aware of token decimals!

#### `strikeToken`
**Type: `address` (`IERC20`)**

Token used as a reference to determine the strike price.

#### `strike`
**Type: `uint256`**

Strike price.

> Be aware of token decimals!

#### `expiration`
**Type: `uint256`**\
**Format: _timestamp as seconds since unix epoch_**

Date of the expiration.

#### `exerciseDuration`
**Type: `uint256`**\
**Format: _seconds_**

Duration during which the buyer may exercise the option. This period start at the `expiration`'s date. After this time range, buyer can't exercise and writer can retrieve his collateral.

#### `premiumToken`
**Type: `address` (`IERC20`)**

Premium token.

#### `premium`
**Type: `uint256`**

Premium price.

> Be aware of token decimals!

#### `type`
**Type: `enum`**

Type of the option. Can take the value `European` or `American`.

#### `writer`
**Type: `address`**

Writer's address. Since the contract inherit from `Ownable`, `writer` is `owner`.

#### `buyer`
**Type: `address`**

Buyer's address.

#### `state`
**Type: `enum`**

State of the option. Can take the value `Invalid` (at creation), `Created` (when collateral received), `Bought`, `Exercised`, `Expired` or `Canceled`.

### Function Descriptions

#### `create`
```solidity
function create() external returns (bool);
```
Allows the writer to validate the option by transferring the collateral to the contract.\

> Previously, the writer has to allow the spend of amount `strike`/`amount` of token `strikeToken`/`underlyingToken` depending if the option is of type `Call` or `Put`. These funds will go to the contract and will be used as a *<u>collateral</u>* to be sure the necessary tokens are available if the buyer decides to exercise.

*Returns a boolean depending on whether or not the function was successfully executed.*

#### `buy`
```solidity
function buy() external returns (bool);
```
Allows the user to buy the option. The buyer has to previously allow the spend to pay for the premium in the specified token. During the call of the function, the premium is be directly send to the writer.

*Returns a boolean depending on whether or not the function was successfully executed.*

#### `exercise`
```solidity
function exercise() external returns (bool);
```
Allows the buyer to exercise his option.

- If the option is a call, buyer pays writer at the specified strike price and gets the specified underlying token(s).
- If the option is a put, buyer transfers to writer the underlying token(s) and gets paid at the specified strike price.

In all case, the buyer has to previously allow the spend of either `strikeToken` or `underlyingToken`.

*Returns a boolean depending on whether or not the function was successfully executed.*

#### `retrieveExpiredTokens`
```solidity
function retrieveExpiredTokens() external returns (bool);
```
Allows the writer to retrieve the token(s) he locked (used as collateral). Writer can only execute this function after the period `exerciseDuration` happening/starting right after `expiration`.

*Returns a boolean depending on whether or not the function was successfully executed.*

#### `cancel`
```solidity
function cancel() external returns (bool);
```
Allows the writer to cancel the option and retrieve his/its locked token(s) (used as collateral). Writer can only execute this function if the option hasn't been bought.

*Returns a boolean depending on whether or not the function was successfully executed.*

### Events

#### `Created`
```solidity
event Created(uint256 timestamp);
```
Emitted when the writer has given the collateral to the contract. Provides information about the transaction's `timestamp`.

#### `Bought`
```solidity
event Bought(address indexed buyer, uint256 timestamp);
```
Emitted when the option has been bought. Provides information about the `buyer` and the transaction's `timestamp`.

#### `Exercised`
```solidity
event Exercised(uint256 timestamp);
```
Emitted when the option has been exercised. Provides information about the transaction's `timestamp`.

#### `Expired`
```solidity
event Expired(uint256 timestamp);
```
Emitted when the option has been expired. Provides information about the transaction's `timestamp`.

#### `Canceled`
```solidity
event Canceled(uint256 timestamp);
```
Emitted when the option has been canceled. Provides information about the transaction's `timestamp`.

### Concrete Example

#### Call Option

Let's say Bob sells an **european call** option to Alice.\
He gives the right to Alice to buy to him **8 LINK** at **25 USDC** each for the **14th of July 2023**.\
For such a contract, he asks Alice to give him **10 DAI** as a premium.\
Moreover, Alice has **2 days** after the 31th to exercise or not his option.\

To create the contract, he will give the following parameters:

- `side`: **Call**
- `underlyingToken`: **0x514910771AF9Ca656af840dff83E8264EcF986CA** *(LINK's address)*
- `amount`: **8000000000000000000** *(8 \* 10^(LINK's decimals))*
- `strikeToken`: **0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48** *(USDC's address)*
- `strike`: **25000000** *(25 \* 10^(USDC's decimals))*
- `expiration`: **1689292800** *(2023-07-14 timestamp)*
- `exerciseDuration`: **172800** *(2 days in seconds)*
- `premiumToken`: **0x6B175474E89094C44Da98b954EedeAC495271d0F** *(DAI's address)*
- `premium`: **10000000000000000000** *(10 \* 10^(DAI's decimals))*
- `type`: **European**

Once the contract created, Bob has to transfer the collateral to the contract. This collateral corresponds to the funds he will have to give Alice if she decides to exercise the option. For this option, he has to give as collateral 8 LINK.\
He does that by calling the function `approve(address spender, uint256 amount)` on the LINK's contract, with as parameters the contract's address (`spender`) and for `amount`: **8000000000000000000**.\
Then he can execute `create` on the contract in order to "validate" the option.

Alice for its part, has to allow the spending of his 10 DAI by calling `approve(address spender, uint256 amount)` on the DAI's contract, with as parameters the contract's address (`spender`) and for `amount`: **10000000000000000000**.\
Then, she can execute `buy` on the contract in order to buy the option.

We're the 15th of July, and Alice has very interest to exercise his option because 1 LINK is traded at 50 USC!\
So to exercise, she just has to call `exercise` on the contract, and that's it! Bob receives 200 USDC (8 LINK \* 25 USDC), and Alice 8 LINK.\
She made a profit of 8\*50 - 200 = 200 USDC!

#### Put Option

Let's say Bob sells an **european put** option to Alice.\
He gives the right to Alice to sell to him **8 LINK** at **25 USDC** each for the **14th of July 2023**.\
For such a contract, he asks Alice to give him **10 DAI** as a premium.\
Moreover, Alice has **2 days** after the 31th to exercise or not his option.\

To create the contract, he will give the following parameters:

- `side`: **Put**
- `underlyingToken`: **0x514910771AF9Ca656af840dff83E8264EcF986CA** *(LINK's address)*
- `amount`: **8000000000000000000** *(8 \* 10^(LINK's decimals))*
- `strikeToken`: **0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48** *(USDC's address)*
- `strike`: **25000000** *(25 \* 10^(USDC's decimals))*
- `expiration`: **1689292800** *(2023-07-14 timestamp)*
- `exerciseDuration`: **172800** *(2 days in seconds)*
- `premiumToken`: **0x6B175474E89094C44Da98b954EedeAC495271d0F** *(DAI's address)*
- `premium`: **10000000000000000000** *(10 \* 10^(DAI's decimals))*
- `type`: **European**

Once the contract created, Bob has to transfer the collateral to the contract. This collateral corresponds to the funds he will have to give Alice if she decides to exercise the option. For this option, he has to give as collateral 200 USDC (8 \* 25).\
He does that by calling the function `approve(address spender, uint256 amount)` on the USDC's contract, with as parameters the contract's address (`spender`) and for `amount`: **200000000** *(`strike`\*`amount` / 10^(LINK's decimals))*.\
Then he can execute `create` on the contract in order to "validate" the option.

Alice for its part, has to allow the spending of his 10 DAI by calling `approve(address spender, uint256 amount)` on the DAI's contract, with as parameters the contract's address (`spender`) and for `amount`: **10000000000000000000**.\
Then, she can execute `buy` on the contract in order to buy the option.

We're the 15th of July, and Alice has very interest to exercise his option because 1 LINK is traded at only 10 USC!\
So to exercise, she just has to call `exercise` on the contract, and that's it! Bob receives 8 LINK, and Alice 200 USDC (8 LINK \* 25 USDC).\
She made a profit of 200 - 8\*10 = 120 USDC!

#### Retrieve collateral

Let's say Alice never exercised his option because it wasn't profitable enough for her. To retrieve his collateral, Bob would have to wait for the `exerciseDuration` period to finish. In the examples, this characteristic is set to 2 days, so he would be able to get back his collateral from the 16th of July, by simply calling `retrieveExpiredTokens`.

## Rationale

The proposed ERC option standard provides a simple yet powerful interface for options contracts on Ethereum. By standardizing the interface, it becomes easier for developers to build applications and platforms that support options trading, and users can seamlessly interact with different options contracts across multiple dApps.

This contract's concept is oracle-free, because we assumed that a rational buyer will exercise his option only if it's profitable for him.

The contract also inherit from OpenZeppelin's `Ownable` contract. Therefore, we decided that the owner of the contract is also the writer.\
You can change the contract's owner (and so the writer) by calling `transferOwnership`.

The premium is to be determined by the writer, so that he's free to choose how to calculate the option's. We assume that many premiums will be determined by the *Black-Scholes model*, and computing this off-chain is better for gas costs purposes.

This ERC is intended to represent **vanilla** options. However, exotic options can be built on top of this ERC.

## Reference Implementation

[See an implementation of this ERC here.](https://github.com/Xeway/ERC/blob/main/contracts/Option.sol)\
The code's foundation is inspired by [Tobias](https://github.com/TobiasBK)'s work.

## Security Considerations

We implemented an additional parameter to the conception called `exerciseDuration`. This gives a determined time range for the buyer to exercise his option after which he won't be able to exercise and the writer will be able to retrieve his collateral. We are conscious that during this time range, price can change, and an option that was not profitable for the buyer at expiration time, can be during this time range. For this reason, we highly advise writers to think and determine carefully each parameter.

Also, if the option is of type European, an user could theoretically buy a profitable option right before the expiration date, and exercise it the second after. This would lead to new bots searching for these kind of options "forgotten" by their writers, and would create new MEV opportunities.\
For American option, this is even worse.\
Once again, we advise writers to frequently check the underlying token price, and take the best decision for them.

**Improvement idea:** if two users agreed for an option off-chain and they want to create it on-chain, there is a risk that between the creation of the contract and the purchase by the second user via the function `buy`, an on-chain user has already bought the contract. So it could be an improvement to add the possibility to directly set a buyer.

## Conclusion

The ERC option standard proposes a common interface for options contracts on Ethereum, promoting interoperability and facilitating the development of decentralized options platforms. By adopting this standard, developers can build applications that seamlessly interact with options contracts, enhancing the user experience and expanding the options trading ecosystem on Ethereum. Community feedback and further discussion are encouraged to refine and improve this proposal.

## Copyright

Copyright and related rights waived via [CC0](https://eips.ethereum.org/LICENSE).
