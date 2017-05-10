## Preamble

    EIP: draft
    Title: Whisper Specification
    Author: Vlad Gluhovsky <gluk256@gmail.com>
    Type: Informational
    Status: Draft
    Created: 2017-05-05

## Abstract

This draft EIP describes the format of Whisper messages within the ÐΞVp2p Wire Protocol.
This EIP should substitute the [existing specification](https://github.com/ethereum/wiki/wiki/Whisper-Wire-Protocol).
More detailed documentation on Whisper could be found [here](https://github.com/ethereum/go-ethereum/wiki/Whisper).

## Motivation

It is necessary to specify the standard for Whipser messages in order to ensure forward compatibility of different Whisper clients.

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

### Whisper Envelope

Envelopes are RLP-encoded structures of the following format:

	[ Version, Expiry, TTL, Topic, AESNonce, Data, EnvNonce ]
	
`Version`: up to 4 bytes (currently one byte containing zero). Version indicates encryption method. If Version is higher than current, envelope could not be decoded, and therefore only forwarded to the peers.

`Expiry`: 4 bytes (UNIX time in seconds).

`TTL`: 4 bytes (time-to-live in seconds).

`Topic`: 4 bytes of arbitrary data.

`AESNonce`: 12 bytes of random data (only present in case of symmetric encryption).

`Data`: byte array of arbitrary size (contains encrypted message).

`EnvNonce`: 8 bytes of arbitrary data (used for PoW calculation).

### Contents of Data Field (Message)

Data field contains encrypted message of the Envelope. Plaintext (unencrypted) payload is formed as a concatenation of a single byte for flags, additional metadata (as stipulated by the flags) and the actual payload. The message has the following structure:

    flags: 1 byte
    
    optional padding: byte array of arbitrary size
    
    payload: byte array of arbitrary size
    
    optional signature: 65 bytes

Those unable to decrypt the message data are also unable to access the signature. The signature, if provided, is the ECDSA signature of the Keccak-256 hash of the unencrypted data using the secret key of the originator identity. The signature is serialised as the concatenation of the `R`, `S` and `V` parameters of the SECP-256k1 ECDSA signature, in that order. `R` and `S` are both big-endian encoded, fixed-width 256-bit unsigned. `V` is an 8-bit big-endian encoded, non-normalised and should be either 27 or 28. 

The padding is introduced in order to align the message size, since message size alone might reveal important metainformation. The first several bytes of padding (up to four bytes) indicate the total size of padding (including these length bytes). E.g. if padding is less than 256 bytes, then one byte is enough; if padding is less than 65536 bytes, then 2 bytes; and so on.

Flags byte uses only three bits in v.5. First two bits indicate, how many bytes indicate the padding size. The third byte indicates if signature is present. Other bits must be set to zero for backwards compatibility of future versions.

### Payload Encryption

Asymmetric encryption uses the standard Elliptic Curve Integrated Encryption Scheme with SECP-256k1 public key.

Symmetric encryption uses AES GCM algorithm with random 96-bit nonce.

## Rationale

Packet codes 0x00 and 0x01 are already used in all Whisper versions.

Packet codes 0x02 and 0x03 are necessary to implement Whisper Mail Server and Client. Without P2P messages it would be impossible to deliver the old messages, since they will be recognized as expired, and the peer will be disconnected for violating the Whisper protocol. They might be useful for other purposes when it is not possible to spend time on PoW, e.g. if a stock exchange will want to provide live feed about the latest trades.

Packet code 0x04 will be necessary for the future developement of Whisper. It will provide possiblitity to adjust the PoW requirement in real time. It is better to allow the network to govern itself, rather than hardcode any specific value for minimal PoW requirement.

Packet code 0x05 will be necessary for scalability of the network. In case of too much traffic, the nodes will be able to request and receive only the messages they are interested in.

## Backwards Compatibility

This EIP is compatible with Whisper version 5. Any client which does not implement certain packet codes should gracefully ignore the packets with those codes. This will ensure the forward compatibility. 

## Implementation

The golang implementation of Whisper (v.5) already uses packet codes 0x00 - 0x03. Codes 0x04 and 0x05 are still unused.
