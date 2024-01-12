---
title: PeerDAS - Peer Data Availability Sampling

description: Introducing simple DAS utilizing gossip distribution and peer requests
author: Danny Ryan (@djrtwo), Dankrad Feist (@dankrad), Francesco D'Amato (@fradamt), Hsiao-Wei Wang (@hwwhww)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Networking
created: 2024-01-12
requires: 4844
---

## Abstract

PeerDAS (Peer Data Availability Sampling) is a networking protocol that allows beacon nodes to perform data availability sampling (DAS) to ensure that blob data has been made available while downloading only a subset of the data. PeerDAS utilizes gossip for distribution, discovery for finding peers of particular data custody, and peer requests for sampling.

## Motivation
    
DAS is a method of scaling data availability beyond the levels of EIP-4844 by not requiring all nodes to download all data while still ensuring that all of the data has been made available.
    
Providing additional data availability helps bring scale to Ethereum users in the context of layer 2 systems called "roll-ups" whose dominant bottleneck is layer 1 data availability.

## Specification
  
We extend the blobs introduced in EIP-4844 using a one-dimensional erasure coding extension. Each row consists of the blob data combined with its erasure code. It is subdivided into cells, which are the smallest units that can be authenticated with their KZG commitments. Each column, associated with a specific gossip subnet, consists of the cells from all rows for a specific index. Each node is responsible for maintaining and custodying a deterministic set of column subnets and data as a function of their node ID.

Nodes find and maintain a diverse peer set and sample columns from their peers to perform DAS.

A node can reconstruct the entire data matrix if it acquires over 50% of all the columns. If a node has less than 50%, it can request the necessary columns from the peer nodes.

The detailed specifications are on [ethereum/consensus-specs](TBD).

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

## Rationale

TBD

## Backwards Compatibility

## Test Cases

## Reference Implementation

## Security Considerations

Needs discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
