## Preamble

    EIP: draft
    Title: Whsiper Packet Codes - Specification
    Author: Vlad Gluhovsky <gluk256@gmail.com>
    Type: Informational
    Status: Draft
    Created: 2017-05-05

## Abstract

This draft EIP describes the packet codes and format used for Whisper messages within the ÐΞVp2p Wire Protocol.
This EIP should substitute the [existing specification](https://github.com/ethereum/wiki/wiki/Whisper-Wire-Protocol).

## Motivation

It is necessary to specify the standard for Whipser messages in order to ensure forward compatibility of different Whisper clients, even in case they don't support particular message codes.

## Specification

All Whisper messages sent as ÐΞVp2p Wire Protocol packets should be RLP-encoded arrays of data containing two objects: integer packet code followed by another object (whose type depends on the packet code). 

If Whisper node does not support a particular packet code, it should just ignore the packet without generating any error.

### Packet Codes

The Whisper sub-protocol should support the following packet codes:

| EIP   | Name                       | Int Value |
|-------|----------------------------|-----------|
|       | Status                     |   0x00    |
|       | Messages                   |   0x01    |
|       | P2P                        |   0x02    |
|       | P2P Request                |   0x03    |
|       | PoW Requirement            |   0x04    |
|       | Bloom Filter               |   0x05    |


### Packet Format and Usage

**Status** [`0x00`, `whisper_protocol_version`] 

This packet contains two objects: integer (0x00) followed by integer (Whisper protocol version).

Informs a peer of the Whisper version. This message should be send after the initial handshake and prior to any other messages.

**Messages** [`0x01`, `whisper_envelope`]

This packet contains two objects: integer (0x01) followed by a single Whisper Envelope.

This packet is used for sending the standard Whisper envelopes.

**P2P** [`0x02`, `whisper_envelope`]

This packet contains two objects: integer (0x02) followed by a single Whisper Envelope.

This packet is used for sending the peer-to-peer messages, which are not supposed to be forwarded any further. E.g. it might be used by the Whisper Mail Server for delivery of old (expired) messages, which is otherwise not allowed.

**P2P Request** [`0x03`, `whisper_envelope`]

This packet contains two objects: integer (0x03) followed by a single Whisper Envelope.

This packet is used for sending Dapp-level peer-to-peer requests, e.g. Whisper Mail Client requesting old messages from the Whisper Mail Server.

**PoW Requirement** [`0x04`, `PoW`]

This packet contains two objects: integer (0x04) followed by a single floating point value of PoW.

This packet is used by Whisper nodes for dynamic adjustment of their individual PoW requirements. Receipient of this message should no longer deliver the sender messages with PoW lower than specified in this message.

**Bloom Filter** [`0x05`, `bytes`]

This packet contains two objects: integer (0x05) followed by a byte array of arbitrary size.

This packet is used by Whisper nodes for sharing their interest in messages with specific topics. 

## Rationale

Packet codes 0x00 and 0x01 are already used in all Whisper versions.

Packet codes 0x02 and 0x03 are necessary to implement Whisper Mail Server and Client. Without P2P messages it would be impossible to deliver the old messages, since they will be recognized as expired, and the peer will be disconnected for violating the Whisper protocol. They might be useful for other purposes when it is not possible to spend time on PoW, e.g. if a stock exchange will want to provide live feed about the latest trades.

Packet code 0x04 will be necessary for the future developement of Whisper. It will provide possiblitity to adjust the PoW requirement in real time. It is better to allow the network to govern itself, rather than hardcode any specific value for minimal PoW requirement.

Packet code 0x05 will be necessary for scalability of the network. In case of too much traffic, the nodes will be able to request and receive only the messages they are interested in.

## Backwards Compatibility

This EIP is backwards-compatible with Whisper version 5. Any client which does not impement certain codes should gracefully ignore the packets with those codes. This will insure the forward compatibility. 

## Implementation

The golang implementation of Whisper (v.5) already uses packet codes 0x00 - 0x03. Codes 0x04 and 0x05 are still unused.
