---
eip: <to be assigned>
title: Poisoning the Well
author: David Stanfill <david@airsquirrels.com> 
discussions-to: <email address>
status: Draft
type: Standards Track
category Core
created: 2018-04-03
---


## Simple Summary

This EIP attempts to break ASIC miners specialized for the current ethash
mining algorithm.


## Abstract

There are companies who currently have dedicated hardware based ethereum miners in
production, and probabalistically actively mining.  This EIP aims to "Poison
the well" by modifying the block mining algorithm in a manner that
probabalistically *"breaks"* these miners if they are in-fact built on ASICs.


## Motivation

ASIC based miners will have lower operational costs than GPU based miners which
will result in GPU based mining quickly becoming unprofitable.  Given that
production of ASIC based miners has a high barrier to entry, this will cause a
trend towards centralization of mining power.

This trend towards centralization has a negative effect on network security,
putting significant control of the network in the hands of only a few entities.

Furthermore, Ethereum was initially designed as an ASIC resistant algorithm and 
the community has voiced strong support for making a definitive stand on our position
regarding dedicated mining hardware development to discourage future R&D investments.

## Specification

If `block.number >= ASIC_MITIGATION_FORK_BLKNUM`, require that the ethash solution 
sealing the block has been mined using `ethashV2`.

## EthashV2

`ethashV2` will be identical in specification to the current `ethash`(v1) algorithm, with
the exception of the implementation of `fnv`. 

The new algorithm replaces the 5 current uses of `fnv` inside `hashimoto` with 5 
seperate instances defined as `fnvA`, `fnvB`, `fnvC`, `fnvD`, and `fnvE`, utilizing 

`FNV_PRIME_A=0x10001a7`  
`FNV_PRIME_B=0x10001ab`  
`FNV_PRIME_C=0x10001cf`  
`FNV_PRIME_D=0x10001e3`  
`FNV_PRIME_E=0x10001f9`  


`fnvA` replaces `fnv` in the DAG item selection step
`fnvB` replaces `fnv` in the DAG item mix step
`fnvC(fnvD(fnvE` replaces `fnv(fnv(fnv(` in the compress mix step

`fnv` as utilized in DAG-item creation should remain unchanged.

## Node Changes

A new field of `EthashVersion` defined as an 8 bit unsigned enumeration is added to 
the the block header. If this field is absent, its value is assumed to be equal to
 zero.

The enumeration should be forward compatible and defined as:
`EthashUndefined = 0x00  
EthashVersion1 = 0x01  
EthashVersion2 = 0x02  
...  
EthashVersion255 = 0xFF`

When this field is present and set to 0x02, the `mine` and `VerifySeal` operations
utilize the `ethashV2` algorithm. If this field is set to any value other than 0x01,
0x02, or 0x00 `VerifySeal` shall reject the block.

`VerifySeal` shall also fail verification in the event 
`block.Number >= ASIC_MITIGATION_FORK_BLKNUM && block.EthashVersion < EthashVersion2`

## Agent Changes
 
GetWork may optionally return the proposed blocks `EthashVersion` field. While a 
miner or pool may infer the requirement for ethashV2 based on the computed 
epoch of the provided seedHash, it may be beneficial to explicitly provide this
field so a miner does not require special configuration when mining on a chain
that chooses not to implement the ASIC_Mitigation hardfork.

Due to compatibility concerns with implementations that already add additional 
parameters to GetWork, it may be desired to define a 33 Byte BlockHeader, where
the first octet represents the EthashVersion enumeration value required for the 
block. If this octet is not present, it may be assumed to be zero.
  
## Rationale

This EIP is aimed at breaking existing ASIC based miners via small changes to the
existing ethash algorithm.  We hope to accomplish the following:

1. Break existing ASIC based miners.
2. Demonstrate a willingness to fork in the event of future ASIC miner production.

Goal #1 is something that we can only do probabalistically without detailed
knowledge of existing ASIC miner design.  Our approach should balance the
inherent security risks involved with changing the mining algorithm with the
risk that the change we make does not break existing ASIC miners.  This EIP
leans towards minimizing the security risks by making minimal changes to the
algorithm accepting the risk that the change may not break dedicated hardware 
miners that utilize partially or fully configurable logic. 

Furthermore, we do not wish to introduce significant algorithm changes that
may alter the power utilization or performance profile of existing GPU hardware.

The change of FNV constant is a minimal change that can be quickly
implemented across the various network node and miner implementations.

It is proposed that `ASIC_MITIGATION_FORK_BLKNUM` be no more than 5550000 (epoch 185), giving
around 30 days of notice to node and miner developers and a sufficient window
for formal analysis of the changes by experts. We must weigh this window against
the risk introduced by allowing ASICs to continue to probalistically propagate
on the network, as well as the risk of providing too much advanced warning to 
ASIC developers. 

It is further understood that this change will not prevent redesign of existing
dedicated hardware with new ASIC chips. The intention of this change is only
to disable currently active or mid-production hardware and provide time for
POS development as well as larger algorithim changes to be well analyzed by 
experts.

The choice of FNV constants is made based on the formal specification at
https://tools.ietf.org/html/draft-eastlake-fnv-14#section-2.1

Typical ASIC synthesis tools would optimize multiplication of a constant
in the FNV algorithm, reducing the area needed for the multiplier according
to the hamming weight of the constant. To reduce the chance of ASIC adaptation
through minor mask changes, we propose choosing new constants with a larger
hamming weight, however care should be taken not to choose constants with too
large of weight.

The current FNV prime, 0x1000193 has a hamming weight of 6.   
`HammingWeight(0x10001a7) = 7;`  
`HammingWeight(0x10001ab) = 7;`    
`HammingWeight(0x10001cf) = 8;`    
`HammingWeight(0x10001e3) = 7;`    
`HammingWeight(0x10001ef) = 9; // Not chosen`   
`HammingWeight(0x10001f9) = 8;`  
`HammingWeight(0x10001fb) = 9; // Not chosen`

An exhaustive analysis was done regarding the dispersion of these constants as compared to 0x01000193.

It can be empirically confirmed that no more than 1 duplicates occur in the 32 bit word space with these constants. 

It is worth noting that FNV is not a cryptographic hash, and it is not used as such in ethash. With 
that said, a more invasive hash algorithm change could consider other options. One suggestion has been 
MurmorHash3 (https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp)

## Backwards Compatibility

This change implements a backwards incompatable change to proof of work based
block mining.  All existing miners will be required to update to clients which
implement this new algorithm, and all nodes will require updates to accept
solutions from the new proof of work algorithm.

## Test Cases

TODO: will need to generate test cases for `ethereum/tests` repository corresponding to the consensus 
changes.

## Implementation

TODO

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
