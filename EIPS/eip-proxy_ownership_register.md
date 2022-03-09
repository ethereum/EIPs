---
eip: <to be assigned>
title: Proxy Ownership Register
description: A proxy ownership register allowing trustless proof of ownership between ethereum addresses, with delegated asset delivery
author: Omnus Sunmo (@omnus)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2022-09-03
---


## Abstract

A proxy protocol that allows users to nominate a proxy address to act on behalf of another wallet address, together with a delivery address for new assets. Smart contracts and applications making use of the protocol can take a proxy address and lookup holding information for the nominator address. This has a number of practical applications, including allowing users to store valuable assets safely in a cold wallet and interact with smart contracts using a proxy contract of low value. The assets in the nominator are protected as all contract interactions take place with the proxy contract. This eliminates a number of exploits seen recently where user's assets are drained through a malicious contract interaction. In addition, the register holds a delivery address, allowing new assets to be delivered directly to a cold wallet address.

## Motivation

To make full use of ethereum users often need to prove their ownership of existing assets. For example:
 * Discord communities require users to sign a message with their wallet to prove they hold the tokens or NFTs of that community.
 * Whitelist events (for example recent airdrops, or NFT mints), require the user to interact using a given address to prove eligibility.
 * Voting in DAOs and other protocols require the user to sign using the address that holds the relevant assets.

 There are more examples, with the unifying theme being that the user must make use of the address with the assets to derive the platform benefit. This means the addresses holding these assets cannot be truly 'cold', and is a gift to malicious developers seeking to steal valuable assets. For example, a new project can offer free NFTs to holders of an existing NFT asset. The existing holders have to prove ownership by minting from the wallet with the asset that determined eligibility. This presents numerous possible attack vectors for a malicious developer who knows that all users interacting with the contract have an asset of that type.

 Possibly even more damaging is the effect on user confidence across the whole ecosystem. Users become reluctant to interact with apps and smart contracts for fear of putting their assets at risk. They may also decide not to store assets in cold wallet addresses as they need to prove they own them on a regular basis. A pertinent example is the user trying to decide whether to 'vault' their NFT and lose access to a discord channel, or keep their NFT in another wallet, or even to connect their 'vault' to discord.

 Ethereum is amazing at providing trustless proofs. I believe that the *only* time you should need to interact using the wallet that holds an asset is if you intend to sell that asset. If you merely wish to prove ownership (to access a resource, or get an airdrop, mint an NFT, or vote in a DAO), you should do this through a trustless proof stored on-chain.

 Furthermore, you should be able to decide where new assets are delivered, rather than them being delivered to the wallet providing the interaction. This allows hot wallets to acquire assets sent directly to a cold wallet 'vault', possibly even the one they are representing in terms of asset ownership.

 The aim of this EIP is to provide a convenient method to avoid this security concern and empower more people to feel confident leveraging the full scope of ethereum functionality.

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

There are two main parts to the register - a nomination and a proxy record:

    Contract / Dapp                        Register

    Nominator: 0x1234..             Nominator: 0x1234..
    Proxy: 0x5678..     --------->  Proxy: 0x4567..
                                    Delivery: 0x9876..

The first step to creating a proxy record is for an address to nominate another address as its proxy. This creates a nomination that maps the nominator (the address making the nomination) to the proposed proxy address. 

This is not a proxy record on the register at this stage, as the proxy address needs to first accept the nomination. Until the nomination is accepted it can be considered to be pending. Once the proxy address has accepted the nomination a proxy record is added to the register.

When accepting a nomination the proxy address sets the delivery address for that proxy record. The proxy address remains in control of updating that delivery address as required. Both the nominator and proxy can delete the proxy record and nomination at any time. The proxy will continue forever if not deleted - it is eternal.

The register is a single smart contract that stores all nomination and register records. The information held for each is as follows:
 * Nomination:
    * The address of the Nominator
    * The address of the Proposed Proxy

* Proxy Record:
    * The address of the Nominator
    * The address of the Proxy
    * The delivery address for proxied deliveries

Any address can act as a Nominator or a Proxy. A Nomination must have been made first in order for an address to accept acting as a Proxy. 

A Nomination cannot be made to an address that is already active as either a Proxy or a Nominator, i.e. that address is already in an active proxy relationship.

The information for both Nominations and Proxy records is held as a mapping. For the Nomination this is address => address for the Nominator to the Proxy address. For the Proxy Record the mapping is from address => struct for the Proxy Address to a struct containing the Nominator and Delivery address.

Mapping between an address and its Nominator and Delivery address is a simple process as shown below:

    Contract / Dapp                        Register

      |                                       |
      |------------- 0x4567..---------------> |
      |                                       |
      | <-------nominator: 0x1234..---------- |
      |         delivery: 0x9876..            |
      |                                       |

The protocol is fully backwards compatible. If it is passed an address that does not have an active mapping it will pass back the received address as both the Nominator and Delivery address, thereby preserving functionality as the address is acting on its own behalf.

    Contract / Dapp                        Register

      |                                       |
      |------------- 0x0222..---------------> |
      |                                       |
      | <-------nominator: 0x0222..---------- |
      |         delivery: 0x0222..            |
      |                                       |

If the EPS register is passed the address of a Nominator it will revert. This is of vital importance. The purpose of the proxy is that the Proxy address is operating on behalf of the Nominator. The Proxy address therefore can derive the same benefits as the Nominator (for example discord roles based on the Nominator's holdings, or mint NFTs that require another NFT to be held). It is therefore imperative that the Nominator in an active proxy cannot also interact and derive these benefits, otherwise two addresses represent the same holding. A Nominator can of course delete the Proxy Record at any time and interact on it's own behalf, with the Proxy address instantly losing any benefits associated with the proxy relationship.

Full technical information is at https://docs.epsproxy.com/. 

## Rationale

The rationale for this design was to provide an easy and convenient way to prove ownership of assets while putting those assets at absolutely zero risk of loss. The motivation was seeing a number of attacks making use of the fact that users need to interact with a wallet holding assets in order to derive benefits of that asset ownership.

In addition to the loss of user's assets it is clear that these events damage confidence in the community in general. Users make decisions based on both actual and perceived risk, and it presents a barrier for new users accessing and using ethereum.

My vision is an ethereum where users setup a new hardware wallet for assets they wish to hold long-term, then make one single contract interaction with that wallet: to nominate a hot wallet proxy. That user can always prove they own assets on that address, and they can specify it as a delivery address for new asset delivery.

## Backwards Compatibility

The eip is fully backwards compatible.

## Test Cases

The full SDLC for this proposal has been completed and it is operation at 0xfa3D2d059E9c0d348dB185B32581ded8E8243924 on mainnet, ropsten and rinkeby. The contract source code is validated and available on etherscan. The full unit test suite is available in `../assets/eip-proxy_ownership_register/`, as is the source code and example implementaitons.

## Reference Implementation

The register is deployed at 0xfa3D2d059E9c0d348dB185B32581ded8E8243924 on mainnet, ropsten and rinkeby. The UI is available as follows:
* Mainnet: https://app.epsproxy.com/
* Ropsten: https://app-ropsten.epsproxy.com/
* Rinkeby: https://app-rinkeby.epsproxy.com/


## Security Considerations

The core intention of the eip is to improve user security by better safeguarding assets and allowing greater use of cold wallet storage. 

I've considered potential negative security implications and cannot envisage any. The proxy record can only become operational when a nomination has been confirmed by a proxy address, both addresses therefore having provided signed proof. 

From a usability perspective the key risk is in users specifying the incorrect asset delivery address, though it is noted that this burden of accuracy is no different to that currently on the network.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
