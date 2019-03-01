---
eip: <to be assigned>
title: Simple Streamable Serialize
author: Piper Merriam (@pipermerriam)
discussions-to: https://ethereum-magicians.org/t/discussion-of-eip-1805/2789
status: Draft
type: <Standards Track>
category: <Networking>
created: 2019-03-01
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

A serialization scheme for network transport between Ethereum clients.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

This document outlines the needs for data serialization in the context of
serializing objects for network transport and makes a case for adopting "Simple
Streamable Serialize" as the defacto replacement for RLP when serializing
objects for network transport.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

The Ethereum network has used RLP for both network transport and object
hashing.  RLP is a custom serialization format that was designed alongside the
various Ethereum protocols.

While RLP has done well, there is room for improvement, specifically at the
networking layer.  Ethereum clients are currently struggling to keep up with
the Ethereum network.  Adoption of this scheme would allow for a reduction in
bandwidth usage across every message type and data structure.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

Work in progress can be found here: https://github.com/ethereum/bimini/blob/master/spec.md


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The following properties are needed in whatever serialization format is used
for network transport.


### Language Support

Implementations available across different languages, primarily

- Go: go-ethereum
- Rust: Parity
- Python: Trinity & Eth2.0 Research
- Java: Enterprise


### Strongly Typed

Values must be strongly typed.

### Compact / Efficient

The serialized data structures should have minimal overhead when serialized.
The resulting serialized byte-size should be as close to the raw number of
bytes needed to represent the data.


### Streamable

The process of encoding and decoding should support streaming.  Efficient
implementations should be able to encode or decode using `O(1)` memory space.


### Data Types

We require the following data types to be well supported in the format.

- Booleans
- Unsigned integers up to 256 bits.
  - e.g. `transaction.value`
- Fixed length byte strings
  - e.g. `header.parent_hash`
  - not strictly required but effects compactness and requires client-side validation of lengths
- Dynamic length byte strings
  - e.g. `log.data`
- Dynamic length arrays of homogenous types
  - e.g. `block.transactions`
- Fixed length arrays of homogenous types
  - e.g. Discovery protocol `Neighbors` response.
  - not strictly required but effects compactness and requires client-side validation of lengths
- Struct-likes for fixed length collections of heterogenous types.
  - e.g. Blocks, Transactions, Headers, etc.


## Candidates

### Popular Formats

The following formats were not considered.

- JSON
  - Not space efficient
  - No native support for schemas


Ideally, we would make use of a well established binary serialization format
with mature libraries in multiple languages.  The following were evaluated and
dismissed due to the listed reasons.

- Protobuf
  - No support for integers above 64 bits
  - No support for fixed size byte strings
  - No support for fixed size arrays
- Message Pack
  - No support for integers above 64 bits
  - No support for fixed size byte strings
  - No support for fixed size arrays
- CBOR
  - No support for strongly typed integers above 64 bits (supports arbitrary bignums)
  - No support for fixed size byte strings
  - No support for fixed size arrays
  - Serialization format contains extraneous metadata not needed by our protocol


### Custom Formats

Having dismissed popular established formats, the following *custom* formats
were evaluated.


- RLP aka Recursive Length Prefix: 
  - https://github.com/ethereum/wiki/wiki/RLP
  - the established serialization used across most parts of the Ethereum protocols
- SSZ aka Simple Serialize:
  - https://github.com/ethereum/eth2.0-specs/blob/bed888810d5c99cd114adc9907c16268a2a285a9/specs/simple-serialize.md
  - the current serialization scheme being used in Eth2.0
- SSS aka Streamable Simple Serialize (working title):
  - https://github.com/ethereum/bimini/blob/master/spec.md
  - an experimental serialization scheme developed specifically for the networking needs of the Ethereum protocol.


#### RLP

RLP is well known and widely used.

- **Language Support**
  - Strong: Established RLP libraries available across most languages
- **Strongly Typed**
  - No: however strong typing is added at the implementation level for most RLP libraries.
- **Compact / Efficient**
  - Medium:
    - No native support for fixed length byte strings results in extra bytes for length prefix
    - No native support for fixed length arrays results in extra bytes for length prefix
    - No layer-2 support for compact integer serialization
- **Streamable**
  - Yes


#### SSZ

SSZ was created as part of the Eth2.0 research.  It was designed to be simple
and low overhead.

- **Language Support**
  - Low: SSZ implementations are being created as part of the Eth2.0 efforts.  None are well established.
- **Strongly Typed**
  - Yes
- **Compact / Efficient**
  - Poor:
    - No support for compact integer serialization
    - Length prefixes are 32-bit, typically resulting in multiple superflous empty bytes
    - Containers are size prefixed with 32-bit values, all of which are superflous
    - No support for compact integer serialization
- **Streamable**
  - No:
    - Size prefixing container types prevents streaming


#### SSS

SSS was created to specifically address the Ethereum network needs.

- **Language Support**
  - Bad: Only one experimental implementation in python https://github.com/ethereum/bimini
- **Strongly Typed**
  - Yes
- **Compact / Efficient**
  - High
    - Near zero superfluous bytes for most schemas
- **Streamable**
  - Yes

## Side-by-Side Comparison

Empirical tests were done to shows how SSS performs with respect to RLP and SSZ for
the following data structures with respect to their serialized sizes.

- Blocks
- Headers
- Transactions
- Receipts
- Logs
- Accounts
- State Trie Nodes (of depths 0-9)
- Discovery Ping
- Discovery Pong
- Discovery FindNode
- Discovery Neighbours

In every case, SSS serialization resulted in a smaller serialized
representation than it's counterparts in either RLP or SSZ.

The comparison to SSZ is less relevant to the Eth1.0 network, but tests are
planned against the Eth2.0 data structures.


### SSS vs RLP Summary

The comparison to RLP shows that there are multiple places where SSS could
reduce the amount of bandwidth used by Ethereum clients.

- ~3% reduction in block size
- ~50% reduction in receipt size
- ~5% reduction in account size (state sync)
- ~2% reduction in trie-node size

Specific to the discovery protocol:

- ~8% reduction for ping
- ~4% reduction for pong
- ~4% reduction for find-nodes
- ~4% reduction for neighbors

## Conclusion


Streamable Simple Serialize (SSS) seems like a strong candidate for the wire
serialization format used by ethereum clients.

- It is simple and easy to implement (the python implementation took a few days to hit a reasonably well polished MVP)
- An optimized implementation should have similar performance to RLP and better than SSZ
- It is highly compact
- It has native support for all desired data types

It is worth noting that SSS is very similar to SSZ, but it is likely wrong to
try and combine the two.  SSS is optimized for network transport, and thus, it
sacrifices the ability to quickly index into data structures *without decoding
them* for compactness.  The data structures we use for hashing needs to support
this feature which seems to be at odds with compactness, requiring additional
metadata to be enbedded into the data structure to account for dynamically
sized fields.  Thus, we will likely want two serialization formats.  One for
network transport.  One for hashing.


## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

TODO: This section will need to be filled in as depending on how broadly this is applied, there will be backwards compatibility issues to deal with.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

TODO

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

An MVP python implementation can be found here: https://github.com/ethereum/bimini

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
