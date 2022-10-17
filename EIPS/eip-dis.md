---
eip: <to be assigned>
title: Digital identity
description: How to find own soul within digital address space.
author: Tim Pechersky (@Peersky)
discussions-to: https://ethereum-magicians.org/t/digital-identity-standard-proposal
status: Draft
type: Standards Track
category: ERC
created: 2022-06-28
requires: 165, 20, 2535
---

## Abstract

Digital identity in an abstraction layer beyond public address, that is required in order to cryptographic based blockchain technology gain wider adoption.

Proposal is a new high level abstraction standard, that defines a smart contract code, interfaces and deployment methodology needed to allow anyone to create token based Digital Identity.
It defines an easy to understand, robust, decentralised way to a high level ownership model as well as means to recover such ownership in case of any attack and enables social recovery mechanisms

Standard enables new mechanics, where one can split identity tokens to family members and his friends or multiple own wallets. And in case of any loss of control over private key - one can ask his family and friends, or use his own backup wallets to destroy "corrupted" tokens, and restore control over his identity.

## Motivation

We are in eager need to make transactions not just from an address to an address but rather to some exact person, organization or institute that is known to use in real world (Identity) without making assumptions on what is their public key / address at given point of time, and assuming that keys and addreesses of that identity might change over time, might get compromised or lost.

That said, a peer-reviewed, well tested standard needs to be used. This EIP aims to be this standard.

This allows to scale security greatly and nevertheless this security layer easily understandable by non-technical people.

The deployed diamond proxy standard contract on behalf of this identity enables one to lookup known identity by identifier to find that smart contract and be sure that any interaction done to that smart contrat - is indeed interaction to the person.

Some examples of desired scenarios that this EIP aims to implement as social recovery and trust mechanisms:

1.

```
Bob has his Identity tokens split in two accounts: BobColdWallet1 (30%), BobColdWallet2 (30%), BobHotWallet1 (20%), BobsParents(20%)

In case if Bob's hot wallet gets compromised, Bob even without requiring an access to cold wallet, can restore control over lost 20% of his identity by asking parents to do mutual burn over BobHotWallet1.

After BobParents execute such transaction token total supply share will change to BobColdWallet1 (50%), BobColdWallet2 (50%), BobHotWallet1 (0%), BobsParents(0%)
```

2.

```
Bob has his Identity tokens split in Four accounts: Bob1 (33%), Bob2 (33%), Papa (17%), Mama (17%).

Once Bob discovers that his wallet Bob2 was compromised, and tokens were moved to another address he has no control over. Bob can call or phisycally talk to his parents so they sign reissuance and send signed transactions to Bob.

After that Bob can execute reissuence method on the token, which will move the memory slot and reissue tokens.
New token allocation will be: Bob1 (~49.25%), Bob2 (0%), Papa (~25.37%), Mama (~25.37%)
```

3.

```
Bob has his Identity tokens split in two accounts: BobColdWallet1 (30%), BobColdWallet2 (30%), BobHotWallet1 (20%), BobsParents(20%).

Bob Wants to give some kind of level of permissions to act on his behalf to his friend, Georg.

Bob can delegate to Georg to act on behalf of 5% of total tokens circulating (from any if his accounts) and Bob can either program in to smart contracts, webhooks or manually follow the Georg actions and build an algorithms that either decrese or increase tokens delegated to Georg based on Georgs actions.

That way Georg and Bob build a public trust model showing how much Bob trusts Georg and vice versa
```

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

### Overview

Smart contract of registry and factory are deployed on pre-determined address. Anyone interacting with this smart contract is able to create own identitiy instance that consists of a: 1) Soul token: an asset holding which is a proof of identity for any public address that holds it and embedds social recovery mechanisms; 2) digital identity proxy (EIP-2535 diamond) that is controlled by soul token holders majority and can act as identities gateway or oracle in to the blockchain; 3) entry in the registry pointing their lookup name to that diamond, allowing human readible name

### Soul Token

Soul token is a fungable token that is very similar to conventional EIP-20 with three four new properties:

1. Anyone can burn anyones tokens by burning same amount of own tokens.
2. Methods exist that allow to read amount of tokens particular address has rights to act on behalf of.
3. Tokens can be delegated to someone giving them right to act on behalf of their weight, however does not give rights to transfer nor burn delegated tokens
4. One having their balance plus delegated amount of tokens as majority can "restart" the token issuance, by moving memory slot that contains balances to another and re-minting whole max supply back only to addresses that are participating in the execution or whitelisted. Effectively this removes anyone who is not in the transaction from holding the tokens.

```solidity
interface ISoulToken is ERC20
{
    //Creates new token and mints it to a given addresses
    constructor(address[] to, uint256[] amount);

    //Returns current amount of tokens in circulation
    function getCurrentSupply() public view returns (uint256);

    //Destroys amount of tokens at destination and a equal amount at senders waller
    function purge(address destination, uint256 amount) public;

    //Proves identity amount of an address, returns amount of tokens owned and delegted to
    function identityAmount(address of) public view returns (uint256);

    //identity level of an address, returns identityAmount(address)/getCurrentSupply();
    function identityLevel(address of) public view returns (uint256);

    //Delegates amount of tokens to a some address. Delegated tokens can be used to prove identity level, cannot be transfered nor burned
    delegate(address to, uint256 amount);

    //Changes memory slot where token amounts where mapped, and reconstructs token with issuing max cap in proportions of amounts that signers held before
    //Signers must have majority of circulating tokens to execute this.
    //This is emegrency recovery method that will make anyone who was not in the signers nor in the whitelist to lose their tokens.
    function Restart(address signers[], uint256 signerDeadlines[], address whiteslist[]) public;

}
```

```solidity
interface DigitalIdentityStandard
{
    //Creates new identity with a name as a lookup in registry and mints amounts of sould tokens to holders
    function newIdentity(bytes32 name, addresses[] holders, uint256[] amounts);

    //Returns diamond proxy address associated with the identity as first value and soul token address as second value
    function resolve(bytes32 name) public view returns (address, address);

}
```

## Rationale

TODO

### Dimond vs other types of proxies

    So far diamond proxy seems most versatile and it can be a great entry point to implementation. The only modification over standard diamond needed is to implement the ownership model that must use majorty of soul tokens

### using bytes32 vs strings

    Bytes32 are limiting the namespace size, however are easier to process

## Backwards Compatibility

This standard will be backwards compatible with commonly used EIP-20 as well as diamon proxy.

## Test Cases

Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation

WIP

## Security Considerations

All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
