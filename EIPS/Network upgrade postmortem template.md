---
eip: TBD
title: Recommendation for creating Ethereum network upgrade analysis/postmortem report
author: Pooja Ranjan 
discussions-to: 
status: Draft
type: Meta
created: 2020-07-20
---

## Simple Summary

Recommendation for creating Ethereum network upgrade analysis report a.k.a. upgrade postmortem report.

## Motivation

The purpose of this document is to create a template to standardize the network upgrade analysis report. This has several advantages:
* the report will describes the chain of events that occurred during the network upgrade process, 
* it will help understand what combination of events created the scenario (successful or not), and 
* how we can make it better for the future. 

This template aims to standardize network upgrade analysis report that will help shape the upgrade coordination and prepare community for potential process improvements and recommend a repository to save them for future references.

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
Muir Glacier postmortem upgrade. 

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
