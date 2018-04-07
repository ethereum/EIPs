---
eip: 908
title: Reward full nodes and clients
author: James Ray and Micah Zoltu
discussions-to: https://gitter.im/ethereum/topics/topic/5ac8574227c509a774e7901a/eip-reward-full-nodes-and-clients
status: Draft
type: Standards Track
category: Core
created: 2018-03-01
---


## Simple Summary
Provide a reward to full nodes for validating transactions and give a reward to clients for developing the client.

## Abstract
This EIP proposes to make a change to the protocol to provide a reward to full nodes for validating transactions and thus providing extra security for the Ethereum network, and a reward to clients for providing the software that enables Ethereum to function. Reward mechanisms that are external to being built in to the protocol are beyond the scope of this EIP. Such extra-protocol reward methods include state channel payments for extra services such as light client servers providing faster information such as receipts; state channel payments for buying state reads from full nodes; archival services (which is only applicable to future proposed versions of Ethereum with stateless clients); and tokens for the client and running full nodes. With a supply cap the issuance can be prevented from increasing indefinitely.

## Motivation
Currently there is a lack of incentives for anyone to run a full node, while joining a mining pool is not really economical if one has to purchase a mining rig (several GPUs) now, since there is unlikely to be a return on investment by the time that Ethereum transitions to hybrid Proof-of-Work/Proof-of-Stake, then full PoS. Additionally, providing a reward for clients gives a revenue stream that is independent of state channels, which are less secure, although this insecurity can be offset by mechanisms such as insurance, bonded payments and time locks. Rationalising that investors may invest in a client because it is an enabler for the Ethereum ecosystem (and thus opening up investment opportunities) may not scale very well, and it seems that it is more sustainable to monetize the client as part of the service(s) it provides.

## Specification
Micah: "when a client signs a transaction, it attaches a user agent to the signature. This could then be used to send some amount of ETH to the author of that user agent." In other words, some amount of ETH could be sent to the organization that develops the client (e.g. Parity, the Ethereum Foundation, etc.), when the transaction is processed (similar to mining rewards). The user agent would contain the information needed to send an amount of ETH to the full node operator and the client developer orgnanisation, which are addresses held by these parties and the amounts to add. Full nodes would need to add to their set up to add the address to receive ETH after validating transactions. These fields could be read-only, or immutable, so that someone can't overwrite them with another address, thus preventing one possible attack.

Alternatively, the full node validator could insert their address (or it could be automatically extracted from the execution environment) after executing the transaction. To prevent the miner getting a double-dose of transaction fees, assert that the full node validator address is not the same as the miner's address. It may also make sense to allocate the rewards for validation not in the same block as the transactions, but multiple blocks later. The details of how these two rewards could be made may be subject to change. The actual amounts are subject to data analysis as discussed below.

The issuance can be prevented from increasing indefinitely with a supply cap as in [this EIP-issue](https://github.com/ethereum/EIPs/issues/960), which includes reducing the rewards for miners (or other participants as in [sharding](https://ethresear.ch/t/sharding-phase-1-spec/1407) and [Casper](https://github.com/ethereum/research/tree/master/papers)), and in the long-run having no block rewards and just transaction fees, with Ether burnt e.g. from slashing participants in sharding and Casper and [lost or stuck](https://github.com/ethereum/wiki/wiki/Major-issues-resulting-in-lost-or-stuck-funds) [funds](https://github.com/ethereum/EIPs/pull/867).

## Rationale

Discussion began at https://ethresear.ch/t/incentives-for-running-full-ethereum-nodes/1239. [Micah stated](https://ethresear.ch/t/incentives-for-running-full-ethereum-nodes/1239/4):
> The first most obvious caveat is that end-users would be incentivized to put an address of their own down as the user agent. Initial thinking on this is that there are few enough users advanced enough to run a custom client so the losses there would be minimal, and client developers are incentivized to not make the user agent string configurable because it is how they get paid. Also, presumably the per-transaction user-agent fee would be small enough such that the average user probably won’t care enough to hack their client to change it (or even switch clients to one that lets the user customize the user agent), usability and simplicity matter more to most. There is a concern that most transactions are coming in through third party Ethereum nodes like Infura or QuikNode and they have incentive and capability to change the user agent.

Obviously, creating such an incentive to centralize full nodes is not desirable. zk-STARKs may help with this, where miners or Casper block proposers could submit a zk-STARK to prove that they executed the transaction, and reduce the cost of validation. However, zk-STARKs aren't performant enough yet to use in the blockchain. zk-SNARKs aren't transparent, so aren't suitable for including in-protocol on a public blockchain. Further research is needed to find a solution for this problem. Micah continued:

> I’m tempted to suggest “lets wait and see if user-agent spoofing becomes a meaningful problem before trying to fix it”, since the worst it can do is put is right back where we are now with no incentives for client development.
Something to consider is that the user agent fee could be used to bribe miners by putting the miner address in instead. Once again, I’m tempted to try it out first (unless someone has better ideas) and see how things go because it is a very high coordination cost to actually bribe miners via user agent (since you don’t know who will mine the block your transaction ends up in), and there is no common infrastructure/protocol for broadcasting different transactions to different miners.

One simple way to prevent bribing miners or miners attempting to validate the transaction in the blocks that they mine is to block miners receiving validation rewards for the blocks that they mine. One problem with this is that a miner could run a full node validator using a different address with the same computer, and just cache the result of their execution and use it for the full node validator. I'm not sure how you would prevent this, but perhaps you could using IP address tracking (similarly asserting that the IP address of a full node validator isn't the same as the miner) which would add additional complexity to the protocol, but this could also be hacked with dynamic IPs and VPNs.

The amount of computation to validate a transaction will be the same as a miner, since the transaction will need to be executed. Thus, if there would be transaction fees for validating full nodes and clients, and transactions need to be executed by validators just like miners have to, it makes sense to have them calculated in the same way as gas fees for miners. This would controversially increase the amount of transaction fees a lot, since there can be many validators for a transaction. In other words, it is controversial whether to provide the same amount of transaction fee for a full node validator as for a miner (which in one respect is fair, since the validator has to do the same amount of computation), or prevent transaction fees from rising much higher, and have a transaction fee for a full node as, say, the transaction fee for a miner, divided by the average number of full nodes validating a transaction. The latter option seems even more controversial (but is still better than the status quo), since while there would be more of an incentive to run a full node than there is now with no incentive, validators would be paid less for performing the same amount of computation.

And as for the absolute amounts, this will require data analysis, but clearly a full node should receive much less than a miner for processing a transaction in a block, since there are many transactions in a block, and there are many confirmations of a block. Data analysis could involve calculating the average number of full nodes verifying transactions in a block. Macroeconomic analysis could entail the economic security benefit that full nodes provide to the network.

Now, as to the ratio of rewards to the client vs the full node, as an initial guess I would suggest something like 99:1. Why such a big difference? Well, I would guess that clients spend roughly 99 times more time on developing and maintaining the client than a full node user spends running and maintaining a full node. During a week there might be several full-time people working on the client, but a full node might only spend half an hour (or less) initially setting it up, plus running it, plus electricity and internet costs. Full node operators probably don't need to upgrade their computer (and buying a mining rig isn't worth it with Casper PoS planning on being implemented soon).

However, on further analysis, clients would also get the benefit of a large volume of rewards from every full node running the client, so to incentivise full node operation further, the ratio could change to say, 4:1, and of course could be adjusted with even further actual data analysis, rather than speculation.

Providing rewards to full node validators and to clients would increase the issuance. In order to maintain the issuance at current levels, this EIP could also reduce the mining reward (despite being reduced previously with the Byzantium release in October 2017 from 5 ETH to 3 ETH), but that would generate more controversy and discusssion.

Another potential point of controversy with rewarding clients and full nodes is that the work previously done by them has not been paid for until now (except of course by the Ethereum Foundation or Parity VCs funding the work), so existing clients may say that this EIP gives an advantage to new entrants. However, this doesn't hold up well, because existing clients have the first mover advantage, with much development to create useful and well-used products.

<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

Introducing in-protocol fees is a backwards-incompatible change, so would be introduced in a hard-fork.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
TODO

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
TODO

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/share-your-work/public-domain/cc0/).
