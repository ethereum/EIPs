---
sip: to be assigned
title: Inflation Smoothing
status: Proposed
author: Deltatigernz, FrameworkVance
discussions-to: governance

created: 2019-09-24
---

## Simple Summary

This SIP gradually decreases SNX inflation by 1.4% per week starting on November 15th, 2019. In accordance with this SIP, on June 22nd, 2022 inflation will 
cease being determined by this schedule and moved to a fixed volume inflation model (100K SNX per week), which is being a written up in a separate SIP.

## Abstract

* SNX's current inflation schedule started on March 13, 2019.
* SNX's current inflation schedule issues 1.44M SNX per week, and halves weekly rewards every 52 weeks for 260 weeks. 
* Smoothing (gradually decreasing vs. abruptly halvening) this inflation schedule decreases the potential risk that an inflation halvening poses.  
* Smoothing the inflation schedule immediately allows for a more gradual inflation decline while adhering to the original protocol target of ~245M total tokens

## Motivation

After 6 months of gathering data on current inflation rates and assessing the community's sentiment in regards to future inflation halvening, the community's consensus is that
the inflation halvening presents an easily avoidable risk that we can address through a gradually decreased inflation curve starting as soon as possible. 

## Specification

* Starting on November 15th, 2019, SNX inflation decreases by 1.4% per week. 
* On June 22nd, 2022, after 188 weeks of smoothing, SNX inflation will transition to a 100K SNX per week inflation schedule. 

## Rationale

An abrupt inflation halvening could lead to:

* minters packing up at the same time
* synth supply shrinking
* SNX unlocking to be sold down
* SNX price dropping
* sETH LPs getting their income halved and also now dropping in value
* sETH LPs exiting by withdrawing and converting sETH to ETH
* sETH getting smashed out of peg
* arb pool being unattractive as SNX drops relative to ETH

## Test Cases

N/A

## Implementation

[Model](https://docs.google.com/spreadsheets/d/1Y8rOoJrPhCRuH7zaIo5oYWzXsy1zq0rRgCTo0AqD4Rs/edit#gid=1640166717)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
