---
sip: 40
title: Time lock on burning after min
status: Proposed
author: Kain Warwick (@kaiynne), Jackson Chan (@jacko125), Clinton Ennis (@hav-noms)
discussions-to: https://discordapp.com/invite/AEdUHzt
created: 2020-02-27
updated: N/A
---
## Simple Summary

Proposal to lock burning for a period after minting to prevent debt burn frontrunning technique.

## Abstract
An SNX staker can mint sUSD continuously until reaching the c-ratio target. Once reached burning will not be possible until the minimumStakeTime has passed.
If a user needs to burn to claim a new function will be available to "burnToTarget" to allow undercollateralized accounts to burn to the taret c-ratio to claim fees.
If an SNX staker wants to burn consecutively to zero they can after the minimumStakeTime has passed.


## Motivation



## Specification



## Rationale



## Test Cases

_To be added_

## Implementation



## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
