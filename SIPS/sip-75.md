---
sip: 75
title: Keeper Synths - Phase 1
status: Proposed
author: Kain Warwick (@kaiynne), Justin J Moses (@justinjmoses)
discussions-to: https://discord.gg/kPPKsPb

created: 2020-07-20
---

## Simple Summary

The current version of the iSynths (inverse price Synths) have price limits to protect the network, when these price limits are hit the Synth is frozen. [SIP-61](./sip-61/md) covers the roadmap for Keeper Synths. Phase 1 of the system will be allowing a public function to freeze iSynths.

## Abstract

This SIP will change the iSynths purge and update pricing functions to be public and incentivised. The first address to call freezeSynth will be paid SNX as an incentive.

## Motivation

The reason the price bands are required is that if the price of the underlying Synth doubles the price of the iSynth will go to 0. As the price of the iSynth tends to 0 the amount of leverage increases. For example if an ETH iSynth was instantiated at $200 and ETH went to $399 then the iSynth would go to $1, so you would get $1 of price movement for each $1 spent on iETH versus $1 of price movement for every \$400 spent on sETH. This property reverses in the other direction such that as the price of ETH drops you must buy significantly more iETH to get the same level of price movement as sETH.

This leverage neccesitates tight price bands and increasing or removing them would add significant risk to the network. The solution proposed in this SIP therefore leaves the bands as is and instead improves the freezing process by incentivising anyone to call public functions to manage iSynth freezing.

## Specification

# Overview

Phase 1 of the Keeper synths will be creating a public function to freezeSynths.

1. FreezeSynth

FreezeSynth - Currently the oracle is responsible for freezing the iSynth when the price limits are hit, as an aside this is also problematic for our transition to chainlink as the CL oracles do not have the ability to call FreezeSynth based on a price limit being hit. Rather than relying on a centralised service to freeze iSynths we will instead make this a public function any address can call. This function will require that the current price of the underlying Synth is outside the defined price bands. If it is the synth will be frozen, if not the call will fail.

The fee in SNX for freezing an iSynth will initially be set to 20 SNX. This fee is deliberately set high to ensure there are sufficient incentives to ensure competition to quickly freeze iSynths.

For Phase 1, the address that calls FreezeSynth successfully will be emitted as part of the `InversePriceFrozen()` event. The protocol DAO will reimburse the address that calls the function manually.

# Rationale

Moving to Chainlink oracles means that iSynths prices won't be frozen on `ExchangeRates.updateRates()` and would require a keeper to freeze them when the price is at the upper or lower bounds.

Until the generalised keeper system is implemented, when a keeper calls `ExchangeRates.freezeRate()`, if the iSynth is frozen, the `msg.sender` will be emitted for manual payment of the reward. This should be updated when the generalised keeper system is implemented.

# Technical Specification

<!--The technical specification should describe the syntax and semantics of any new feature.-->

The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.

**Interface**

```
pragma solidity >=0.4.24;

interface IExchangeRates {
    // Views
    function canFreezeRate(bytes32 currencKey) external view returns (bool);

    // Mutative Functions
    function freezeRate(bytes32 currencyKey) external;

    // Struct
    struct InversePricing {
        uint entryPoint;
        uint upperLimit;
        uint lowerLimit;
        bool frozenUpperLimit;
        bool frozenLowerLimit;
    }
}
```

`freezeSynth()` will check the current exchange rate for the Synth being frozen from the `ExchangeRates` contract (whether it is from Chainlink oracles or being updated from Synthetix oracle) to determine if the inverse synth is able to be frozen.

InversePricing will require two new fields, `frozenUpperLimit` and `frozenLowerLimit` to record at which bound the inverse synth was frozen at.

# Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

Given iETH on `ExchangeRates` is above the upper limit

- When a user calls `ExchangeRates.freezeRate(iETH)`
  - iETH is frozen at the upper limit
  - `msg.sender` is emitted as the address who froze the iSynth
  - The `InversePricing.frozenUpperLimit` is set to true

Given iETH on `ExchangeRates` is below the lower limit

- When a user calls `ExchangeRates.freezeRate(iETH)`
  - iETH is frozen at the lower limit
  - `msg.sender` is emitted as the address who froze the iSynth
  - The `InversePricing.frozenLowerLimit` is set to true

Given iETH on `ExchangeRates` is below the upper limit and above the lower limit

- When a user calls `ExchangeRates.freezeRate(iETH)`
  - It should revert.

## Configurable Values (Via SCCP)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
