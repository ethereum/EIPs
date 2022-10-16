---
eip: <to be assigned>
title: Digital identity Standard
description: How to find own soul within digital address space.
author: Tim Pechersky (@Peersky)
discussions-to: <https://ethereum-magicians.org/t/digital-identity-standard-proposal>
status: Draft
type: Standards Track
category: ERC
created: 2022-06-28
requires (*optional): EIP165, ERC20, eip-2535
---

## Simple Summary

Digital identity in an abstraction layer beyond public address, that is required in order to cryptographic based blockchain technology gain wider adoption.

We are in eager need to make transactions not just from an address to an address but rather to some exact person, organization or institute that is known to use in real world (Identity) without making assumptions on what is their public key / address at given point of time, and assuming that keys and addreesses of that identity might change over time, might get compromised or lost.

That said, a peer-reviewed, well tested standard needs to be used. This EIP aims to be this standard.

Proposal is a new high level abstraction standard, that defines a smart contract code, interfaces and deployment methodology needed to allow anyone to create Digital Identity.
It defines an easy to understand, robust, decentralised way to a high level ownership model as well as means to recover such ownership in case of any attack and enables social recovery mechanisms

## Abstract

Smart contract of registry and factory are deployed on pre-determined address. Anyone interacting with this smart contract is able to create own identitiy instance that consists of a: 1) Soul token: an asset holding which is a proof of identity for any public address that holds it and embedds social recovery mechanisms; 2) digital identity proxy (EIP2535 diamond) that is controlled by soul tokens majority and can act as identities gateway or oracle in to the blockchain; 3) entry in the registry pointing their lookup name to that diamond, allowing human readible name

Soul token is a fungable token that one can not just simply transfer and burn from own wallet, but also burn from any externally wallet at expense of 1:1 burning own soul tokens

<!-- It defines a smart contract that acts as a registry and a factory which for each new identity deploys a smart contract(s) required by this EIP and records them in to the registry. It also defines identity proxy smart contract interface and a novel ownership model that allows to have more secure, trust based approach for ownership management.

to mint a full supply tokens that are being associated with some given identifier at mint time (that can be phone number, passport, email, public key or ethereum account address) and at the same time same factory deploys a EIP2535 Diamond proxy contract with ownership modifier such that execution of methods on that contract are possible only from an address that interacts on behalf of majority of currently circulating tokens supply.

The Digital identity tokens on their side are very similar to ERC20 tokens, with difference that digital identity tokens allow to burn same identity tokens but on another address at the expense of burning same amount of own tokens. Hence multiple wallets can nullify one of the wallet if it stops to represent the identity i.e.  - had been hacked. -->

## Motivation

Private keys cannot be changed without changing public address.

Currently there is no solution present nor developed that is able to solve such riddle. Ongoing discussions on souldbond tokens are esentially relying on same cryptographic structure that stays limited within the boundaries of private key that must be stored secure.

Such standard allows one to have multiple wallets, or even split his identity tokens to family members and his friends, even if one of the addresses that possesses the tokens - one can ask his family and friends, or use his own backup wallets to destroy "corrupted" tokens, and restore control over his identity.

This allows to scale security greatly and nvertheless this security layer easily understandable by non-technical people.

The deployed diamond proxy standard contract on behalf of this identity enables one to lookup known identity by identifier to find that smart contract and be sure that any interaction done to that smart contrat - is indeed interaction to the person.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

### Soul Token

Soul token is a fungable token similar in interface with ERC20, however

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

This standard will be backwards compatible with commonly used ERC20 as well as diamon proxy.

## Test Cases

Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in `../assets/eip-####/`.

## Reference Implementation

WIP

## Security Considerations

All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
