## Preamble

    EIP: <to be assigned>
    Title: Responsible Disclosure
    Author: Yurii Rashkovskii <yrashk@gmail.com>
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2017-10-07


## Simple Summary

A standard interface for responsible disclosure of smart contract vulnerabilities.

## Abstract

The following standard allows for security researchers to have a standard way to discover
smart contract's responsible disclosure policy and a method of disclosure submission. 

## Motivation

Smart contracts often contain bugs and vulnerabilities. However, there is no
universal way to indicate presence of the responsible disclosure policy and
associated resources. It might be difficult for security researchers to find these.

This standard defines an interface that a smart contract can implement in order
to make such indications.

## Specification

### Methods

#### responsibleDisclosurePolicyURL

Returns the URL of the responsible disclosure policy adhered by the contract operators
with the respect to the contract that implements it.

```js
function responsibleDisclosurePolicyURL() constant returns (string url)
```


#### responsibleDisclosureURL

Returns the URL of the responsible disclosure submission method. MAY include
such schemes as "mailto:", however, it is RECOMMENDED that smart contracts
advertise submission methods that keep the message encrypted while in transport
(for example, use of HTTPS, or mandating encrypting email content).

```js
function responsibleDisclosureURL() constant returns (string url)
```

## Rationale

Implementing responsible disclosure as an interface allows security researchers to quickly identify
the responsible disclosure policy of a smart contract.

The original (unpublished) draft of this proposal contained a method for registration and resolution
of disclosures. However, it was subsequently removed as it could have been used as an indication
of potential vulnerabilities and therefore invite an unwanted attention from those who may be able
to find and exploit those vulnerabilities.

## Backwards Compatibility

Backwards compatible.

## Test Cases

None

## Implementation

None

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
