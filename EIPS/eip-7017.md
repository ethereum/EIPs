---
eip: 7017
title: Notification Interface
description: An interface for notifications
author: Oliver Stehr (@Oli-art)
discussions-to: https://ethereum-magicians.org/t/idea-standardized-notifications-in-ethereum-for-a-more-engaging-blockchain/11091
status: Draft
type: Standards Track
category: ERC
created: 2022-11-10
---

## Abstract

The following standard allows addresses / smart contracts to send notifications to specific addresses / broadcast to subscribers.

It achieves it in a trustless and decentralized way and without requiring any on-chain interaction by the receivers.

It requires a front-end implementation where the notifications are listened to, filtered and showed to the end user (address owner).

Some usecases include but are not limited to:

- DAO governance voting anouncement
- DEX informing an address about a certain price limit being reached, for example a stop-loss or a margin-call.
- An NFT marketplace informing an NFT owner about an offer being made to one of it’s NFTs.
- A metaverse informing about an important event.
- Warning to an address about an ENS domain expiration date approaching.

## Motivation

With the adoption of web3 applications, an increasing necessity arises to be informed about certain events happening on-chain.

Users are used to being informed, whether it be about news or updates of their favorite applications. As we are in a time of instant data feeds on social media, instant messaging apps and notifications of events that users care about, notifications are a feature in practically every application that exists in web2. They mostly come to email inboxes, SMSs, inside the applications, or in the notification inbox in the operating system.

If they would be taken away, the engagement on these web2 applications would sink. This is not different with web3 applications: users cannot be left in the dark about what is going on in them. Not only that, for some applications, all that matters is the participation of users on certain events, like governance on a DAO.

In web2, most of the user account’s are linked to an email address that is required at sign-up. This makes it easy to send notifications to specific users and requires no further complexity as an infrastructure exists to deliver a message to the user using their email address.

In web3, on the other hand, there's mostly is only one inbox to send notifications to: addresses.
Every smart contract can define its own event’s to which one can listen to, but for each of them, a change has to be done in the frontend to listen to that specific contract and event structure. This poses a problem of coordination between smart contracts and web3 applications that can notify users.

This EIP aims at proposing a decentralized approach to send and receive notifications from and to ethereum addresses, including smart contracts, in a standarized way, facilitating front-end intrgrations. These could be:

- Wallets
- Mobile phone dapps
- Email services

All of these could be notifying about on-chain notifications to the user.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

An approach that is both simple, decentralized and easy to implement is to use a **notifications smart contract standard** that is **event-based** to be able to emit notifications to one address or broadcast them to anyone that wants to listen. Off-chain **whitelists** would record all addresses a user wants to allow receiving messages from to avoid spam. This is useful for direct messages from one address to another. Off-chain **subscription lists** would indicate which addresses they want to listen for general broadcasts. This is useful for receiving updates on a project.

As a user is not required to record its whitelist and subscription list on-chain, the receiver must not do any transaction.

Every compliant contract must implement the `INotification` interface:

```solidity
pragma solidity ^0.8.7;

interface INotification {
    /// @notice Send a direct message (with subject and body) to an address.
    /// @dev `from` must be equal to either the smart contract address
    /// or msg.sender. `to` must not be the zero address.
    event DirectMsg (address indexed from, address indexed to, string subject, bytes[] body);
  
    /// @notice Broadcast a message (with subject and body) to a general public.
    /// @dev `from` parameter must be equal to either the smart contract address
    /// or msg.sender.
    event BroadcastMsg (address indexed from, string subject, bytes[] body);
  
    /**
    * @dev Send a notification to an address from the address executing the function
    * @param to address to send a notification to
    * @param subject subject of the message to send
    * @param body body of the message to send
    */
    function walletDM(address to, string memory subject, bytes[] memory body) external payable;

    /**
    * @dev Send a notification to an address from the smart contract
    * @param to address to send a notification to
    * @param subject subject of the message to send
    * @param body body of the message to send
    */
    function contractDM(address to, string memory subject, bytes[] memory body) external;
  
    /**
    * @dev Send a general notification from the address executing the function
    * @param subject subject of the message to broadcast
    * @param body body of the message to broadcast
    */
    function walletBroadcast(string memory subject, bytes[] memory body) external payable;

    /**
    * @dev Send a general notification from the address executing the function
    * @param subject subject of the message to broadcast
    * @param body body of the message to broadcast
    */
    function contractBroadcast(string memory subject, bytes[] memory body) external;
}
```

The event's are the message couriers and the functions call the events:

Every `walletBroadcast` and `contractBroadcast` function must implement the `BroadcastMsg` event with `from` set as `msg.sender` and `address(this)` respectively.

Also, every `walletDM` and `contractDM` function must implement the `DirectMsg` event with `from` set as `msg.sender` and `address(this)` respectively.

Here is a table to better represent this:

|          | DirectMessage                                     | Broadcast                                        |
| -------- | ------------------------------------------------- | ------------------------------------------------ |
| Wallet   | emit DirectMsg(msg.sender, to, subject, body);    | emit BroadcastMsg(msg.sender, subject, body);    |
| Contract | emit DirectMsg(address(this), to, subject, body); | emit BroadcastMsg(address(this), subject, body); |

## Rationale

### Why these four functions?

Given that both smart contracts and wallets should be able to send notifications, two different types of functions must exist, as the sender is defined differently.
Then, as there are two different methods of sending notifications, a targeted one or a general one, also two types of functions must exist.
In total, if we want to have all combinations, we must have these four functions, one for evey combination of sender and method.

### Initial Idea

The initial idea was to have one smart contract which would be called to send messages to addresses. Such messages would be stored in inboxes linked to every address.

This was an obvious mistake, as pointed out by the community, as on-chain storage is not neccesary if the messages are not read from within the EVM. All that is needed is for off-chain reading of events. This also eliminated the need for one smart contract to manage all the messages and now every smart contract could implement the interface with the events.

### Why is body in bytes[]

bytes[] allows for broarder possibilities, as not only could a message be sent for a user to read on the screen, but additional data could be sent to create more specific standards. bytes[] allows for better composabilty, as pointed out by the community.

### What about Push Protocol's solution?

Push Protocol could be thought as a solution to all the problems described and is something that is already in use. But there are many points that make it's use problematic. This problems are:

- Despite what they say, their protocol is not really decentralized, as described in their whitepaper. For example, to send a notification, you send a JSON to their API, which they can then pass over to the users that are listening. This is done off-chain and has no way to be verified. There has to be trust in the server running the protocol.
- As described in “subscribing-to-channel” section of their whitepaper, their protocol requires subscribers to do a transaction in order to subscribe or unsubscribe. The lists are stored on-chain, which is something that isn’t necessary, as users could choose who to sisten from by doing a filter in the frontend.
- To ease this problem, they decided to incentivize the subscribers by paying them for subscribing. This is a cost that goes to the entities emitting the messages, as they are required to stake DAI on behalf of the protocol. This is yet another cost to consider.
- Sending and receiving notifications is not only costly, but involves a process that is unnecessarily tied to their servers. The processes involved are uneasy to implement. Sender’s can’t simply send a message from their smart contract at low cost, but they have to go to a DeFi protocol, create an account, stake DAI, develop a way to deliver the message to the protocol, etc. All of this with poor documentation and transparency.
- As described in the governance section of their whitepaper, the protocol is not run by users. All decisions will be made by “the Company”. There is no actual governance mechanism in place.

Some of this problems could be solved, but most of them are in the very architecture of their solution. Because of this, a new solution must be implemented to overcome them.

## Reference Implementation

```solidity
pragma solidity ^0.8.7;

contract Notification is INotification {
    /**
    * @dev Send a notification to an address from the address executing the function
    * @param to address to send a notification to
    * @param subject subject of the message to send
    * @param body body of the message to send
    */
    function walletDM(address to, string memory subject, bytes[] memory body) external payable virtual override {
        emit DirectMsg(msg.sender, to, subject, body);
    }

    /**
    * @dev Send a notification to an address from the smart contract
    * @param to address to send a notification to
    * @param subject subject of the message to send
    * @param body body of the message to send
    */
    function contractDM(address to, string memory subject, bytes[] memory body) external virtual override {
        emit DirectMsg(address(this), to, subject, body);
    }
  
    /**
    * @dev Send a general notification from the address executing the function
    * @param subject subject of the message to broadcast
    * @param body body of the message to broadcast
    */
    function walletBroadcast(string memory subject, bytes[] memory body) external payable virtual override {
        emit BroadcastMsg(msg.sender, subject, body);
    }

    /**
    * @dev Send a general notification from the address executing the function
    * @param subject subject of the message to broadcast
    * @param body body of the message to broadcast
    */
    function contractBroadcast(string memory subject, bytes[] memory body) external virtual override {
        emit BroadcastMsg(address(this), subject, body);
    }
}
```

## Security Considerations

There are security considerations for the proposal regarding threats.

The first is related to how the clients will interpret and filter the events. There can be malicious contracts that implement the notification interface but whose functions emit events where the sender is neither the message sender nor the contract. They could impersonate another address. The clients listening to the events must do an additional check to validate that this is not the case.

Another way to impersonate a sender would be to find a vulnerability in a contract and execute the contractBroadcast() or contractDM() functions to send messages that do not represent the entity behind the contract.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
