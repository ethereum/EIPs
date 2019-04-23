---
eip: <to be assigned>
title: Formal process of selection of EIPs for hardforks (Meta EIP#) 
author: Pooja Ranjan (@poojaranjan)
discussions-to: https://ethereum-magicians.org/t/proposal-of-a-formal-process-of-selection-of-eips-for-hardforks-meta-eip/3115
status: Draft
type: Meta 
created: 2019-04-09
requires : 233
---


## Abstract

To describe a formal process of selection of EIPs for upcoming hardfork (Meta EIP#).


## Motivation
    
Recently, discussion to streamline the process of protocol upgrades is happening at various forum. In order to move from ad-hoc to fixed-schedule to release protocol upgrades, a process of EIP selection is proposed. 

## Description

This meta EIP provides a general outline process to propose, discuss and track progress of EIPs for upcoming hardfork (Meta EIP#). It recommends to make decision on a hard deadline and suggests to take all other proposals received after the deadline into a subsequent hardfork for a smooth upgrade.

## Specification

A Meta EIP should be created and merged following the process mentioned in [EIP 233](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-233.md).

###  EIP selection process for Meta EIP

**1.  Proposing an EIP**

* If you're an author, and still vetting the idea, please follow guidelines mentioned in [EIP - 1](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-work-flow) to formalise your idea into an EIP.

* Once EIP is created, create a new issue at [ECH repository](https://github.com/ethereum-cat-herders/PM/issues) referring "*EIP# to be considered for next upgrade (Meta EIP#)*" , before the deadline for acceptance of proposals.

* It will be then picked up by the [HF coordinators](https://github.com/ethereum-cat-herders/PM/tree/master/Hard%20Fork%20Planning%20and%20Coordination) (Ethereum Cat Herders) and added as Proposed EIP under EIP tracker eg for [Istanbul](https://github.com/ethereum-cat-herders/PM/blob/master/Hard%20Fork%20Planning%20and%20Coordination/IstanbulHFEIPs.md).

**2. Socializing an EIP**

* Open a discussion thread preferably at EthMagician or publish a blog post for background, need and application of the EIP. Share it on  gitter, reddit and twitter (if need be).

* Invite author to All core dev call to explain / discuss.


**3. Reviewing an EIP**

Author may reach out to [EIP Editors](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-editors) or HF coordinator for help in review the EIP, if not already reviewed. HF coordinator may coordinate with EIP Editors based on the interest / availability.

**4. EIP Readiness Tracker**

EIP Readiness Tracker may be a combination of [EIP tracker](https://github.com/ethereum-cat-herders/PM/blob/master/Hard%20Fork%20Planning%20and%20Coordination/IstanbulHFEIPs.md) and [Client Implementation Progress Tracker](https://github.com/ethereum/pm/wiki/Constantinople-Progress-Tracker). 

| № | EIP  | Description |EIP Status | Client 1| Client 2| Client 3| Client 4 | Testnet | Include in HF / Meta EIP# 
|---| -----|-------------|-----------| ------- | ------- | --------| -------- | --------| ----------------------- |
| 1 |
| 2 |
| 3 |


## Rationale

An EIP readiness tracker for coordinating the hard fork should help in visibility and traceability of the scope of changes to the upcoming hardfork.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).


