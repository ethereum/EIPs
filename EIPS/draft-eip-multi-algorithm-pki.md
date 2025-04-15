---
title: Support for transactions signed with non-secp256k1 algorithms
description: This EIP adds a standardized way to support additional algorithms to signed transactions
author: James Kempton (@SirSpudlington)
discussions-to: https://ethereum-magicians.org/t/draft-eip-multi-algorithm-signing-support/23514
status: Draft
type: Standards Track
category: Core
created: 2025-04-12
requires: 2718, 2930, 1559, 4844
---

## Abstract

This EIP introduces a new [eip-2718](./eip-2718.md) type transaction that wraps (contains) another transaction, this EIP nullifies the default signature parameters and appends signature data to the front of the transaction with a selector, this effectively wraps a transactions and swaps out signature data for alternative algorithms and data. It also modifies the ecrecover precompile to be able to decode these additional signature algorithms.

## Motivation

As quantum computers are getting more advanced, several new post-quantum (PQ) algorithms have been designed. These algorithms all contain drawbacks such as large key sizes (>1KiB), large signature sizes or long verification times. These issues make them more expensive to compute and store than the current secp256k1 curve in use (as of 2025-04-12).

This EIP provides a future-proofed solution to the several algorithms by adding a standardized way to represent alternative algorithms within a transaction.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Parameters

| Constant | Value |
| - | - |
| `ALG_TX_TYPE` | `Bytes1(0x07)` |
| `GAS_PER_ADDITIONAL_VERIFICATION_BYTE`| `16` |

### Algorithmic Transaction

This EIP introduces a new [eip-2718](./eip-2718.md) transaction with a `TransactionType` of `ALG_TX_TYPE` and a `TransactionPayload` of the RLP serialization of the `AlgTransactionPayloadBody` defined below:

`[alg_type, signature_info, parent, (additional_info)]`

The field `alg_type` is a unsigned 8-bit integer (uint8) that represents the algorithm used to sign the transaction in the `parent` field. This EIP does not define algorithms for use with this transaction type.

The `signature_info` info field contains information required to verify the signature of the transaction in the `parent` field. This is a byte-array of arbitrary length, which would be passed to the verification function.

The `parent` field contains another [eip-2718](./eip-2718.md) Typed Transaction Envelope, while MUST be able to contain every possible `TransactionType`s, including legacy transactions with a `TransactionType` of `> 0x7f`, the only exception to this rule is the `Algorithmic Transaction` itself, which MUST NOT be placed within itself. These transactions all contain `y_parity`, `r`, `s` values, which MUST be set to `Bytes0()` if wrapped in a `AlgTransactionPayloadBody`, all other values MUST be unchanged from their original values.

If new transaction types are specified they MUST NOT attempt to build off of this EIP but instead MUST include the `y_parity`, `r`, `s` values, this will prevent backwards compatibility issues and ensure that any transaction other than EIP-<TODO-PUT-EIP-NUMBER-HERE> can be safely assumed to be secp256k1.

The Algorithmic Transaction MUST NOT generate a transaction reciept with a `TransactionType` of `ALG_TX_TYPE`, it MUST generate a transaction receipt of the transaction it is wrapping (the tx in the `parent` field). Implementations MUST not be able differentiate between these receipts.

### Algorithm specification

Further algorithms MUST be specified via an additional EIP.

Each type of algorithm MUST specify the following fields:
| Field Name | Description |
|-|-|
|`ALG_TYPE`| The uint8 of the algorithm unique ID |
|`MAX_SIZE`| The maximum size of `signature_info` field in a transaction |
|`GAS_PENALTY`| The additional gas penalty from verification of the signature |

The `GAS_PENALTY` field MUST only account for verification costs, not storage nor signing.

New algorithms MUST also specify how to recover & verify a valid address (`bytes20`) from the `signature_info` field inside the transaction, the verification function MUST follow the following function signature:

`def verify(signature_info: bytes, parent_hash: bytes32) -> boolean, bytes20`

The verify function MUST return `(false, 0x0)` if there was an error recovering a valid address from the signature, otherwise the function MUST return `true` and the address of the signer.

An example of this specification can be found [here](../assets/draft-eip-multi-algorithm-pki/template-eip.md).

### Verification

Implementations MUST consider transactions invalid where `len(tx.signature_info) > alg.MAX_SIZE`.

The validity/processing of the transaction is completed by the function defined below:
```python

def process_transaction(tx: Transaction, from_address: bytes20 = None, start_gas = 21000):
  match tx:
    # Verification for other transactions, if `from_address != None`
    # then the verifier MUST NOT attempt to validate the `y_parity`, `r`, `s`
    # parameters. Additionally, the verification function MUST start the initial gas value
    # at `start_gas`.
    ...

    ALG_TX:
      assert(from_address == None)          # Ensure no double-wrapping
      assert(Algorithms[alg_type] != None)  # `Algorithms` is a dictionary containing every defined algorithm

      alg = Algorithms[alg_type]

      assert(len(tx.signature_info) <= alg.MAX_SIZE)

      valid, from_address = alg.verify(tx.signature_info, calculate_signing_hash(wrapped)) # calculate_signing_hash is defined within the wrapped transaction's EIP.
      assert(valid)

      process_transaction(tx.parent, from_address, 21000 + calculate_penalty(tx.signature_info, alg))

```

### Gas calculation

All transactions that use more resources than the secp256k1 curve suffer an additional penalty. This penalty MUST be calculated as follows:
```python
def calculate_penalty(signing_data: bytes, algorithm: int) -> int:
  gas_penalty_base = max(len(signing_data) - 65, 0) * GAS_PER_ADDITIONAL_VERIFICATION_BYTE
  total_gas_pentalty = gas_penalty_base + ALGORITHMS[algorithm].GAS_PENALTY
  return total_gas_pentalty
```

The penalty MUST be added onto the `21000` base gas of each transaction BEFORE the transaction is processed. If the wrapped tx's `gas_limit` is less than to `21000 + calculate_penalty(signing_data, algorithm)` than the transaction MUST be considered invalid and MUST NOT be included within blocks. This transaction also MUST inherit the intrinsics of the wrapped tx's fee structure (e.g. a wrapped EIP-1559 tx would behave as a EIP-1559 tx).

### Modification to `ecrecover` precompile



## Rationale

### Setting `y_parity`, `r`, `s` values to zero rather than removing them

Keeping the `y_parity`, `r`, `s` values inside the transactions keeps the previous parsing, verification and processing logic the same and allows for minimal modification to the other specifications while still preventing excessive space usage.

### Opaque `signature_info` type

As each algorithm has unique properties, i.e. signature recovery and key sizes. A bytearray of dynamic size would be able to hold every permutation of every possible key and signature, this does lead to a DOS vector which the [Gas penalties](#gas-penalties) section solves along with the `MAX_SIZE` parameter.

### Gas penalties

Since having multiple different algorithms results in multiple different signature sizes, and verification costs. Hence, every signature algorithm that is more expensive than the default ECDSA secp256k1 curve, incurs an additional gas penalty, this is to discourage the use of overly expensive algorithms for no specific reason.

The `GAS_PER_ADDITIONAL_VERIFICATION_BYTE` value being `16` was taken from the calldata cost of a transaction, as it is a similar datatype and must persist indefinitely to ensure later verification.

### Not adding the `secp256k1` curve

Having a type for `secp256k1` allows for several iterations of the same object to be present across the network. Additionally the only purpose for this curve would be for prototyping and testing with client teams, as the resultant reciept, logs and state change would be the same as a non-wrapped transaction.

### Not specifing account key-sharing / migration

Allowing a single account to share multiple keys creates a security risk as it reduces the security to the weakest algorithm. This is also out of scope for this EIP and could be implemented via a future EIP.

### Keeping a similar address rather than introducing a new address format

While adding a new address format for every new algorithm would ensure that collisions never happen and that security is not bound by the lowest common denominator, the amount of changes that would have to be made and backwards compatibility issues would be too vast to warrent this.

## Backwards Compatibility

Non-EIP-<TODO-PUT-EIP-NUMBER-HERE> transactions will still be included within blocks and will be treated as the default secp256k1 curve. Therefore there would be no backwards compatibility issues will processing other transactions. However, as a new [eip-2718](./eip-2718.md) transaction has been added non-upgraded clients would not be able to process these transactions nor blocks that include these transactions.

## Test Cases

These test cases do not involve processing other types of transactions. Only the wrapping, unwrapping and verification of these transactions without interfacing with the `parent` tx held inside the main tx.

All the following test cases use the parameters from the example eip specified in the [Algorithm Specification Section](../assets/draft-eip-multi-algorithm-pki/template-eip.md) listed above.

TODO, must be done before EIP enter review stage.

## Security Considerations

Allowing more ways to potentially create transactions for a single account may decrease overall security for that specific account, however this is partially mitigated by the increase in processing power required to trial all algorithms. Even still, adding additional algorithms may need further discussing to ensure that the security of the network would not be compromised.

Having `signature_info` be of no concrete type creates a chance that an algorithms logic could be specified or implemented incorrectly, which could lead to, in the best case, invalid blocks, or at worst, the ability for anyone to sign a fraudulent transaction for any account. This security consideration is delegated to the algorithms specification, therefore care must be taken when writing these algorithm specifications to avoid critical security flaws.

Further security considerations need discussion.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).