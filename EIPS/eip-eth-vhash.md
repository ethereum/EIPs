---
eip: TBD
title: eth/vhash - blob-aware mempool
description: Make mempool messaging vhash aware
author: Csaba Kiraly (@cskiraly)
discussions-to: 
status: Draft
type: Standards Track
category: Networking
created: 2025-11-29
requires: 7642
---

## Abstract

This EIP eliminates the need to redistribute blob content in the mempool if
only the metadata (fees) of a transaction are updated, making RBF
(replace-by-fee) more efficient and cheaper for the network. It achieves this
modifying the devp2p ‘eth’ protocol to address blobs in type3 transaction
sidecars by content (vhash).

## Motivation

In the current version of devp2p eth/69, when a transaction is replaced, it
must be redistributed in the mempool like any new transaction. Even if the
actual content is largely the same, protocol participants have no means to
figure this out before getting the full content, making a replacement use the
same amount of network resources as a new transaction would.

What is especially problematic is that RBF is used most in periods of fee
volatility, and a network overload is the typical case of such a situation.
Thus, when there is already high demand, we make the situation worse by adding
extra traffic redistributing blob content that was already distributed.

## Specification

### Transactions (0x02) changes

Type 3 transaction should be sent without sidecar

### PooledTransactions (0x0a) changes

Type 3 transaction should be sent without sidecar

### GetPooledBlobs (msg code TBA)

[request-id: P, [vhash₁: B_32, vhash₂: B_32, ...]]

This message requests blobs from the recipient's transaction pool by vhash.

### PooledBlobs (msg code TBA)

[request-id: P, [blob₁, blob₂...]]

This is the response to GetPooledBlobs, returning the requested blobs. The
items in the list are blobs in the format described in the main Ethereum
specification.

> Note: optionally, we might prefix the blob format with the blob version number

> Note: optionally, we might decide to improve the blob format allowing nodes
to reconstruct RS encoding instead of using extra bandwidth, by sending the
following fields per blob:
> - blob version
> - blob content, **excluding** the erasure coding extension in case of version 1
> - blob commitment
> - blob proof(s), **including** cell proofs of the erasure coded piece in case
of version 1 
>
> It is important to include all cell proofs to keep reconstruction
CPU-efficient.

The blobs must be in the same order as in the request, but it is OK to skip
blobs which are not available. Since the recipient have to check that
transmitted blob hashes correspond to the requested vhashes anyway, we can
avoid sending the list of vhashes as part of this message.

> Note: Optionally, we could extend this message with a bitmap of sent/unsent
blobs from the request, or with the list of vhashes sent. This information is
redundant, but it can simplify processing on the receiver side.

### Other spec changes

EIP-4844 introduced the following:

    Nodes MUST NOT automatically broadcast blob transactions to their peers.
    Instead, those transactions are only announced using
    NewPooledTransactionHashes messages, and can then be manually requested
    via GetPooledTransactions.

The above should be changed as follows:

    Nodes MUST send (broadcast or send in NewPooledTransactionHashes) blob
    transactions **without** sidecars to their peers. Peers can then request
    blob content using `GetPooledBlobs` messages. Nodes MUST NOT forward blob
    transactions before receiving and validating all blobs".

## Rationale

A typical blob transaction RBF changes the fees only, while the sidecar (blob
content) remains the same. If a node that has the previous version would know
this, it could avoid pulling the sidecar, largely reducing bandwidth
consumption. However, this is not possible with the current messaging. To make
this happen, we have to expose blob (or at least sidecar) identifiers in
mempool messaging.

### Should we use blob identifiers or a sidecar identifier?
We can either use vhashes, or a sidecar level hash. The latter has the slight
advantage of being a single element, thus simplifying message format, but it
has several disadvantages:
- It would be a new identifier, while the blob level vhash is already well
established (just not in devp2p) 
- It would not allow restructuring the message, sending e.g. less blobs under a
fee surge

Thus, we use vhashes.

### Implementation options

There are several options to bring vhashes to devp2p messaging:

#### Option 1
- Extend announcements with vhashes
- Allow nodes to request transaction with/without sidecar content, or even
selecting which parts are needed (bitmap or vhash list)

#### Option 2
- Extend announcements with nonce (see EIP-8077)
- If hash differs from what we have, request with/without sidecar content based
on whether we already have the sidecars for the same nonce, assuming this is a
simple replacement
- Request again with sidecar if vhashes differ

#### Option 3 (selected)
- Push (or announce and then pull) type 3 transaction **without sidecar**
- Allow to **request sidecar separately** (new message type)

At first it might seem that Option 3 is slowing down distribution, adding one
more RTT latency per hop. However, since most type 3 transactions are small
without a sidecar, we could change the protocol behaviour to allow pushing
these transactions without the sidecar, leaving it to the receiver of the push
to ask for the blobs if needed. Forwarding of type3 transactions without
sidecar should be prohibited until sidecars are fetched and the content can be
verified.

After considering the above options, we chose to propose Option 3, introducing
a new message type.

### Relation to other EIPs in draft state
- EIP-8077 (announce source and nonce): the changes can be simply combined.
- EIP-8070 (Sparse blobpool): both EIPs change how blob transactions are
propagated over the network. The goal of the two EIPs are different. EIP-8070
is about a proportional bandwidth reduction in the normal case without dealing
with specifics of RBF. This EIP is about enabling RBF without using extra
bandwidth. The two EIPs can be combined, but the combination depends on the
order of introduction, hence we leave this for later.

## Backwards Compatibility

This EIP changes the eth protocol and requires rolling out a new version.
Supporting multiple versions of a wire protocol is routine practice. Rolling
out this new version does not break older clients, since they can keep using
the previous protocol version.

This EIP does not change consensus rules of the EVM and does not require a hard
fork.

## Security Considerations

## Copyright

Copyright and related rights waived via CC0.
