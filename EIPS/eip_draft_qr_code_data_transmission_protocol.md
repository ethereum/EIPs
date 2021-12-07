---
eip: eip_draft_qr_code_data_transmission_protocol
title: QR Code data transmission protocol for the Ethereum wallets
description: QR Code data transmission protocol between wallets and offline signers.
author: Aaron Chen (@aaronisme), Sora Lee (@soralit), ligi(@ligi), Dan Miller(@danjm), AndreasGassmann (@andreasgassmann), xardass(@xardass), Lixin Liu (@BitcoinLixin)
discussions-to: https://ethereum-magicians.org/t/add-qr-code-scanning-between-software-wallet-cold-signer-hardware-wallet/6568
status: Draft
type: Standards Track
category: ERC
created: 2021-12-07
---

## Abstract
This EIP is for proposing the process and data transmission protocol via QR Code between the offline signers and the watch-only wallets

## Motivation
Currently, more and more users would like to use complete offline signers like hardware wallets, mobile phones on offline mode to manage their private keys. In order to sign transactions or data, these offline signers have to work with a watch-only wallet. these watch-only will prepare the data to be signed. The data transmission method between offline signers and watch-only wallets will include QR Code, USB, Bluetooth, and file transfer. Compare with other data transmission method like USB, Bluetooth, and file transfer, the QR Code data transmission have these advantages.

- Transparency and Security: Compared to USB or Bluetooth, users can easily decode the data in QR Code (with the help of some tools), it can let users know what they are going to sign. this Transparency can provide more security.
- Better Compatibility: Compared to USB and Bluetooth, the QR Code data transmission has better compatibility, normally it will not be broken by other software changes like browser upgrade. system upgrade etc.
- Better User experience: The QR Code data transmission can provide a better user experience compared to USB, Bluetooth, and file transfer especially in the mobile environment.
- Smaller attack surface. USB and Bluetooth have a higher attack surface than QR-Codes.

Because of these advantages, the QR Code data transmission is a better choice. But currently, there is no standard for how the offline signer works with the watch-only wallet and how the data should be encoded.
This EIP presents a standard process and data transmission protocol for offline signers to work with the watch-only wallet.

## Specification
**Offline signer**: the offline signer is a device or application which holds the user’s private keys and does not have network access.

**Watch-only wallet**: the watch-only wallet is the wallet that has network access and will interact with the Ethereum blockchain.

### Process:
In order to work with offline signers, the watch-only wallet should follow the following process.
1. The offline signer provides public key information to watch-only wallets to generate addresses and sync balance etc via QR Code.
2. The watch-only wallet generates the unsigned data and sends it to an offline signer to sign it including transactions, typed data, etc via QR Code.
3. The offline signer signs the data and provides a signature back to the watch-only wallet via QR Code.
4. The watch-only wallet gets the signature and constructs the signed data (transaction) and performs the following activities like broadcasting the transaction etc.

### Data Transmission Protocol

Since one QR Code can only contain a limited size of data, the animated QR Codes should be included for data transmission. The [BlockchainCommons](https://github.com/BlockchainCommons/) have published a series data transmission protocol called Uniform Resources (UR). It provides a basic method for encoding data to the animated QR Codes. This EIP will use UR and extend its current definition. For more info about UR, please check out [here](https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-005-ur.md).

[Concise Binary Object Representation(CBOR)](https://datatracker.ietf.org/doc/html/rfc7049) will be used for binary data encoding. [Concise Data Definition Language(CDDL)](https://datatracker.ietf.org/doc/html/rfc8610) will be used for expressing the CBOR.

### Setup watch-only wallet by the offline signer. 
In order to let a watch-only wallet collect information from the Ethereum blockchain, the offline signer should provide public keys to watch-only wallets which will use them to query needed information from the Ethereum blockchain.

In this case, offline signers should provide the extended public keys and derivation path. the UR Type called [crypto-hdkey](https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-007-hdkey.md) will be used to encode these data. and the derivation path will be encoded as [crypto-keypath](https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-007-hdkey.md).

 
#### CDDL for Key Path
The [`crypto-keypath`](https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-007-hdkey.md#cddl-for-key-path) will be used for specifying the key path.

The following specification is written in Concise Data Definition Language(CDDL) for `crypto-key-path`

``` 
; Metadata for the derivation path of a key.
;
; `source-fingerprint`, if present, is the fingerprint of the
; ancestor key from which the associated key was derived.
;
; If `components` is empty, then `source-fingerprint` MUST be a fingerprint of
; a master key.
;
; `depth`, if present, represents the number of derivation steps in
; the path of the associated key, even if not present in the `components` element
; of this structure.
    crypto-keypath = {
        components: [path-component], ; If empty, source-fingerprint MUST be present
        ? source-fingerprint: uint32 .ne 0 ; fingerprint of ancestor key, or master key if components is empty
        ? depth: uint8 ; 0 if this is a public key derived directly from a master key
    }
    path-component = (
        child-index / child-index-range / child-index-wildcard-range,
        is-hardened
    )
    uint32 = uint .size 4
    uint31 = uint32 .lt 2147483648 ;0x80000000
    child-index = uint31
    child-index-range = [child-index, child-index] ; [low, high] where low < high
    child-index-wildcard = []
    is-hardened = bool
    components = 1
    source-fingerprint = 2
    depth = 3
```

#### CDDL for Extended Public Keys
Since the purpose is to transfer public key data, the definition of `crypto-hdkey` will be kept only for public keys usage.

The following specification is written in Concise Data Definition Language [CDDL] and includes the crypto-keypath spec above.
```
; An hd-key must be a derived key.
hd-key = {
    derived-key
}
; A derived key must be public, has an optional chain code, and
; may carry additional metadata about its use and derivation.
; To maintain isomorphism with [BIP32] and allow keys to be derived from
; this key `chain-code`, `origin`, and `parent-fingerprint` must be present.
; If `origin` contains only a single derivation step and also contains `source-fingerprint`,
; then `parent-fingerprint` MUST be identical to `source-fingerprint` or may be omitted.
derived-key = (
    key-data: key-data-bytes,
    ? chain-code: chain-code-bytes       ; omit if no further keys may be derived from this key
    ? origin: #6.304(crypto-keypath),    ; How the key was derived
    ? name: text,                        ; A short name for this key.
)
key-data = 3
chain-code = 4
origin = 6
name = 9

uint8 = uint .size 1
key-data-bytes = bytes .size 33
chain-code-bytes = bytes .size 32
```
If the chain-code is provided is can be used to derive child keys and if the chain code is not provided it is just a solo key and origin can be provided to indicate the derivation key path.

### Sending the unsigned data from the watch-only wallet to the offline signer.
For sending the unsigned data from a watch-only wallet to an offline signer, the new UR type `eth-sign-request` will be introduced for encoding the signing request.

#### CDDL for Eth Sign Request.
The following specification is written in Concise Data Definition Language [CDDL].
UUIDs in this specification notated UUID are CBOR binary strings tagged with #6.37, per the IANA [CBOR Tags Registry](https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml).

```
; Metadata for the signing request for Ethereum.
; 
sign-data-type = {
    type: int .default 1 transaction data; the unsigned data type
}

eth-transaction-data = 1; legacy transaction rlp encoding of unsigned transaction data
eth-typed-data = 2; EIP-712 typed signing data
eth-raw-bytes=3;   for signing message usage, like EIP-191 personal_sign data
eth-typed-transaction=4; EIP-2718 typed transaction of unsigned transaction data

; Metadata for the signing request for Ethereum.
; request-id: the identifier for this signing request.
; sign-data: the unsigned data
; data-type: see sign-data-type definition
; chain-id: chain id definition see https://github.com/ethereum-lists/chains for detail
; derivation-path: the key path of the private key to sign the data
; address: Ethereum address of the signing type for verification purposes which is optional

eth-sign-request = (
    sign-data: sign-data-bytes, ; sign-data is the data to be signed by offline signer, currently it can be unsigned transaction or typed data
    data-type: #3.401(sign-data-type),
    chain-id: int .default 1,
    derivation-path: #5.304(crypto-keypath), ;the key path for signing this request
    ?request-id: uuid, ; the uuid for this signing request
    ?address: eth-address-bytes,            ;verification purpose for the address of the signing key
    ?origin: text  ;the origin of this sign request, like wallet name
)
request-id = 1
sign-data = 2
data-type = 3
chain-id = 4 ;it will be the chain id of ethereum related blockchain
derivation-path = 5
address = 6
origin = 7
eth-address-bytes = bytes .size 20
sign-data-bytes = bytes ; for unsigned transactions it will be the rlp encoding for unsigned transaction data and ERC 712 typed data it will be the bytes of json string.
```

### Offline signers provide the signature to watch-only wallets.
After the data is signed, the offline signer should send the signature back to the watch-only wallet, the new UR type called `eth-signature` is introduced here to encode the data.

#### CDDL for Eth Signature.
The following specification is written in Concise Data Definition Language [CDDL].

```
eth-signature  = (
    request-id: uuid,
    signature: eth-signature-bytes
)
eth-signature-bytes = bytes .size 65; the signature of the signing request (r,s,v)
```

## Rationale
This EIP is using some existing UR types like `crypto-keypath` and `crypto-hdkey` and also introduce some new UR types like `eth-sign-request` and `eth-signature`. There are the following reasons we choose UR for the QR Code data transmission protocol.

#### UR provides a solid foundation for QR Code data transmission. 
- Use the alphanumeric QR code mode for efficiency.
- Include a CRC32 checksum of the entire message in each part to tie them together and ensure the transmitted message has been reconstructed.
- using [Fountain Code](https://en.wikipedia.org/wiki/Fountain_code) for the arbitrary amount of data which can both as a minimal, finite sequence of parts and as an indefinite sequence of parts. It can help a lot for the receiver to extract the data/

#### UR provides the existing helpful types and scalability to new usages.

Currently, UR has provided some existing types like `crypto-keypath` and `crypto-hdkey`, And It is quite easy to add new type and definitions for new usage.

#### UR has an active air-gapped wallet community.
Currently, the UR has an active [airgapped wallet community](https://github.com/BlockchainCommons/Airgapped-Wallet-Community) which moves the UR forward.

Based on the following reasons, in this EIP we are using some existing UR types and propose two new UR types `eth-sign-request` and `eth-signature`.

## Backwards Compatibility
Currently, there is no existing protocol for defining the data transmission via QR Codes. So there are no backward compatibility issues that should be addressed now.

## Test Cases
The reference implementation contains the [test cases](https://github.com/KeystoneHQ/keystone-airgaped-base/tree/master/packages/ur-registry-eth/__tests__).

## Reference Implementation
The reference implementation is in Javascript and available at [https://github.com/KeystoneHQ/keystone-airgaped-base/tree/master/packages/ur-registry-eth]

Metamask has adopted it for the integration with QR-based Signer. https://github.com/MetaMask/metamask-extension/pull/12065

Here is the video to show how it works: https://www.youtube.com/watch?v=1eM53TYG1YA

## Security Considerations
The offline signer should decode all the data from `eth-sign-request` and show them to the user to confirm before signing. It is recommended to provide an address field in the `eth-sign-request`, If it is provided, the offline signer should verify the address is the same as the signing key associated address.


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
