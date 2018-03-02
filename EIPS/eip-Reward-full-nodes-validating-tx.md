To be completed, probably after considerable discussion.

## Preamble

    EIP: <to be assigned>
    Title: Reward for full nodes and clients
    Author: James Ray, Micah Zoltu
    Type: Standard Track
    Category: Core & ERC
    Status: Draft
    Created: 2017-03-01

## Simple Summary
Provide rewards to full nodes validators and clients for validating and processing transactions.

## Abstract
A short (~200 word) description of the technical issue being addressed.

## Motivation
Currently there is a lack of incentives for anyone to run a full node, while joining a mining pool is not really economical if one has to purchase a mining rig (several GPUs) now, since there is unlikely to be a return on investment by the time that Ethereum transitions to hybrid Proof-of-Work/Proof-of-Stake, then full PoS. Additionally, providing a reward for clients gives a revenue stream that is independent of state channels, which are less secure, although this insecurity can be offset by mechanisms such as insurance, bonded payments and time locks. Rationalising that investors may invest in a client because it is an enabler for the Ethereum ecosystem may not scale very well; the investment would be considered as more of a donation.

## Specification
when a client signs a transaction, it attaches a user agent to the signature. This could then be used to send some amount of ETH to the author of that user agent. Additionally, some ETH could be sent to the organization that develops the client (e.g. Parity, the Ethereum Foundation, etc.), when the transaction is processed (similar to mining rewards).

## Rationale

Discussion at https://ethresear.ch/t/incentives-for-running-full-ethereum-nodes/1239/20.

Providing rewards to full node validators and to clients would increase the issuance. In order to maintain the issuance at current levels, this EIP could also reduce the mining reward (despite being reduced previously with the Byzantium release in October 2017 from 5 ETH to 3 ETH), but that would generate more controversy and discusssion.

One point of controversy with rewarding clients and full nodes is that the work previously done by them has not been paid for until now (except of course by the Ethereum Foundation or Parity VCs funding the work), so existing clients may say that this EIP gives an advantage to new entrants. However, this doesn't hold up well, because existing clients have the first mover advantage, with much development to create useful and well-used products.

The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.


## Backwards Compatibility
All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.

## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://
