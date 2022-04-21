---
eip: <to be assigned>
title: Subscription Tokens
description: Tokens with the ability to pay recurring costs
author: Pandapip1 (@Pandapip1)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-04-21
requires: 20, 4524
---

## Abstract
Recurring payments (hereafter referred to as "subscriptions"), are tricky to implement, and bad for user experience. The current standards ([EIP-1337](./eip-1337.md), [EIP-4885](./eip-4885.md)) are implemented by users transferring a certain amount to a contract, which then performs its function for the duration. This has obvious downsides, however: the user has to decide in advance for how long they want to pay for the service, and continally re-pay the contract. This EIP proposes an interface that allows addresses to recieve tokens over time.

## Motivation
A typical type of ICO is where the token amount is paid out over time. This is usually done through a form of pull payment, which is cumbersome for the user. With this system, the user only has to make a single transaction to recieve the funds: `updateSubscription` for the maximum uint256 value. Lottery payouts or pensions could also be paid out in this manner.

NFTs could require that a maintenance cost be paid. An silly example could be an NFT game with virtual chickens that require virtual food to stay alive. These could be combined in interesting manners -- food can be used to "feed" chickens, which "lay" eggs automatically. Eggs could be automatically "exported" to a market, and so on.

## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### ERCXXXXToken

```solidity
interface ERCXXXXToken is ERC20, ERC165, ERC4524 {

    /////////////////
    //// GETTERS ////
    /////////////////

    /// @notice             Gets the number of tokens that are sent per block from `from` to `to`
    /// @param  from        The address sending tokens
    /// @param  to          The address recieving tokens
    /// @return amount      The amount of tokens being sent
    function subscription(address from, address to) external view returns (uint256 amount);


    /// @notice             Gets the maximum number of tokens that can be sent per block from `from` to `to`
    /// @param  from        The address sending tokens
    /// @param  to          The address recieving tokens
    /// @return allowance   The maximum value of `amount` in `updateSubscription`
    function subscriptionAllowance(address from, address to) external view returns (uint256 allowance);

    /// @notice             Gets if the balance is larger than or equal to the amount paid each block
    /// @param  subscriber  The account paying
    /// @return active      Whether or not the account is able to pay
    function subscriptionActive(address subscriber) external view returns (bool active);

    /////////////////
    //// SETTERS ////
    /////////////////

    /// @notice             Sets the subscription allowance to `amount`
    /// @param  to          The address recieving tokens
    /// @param  amount      The amount to send/approve each block
    function subscribe(address to, uint256 amount) external;


    /// @notice             Sets the subscription allowance to `amount`, and calls `onERC20Subscribed` if `to` is a contract
    /// @param  to          The address recieving tokens
    /// @param  amount      The amount to send/approve each block
    function safeSubscribe(address to, uint256 amount) external;


    /// @notice             Sets the subscription allowance to `amount`, sets the subscription amount to `amount`, and calls `onERC20Subscribed` if `to` is a contract with the same validation as EIP-4524
    /// @param  to          The address recieving tokens
    /// @param  amount      The amount to send/approve each block
    /// @param  data        Data to provide to `onERC20Subscribed`
    function safeSubscribe(address to, uint256 amount, bytes memory data) external;


    /// @notice             Sets the subscription amount to `amount`
    /// @param  from        The address sending tokens
    /// @param  amount      The amount to send/approve each block. If greater than the allowance, then only the allowance will be sent
    /// @return authed      `true` if `amount` is less than or equal to the authorization.
    function updateSubscription(address from, uint256 amount) external returns (bool authed);

    ////////////////
    //// EVENTS ////
    ////////////////

    /// @notice             Emitted when the subscription amount is changed
    /// @param  from        The address sending tokens
    /// @param  to          The address recieving tokens
    /// @param  amount      The amount sent each block
    event Subscription(address indexed from, address indexed to, uint256 amount);


    /// @notice             Emitted when the subscription allowance is changed
    /// @param  from        The address sending tokens
    /// @param  to          The address recieving tokens
    /// @param  amount      The maximum amount sent each block
    event SubscriptionApproval(address indexed from, address indexed to, uint256 amount);
}
```

### ERC20Subscriber
```solidity
interface ERC20Subscriber is ERC20Receiver {
    /// @dev                Note: `updateSubscription` can be safely called from this function, because it does not re-call `onERC20Subscribed`. This is the recommended way to automatically accept subscriptions
    function onERC20Subscribed(address from, uint256 amount, bytes data) external returns(bytes4);
}
```

## Rationale
EIP-4524 was used as a base because of the similarity of use-cases. The reason that `subscribe` and `safeSubscribe` don't directly set the subscription amount is so that contracts can make it so that users only pay for their usage (e.g. an nft doesn't need to pull payments from everyone who ever owned it).

## Backwards Compatibility
There are no backwards compatibilty issues. All function and event names are unique.

## Security Considerations
`onERC20Subscribed` is a callback function. Callback functions have been exploited in the past as a reentrancy vector, and care should be taken to make sure implementations are not vulnerable. (Taken word-for-word from EIP-4524)

Subscriptions are not enumerable, and balance changes because of subscriptions do not show up in event logs because there are no associated transactions. Make sure to keep track of what you're subscribed to!

If you are implementing an `ERC20Subscriber` contract, make sure that `subscriptionActive(subscriber)` and that the subscription amount is high enough. No callback is called if the subscriber runs out of tokens.

Implementing EIP-XXXX significantly increases the code complexity, because balances change without changes in state. Make sure to have your code **thoroughly** audited. In particular, watch out for edge cases, particularly overflows and underflows.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
