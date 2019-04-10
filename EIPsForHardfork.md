---
EIP: <to be assigned>
Title: Formal process of selection of EIPs for hardforks (Meta EIP#) 
Author: Pooja Ranjan (@poojaranjan)
Discussions-to: <URL>
Status: WIP
Type: Meta 
Created: 2019-04-09
Requires : EIP 233
---


## Abstract

To describe the formal process of selection of EIPs for upcoming hardforks (Meta EIP#)


## Motivation
    
It may be the time to move from ad-hoc hardfork to fixed-schedule to release protocol upgrades. This EIP provides a general outline process to propose, discuss and track progress of EIPs for MetaEIP for upcoming hard fork. It suggests to make decision on a hard deadline and proposes to take all other proposals accepted after that should go into a subsequent hardfork for a smooth upgrade.


## Specification

A Meta EIP should be created and merged following the process mentioned in [EIP 233](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-233.md).

###  EIP selection process for Meta EIP

**1.  Proposing an EIP**

* If you're an author, and still vetting the idea, please follow guidelines mentioned in [EIP - 1](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md#eip-work-flow) to formalise your idea into an EIP.

* Once EIP is created, submit  a Pull Request at [EIPs repository](https://github.com/ethereum/EIPs/pulls) referring "*EIP# to be considered for next upgrade (Meta EIP#)*" , before the deadline for acceptance of proposals.

* It will be then picked up by the [HF coordinators](https://github.com/ethereum-cat-herders/PM/tree/master/Hard%20Fork%20Planning%20and%20Coordination) (Ethereum Cat Herders) and added as Proposed EIP under EIP tracker eg for [Istanbul](https://github.com/ethereum-cat-herders/PM/blob/master/Hard%20Fork%20Planning%20and%20Coordination/IstanbulHFEIPs.md).

**2. Socializing an EIP**

* Open an Eth Magician thread or publish a blog post for background, need and application of the EIP. Discuss it on  gitter, reddit and Twitter (if need be).

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


