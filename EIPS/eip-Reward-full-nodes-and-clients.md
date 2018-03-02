## Preamble

    EIP: to be assigned
    Title: Reward full nodes and clients
    Author: James Ray and Micah Zoltu
    Type: Standard Track
    Category: Core & ERC
    Status: Draft
    Created: 2017-03-01

## Simple Summary
Provide a reward to full nodes for validating transactions and give a reward to clients for developing the client.

<!--## Abstract-->
<!--A short (~200 word) description of the technical issue being addressed.-->

## Motivation
Currently there is a lack of incentives for anyone to run a full node, while joining a mining pool is not really economical if one has to purchase a mining rig (several GPUs) now, since there is unlikely to be a return on investment by the time that Ethereum transitions to hybrid Proof-of-Work/Proof-of-Stake, then full PoS. Additionally, providing a reward for clients gives a revenue stream that is independent of state channels, which are less secure, although this insecurity can be offset by mechanisms such as insurance, bonded payments and time locks. Rationalising that investors may invest in a client because it is an enabler for the Ethereum ecosystem may not scale very well; the investment would be considered as more of a donation.

## Specification
when a client signs a transaction, it attaches a user agent to the signature. This could then be used to send some amount of ETH to the author of that user agent. Additionally, some amount of ETH could be sent to the organization that develops the client (e.g. Parity, the Ethereum Foundation, etc.), when the transaction is processed (similar to mining rewards). The actual amounts are subject to data analysis as discussed below.

## Rationale

Discussion began at https://ethresear.ch/t/incentives-for-running-full-ethereum-nodes/1239/20.

The first most obvious caveat is that end-users would be incentivized to put an address of their own down as the user agent. Initial thinking on this is that there are few enough users advanced enough to run a custom client so the losses there would be minimal, and client developers are incentivized to not make the user agent string configurable because it is how they get paid. Also, presumably the per-transaction user-agent fee would be small enough such that the average user probably won’t care enough to hack their client to change it (or even switch clients to one that lets the user customize the user agent), usability and simplicity matter more to most. There is a concern that most transactions are coming in through third party Ethereum nodes like Infura or QuikNode and they have incentive and capability to change the user agent.
I’m tempted to suggest “lets wait and see if user-agent spoofing becomes a meaningful problem before trying to fix it”, since the worst it can do is put is right back where we are now with no incentives for client development.
Something to consider is that the user agent fee could be used to bribe miners by putting the miner address in instead. Once again, I’m tempted to try it out first (unless someone has better ideas) and see how things go because it is a very high coordination cost to actually bribe miners via user agent (since you don’t know who will mine the block your transaction ends up in), and there is no common infrastructure/protocol for broadcasting different transactions to different miners.

The amount of computation to validate a transaction should be relatively constant, AIUI it just involves computing a verification of the signature (e.g. with ECDSA). Thus, the transaction reward to the validator and client could be fixed.

Now, as to the ratio of rewards to the client vs the full node, as an initial guess I would suggest something like 99:1. Why such a big difference? Well, I would guess that clients spend roughly 99 times more time on developing and maintaining the client than a full node user spends running and maintaining a full node. During a week there might be several full-time people working on the client, but a full node might only spend half an hour (or less) initially setting it up, plus running it, plus electricity and internet costs. Full node operators probably don't need to upgrade their computer (and buying a mining rig isn't worth it with Casper PoS planning on being implemented soon).

However, on further analysis, clients would also get the benefit of a large volume of rewards from every full node running the client, so to incentivise full node operation further, the ratio could change to say, 4:1, and of course could be adjusted with even further actual data analysis, rather than speculation.

And as for the absolute amounts, this will require data analysis, but clearly a full node should receive much less than a miner for processing a transaction in a block, since there are many transactions in a block, and there are many confirmations of a block. Data analysis could involve calculating the average number of transactions in a block and the average number of full nodes verifying transactions in a block. Macroeconomic analysis could entail the economic security benefit that full nodes provide to the network.

Providing rewards to full node validators and to clients would increase the issuance. In order to maintain the issuance at current levels, this EIP could also reduce the mining reward (despite being reduced previously with the Byzantium release in October 2017 from 5 ETH to 3 ETH), but that would generate more controversy and discusssion.

One point of controversy with rewarding clients and full nodes is that the work previously done by them has not been paid for until now (except of course by the Ethereum Foundation or Parity VCs funding the work), so existing clients may say that this EIP gives an advantage to new entrants. However, this doesn't hold up well, because existing clients have the first mover advantage, with much development to create useful and well-used products.

<--!The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.!-->

<!--## Backwards Compatibility-->
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

<!--## Test Cases-->
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

## Implementation
The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/share-your-work/public-domain/cc0/).
