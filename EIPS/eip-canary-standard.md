## Preamble

    EIP: 801
    Title: ERC-801 Canary Standard
    Author: ligi<ligi@ligi.de>
    Type: Standard
    Category: ERC
    Status: Draft
    Created: 2017-12-16


## Simple Summary

A standard interface for canary contracts.

## Abstract

The following standard allows the implementation of canaries within contracts.
This standard provides basic functionality to check if a canary is alive, keeping the canary alive and optionally manage feeders.

## Motivation

The canary can e.g. be used as a [warrant canary](https://en.wikipedia.org/wiki/Warrant_canary).
A standard interface allows other applications to easily interface with canaries on Ethereum - e.g. for visualizing the state, automated alarms, applications to feed the canary or contracts (e.g. insurance) that use the state.

## Specification

### Methods

#### isAlive()

Returns if the canary was feed properly to signal e.g. that no warrant was received.

``` js
function isAlive() constant returns (bool alive)
```

#### timeToLive()

The time in seconds that can elapse between feed() calls without starving the canary dead.

``` js
function timeToLive() constant returns (uint256 ttl)
```

#### feed()

Extend the life of the canary by timeToLive() seconds.

**NOTE**: this should trigger the event listed below

``` js
function feed()
```

#### poison()

Kills the canary instantly. E.g. in a urgent case when a warrant was received.

``` js
function poison()
```

#### (optional) addFeeder(address feeder)

Add address that is allowed to feed (and therefore also poison) the canary.

``` js
function addFeeder(address feeder)
```

#### (optional) removeFeeder(address feeder)

Remove address that is allowed to feed the canary.

``` js
function removeFeeder(address feeder)
```

#### (optional) getFeederCount()

Returns the count of addresses that are allowed to feed the canary.

``` js
function getFeederCount() constant returns (int count)
```

#### (optional) getFeederByIndex(unit8 index)

Returns the address of the feeder at the given index.

``` js
function getFeederByIndex(unit8 index) constant returns (address feederAddress)
```

#### (optional) needsAllFeeders()

When true: all feeders need to call feed() in the intervals defined by timeToLive() - analog to a multisig.
When false: all the feeders can extend the lifespan of the canary.

This does not affect poisoning - one feeder is always enough to kill the canary.

``` js
function needsAllFeeders() constant returns (bool needsAllFeeders)
```

### Events

#### Feed

MUST trigger when the canary got food.

``` js
event Feed(address feeder)
```

## Implementation

TODO

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
