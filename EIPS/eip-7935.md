---
eip: 7935
title: Set default gas limit to XX0M
description: Recommend a new gas limit value for Fusaka and update execution layer client default configs
author: Sophia Gold (@sophia-gold), Parithosh Jayanthi (@parithoshj), Toni Wahrstätter (@nerolation), Carl Beekhuizen (@CarlBeek), Ansgar Dietrichs (@adietrichs), Dankrad Feist (@dankrad), Alex Stokes (@ralexstokes), Josh Rudolph (@jrudolph), Giulio Rebuffo (@Giulio2002), Storm Slivkoff (@sslivkoff)
discussions-to: https://ethereum-magicians.org/t/eip-7935-set-default-gas-limit-to-xx0m/23789
status: Draft
type: Informational
created: 2025-04-22
---

## Abstract

<!--TODO: Fill in recommended gas limit-->
The gas limit on mainnet is currently 36M. This should be significantly increased to XX0Mby the time Fusaka is released by execution layer clients updating their default configurations.

## Motivation

There is currently great interest in scaling L1 execution. This can likely be done to some extent without implementing any new features. However, it requires guidance from EL devs as we expect to find bugs in clients at higher gas limits than currently used on mainnet. This will require time from client developers both to test and to fix any bugs that arise, therefore it makes sense to include as an EIP in a hard fork to commit to this.

## Specification

Execution layer clients have different configuration formats. They should all update the gas limit value generated in their default configurations to XX0M.

## Rationale

In the past there has been some difficulty coordinating EL clients to update gas limit values in their default configurations. Therefore we suggest tying a new value to a hard fork release.

## Backwards Compatibility

A higher gas limit should not break any existing contracts. It is possible that with a higher limit new transactions could exceed the proposed 30M transaction gas limit, so the scheduling of these two EIPs should be coordinated.

## Security Considerations

Devnets will be stood up with nodes running all combinations of EL and CL clients in order to test if a gas limit of 60M is safe. Synthetic transactions will be created until blocks are full, and network and node health monitored. If bugs are discovered, client teams will patch them and then start the process again. If everything looks good, the gas limit will be increased incrementally.

Adversarial block constructions that would increase the worst-case size have already been researched and should not be a factor below 150M gas because this is close to where the current worst-case block size of 1.79 MiB would reach the current 10MiB CL gossip limit.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
