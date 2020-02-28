---
sip: 40
title: Time lock on burning after min
status: Proposed
author: Kain Warwick (@kaiynne), Jackson Chan (@jacko125), Clinton Ennis (@hav-noms), Garth Travers (@garthtravers)
discussions-to: https://discordapp.com/invite/AEdUHzt
created: 2020-02-27
updated: N/A
---
## Simple Summary

Proposal to lock burning for a period after minting to prevent debt burn frontrunning technique.

## Abstract
An SNX staker can mint sUSD continuously until reaching the C-Ratio target. Once reached burning will not be possible until the minimumStakeTime has passed.
If a user needs to burn to claim a new function will be available to "burnToTarget" to allow undercollateralized accounts to burn to the taret C-Ratio to claim fees.
If an SNX staker wants to burn consecutively to zero they can after the minimumStakeTime has passed.

## Motivation

A wallet has just recently started executing this exploit since the launch of fee reclamation. If it goes unresolved, this issue could lead to further debt for SNX stakers. Closing this loophole protects SNX stakers. 

## Specification
- New EternalStorage Contract for Issuer
  - Stores "LAST_ISSUE_EVENT" with timestamp of minters last mint event
- Issuer Configuration
  - minimumStakeTime: Minimum time required to be staked. So after minting this period must pass before burning above target c-ration will be allowed. Default 8 Hours. 
- Issuer new function
  - burnSynthsToTarget(): Helper function so anyone can burn Synths to the target c-ratio to be able to claim fees and rewards. 


## Rationale

This solution has the fewest trade-offs of the available solutions, as it still allows stakers to burn to claim rewards. 

## Test Cases



## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
