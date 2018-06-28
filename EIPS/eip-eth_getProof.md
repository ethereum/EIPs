---
eip: <to be assigned>
title: eth_getProof 
author: Simon Jentzsch <simon.jentzsch@slock.it>, Christoph Jentzsch <christoph.jentzsch@slock.it>
discussions-to: simon.jentzsch@slock.it
status: Draft
type: Standards Track (Core, Networking, Interface, ERC)
category : Interface
created: 2018-06-24
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->

One of the great feature of Ethereum is the fact, that you can verify all data of the state. But in order to allow verification of accounts outside the client, we need a additional function delivering us the required proof. These proofs are important to secure Layer2-Technologies.


## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->

Ethereum uses MerkleTrees to store the state of accounts and their storage. This allows verification of each value by simply creating a MerkleProof. But currently the eth-Module does not give you access to these proofs. This EIP suggests a additional RPC-Method, which creates MerkleProofs for Accounts and Storage-Values. 

Combined with a stateRoot (from the blockheader) it enables offline verification of any account or storage-value. This allows especially IOT-Devices or even mobile apps which are not able to run a light client to verify responses from a untrusted source.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

In order to create a MerkleProof access to the full state is required. The current RPC-Methods allow a application to access single values (`eth_getBalance`,`eth_getTransactionCount`,`eth_getStorageAt`,`eth_getCode`), but it is impossible to read Information about the MerkleTree storing these values through the standard RPC-Interface.

Today MerkleProofs are already used internally. For example the [Light Client Protocol](https://github.com/zsfelfoldi/go-ethereum/wiki/Light-Ethereum-Subprotocol-%28LES%29#on-demand-data-retrieval) supports a function creating MerkleProof, which is used in order to verify the requested account or storage-data.
Offering these already existing function through the RPC-Interface as well would enable Applications to store and send these proofs to devices which are not directly connected to the p2p-network and still are able to verify the data. 


## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

As Part of the eth-Module, a additional Method called `eth_getProof` should be defined as following:

#### eth_getProof

Returns the account- and storage-values of the specified account including the merkle-proof.  

##### Parameters

1. `DATA`, 20 Bytes - address of the storage.
2. `ARRAY`, 32 Bytes - array of storage-keys which should be proofed and included. See [`eth_getStorageAt`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getstorageat)  
3. `QUANTITY|TAG` - integer block number, or the string `"latest"`, `"earliest"` or `"pending"`, see the [default block parameter](https://github.com/ethereum/wiki/wiki/JSON-RPC#the-default-block-parameter)

##### Returns

`Object` - A account object:

  - `balance`: `QUANTITY` - the balance of the account. See [`eth_getBalance`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getbalance) 
  - `codeHash`: `DATA`, 32 Bytes - hash of the code of the account. For a simple Account without code it will return `"0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"` 
  - `nonce`: `QUANTITY`, - nonce of the account. See [`eth_getTransactionCount`](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactioncount) 
  - `storageHash`: `DATA`, 32 Bytes - SHA3 of the StorageRoot. All storage will deliver a MerkleProof starting with this rootHash.
  - `accountProof`: `ARRAY` - Array of rlp-serialized MerkleTree-Nodes, starting with the stateRoot-Node, following the path of the SHA3 (address) as key. 
  - `storageProof`: `ARRAY` - Array of storage-entries as requested. Each entry is a object with these properties:
  
      - `key`: `QUANTITY` - the requested storage key
      - `value`: `QUANTITY` - the storage value
      - `proof`: `ARRAY` - Array of rlp-serialized MerkleTree-Nodes, starting with the storageHash-Node, following the path of the SHA3 (key) as path. 
      

##### Example


```json
{
  "jsonrpc": "2.0",
  "id": 1,
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
  "jsonrpc": "2.0",
  "result": {
    "accountProof": [
      "0xf90211a...0701bc80",
      "0xf90211a...0d832380",
      "0xf90211a...5fb20c80",
      "0xf90211a...0675b80",
      "0xf90151a0...ca08080"
    ],
    "address": "0x7f0d15c7faae65896648c8273b6d7e43f58fa842",
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
  },
  "id": 1
}
```

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
