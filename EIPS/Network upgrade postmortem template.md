---
eip: TBD
title: Ethereum network upgrade retrospective template
author: Pooja Ranjan (@poojaranjan)
discussions-to: TBD
status: Draft
type: Meta
created: 2020-07-20
---

## Abstract

A template for creating network upgrade retrospective a.k.a. upgrade postmortem report. EIPs that follow this template are _informational_.

## Motivation

The purpose of this document is to create a template to standardize the network upgrade retrospective report. This report will be helpful 
* to document the sequence of decisions made that lead to the upgrade,
* to analyze decisions that could have been improvised, and
* to document best practices for future upgrades.
This template aims to standardize retrospective reports that will help future upgrade coordination process, prepare the community for potential process improvements, and recommend to save them in _Informational EIPs_ for references.


## Specification

```
# Upgrade summary 

(Write summary of the upgrade including)

* Date and time (in UTC) 
* Block Number (Mainnet) 
* Synced node (%)
* Winner miner 
* Block Reward
* Uncles Reward 
* Difficulty
* Block number (Ropsten)
* Any other details

# EIPs Included 

(Which EIPs were included and what are the proposed improvements? List new features added to the blockchain and advantages.)

* EIP-1
* EIP-2
* EIP-3
* Meta EIP#

# EIP selection process

(EIP for upgrade selection process eg. Schedule based, EIP Centric etc.)

* EFI/EIP selection highlights
* Describe protocol selection process

# Timeline - Backlog check

(List sequence of events with date)

* Discovery of problem 
* Validation of problem
* Discussion & decision making 
* Implementation

# Best Practices

(List of best practices to be followed in future.)

# Process Evaluation

(Review the timeline and meeting notes to find out if there was any unplanned EIP added at the last minute that could have been planned, or at least moved to the next upgrade?)

# Suggested Corrective Action

(How can we optimize the decision-making process?)

* List of problem and possible suggestions.
```

## Rationale
The aim is to collect relevant information to support the need, process, and deployment of the next network upgrade. While this could be collected in form of an informational EIP, it is highly recommended to capture in an upgrade postmortem report. 

## Test Cases
Not applicable. This is for documentation purpose only.

## Implementation
Reference implementation is available in Muir Glacier upgrade retrospective. 

## Security considerations
No foreseeable security risk associated. This Meta EIP is created as a template for upgrade retrospective report. 

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
