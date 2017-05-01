## Preamble

    EIP: <to be assigned>
    Title: Storage of SECP256k1 public keys in ENS
    Author: Nick Johnson <nick@ethereum.org>
    Type: Standard Track
    Category ERC
    Status: Draft
    Created: 2017-05-01
    Requires: 137
    Discussions-To: https://github.com/ethereum/EIPs/issues/620
    
## Abstract
This EIP defines a resolver profile for ENS that permits the lookup of SECP256k1 public keys. This is necessary in order to facilitate ENS lookup for applications such as Whisper.

## Motivation
Whisper and other applications requiring secrecy typically need to obtain a user's public key in order to initiate communication with them. Further, such a mechanism needs to be stanardised in order to be widely compatible across different implementations and clients. In this EIP, we define a simple resolver profile for ENS that permits ENS names to be associated with SECP256k1 public keys.

## Specification
### Resolver profile
A new resolver interface is defined, consisting of the following method:

    function pubkey(bytes32 node) constant returns (bytes32 x, bytes32 y)

The interface ID of this interface is 0xc8690233.

`x` and `y` are the coordinates of an uncompressed SECP256k1 curve point comprising the public key. This can be converted to standard binary representation with `'\x04' + x + y` - that is, the octet 0x04 followed by the x coordinate, followed by the y coordinate.

The `pubkey` resolver profile is valid on both forward and reverse records, but when used on a reverse record, `keccak256(x + y)[:12]` - that is, the Ethereum address of the public key - must be equal to the address the record is associated with.

## Rationale
### Application-specific vs general-purpose record types
Rather than define a 'whisper' record type, we have chosen to define a 'public key' record type. This follows DNS's lead, and the observation that more general record types are more universally useful and adopted. The manner in which the record is to be used is generally clear from the context (Eg, calling application, or URI format), and when ambiguity exists, users can create multiple names to disambiguate.

### Use of uncompressed public keys
Compressed notation for SECP256k1 public keys is available, and shortens keys from 65 bytes to 33 bytes. However, while the first byte in an uncompressed public key is redundant and always set to 0x04 (and hence is omitted here), in a compressed public key it conveys important information, and may be 0x02 or 0x03.

Since the EVM stores data in word-size (32 byte) chunks, no effective space savings are realised from storing compressed public keys. Since uncompressed keys are in more common use throughout Ethereum, we decidede to take the option that provides for easiest integration, and use uncompressed public keys.

## Backwards Compatibility
Not applicable.

## Test Cases
TBD

## Implementation
None yet.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
