## Preamble

    EIP: <to be assigned>
    Title: devp2p snappy compression
    Author: Péter Szilágyi <peter@ethereum.org>
    Type: Standard Track
    Category: Networking
    Status: Draft
    Created: 2017-09-07

## Abstract
The base networking protocol (devp2p) used by Ethereum currently does not employ any form of compression. This results in a massive amount of bandwidth wasted in the entire network, making both initial sync as well as normal operation slower and laggyer.

This EIP proposes a tiny extension to the devp2p protocol to enable [Snappy compression](https://en.wikipedia.org/wiki/Snappy_(compression)) on all message payloads after the initial handshake. After extensive benchmarks, results show that data traffic is decreased by 60-80% for initial sync. You can find exact numbers below.

## Motivation
Synchronizing the Ethereum main network (block 4,248,000) in Geth using fast sync currently consumes 1.01GB upload and 33.59GB download bandwidth. On the Rinkeby test network (block 852,000) it's 55.89MB upload and 2.51GB download.

However, most of this data (blocks, transactions) are heavily compressable. By enabling compression at the message payload level, we can reduce the previous numbers to 1.01GB upload / 13.46GB download on the main network, and 46.21MB upload / 463.65MB download on the test network.

The motivation behind doing this at the devp2p level (opposed to eth for example) is that it would enable compression for all sub-protocols (eth, les, bzz) seamlessly, reducing any complexity those protocols might incur in trying to individually optimize for data traffic.

## Specification
Bump the advertised devp2p version number from `4` to `5`. If during handshake, the remote side advertises support only for version `4`, run the exact same protocol as until now.

If the remote side advertises a devp2p version `>= 5`, inject a Snappy compression step right before encrypting the devp2p message during sending:

 * A message consists of `{Code, Size, Payload}`
  * Compress the original payload with Snappy and store it in the same field.
  * Update the message size to the length of the compressed payload.
  * Encrypt and send the message as before, oblivious to compression.

Similarly to message sending, when receiving a devp2p v5 message from a remote node, insert a Snappy decompression step right after the decrypting the devp2p message:

* A message consists of `{Code, Size, Payload}`
 * Decrypt the message payload as before, oblivious to compression.
 * Decompress the payload with Snappy and store it in the same field.
 * Update the message size to the length of the decompressed payload.

Note, the handshake message is never compressed, since it is needed to negotiate the common version.

### Avoiding DOS attacks

Currently a devp2p message length is limited to 24 bits, amoutning to a maximum size of 16MB. With the introduction of Snappy compression, care must be taken not to blidly decompress messages, since they may get significantly larger than 16MB.

However, Snappy is capable of calculating the decompressed size of an input message without inflating it in memory. This can be used to set the message size to its final decompressed length and only execute the decompression lazily if upper layers still accept the message. This allows the `eth` protocol to enforce the current 10MB message limit without needing to decompress malicious payload.

## Rationale
Alternative solutions to data compression that have been brought up and discarded are:

 * Extend protocol `xyz` to support compressed messages
  * **Pro**: Can be better optimized when to compress and when not to.
  * **Con**: Mixes in transport layer encoding into application layer logic.
  * **Con**: Makes the individual message specs more convoluted with compression details.
  * **Con**: Requires cross client coordination on every single protocol, making the effor much harder and repeated (eth, les, shh, bzz).
 * Introduce seamless variations of protocol such as `xyz` expanded with `xyz-compressed`:
  * **Pro**: Can be done (hacked in) without cross client coordination.
  * **Con**: Litters the network with client specific protocol announces.
  * **Con**: Needs to be specced in an EIP for cross interoperability anyway.

## Backwards Compatibility
This proposal is fully backward compatible. Clients upgrading to the proposed devp2p protocol version `5` should still support skipping the compression step for connections that only advertise version `4` of the devp2p protocol.

## Implementation
You can find a reference implementation of this EIP in https://github.com/ethereum/go-ethereum/pull/15106.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
