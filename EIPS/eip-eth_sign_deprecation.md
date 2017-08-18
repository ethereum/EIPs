## Preamble

    EIP: <to be assigned>
    Title: Deprecate eth_sign in favor of methods that signing tools can decipher.
    Author: Micah Zoltu <micah@zoltu.net>
    Type: Standard Track
    Category Interface
    Status: Draft
    Created: 2017-08-18


## Simple Summary
Deprecate the `eth_sign` JSON-RPC method and replace it with several new methods that allow users to sign specific data types.


## Abstract
`eth_sign` has the problem that when a signing tool presents the message to the user, it is an opaque byte array, usually just a hash.  This means that the user must trust that the dApp requesting the signature is not doing anything malicious and they are not under some form of attack such as a MITM attack.  As state channels become more common, this becomes a bigger problem as non-transaction signed messages are used to transact on Ethereum.  This EIP deprecates the implementation and usage of `eth_sign` and replaces it with several new methods that allow the caller to pass the raw data to be signed to the signing tool so that the signing tool can meaningfully display details to the end-user, much like how signing tools currentyl display transaction data to the user when prompting them to sign.


## Motivation
Currently, users have no way of knowing what they are signing when they are signing a non-transaction message.  This not only is an immediate risk to users by requiring them to extend their trust network to not only the dApp in question but also the infrastructure on which the dApp runs but it also trains users to get used to signing arbitrary messages without knowledge of their contents.

The current signing method also does not have a mechanism for preventing dApps from requesting signing of an Ethereum transaction, which has lead some implementations to apply a hard-coded prefix to all messages being signed.  While this hard-coded prefix does prevent the signing of Ethereum transactions via the `eth_sign` method, it doesn't prevent the signing of state channel updates and it cripples the user's ability to sign arbitrary messages that they _intend_ to sign (e.g., a string).


## Specification
### `eth_sign(message: bytesAsString)`
This method will be marked as *deprecated* in current clients and eventually removed in some future version.  It is up to the individual clients to decide how best to convey this information to users and dApp developers and also up to individual clients to decide when to remove the deprecated method.  New clients should avoid implementing this method unless it is necessary for backward compatibility.

### `eth_signString(message: string): string`
#### Parameter: Message
A UTF-8 string of arbitrary length.  It will be interpreted as-is and will not be mutated before being hashed for signing.
#### Returns
A signature (using the private key chosen by the signing tool) of the keccak256 hash of the bytes that make up the provided string.  The format of the result will be a string containing a `0x` prefixed hex encoded byte array containing the signature's `r`, `s` and `recoveryParam + 27`.

#### Pseudocode implementation
```
fun eth_signString(message: string): string {
  // TODO: present `message` to user as a UTF-8 string as part of signing prompt
  messageBytes = message.toByteArray('utf-8')
  hash = keccak256(messageBytes)
  signature = secp256k1.sign(privateKey, hash)
  rHex = padAsHex(signature.r, 64)
  sHex = padAsHex(signature.s, 64)
  vHex = padAsHex(signature.recoveryParam + 27, 2)
  return `0x{rHex}{sHex}{vHex}`
```

### `eth_signNumber(value: string): string`
#### Parameter: value
A 256-bit unsigned numeric value, encoded as a hex string with a leading `0x` prefix.  This should conform to the Ethereum JSON-RPC standard for encoding QUANTITIES (strip leading zeros, etc.).
#### Returns
A signature (using the private key chosen by the signing tool) of the keccak256 hash of the bytes that make up the provided value (as a 256-bit number).  The format of the result will be a string containing a `0x` prefixed hex encoded byte array containing the signature's `r`, `s` and `recoveryParam + 27`.

#### Pseudocode implementation
```
fun eth_signNumber(value: string): string {
  number = parseBigInt(value, 'hex')
  // TODO: present `number` to user as a 256-bit number as part of signing prompt
  bytes = number.toByteArray()
  hash = keccak256(bytes)
  signature = secp256k1.sign(privateKey, hash)
  rHex = padAsHex(signature.r, 64)
  sHex = padAsHex(signature.s, 64)
  vHex = padAsHex(signature.recoveryParam + 27, 2)
  return `0x{rHex}{sHex}{vHex}`
```

### `eth_signBytes(prefix: string, value: string): string`
#### Parameter: prefix
An arbitrary length non-empty UTF-8 string provided by the signing tool that will be prefixed to the byte array prior to signing that will be presented to the user as part of the signing process.  Tools should encourage users to validate that the prefix aligns with what they expect from the dApp.  For example, if the dApp they are using is "GamblingSiteA" and the prefix is "ExchangeSiteB State Channel Update" then the user should _not_ sign the message.
#### Parameter: value
An arbitrary length byte array of data that needs to be signed.  It will be interpreted as-is and not mutated outside of the prescribed prefix addition.
#### Returns
A signature (using the private key chosen by the signing tool) of the keccak256 hash of the UTF-8 bytes of `prefix`, followed by the sentinal `0xFF0000FF`, followed by the provided bytes.  The format of the result will be a string containing a `0x` prefixed hex encoded byte array containing the signature's `r`, `s` and `recoveryParam + 27`.

#### Pseudocode implementation
```
fun eth_signBytes(prefix: string, value: string): string {
  // TODO: present `prefix` to user as a UTF-8 string as part of signing prompt
  prefixBytes = prefix.toByteArray('utf-8')
  sentinelBytes = [0xff, 0x00, 0x00, 0xff]
  bytes = hexStringToBytes(value)
  bytesToHash = concatenate(prefixBytes, sentinelBytes, bytes)
  hash = keccak256(bytesToHash)
  signature = secp256k1.sign(privateKey, hash)
  rHex = padAsHex(signature.r, 64)
  sHex = padAsHex(signature.s, 64)
  vHex = padAsHex(signature.recoveryParam + 27, 2)
  return `0x{rHex}{sHex}{vHex}`
```


## Rationale
This strategy has worked well for `eth_signTransaction` and has allowed signing tools to build custom UIs around transaction signing that allow the user to validate that what they are signing is in fact what they intended to sign.  We have chosen to follow the defacto standard JSON-RPC types for passing QUANTITIES, strings, and signatures to avoid implementors having to implement new utilities for handling the input/output.


## Backwards Compatibility
This EIP deprecates `eth_sign`, though it does not explicitly remove it yet.  It is left up to node implementations to decide on exact strategy for removal of `eth_sign`, and it is up to clients to switch away from using `eth_sign` as soon as the new methods are implemented by clients.  It is expected that nodes will likely leave `eth_sign` in for an extended period of time to facilitate a smooth transition, and only remove it after they have given end-users enough warning about it going away and gathered data that suggests it is no longer often used.


## Implementation
- [ ] Parity
- [ ] Geth
- [ ] MetaMask
- [ ] EthereumJ
- [ ] Ledger (Nano/Blue)


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
