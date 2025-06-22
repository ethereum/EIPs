---
eip: 1186
title: RPC-Method to get Merkle Proofs - eth_getProof
author: Simon Jentzsch <simon.jentzsch@slock.it>, Christoph Jentzsch <christoph.jentzsch@slock.it>
discussions-to: https://github.com/ethereum/EIPs/issues/1186
status: Stagnant
type: Standards Track
category: Interface
created: 2018-06-24
requires: 1474
---

## Simple Summary

One of the great features of Ethereum is the fact, that you can verify all data of the state. But in order to allow verification of accounts outside the client, we need an additional function delivering us the required proof. These proofs are important to secure Layer2-Technologies.

## Abstract

Ethereum uses a [Merkle Tree](https://github.com/ethereum/eth-wiki/blob/master/fundamentals/patricia-tree.md) to store the state of accounts and their storage. This allows verification of each value by simply creating a Merkle Proof. But currently, the standard RPC-Interface does not give you access to these proofs. This EIP suggests an additional RPC-Method, which creates Merkle Proofs for Accounts and Storage Values. 

Combined with a stateRoot (from the blockheader) it enables offline verification of any account or storage-value. This allows especially IOT-Devices or even mobile apps which are not able to run a light client to verify responses from an untrusted source only given a trusted blockhash.

## Motivation

In order to create a MerkleProof access to the full state db is required. The current RPC-Methods allow an application to access single values (`eth_getBalance`,`eth_getTransactionCount`,`eth_getStorageAt`,`eth_getCode`), but it is impossible to read the data needed for a  MerkleProof through the standard RPC-Interface. (There are implementations using leveldb and accessing the data via filesystems, but this can not be used for production systems since it requires the client to be stopped first - See https://github.com/zmitton/eth-proof) 

Today MerkleProofs are already used internally. For example, the [Light Client Protocol](https://github.com/zsfelfoldi/go-ethereum/wiki/Light-Ethereum-Subprotocol-%28LES%29#on-demand-data-retrieval) supports a function creating MerkleProof, which is used in order to verify the requested account or storage-data.

Offering these already existing function through the RPC-Interface as well would enable Applications to store and send these proofs to devices which are not directly connected to the p2p-network and still are able to verify the data. This could be used to verify data in mobile applications or IOT-devices, which are currently only using a remote client.


## Specification

As Part of the eth-Module, an additional Method called `eth_getProof` should be defined as follows:

#### eth_getProof

Returns the account- and storage-values of the specified account including the Merkle-proof.  

##### Parameters

1. `DATA`, 20 Bytes - address of the account.
2. `ARRAY`, 32 Bytes - array of storage-keys which should be proofed and included. See [`eth_getStorageAt`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getstorageat)  
3. `QUANTITY|TAG` - integer block number, or the string `"latest"` or `"earliest"`, see the [default block parameter](https://github.com/ethereum/wiki/wiki/JSON-RPC#the-default-block-parameter)

##### Returns

`Object` - A account object:

  - `balance`: `QUANTITY` - the balance of the account. See [`eth_getBalance`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getbalance) 
  - `codeHash`: `DATA`, 32 Bytes - hash of the code of the account. For a simple Account without code it will return `"0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"` 
  - `nonce`: `QUANTITY`, - nonce of the account. See [`eth_getTransactionCount`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactioncount) 
  - `storageHash`: `DATA`, 32 Bytes - SHA3 of the StorageRoot. All storage will deliver a MerkleProof starting with this rootHash.
  - `accountProof`: `ARRAY` - Array of rlp-serialized MerkleTree-Nodes, starting with the stateRoot-Node, following the path of the SHA3 (address) as key. 
  - `storageProof`: `ARRAY` - Array of storage-entries as requested. Each entry is an object with these properties:
  
      - `key`: `QUANTITY` - the requested storage key
      - `value`: `QUANTITY` - the storage value
      - `proof`: `ARRAY` - Array of rlp-serialized MerkleTree-Nodes, starting with the storageHash-Node, following the path of the SHA3 (key) as path. 
      

##### Example


```json
{
  "id": 1,
  "jsonrpc": "2.0",
  "method": "eth_getProof",
  "params": [
    "0x7F0d15C7FAae65896648C8273B6d7E43f58Fa842",
    [  "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421" ],
    "latest"
  ]
}
```

The result will look like this:

```json
{
  "id": 1,
  "jsonrpc": "2.0",
  "result": {
    "accountProof": [
      "0xf90211a...0701bc80",
      "0xf90211a...0d832380",
      "0xf90211a...5fb20c80",
      "0xf90211a...0675b80",
      "0xf90151a0...ca08080"
    ],
    "balance": "0x0",
    "codeHash": "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
    "nonce": "0x0",
    "storageHash": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
    "storageProof": [
      {
        "key": "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
        "proof": [
          "0xf90211a...0701bc80",
          "0xf90211a...0d832380"
        ],
        "value": "0x1"
      }
    ]
  }
}
```

## Rationale

This one Method actually returns 3 different important data points:

1. The 4 fields of an account-object as specified in the yellow paper `[nonce, balance, storageHash, codeHash ]`, which allows storing a hash of the account-object in order to keep track of changes.
2. The MerkleProof for the account starting with a stateRoot from the specified block.
3. The MerkleProof for each requested storage entry starting with a storageHash from the account.

Combining these in one Method allows the client to work very efficient since the required data are already fetched from the db.

### Proofs for non existent values

In case an address or storage-value does not exist, the proof needs to provide enough data to verify this fact. This means the client needs to follow the path from the root node and deliver until the last matching node. If the last matching node is a branch, the proof value in the node must be an empty one. In case of leaf-type, it must be pointing to a different relative-path in order to proof that the requested path does not exist.

### possible Changes to be discussed:

- instead of providing the blocknumber maybe the blockhash would be better since it would allow proofs of uncles-states.
- in order to reduce data, the account-object may only provide the `accountProof` and `storageProof`. The Fields `balance`, `nonce`, `storageHash` and `codeHash` could be taken from the last Node in the proof by deserializing it. 

## Backwards Compatibility

Since this only adds a new Method there are no issues with Backwards Compatibility.

## Test Cases

TODO: Tests still need to be implemented, but the core function creating the proof already exists inside the clients and are well tested.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
