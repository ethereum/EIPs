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

The message codes reserved for Whisper protocol: 0 - 127.
Messages with unknown codes must be ignored, for forward compatibility of future versions.

The Whisper sub-protocol should support the following packet codes:

| EIP   | Name                       | Int Value |
|-------|----------------------------|-----------|
|       | Status                     |     0     |
|       | Messages                   |     1     |
|       | PoW Requirement            |     2     |
|       | Bloom Filter               |     3     |
|-------|----------------------------|-----------|


The following message codes are optional, but they are reserved for specific purpose.

| EIP   | Name                       | Int Value |
|-------|----------------------------|-----------|
|       | P2P Request                |    126    |
|       | P2P Message                |    127    |
|-------|----------------------------|-----------|

### Packet Format and Usage

**Status** [`0`]

This packet contains two objects: integer (0x00). Might be followed by some arbitrary data in future versions, which should be gracefully ignored for future compatibility.
This message should be send after the initial handshake and prior to any other messages.

**Messages** [`1`, `whisper_envelopes`]

This packet contains two objects: integer (0x01) followed by a list (possibly empty) of Whisper Envelopes.

This packet is used for sending the standard Whisper envelopes.

**PoW Requirement** [`2`, `PoW`]

This packet contains two objects: integer (0x02) followed by a single floating point value of PoW.

This packet is used by Whisper nodes for dynamic adjustment of their individual PoW requirements. Receipient of this message should no longer deliver the sender messages with PoW lower than specified in this message.

PoW is defined as average number of iterations, required to find the current BestBit (the number of leading zero bits in the hash), divided by message size and TTL:

	PoW = (2**BestBit) / (size * TTL)

PoW calculation:

	fn short_rlp(envelope) = rlp of envelope, excluding env_nonce field.
	fn pow_hash(envelope, env_nonce) = sha3(short_rlp(envelope) ++ env_nonce)
	fn pow(pow_hash, size, ttl) = 2**leading_zeros(pow_hash) / (size * ttl)

where size is the size of the full RLP-encoded envelope.

**Bloom Filter** [`3`, `bytes`]

This packet contains two objects: integer (0x03) followed by a byte array of arbitrary size.

This packet is used by Whisper nodes for sharing their interest in messages with specific topics.

The Bloom filter is used to identify a number of topics to a peer without compromising (too much) privacy over precisely what topics are of interest. Precise control over the information content (and thus efficiency of the filter) may be maintained through the addition of bits.

Blooms are formed by the bitwise OR operation on a number of bloomed topics. The bloom function takes the topic and projects them onto a 512-bit slice. At most, three bits are marked for each bloomed topic.

The projection function is defined as a mapping from a a 4-byte slice S to a 512-bit slice D; for ease of explanation, S will dereference to bytes, whereas D will dereference to bits.

	LET D[*] = 0
	FOREACH i IN { 0, 1, 2 } DO
	LET n = S[i]
	IF S[3] & (2 ** i) THEN n += 256
	D[n] = 1
	END FOR


OPTIONAL

**P2P Request** [`126`, `whisper_envelope`]

This packet contains two objects: integer (0x7E) followed by a single Whisper Envelope.

This packet is used for sending Dapp-level peer-to-peer requests, e.g. Whisper Mail Client requesting old messages from the Whisper Mail Server.

**P2P Message** [`127`, `whisper_envelope`]

This packet contains two objects: integer (0x7F) followed by a single Whisper Envelope.

This packet is used for sending the peer-to-peer messages, which are not supposed to be forwarded any further. E.g. it might be used by the Whisper Mail Server for delivery of old (expired) messages, which is otherwise not allowed.


### Whisper Envelope

Envelopes are RLP-encoded structures of the following format:

	[ Version, Expiry, TTL, Topic, Data, Nonce ]
	
`Version`: 1 byte. If Version is higher than current, envelope could not be decoded, and therefore only forwarded to the peers.

`Expiry`: 4 bytes (UNIX time in seconds).

`TTL`: 4 bytes (time-to-live in seconds).

`Topic`: 4 bytes of arbitrary data.

`Data`: byte array of arbitrary size (contains encrypted message).

`Nonce`: 8 bytes of arbitrary data (used for PoW calculation).

### Contents of Data Field of the Message (Optional)

This section describes optional description of Data Field to set up an example. Later it may be moved to a separate EIP.

It is only relevant if you want to decrypt the incoming message, but any other format would be perfectly valid and must be forwarded to the peers.

Data field contains encrypted message of the Envelope. In case of symmetric encryption, it also contains appended Salt (12 bytes). Plaintext (unencrypted) payload is formed as a concatenation of a single byte for flags, additional metadata (as stipulated by the flags) and the actual payload. The message has the following structure:

    flags: 1 byte
    
    optional padding: byte array of arbitrary size
    
    payload: byte array of arbitrary size
    
    optional signature: 65 bytes

Those unable to decrypt the message data are also unable to access the signature. The signature, if provided, is the ECDSA signature of the Keccak-256 hash of the unencrypted data using the secret key of the originator identity. The signature is serialised as the concatenation of the `R`, `S` and `V` parameters of the SECP-256k1 ECDSA signature, in that order. `R` and `S` are both big-endian encoded, fixed-width 256-bit unsigned. `V` is an 8-bit big-endian encoded, non-normalised and should be either 27 or 28. 

The padding is introduced in order to align the message size, since message size alone might reveal important metainformation. The first several bytes of padding (up to four bytes) indicate the total size of padding (including these length bytes). E.g. if padding is less than 256 bytes, then one byte is enough; if padding is less than 65536 bytes, then 2 bytes; and so on.

Flags byte uses only three bits in v.6. First two bits indicate, how many bytes indicate the padding size. The third byte indicates if signature is present. Other bits must be set to zero for backwards compatibility of future versions.

### Payload Encryption

Asymmetric encryption uses the standard Elliptic Curve Integrated Encryption Scheme with SECP-256k1 public key.

Symmetric encryption uses AES GCM algorithm with random 96-bit nonce.

## Rationale

Packet codes 0x00 and 0x01 are already used in all Whisper versions.

Packet code 0x02 will be necessary for the future developement of Whisper. It will provide possiblitity to adjust the PoW requirement in real time. It is better to allow the network to govern itself, rather than hardcode any specific value for minimal PoW requirement.

Packet code 0x03 will be necessary for scalability of the network. In case of too much traffic, the nodes will be able to request and receive only the messages they are interested in.

Packet codes 0x7E and 0x7F may be used to implement Whisper Mail Server and Client. Without P2P messages it would be impossible to deliver the old messages, since they will be recognized as expired, and the peer will be disconnected for violating the Whisper protocol. They might be useful for other purposes when it is not possible to spend time on PoW, e.g. if a stock exchange will want to provide live feed about the latest trades.

## Backwards Compatibility

This EIP is compatible with Whisper version 6. Any client which does not implement certain packet codes should gracefully ignore the packets with those codes. This will ensure the forward compatibility. 

## Implementation

The golang implementation of Whisper (v.6) already uses packet codes 0x00 - 0x03. Parity's implementation of v.6 will also use codes 0x00 - 0x03. Codes 0x7E and 0x7F are reserved, but still unused and left for custom implementation of Whisper Mail Server.
