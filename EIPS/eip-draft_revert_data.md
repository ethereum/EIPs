## Preamble

    EIP: <to be assigned>
    Title: Data structure for the REVERT instruction
    Author: Alex Beregszaszi
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2017-02-06
    Requires: (`REVERT` EIP)

## Simple Summary

Suggested data format for the return value of a `REVERT` instruction.

## Abstract

The `REVERT` instruction is able to abort execution, while retaining data to be returned to the caller. This specification defines a suggested format for encoding error messages to be used by this instruction.

## Motivation

The `REVERT` instruction provides a flexible way to return data. It would be beneficial to define a standardised format in order for clients to make use of this data. Clients, such as Mist, could display the error in a user friendly manner.

Potentially in the future, the *Natural Language Specification* could be extended with a list of error codes for each function.

## Specification

The data to be returned via a `REVERT` instruction is defined as an array, in the following order, consisting of two fields:
- an unsigned number, containing an error code
- an optional UTF-8 encoded string, containing an error message

This array is encoded using *CBOR* (RFC7049).

## Rationale

The reason CBOR is chosen over RLP is its ability to encode multiple data types and the availability of CBOR libraries in a multitude of languages.

## Backwards Compatibility

This change has no effect on contracts created in the past.

## Test Cases

Valid:

`[ 13 ]` -> `81 0d`

`[ 42, "Invalid key"]` -> `82 18 2a 6b 496e76616c6964206b6579`

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
