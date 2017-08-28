
## Preamble

    EIP: <to be assigned>
    Title: Add receipt status field to rpc return
    Author: Gary Rong <garyrong0905@gmail.com>
    Type: Standard Track
    Category: Interface 
    Status: Draft
    Created: 2017-08-28
    Requires: 658
    Replaces: none


## Simple Summary

This EIP proposes to add the receipt's status field to `eth_getTransactionReceipt` rpc interface return.

## Abstract

EIP658 proposed to add a status field to receipt which indicates the transaction execution status. But now the field is only used for consensus comparison, the external user can not query the transaction receipt to obtain the contents of the field. So a new field named `status` should be added to the relevant rpc interface return.

## Motivation

At present, the user can not obtain the exact transaction execution status via rpc interface, this will cause great distress to the user.
So it is necessary to add a field in the rpc interface's return value to identify the execution status of the transaction.


## Specification

If `block.number > BYZANTIUM_FORK_BLKNUM`, the `PostState` field in receipt will been replaced with `Status` field, an additional field called `status` will be returned in the `eth_getTransactionReceipt` interface, where `0x0` indicates that the transaction failed, and `0x1` indicates that the transaction was successful, and the `root` field will been discarded.

## Rationale

This allows external user to obtain the transaction execution status clearly. Client implementations will be simpler with this EIP.

## Backwards Compatibility

This EIP is backwards compatible on the main network. 

## Test Cases


## Implementation


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
