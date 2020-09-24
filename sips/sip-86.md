---
sip: 86
title: ExchangeRates Chainlink Aggregator V2V3
status: Implemented
author: Clement Balestrat (@clementbalestrat)

created: 2020-09-02
requires:
---

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->

Updating the ExchangeRates contract to use the ChainLink Aggregator V2V3 Interface.

## Abstract

<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

The current `ExchangeRates` contract uses a deprecated version of Chainlink's aggregator interface to get its prices. This SIP proposes to update `ExchangeRates` to be using a newer version, the [AggregatorV2V3Interface](https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV2V3Interface.sol), which is a hybrid interface including functions from both V2 and V3 interfaces.

## Motivation

<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is inaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

[SIP-79](https://sips.synthetix.io/sips/sip-79) requires `ExchangeRates` to add a new Chainlink aggregator in order to track `fastGasPrice`. This is the first time this contract is using an aggregator to fetch a value which is not related to an asset price. Although it is not mandatory for `ExchangeRates` to track asset rates only, the current implementation may introduce some issues related to how many decimals a value returned by an aggregator contains.
All the current aggregators used by the system return 8 decimals, which are then converted to 18 decimals using a multiplier.
However, `fasGasPrice` aggregator returns a value which is already in WEI (0 decimals), meaning `ExchangeRates` will have to check if whether or not, the value is already in the expected format.

Another issue with using the current Aggregator Interface is the amount of gas needed to update a price. To do so, the `ExchangeRates` contract needs to make two calls to an aggregator in order to get the value and its last update timestamp.

This SIP proposes to update `ExchangeRates` to use `AggregatorV2V3Interface`, which contains a few enhancements that will solve both of the issues explained above.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

### Overview

<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->

The interface proposed by Chainlink provides a `decimals()` function which returns the number of decimals the aggregator response contains. This will be used to determine if a value needs to be formatted with a multiplier or not in the `ExchangeRates` contract.

It also returns all the required data for a price update (value and timestamp) in one single function call, meaning this process will consume a smaller amount of gas.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

Adding new kind of aggregators into `ExchangeRates` such as `fastGasPrice` introduces the necessity of handling multiple data formats. If `BTC/USD` rate contains 8 decimals and `fastGasPrice` none, then we only need to convert the former.

Switching to this new interface will allow `ExchangeRates` to know if an aggregator answer needs to be formatted without the need to hardcode the `currencyKey` directly into the contract. Then, if let's say the `lowGasPrice` aggregator needs to be added in the future, no change and redeployment will be required.

The fact that this interface includes `V2` and `V3` will allow `ExchangeRates` to continue using some functions from the current aggregator which were removed from `V3`, such as `latestRound()`. It will also allow the contract to use the following new functions:

- `decimals()` which indicates what kind of format is expected from an aggregator
- `getRoundData(uint80 _roundId)` to get the aggregator data at a specific round ID
- `latestRoundData()` to get the latest aggregator data

In the `ExchangeRates`, two functions are used to fetch data from an aggregator: `_getRateAndUpdatedTime()` and `_getRateAndTimestampAtRound()`.

They both require two calls to get a price and a timestamp so it can be stored in the contract.

Current `V2` interface doesn't allow these two values to be fetched at the same time, into a single call:

```
function getAnswer(uint256 roundId) external view returns (int256);
function getTimestamp(uint256 roundId) external view returns (uint256);
```

However, the new aggregator simplifies this process by returning the data from a single function, which should decrease the gas cost significantly:

```
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
```

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

This SIP requires the `ExchangeRates` contract to update some of its logic to be compatible with the new interface. It also includes finding a solution to store the number of decimals an aggregator will return to avoid any unnecessary calls while fetching a new price update.

Here is a list of most of the required changes and new implementations:

- New mapping `mapping(bytes32 -> unit8) public currencyKeyDecimals` to store the currency keys and their number of decimals
- `addAggregator()` calling `aggregator.decimals()` and storing the returned value into `currencyKeyDecimals`.
- `removeAggregator()` removing `currencyKey` from the `currencyKeyDecimals` mapping.
- New function `_formatAggregatorAnswer(bytes32 currencyKey, int256 rate)` reading `currencyKeyDecimals` and applying the multiplier on a rate if needed.
- `_getRateAndUpdatedTime()` and `_getRateAndTimestampAtRound()` calling `latestRoundData()` and `getRoundData()` to fetch the new rates from an aggregator, and using `_formatAggregatorAnswer()` to format them.

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Given one aggregator, tracking `BTC/USD` price:

- When owner calls `addAggregator()`
  - `currencyKeyDecimals` mapping now contains `BTC => 8`
- When user calls `rateAndTimestampAtRound()`
  - should return `rate` and `time` in correct formats
- When user calls `rateAndUpdatedTime()`
  - should return `rate` and `time` in correct formats

Given one aggregator, tracking `fasGasPrice` price:

- When owner calls `addAggregator()`
  - `currencyKeyDecimals` mapping now contains `fasGasPrice => 0`
- When user calls `rateAndTimestampAtRound()`
  - should return `rate` and `time` in correct formats
- When user calls `rateAndUpdatedTime()`
  - should return `rate` and `time` in correct formats

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

N/A

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
