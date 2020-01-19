---
eip: <to be assigned>
title: Abstract Gas Market 
author: Ricardo Guilherme Schmidt (@3esmit)
discussions-to: https://ethresear.ch/t/pos-and-economic-abstraction-stakers-would-be-able-to-accept-gas-price-in-any-erc20-token/721
status: Draft
type: Standards Track 
category: Core
created: 2020-01-19
requires: 1077
---

## Simple Summary

Allow block validators to include account contract's gas abstract transactions. 

Softfork miners to accept other tokens as gas through [ERC-1077] meta-transactions. 

## Abstract

[ERC-1077] allows for users agreeing with gas relayers, but also for agreeing with next `block.coinbase`, this proposal suggests that the gas market, currently only in ether, becomes abstracted by allowing the validators of listening directly for those type of transactions.

## Motivation

There are ongoing efforts in creating parallel gas markets, while this should ideally be solved at root through the validators. With PoS, staking ETH would allow rewards in any ERC20 token staker chooses to accept.

## Specification

Block validators should listen to messages in the [ERC-1077] format with `_gasRelayer` set as `address(0)`, and while forging a block, test their event outcomes to see if it's valid within custom configs (min gas prices in USD).
Valid meta transactions should be included early as transactions from any address (`msg.sender` is not used) with gas price zero.
A separated whisper channel would be made for every different token, including ether as meta transaction. 
Validators choose the tokens they accept and a minimal value in USD for all of them. 

## Rationale

This change would become an effective way of creating an abstract gas market in top of ether, however with mining pools this will not have too much network effects. The network effects would be more evident as proof of stake would remove the need of mining pools. 

## Backwards Compatibility

Regular transactions are not affected. This provides additional feature that won't affect other parts of the system.

## Test Cases

TBD 

## Implementation

TBD

## Security Considerations

TBD

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

[ERC-1077]: https://eips.ethereum.org/EIPS/eip-1077