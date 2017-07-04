## Preamble

    EIP: <to be assigned>
    Title: Token payouts
    Author: Remco Bloemen <remco@neufund.org>, Marcin Rudolf <marcin@neufund.org >
    Type: Standard Track
    Category ERC
    Status: Draft
    Created: 2017-07-04
    Requires: 20
    Replaces: —


## Simple Summary
An entity may want to distribute goods to token holders. For example a DAO business wants to pay dividends to the token holders. The trivial solution of directly sending tokens to the tokens holder has problems described below. In this EIP we propose a standardized solution to address those problems.

## Abstract
A short (~200 word) description of the technical issue being addressed.

## Motivation
The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.

EIP-20,

Assuming we want to send X Tokens to the current holders of Y Tokens. Some none-solutions are:

* Send them directly: Receivers might not be able to use them (e.g. a smart contract). Also, all the transaction cost is put on the sender, which might be prohibitive.

* Track accrued balances per token: Depending on implementation, this can hurt fungibility of the token.

Extra credit: What if we want to issue the X Tokens in a continuous fashion.

## Prior art

See [this Reddit thread](https://www.reddit.com/r/ethdev/comments/6l4od2/erc20_revenue_sharedividend_examples/).


## Specification
The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (cpp-ethereum, go-ethereum, parity, ethereumj, ethereumjs, ...).

```

    function receiveDividends() {

    }

```


## Rationale
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.

## Backwards Compatibility
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
