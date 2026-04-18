---
title: EIP tagging
description: Acceptable tags for EIPs with descriptions
author: James Kempton (@SirSpudlington), et al.
discussions-to: https://ethereum-magicians.org/t/eip-tagging/28275
status: Draft
type: Meta
created: 2026-04-18
requires: 1
tags:
  - "meta:eip/tags"
---

## Tag structure

EIP tags must follow the structure of `namespace:category[/subcategory]`. The `[/subcategory]` section of a tag is optional, and may be omitted if an EIP broadly covers a topic.
Tags should be appended on a per-tag basis, no two tags are mutually exclusive.

## Acceptable tags

The acceptable tags that may be found in an EIP are defined below.

### The `el` namespace

| Tag name | Description |
|-|-|
| `el:block` | Modifications to the structure, processing or handling of blocks. (Excluding EVM processing) |
| `el:cryptography` | Introduction or modification of any new cryptographic primitive or algorithms. |
| `el:data-availability` | Introduction or modification of any system with a primary purpose of providing data availability to external consumers outside of the EVM. |
| `el:evm` | Introduction or modification of the processing or structure of EVM bytecode. |
| `el:evm/opcode` | Introduction or modification of specific EVM opcodes. |
| `el:evm/precompile` | Introduction or modification of precompiled contracts. |
| `el:receipt` | Modifications to the structure or handling of transaction receipts.  |
| `el:state` | Changes to how the state is structured or processed. |
| `el:transaction` | Modification or introduction of a transactions structure or processing **or** introduction of new transaction types. (Excluding EVM processing) |
| `el:validator` | Changes to how validators are processed on the execution layer. |

### The `cl` namespace

| Tag name | Description |
|-|-|
| `cl:cryptography` | Introduction or modification of any new cryptographic primitive or algorithms. |
| `cl:data-availability` | Introduction or modification of any system with a primary purpose of providing data availability to external consumers outside of the EVM. |
| `cl:finalization` | Changes to how blocks are finalized. |
| `cl:fork-choice` | Changes to how the the next correct block is selected. |
| `cl:light` | Systems that have a primary purpose of providing for light clients. |
| `cl:slot` | Modifications to the structure, timing, processing or handling of slots. |
| `cl:validator` | Changes to validator operation or processing. |

### The `net` namespace

| Tag name | Description |
|-|-|
| `net:transports` | Changes to how messages are passed between clients. |
| `net:discovery` | Changes to how clients discover and peer with each other. |
| `net:identification` | How peers may identify themselves to other peers. |
| `net:protocol` | Introduction or changes of specific protocols. |
| `net:protocol/execution` | Protocols for execution bound messages. |
| `net:protocol/sync` | Protocols that have a primary purpose of syncing with other peers. |
| `net:protocol/consensus` | Protocols for consensus bound messages. |
| `net:protocol/light-client` | Protocols that have a primary purpose of providing light clients with chain information. |
| `net:protocol/rpc` | Protocols for communication of chain data between clients |
<!-- More TBD -->

### The `erc` namespace

<!-- TBD -->
<!-- Should this even exist or should tags be EIP only? -->

### The `meta` namespace

| Tag name | Description |
|-|-|
| `meta:eip/tags` | EIPs that modifies existing tags or how they are handled. |
| `meta:experimental` | EIPs that have functionality that does not fit into pre-existing tags. EIPs with this tag cannot finalize, tags should be created to replace this tag before finalization. |
<!-- More TBD -->

## Tagging guidelines

Introducing new tags must follow the below conditions:

- Tags must be generic. Tags must not specify how something is done, just what is done.
- Tags should be short and human readable.
- Tags must map to one namespace
- Tags can only be created if they are:
  - Blocking an EIP with the `meta:experimental` tag from finalizing
  - Are currently present in the network
- Tags can only be removed if:
  - All EIPs using the tag are Withdrawn or Stagnant.
  - The tag does not have a reasonable implementation within a major client

<!-- Should there be more conditions? -->

## Example tags

The tags for [EIP-2718](./eip-2718.md) would be `el:transaction` and `el:receipt`.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).