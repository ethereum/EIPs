---
title: RowDAS - Distributed Blobspace Reconstruction
description: Distribute reconstruction load in the network through row-level cell messaging.
author: Csaba Kiraly (@cskiraly), TBD (@tbd)
discussions-to: URL
status: Draft
type: Standards Track
category: Networking # Only required for Standards Track. Otherwise, remove this field.
created: 2026-08-05
requires: 7594, 8136 # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

## Abstract

PeerDAS requires supernodes to provide reconstruction, and at the same time it puts a high burden on supernodes that scales linearly with blobcount. RowDAS enables distributed blobspace reconstruction using partial message based row topics, allowing all nodes to contribute to reconstruction, while significantly reducing the load on supernodes, leading to a more efficient and more resilient DAS construct.

## Motivation

EIP-7594 PeerDAS was designed with a simple but powerful-enough erasure coding based reconstruction model where any node receiving at least half of the 128 columns should reconstruct the whole extended blob content belonging to a block. As the number of blobs grow, however, the reconstruction burden on every supernode also grows linearly with blob count.

Moreover, supernodes execute largely redundant work: each one of them reconstructing all missing blobs, without the means to distribute this work efficiently in the network.

This EIP introduces distributed blobspace reconstruction, where different nodes prioritize the reconstruction of different parts of the blobspace, leading to a faster, less-cpu intensive, and more resilient construct.

## Specification

The EIP introduces new GossipSub topics, changes to the rules of reconstruction, and a few minor changes to how current column topics operate.

### Column topics

Regarding column topics EIP-7594 already mandates the following:

> Once the node obtains a column through reconstruction, the node MUST expose the new column as if it had received it over the network. If the node is subscribed to the subnet corresponding to the column, it MUST send the reconstructed DataColumnSidecar to its topic mesh neighbors. If instead the node is not subscribed to the corresponding subnet, it SHOULD still expose the availability of the DataColumnSidecar as part of the gossip emission process.

This is extended to allow cell-level operation towards peers that support it using the following rules:

- Prior to reconstructing, a node MAY also use the Gossipsub “fanout” mechanism to request relevant cells from other peers across column subnets it is not subscribed to.

- After reconstruction, a node SHOULD use the Gossipsub “fanout” mechanism to provide cells from the reconstructed blob to peers across column subnets it is not subscribed to. A node MAY choose to only advertise to a random subset of these columns rather than all columns. This allows the node to provide another path for cell dissemination to the network. A node MAY choose to delay these fanout messages for a bit, in order to conserve bandwidth by not competing with other nodes who are subscribed to the column topic, and can provide the cell instead.

### Row topics

Similar to column subnets, we introduce new row subnets: `data_row_{subnet_id}`. These resemble, but not to be confused with the deprecated `blob_sidecar_{subnet_id}` topics. Their properties:

- A row subnet MUST use Cell-Level Deltas without eager push. Like for Cell-Level Deltas in column subnets, the GroupID for a message in the row subnet is the block root. Since cells might arrive from three different sources (getBlobs, columns, rows) a node MAY choose to delay the request of cells from rows.
- We make the number of subnet_ids equal to maximum blob count. However, to distribute load evenly in the network, we introduce a mapping function that rotates which blob goes to which subnet_id in which slot (exact permutation function TBD).
- Nodes subscribe to a single row subnet, derived with a pseudo-random function from their node ID similar to how it is done for custody columns, however, there is no custody requirement.

A peer MAY limit the number of cells it serves a peer on the row subnet to just the majority of cells, as the rest can be reconstructed.

As a node receives cells from any source (either from row-subnets, column-subnets, or getBlobs), it SHOULD send updated bitmap states to its peers. A node MAY choose to debounce these updates.

### Reconstruction

A node, even if not a supernode, SHOULD collect at least 64 cells on its designated row and expose these in updated bitmap states to its peers. It MAY also decide to reconstruct the whole row. If it does, it SHOULD send its updated bitmap state to its peers.

Similar to PeerDAS, a supernode (in this context any node with 64 or more column subscriptions) MUST contribute to reconstruction. However, reconstruction becomes a two phase process:

- 1st phase: a supernode MUST reconstruct its designated row subnet, and it MUST send updated bitmap states to its peers. A small random delay before reconstruction is allowed to desyncronise nodes in the network and reduce overall load.
- 2nd phase: after a slightly longer delay, during which cells are collected from getBlobs, columns, and rows, a supernode SHOULD do a second reconstruction phase, reconstructing all missing rows, and sharing the results as defined above.

## Rationale

Row topics were part of the DAS discussion from the early days, well before PeerDAS was designed. [FullDAS](https://ethresear.ch/t/fulldas-towards-massive-scalability-with-32mb-blocks-and-beyond/19529) introduced cell-level messaging over both column and row topics, with cross-seeding and in-network reconstruction. It also introduced bitmap representations of IHAVE messages, but without the exact protocol details.

The [Gossipsub Partial Message Extension](https://github.com/libp2p/specs/blob/master/pubsub/gossipsub/partial-messages.md) introduced the mapping of bitmap-based partial message representations into GossipSub, opening the way to use them on columns in [EIP-8136](https://eips.ethereum.org/EIPS/eip-8136).

Until now, while we have developed the tools to implement better schemes, we remained with the original simplified PeerDAS construct. At the same time, blob count scaling made the CPU and bandwidth requirement of supernodes more of a point of contention. Reliance on supernodes, while abundant on current mainnet, is also a point of concentration leading to a protocol with less resilience then desirable.

This EIP corrects some of these shortcomings, making sure supernodes are not doing (as much) useless work, and reconstruction is possible (althong not yet mandated) even without supernodes.

### What it is not

This EIP is not FullDAS. It does not introduce sub-linear (cell-level) sampling. The bandwidth requirement of sampling nodes is still proportional to the amount of blobs.

It also does not introduce column-wise encoding, so protection and reconstruction is still only along the row axis.

Finally, it does not directly help L2 nodes retrieve individual blobs (although there are possible extensions in that direction). However, it helps them run supernodes with less resources, leading to a net gain.

### Possible extension to retrieve individual blobs

With the introduction of PeerDAS, L2 nodes have the problem that retrieving a specific blob from a CL client requires it to either be a supernode, or to download it on request through columns. By interoding row topics with allocation rooted in the nodeID, it is easier for nodes to indetify which node they can download the relevant blob from.


### Design decisions

- why are non-supernodes part of the row-topics?

This is to enable the possibility of reconstructing without supernodes. The additional traffic of one row, most probably already suppressed by getBlobs, is worth it in our opinion.

- why are non-supernodes not required to reconstruct?

While mandated reconstruction would be desirable from the perspective of not relying on supernodes at all, this would introduce extra CPU load on nodes, and we try to avoid this in this phase. It is still recommended to activate this reconstruction path with a delay as a resilience mechanism.

- why only a single row, and why is it not dependent on custody?

the current mainnet has approx. 12K nodes of which 3K are supernodes. The latter is much more than what we expected initially. With current and planned blob counts, even a single row creates abundant overlap.

## Backwards Compatibility

Row topics are limited to peers that have libp2p gossipsub implementations supporting Cell-level Deltas. The portion of peers that supports the extension is already reaching considerable numbers on mainnet, even before Glamsterdam. We expect the majority of peers to support it after the Glamsterdam fork and EIP-8136. For peers that do not support the extension, getBlobs and column topics are still fully available.

## Test Cases

TBD

## Security Considerations

The EIP changes DAS networking, but it does not change the custody allocation and the probabilistic guarantees of PeerDAS.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
