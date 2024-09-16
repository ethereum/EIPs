---
title: SSZ Transaction / Receipt proofs
description: Extend transactions / receipt RPC objects with SSZ inclusion proofs
author: Etan Kissling (@etan-status), Gajinder Singh (@g11tech)
discussions-to: https://ethereum-magicians.org/t/eip-ssz-transaction-receipt-proofs/21104
status: Draft
type: Standards Track
category: Interface
created: 2024-09-16
requires: 6404, 6466
---

## Abstract

This EIP defines a mechanism to extend JSON-RPC history methods with inclusion proofs based on [Simple Serialize (SSZ)](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/ssz/simple-serialize.md).

## Motivation

As of [EIP-6404](./eip-6404.md) and [EIP-6466](./eip-6466.md) the Merkle-Patricia Tries (MPT) backing the execution block header's `transactionsRoot` and `receiptsRoot` are migrated to SSZ, allowing transactions and receipts to be identified by their SSZ summary. Extending the JSON-RPC API with SSZ inclusion proofs based on these summaries enables client applications to verify the correctness of response data without fetching full block bodies.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Proof format

An inclusion proof is represented by an object `inclusionProof` containing:

- `transactionsRoot` / `receiptsRoot`: The `transactionsRoot` or `receiptsRoot` from the execution block header corresponding to `blockHash`. Verifying client implementations MUST check that this value matches the block header data.
- `transactionRoot` / `receiptRoot`: The [`hash_tree_root`](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/ssz/simple-serialize.md) of the transaction or receipt object. Verifying client implementations MUST check that JSON-RPC response data matches this root when converted to the [`Transaction`](./eip-6404.md#transaction-container) or [`Receipt`](./eip-6466.md#receipt-container) SSZ container representation.
- `merkleBranch`: An [SSZ Merkle proof](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/ssz/merkle-proofs.md) that proofs `transactionRoot` / `receiptRoot` to be located at `transactionIndex` within `transactionsRoot` / `receiptsRoot`. Verifying client implementations MUST check correctness of this proof. The proof can be verified using [`is_valid_merkle_branch`](https://github.com/ethereum/consensus-specs/blob/ef434e87165e9a4c82a99f54ffd4974ae113f732/specs/phase0/beacon-chain.md#is_valid_merkle_branch).

### Extended JSON-RPC API methods

The following JSON-RPC API methods are extended with an `inclusionProof` object in their response:

- eth_getTransactionByHash
- eth_getTransactionByBlockHashAndIndex
- eth_getTransactionByBlockNumberAndIndex
- eth_getTransactionReceipt

## Rationale

Adding inclusion proofs for transactions and receipts considerably reduces the data required to be fetched when verifying JSON-API responses, enabling more lightweight client application use cases.

Verifiable JSON-API responses can be provided by untrusted servers, potentially improving user privacy. When requests can be distributed across various servers, the ability of a centralized trusted server to profile users by correlating their requests is diminished.

## Backwards Compatibility

A new `inclusionProof` key is added to certain JSON-RPC response dictionaries. As extra keys are typically ignored, no backwards compatibility issues are expected.

## Test Cases

Example `eth_getTransactionByHash` response:

```
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "blockHash": "0xd6f641e25c9b2f1c0202f4ba8e4a77f798813d4ce904230fdbf0f979fe35dd15",
    "blockNumber": "0x37",
    "from": "0xf93ee4cf8c6c40b329b0c0626f28333c132cf241",
    "gas": "0x5208",
    "gasPrice": "0xa42ac",
    "type": "0x0",
    "hash": "0xbb4dc00396e4dfc28776951ed9d7a1feb24990a4c0617707fbe432d7ba098085",
    "input": "0x",
    "nonce": "0x123",
    "to": "0xaf23e04b04fbe15630eadd32a6f27a5a65ea554a",
    "transactionIndex": "0x5b",
    "value": "0xe35fa931a0000",
    "v": "0x60306c",
    "r": "0x67d2507a68571f4cd61a9d0cbbfbe40362acd32072b91b759c9143548e565964",
    "s": "0x58dda901d926603bf6832da69c4aedd01d278f457117b43887afa416b37313f8",
    "inclusionProof": {
      "merkleBranch": [
        "0xcc2fb2cd60830fd6ad17b47aa384fdde757577e506e5a93b870193882252bf78",
        "0x9d7d1a2d49164548f3ae60bdfb09c1ed557d8ae8b057049608e579344e1e6db7",
        "0x0f3f4ce6d7b59ef0d38b392d932e3a8bf436a3f8d04b87a4e574d0a5c01d509f",
        "0xffed37b780a6e37575b9b53eea3dcaeb03263b8cc50b8a4f0af874b4e63cc2aa",
        "0xd1833b209e8cbcb38c0c5a51bf4e65e179128733ccf3252e9e00de445036c0d4",
        "0xca8c77d4779947ca00ee535ceb22f8a625aeb6f6d69d896e50b713ee0e198b82",
        "0xe601a56436c129df77da238af9663b59ad5ec099dd7fe119bc547769f58101d6",
        "0x87eb0ddba57e35f6d286673802a4af5975e22506c7cf4c64bb6be5ee11527f2c",
        "0x26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193",
        "0x506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1",
        "0xffff0ad7e659772f9534c195c815efc4014ef1e1daed4404c06385d11192e92b",
        "0x6cf04127db05441cd833107a52be852868890e4317e6a02ab47683aa75964220",
        "0xb7d05f875f140027ef5118a2247bbb84ce8f2f0f1123623085daf7960c329f5f",
        "0xdf6af5f5bbdb6be9ef8aa618e4bf8073960867171e29676f8b284dea6a08a85e",
        "0xb58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784",
        "0xd49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb",
        "0x8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb",
        "0x8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab",
        "0x95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4",
        "0xf893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f",
        "0x6400000000000000000000000000000000000000000000000000000000000000"
      ],
      "transactionsRoot": "0x87f872755b8cc10fbcd0f20043438b2c0626045edea365628071c7daf2bb3de7",
      "transactionRoot": "0xa2926d4846cf1f52b1e4f79adf3f2ac11f57000000cdc2b357443bb3747a3528"
    }
  }
}
```

## Security Considerations

Only the JSON-RPC data covered by the [`Transaction`](./eip-6404.md#transaction-container) or [`Receipt`](./eip-6466.md#receipt-container) SSZ container can be verified.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
