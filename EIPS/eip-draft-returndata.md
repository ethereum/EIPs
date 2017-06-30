## Preamble

    EIP: <to be assigned>
    Title: Embedding transaction return data in receipts
    Author: Nick Johnson <nick@ethereum.org>
    Type: Standard Track
    Category Core
    Status: Draft
    Created: 2017-06-30
    Requires: 140
    Replaces: 98


## Abstract
This EIP replaces the intermediate state root field of the receipt with either the contract return data and status, or a hash of that value.

## Motivation
With the introduction of the REVERT opcode in EIP140, it is no longer possible for users to assume that a transaction failed iff it consumed all gas. As a result, there is no clear mechanism for callers to determine whether a transaction succeeded and the state changes contained in it were applied.

Full nodes can provide RPCs to get a transaction return status and value by replaying the transaction, but fast nodes can only do this for nodes after their pivot point, and light nodes cannot do this at all, making a non-consensus solution impractical.

Instead, we propose to replace the intermediate state root, already obsoleted by EIP98, with either the return status (1 for success, 0 for failure) and any return/revert data, or the hash of the above. This both allows callers to determine success status, and remedies the previous omission of return data from the receipt.

## Specification
Option 1: For blocks where block.number >= METROPOLIS_FORK_BLKNUM, the intermediate state root is replaced by `status + return_data`, where `status` is the 1 byte status code, with 0 indicating failure (due to any operation that can cause the transaction or top-level call to revert) and 1 indicating success, and `return_data` is the data returned from the `RETURN` or `REVERT` opcode of the top-level call, and where `+` indicates concatenation.

Option 2: For blocks where block.number >= METROPOLIS_FORK_BLKNUM, the intermediate state root is replaced by `keccak256(status + return_data)`, where `status`, `return_data` and `+` have meanings as described in option 1. Additionally, new wire protocol messages are added for `GetReturnData` and `ReturnData`, permitting nodes to fetch the status and return data for transactions contained in specified blocks.

## Rationale
Option 1 minimises additional complexity in the wire protocol and client synchronisation implementations by embedding all necessary data in the receipt itself, but may complicate the transition process by changing the relevant field from a fixed length hash to a variable length field. The implications of a transaction sender being able to add arbitrary length data to transaction receipts also need close examination from the perspective of gas costing.

Option 2 reduces overhead from data type changes, but introduces extra wire protocol complexity, and another record type for fast and light nodes to synchronise or fetch.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
