---
eip: 7594
title: PeerDAS - Peer Data Availability Sampling
description: Introducing simple DAS utilizing gossip distribution and peer requests
author: Danny Ryan (@djrtwo), Dankrad Feist (@dankrad), Francesco D'Amato (@fradamt), Hsiao-Wei Wang (@hwwhww), Alex Stokes (@ralexstokes)
discussions-to: https://ethereum-magicians.org/t/eip-7594-peerdas-peer-data-availability-sampling/18215
status: Final
type: Standards Track
category: Core
created: 2024-01-12
requires: 4844
---

## Abstract

PeerDAS (Peer Data Availability Sampling) is a networking protocol that allows nodes to perform data availability sampling (DAS) to ensure that blob data has been made available while downloading only a subset of the data. PeerDAS utilizes gossip for distribution, discovery for finding peers of particular data custody, and peer requests for sampling.

## Motivation

DAS is a method of scaling data availability beyond the levels of [EIP-4844](./eip-4844.md) by not requiring all nodes to download all data while still ensuring that all of the data has been made available.

Providing additional data availability helps bring scale to Ethereum users in the context of layer 2 systems called "roll-ups" whose dominant bottleneck is layer 1 data availability.

## Specification

We extend the blobs introduced in EIP-4844 using a one-dimensional erasure coding extension. Each row consists of the blob data combined with its erasure code. It is subdivided into cells, which are the smallest units that can be authenticated with their respective blob's KZG commitments. Each column, associated with a specific gossip subnet, consists of the cells from all rows for a specific index. Each node is responsible for maintaining a deterministic set of column subnets and custodying their data as a function of their node ID.

Nodes find and maintain a diverse peer set and sample columns from their peers to perform DAS every slot.

A node can reconstruct the entire data matrix if it acquires at least 50% of all the columns. If a node has less than 50%, it can request the necessary columns from its peer nodes.

Additionally, a limit of 6 blobs per transaction is introduced. Clients MUST enforce this limit when validating blob transactions at submission time, when received from the network, and during block production and processing.

The detailed specifications are on [ethereum/consensus-specs](https://github.com/ethereum/consensus-specs/tree/9d377fd53d029536e57cfda1a4d2c700c59f86bf/specs/fulu/).

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Networking

This EIP introduces cell KZG proofs, which are used to prove that a KZG commitment opens to a cell at the given index. This allows downloading only specific cells from a blob, while still ensuring data integrity with respect to the corresponding KZG commitment, and is therefore a key component of data availability sampling. However, computing the cell proofs for a blob is an expensive operation, which a block producer would have to repeat for many blobs. Since proof verification is much cheaper than proof computation, and the proof size is negligible compared to cell size, we instead require blob transaction senders to compute the proofs themselves and include them in the EIP-4844 transaction pool wrapper for blob transactions.

To this end, during transaction gossip responses (`PooledTransactions`), the wrapper is modified to:

```
rlp([tx_payload_body, wrapper_version, blobs, commitments, cell_proofs])

cell_proofs = [cell_proof_0, cell_proof_1, ...]
```

The `tx_payload_body`, `blobs` and `commitments` are as in EIP-4844, while the `proofs` field is replaced by `cell_proofs`, and a `wrapper_version` is added. These are defined as follows:

- `wrapper_version` - one byte indicating which version of the wrapper is used. For the current version, it is set to **`1`**.
- `cell_proofs` - list of cell proofs for all `blobs`, including the proofs for the extension indices, for a total of `CELLS_PER_EXT_BLOB` proofs per blob (`CELLS_PER_EXT_BLOB` is the number of cells for an extended blob, defined [in the consensus specs](https://github.com/ethereum/consensus-specs/tree/9d377fd53d029536e57cfda1a4d2c700c59f86bf/specs/fulu/polynomial-commitments-sampling.md#cells))

Note that, while `cell_proofs` contain the proofs for all cells, including the extension cells, the blobs themselves are sent without being extended (`CELLS_PER_EXT_BLOB / 2` cells per blob). This is to avoid sending redundant data, which can quickly be computed by the receiving node.
In other words, `cell_proofs[i * CELLS_PER_EXT_BLOB + j]` is the proof for cell `j` of `compute_cells(blobs[i])`, where `compute_cells(blob)` outputs all cells of `blob`, including the extension cells.

The node MUST validate `tx_payload_body` and verify the wrapped data against it. To do so, ensure that:

- There are an equal number of `tx_payload_body.blob_versioned_hashes`, `blobs` and `commitments`.
- `cell_proofs` contains exactly `CELLS_PER_EXT_BLOB * len(blobs)` cell proofs
- The KZG `commitments` hash to the versioned hashes, i.e. `kzg_to_versioned_hash(commitments[i]) == tx_payload_body.blob_versioned_hashes[i]`
- The KZG `commitments` match the corresponding `blobs` and `cell_proofs`. This requires computing the extension cells for all `blobs` (e.g. via `compute_cells`), and verifying all `cell_proofs`. (Note: all cell proofs can be batch verified at once, e.g. via `verify_cell_kzg_proof_batch`)

## Rationale

### Why use DAS to scale the DA layer?

PeerDAS is a DAS scheme that requires nodes to only download a small constant fraction of the data to satisfy a local availability check. With the current parameters, this is 1/8 of the total data (i.e. blobs in a block), which can in the future be decreased to 1/16 or even 1/32 by reducing the size of samples (increasing the number of columns). In this way, PeerDAS allows for securely scaling the blob throughput of the network without compromising decentralization, i.e., without increasing node's bandwidth and storage requirements.

### What does peer sampling provide?

PeerDAS takes the set of peers of a node on the network as a primitive to build a DAS scheme around. A focus on peers allows for redundancy in the mechanism (as a node generally has many peers, and peer count can also be cheaply increased) which both helps with theoretical security as detailed in the "Security Considerations" section, but also practical security of the implementation (e.g. if a single peer fails, a node can likely use another peer for the same sampling task).

PeerDAS also has the nice property that any given node may voluntarily custody more of the data than the bare minimum which increases the performance of the mechanism. Alternative schemes do not readily support this "transparent" scaling property.

### Why are these parameters chosen?

The parameters of PeerDAS given in the specs support network security while keeping node requirements sufficiently low. See the security argument below for further details.

### Why do validators have an additional custody requirement beyond full nodes?

Validators are assumed to have marginally higher requirements to participate on the network. PeerDAS introduces a custody requirement that scales with the validator count so that nodes with more resources can contribute to a more stable backbone that makes the global network more robust.

### Column sampling vs row sampling

PeerDAS defines a sample as a "column" which is a cross-section across _all_ blobs, rather than a "row" which would be a full blob.
The sampling scheme could be defined over rows but then any reconstruction strategy would need to work over "extension" blobs that do not a priori exist on the network.
Reconstruction becomes much more tractable by working over columns as nodes can be assumed to have much more of the complete data by default (e.g. because most/all of the blobs are in the public mempool).

Another benefit is that sampling over rows requires _column_ extensions which would have to be done at the time of block construction, i.e. on the "critical path". Sampling over columns requires row extensions which can be done in advance (not on the critical path), and moreover proof computation can be outsourced to senders of blob transactions.

## Backwards Compatibility

This EIP is fully backwards compatible with [EIP-4844](./eip-4844.md).

## Test Cases

Refer to the consensus and execution spec tests for testing of this EIP.

## Security Considerations

The primary failure mode of a DAS scheme is a "data withholding" attack, where a block producer attempts to convince the network some data is available even when the block producer fails to provide the associated data.
PeerDAS resolves withholding attacks by implementing a (pseudo)randomized sampling scheme that decreases the probability of a successful attack as the size of the network grows for a sublinear amount of data that must be downloaded.

This intuition can be formalized as follows:

Letting `n` be the total number of sampling nodes (i.e. the size of the network), `m` be the total number of samples possible (cf. `NUMBER_OF_CUSTODY_GROUPS` in the specs) and `k` be the minimum number of samples that a node must download (cf. `SAMPLES_PER_SLOT` in the specs), we have the following bound for the probability of convincing a fraction $\epsilon$ of the nodes that some data is available when it is withheld:

![withholding-probability](../assets/eip-7594/withholding-probability.svg)

The first term is the number of possible ways to choose a subset of $n\epsilon$ nodes whose sampling queries should be satisfied (i.e. the nodes to be tricked).
The second term is the number of ways to choose a maximally large subset of samples to be made available to satisfy the sampling queries of the $n\epsilon$ nodes without allowing reconstruction of the full data.
Finally, for any such choices, the third term is the probability of success, i.e. the probability that the sampling queries of all chosen $n\epsilon$ nodes are satisfied by the chosen subset up to the reconstruction threshold.

For mainnet parameters given in the specs and assuming 10,000 nodes on the network, we can compute upper bounds of attack success for varying $\epsilon$:

| $\epsilon$ | $n\epsilon$ (target nodes) | Upper bound on $\mathbb{P}$ |
|:----------:|:-------------------:|:---------------------------:|
| 0.01        | 100                | $1$                         |
| 0.02        | 200                | $10^{-20.04}$               |
| 0.03        | 300                | $10^{-101.55}$              |
| 0.04        | 400                | $10^{-198.24}$              |
| 0.05        | 500                | $10^{-306.34}$              |

The table shows that the chances of a successful attack quickly drop to a negligible amount and so PeerDAS is considered secure to withholding attacks.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
