---
eip: tba
title: Hierarchical store wallet layout
author: Jim McDonald (Jim@mcdee.net)
discussions-to: tba
status: Draft
type: Standards Track
category: ERC
created: 2019-11-26
requires: ?
---

## Simple Summary

A layout for storing an Ethereum wallet within a hierarchical store (e.g. a filesystem).

## Abstract

Ethereum wallets have no standards for their layout in persistent storage, making different wallet implementations incompatible.  This defines a standard for Ethereum wallets that can be followed by wallets to provide a single layout that works across any hierarchical store.

##### Ethereum has the concept of keystores: pieces of data that define a key (see [EIP-2333](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2333.md) for details).  This adds the concept of walletstores: stores that define wallets and how keys in said wallets can be created.

## Motivation

Ethereum wallets often require additional metadata above that in the keystore, for example a hierarchical deterministic wallet needs to know the seed and index of the last account created to generate new accounts.  In addition, wallets themselves can have names.  Standardizing this information and how it is stored allows it to be portable between different wallet providers with minimal effort.

## Specification

There are three elements for a wallet that need to be addressed.  These are defined below.

### Wallet container
The wallet container holds all walletstore and keystore objects.

The wallet container is identified by the wallet's UUID.  It MUST be a string following the syntactic structure as laid out in [section 3 of RFC 4122](https://  tools.ietf.org/html/rfc4122#section-3).

### Walletstore
The walletstore element contains the walletstore and is held within the wallet container.  It is identified by the wallet's UUID.  It MUST be a string following the syntactic structure as laid out in [section 3 of RFC 4122](https://  tools.ietf.org/html/rfc4122#section-3).

### Keystore
The keystore element contains the keystore for a given key and is held within the wallet container.  It is identified by the key's UUID.  It MUST be a string following the syntactic structure as laid out in [section 3 of RFC 4122](https://  tools.ietf.org/html/rfc4122#section-3).

### Hierarchical stores
Hierarchical stores are a common way to store and organize information.  The most common example is the filesystem, but a number of object-based stores such as 

Putting these elements together for a sample wallet with wallet UUID `1f031fff-c51d-44fc-8baf-d6b304cb70a7` and key UUIDs `1302106c-8441-4e2e-b687-6c77f49fc624` and `4a320100-83fd-4db7-8126-6d6d205ba834` gives the following layout:

```
- 1f031fff-c51d-44fc-8baf-d6b304cb70a7
+- 1302106c-8441-4e2e-b687-6c77f49fc624
+- 1f031fff-c51d-44fc-8baf-d6b304cb70a7
+- 4a320100-83fd-4db7-8126-6d6d205ba834
```

## Non-hierarchical stores
Non-hierarchical stores 

```
1f031fff-c51d-44fc-8baf-d6b304cb70a7:1302106c-8441-4e2e-b687-6c77f49fc624
1f031fff-c51d-44fc-8baf-d6b304cb70a7:1f031fff-c51d-44fc-8baf-d6b304cb70a7
1f031fff-c51d-44fc-8baf-d6b304cb70a7:4a320100-83fd-4db7-8126-6d6d205ba834
```

### Iterating over wallets

### Iterating over keys

### Crypto

The `crypto` provided is the secure storage of a secret for wallets that require this information.  For example `hierarchical deterministic` wallets have a seed from which they calculate individual private keys.

The `crypto` section follows the definition described in [EIP-2333](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2333.md).

This element MAY be present if the wallet type requires it.

### Next Account

The `nextaccount` provided is the next account to generate for wallets that require this information.  For example, `hierarchical deterministic` wallets create private keys based on a path that has an incrementing value (the first wallet will be `m/12381/60/0/0`, the second `m/12381/60/1/0`, the third `m/12381/60/2/0` etc.).

This element MAY be present if the wallet type requires it.  If present it MUST be a non-negative integer.

## JSON schema

The walletstore follows a similar format to that of the keystore described in [EIP-2333](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2333.md).

```json
{
    "$ref": "#/definitions/Walletstore",
    "definitions": {
        "Walletstore": {
            "type": "object",
            "properties": {
                "crypto": {
                    "type": "object",
                    "properties": {
                        "kdf": {
                            "$ref": "#/definitions/Module"
                        },
                        "checksum": {
                            "$ref": "#/definitions/Module"
                        },
                        "cipher": {
                            "$ref": "#/definitions/Module"
                        }
                    }
                },
                "name": {
                    "type": "string"
                },
                "nextaccount": {
                    "type": "integer"
                },
                "type": {
                    "type": "string"
                },
                "uuid": {
                    "type": "string",
                    "format": "uuid"
                },
                "version": {
                    "type": "integer"
                }
            },
            "required": [
                "name",
                "type",
                "uuid",
                "version"
            ],
            "title": "Walletstore"
        },
        "Module": {
            "type": "object",
            "properties": {
                "function": {
                    "type": "string"
                },
                "params": {
                    "type": "object"
                },
                "message": {
                    "type": "string"
                }
            },
            "required": [
                "function",
                "message",
                "params"
            ]
        }
    }
}
```

## Rationale

A standard for walletstores, similar to that for keystores, provides a higher level of compatibility between wallets and allows for simpler wallet and key interchange between them.

## Test Cases

### Non-deterministic Test Vector

```json
{
  "name": "Test wallet 1",
  "type": "non-deterministic",
  "uuid": "5d71e10b-6e00-4cab-a5a0-866a5d8843c3",
  "version": 1
}
```

### Hierarchical deterministic Test Vector

Password `'testpassword'`
Seed `0x147addc7ec981eb2715a22603813271cce540e0b7f577126011eb06249d9227c`

```json
{
  "crypto": {
    "checksum": {
      "function": "sha256",
      "message": "8bdadea203eeaf8f23c96137af176ded4b098773410634727bd81c4e8f7f1021",
      "params": {}
    },
    "cipher": {
      "function": "aes-128-ctr",
      "message": "7f8211b88dfb8694bac7de3fa32f5f84d0a30f15563358133cda3b287e0f3f4a",
      "params": {
        "iv": "9476702ab99beff3e8012eff49ffb60d"
      }
    },
    "kdf": {
      "function": "pbkdf2",
      "message": "",
      "params": {
        "c": 16,
        "dklen": 32,
        "prf": "hmac-sha256",
        "salt": "dd35b0c08ebb672fe18832120a55cb8098f428306bf5820f5486b514f61eb712"
      }
    }
  },
  "name": "Test wallet 2",
  "nextaccount": 0,
  "type": "hierarchical deterministic",
  "uuid": "b74559b8-ed56-4841-b25c-dba1b7c9d9d5",
  "version": 1
}
```

## Implementation

A Go implementation of the non-deterministic wallet can be found at [https://github.com/wealdtech/go-eth2-wallet-nd](https://github.com/wealdtech/go-eth2-wallet-nd).

A Go implementation of the hierarchical deterministic wallet can be found at [https://github.com/wealdtech/go-eth2-wallet-hd](https://github.com/wealdtech/go-eth2-wallet-hd).

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

