## Preamble

    EIP: <to be assigned>
    Title: Ethereum message signing
    Author: ligi <ligi@ligi.de>
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2017-08-09

## Simple Summary

Standard for message signing with Ethereum accounts.

## Abstract

Messages should not be signed in a raw form directly to prevent unintended signing e.g. of valid transactions. We use a prefix here to prevent the data we sign to be something like a valid transaction.

## Motivation

The need for this EIP came up in a [github issue of go-ethereum](https://github.com/ethereum/go-ethereum/issues/14794). As there was no EIP for this use-case, different incompatible implementations for this use-case emerged. This EIP is intended to formalize how messages are prefixed so implementations for this use-case can be compatible

## Specification

`<varint_prefix_length><prefix><varint_message_length><message>`

To specify the length of prefix and message we use [variable length integer (varint)](https://en.bitcoin.it/wiki/Protocol_documentation#Variable_length_integer) as used in Bitcoin. This is defined as the following:

| Value          | Storage length |	Format                                  |
| -------------- | -------------- |	--------------------------------------- |
| < 0xFD         | 1              | uint8_t                                 |
| <= 0xFFFF      | 3              | 0xFD followed by the length as uint16_t |
| <= 0xFFFF FFFF | 5              | 0xFE followed by the length as uint32_t |
| -              | 9              | 0xFF followed by the length as uint64_t |


## Rationale

WIP

## Test Cases

WIP

## Implementation

WIP

## Links

* [Article on medium from the Metamask team regarding the problem](https://medium.com/metamask/the-new-secure-way-to-sign-data-in-your-browser-6af9dd2a1527)
* [PR in go-ethereum to implement personal_sign](https://github.com/ethereum/go-ethereum/pull/2940)
* [Issue in go-ethereum that is the spark of this standard](https://github.com/ethereum/go-ethereum/issues/14794)


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
