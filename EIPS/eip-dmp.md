---
eip: <to be assigned>
title: Deflationary Monetary Policy
author: @flyingauklet >
discussions-to: <URL>
status: Draft-
type: Standards Track
category: Core
created: 2019-03-15
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->
This is the suggested template for new EIPs.

Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

The title should be 44 characters or less.

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
A short (~200 word) description of the technical issue being addressed.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
*An "Era" is defined as the number of blocks containing a given production rate.*

The proposed mining rewards on the Ethereum Network are as follows:

* Era 1 (blocks 1 - 5,000,000)

    * A "static" block reward for the winning block of 5 ETH

    * An extra reward to the winning miner for including uncles as part of the block, in the form of an extra 1/32 (0.15625ETH) per uncle included, up to a maximum of two (2) uncles. 

    * A reward of up to 7/8 of the winning block reward (4.375ETH) for a miner who has mined an uncled block and has that uncle included in the winning block by the winning miner, up to a maximum of two (2) uncles included in a winning block.

* Era 2 (blocks 5,000,001 - 10,000,000)

    * A "static" block reward for the winning block of 4 ETH

    * An extra reward to the winning miner for including uncles as part of the block, in the form of an extra 1/32 (0.125ETH) per uncle included, up to a maximum of two (2) uncles. 

    * A reward of 1/32 (0.125ETH) of the winning block reward for a miner who has mined an uncled block and has that uncle included in the winning block by the winning miner, up to a maximum of two (2) uncles included in a winning block.

    * Era 2 represents a reduction of 20% of Era 1 values, while also reducing uncle rewards to uncle miners to be the same value as the reward to the winning miner for including the uncle(s).

* Era 3+

    * All rewards will be reduced at a constant rate of 20% upon entering a new Era. 

    * Every Era will last for 5,000,000 blocks. 

## Rationale
Why this 5M20 model:

* Minimizes making the first adjustment too "exceptional." Other than equalizing all uncle rewards at block 5M, the changes/reductions to supply over time are equal. 

* The model is easy to understand. Every 5M blocks, total reward is reduced by 20%.

* Uncle inclusion rates through block 5M will likely remain at around the 5%. Because of this, once block 5M is reached, in the worst case scenario (supply wise, which assumes two uncles included every block in perpetuity) the total supply will not exceed 210.7M ETH. Should the network remain as efficient in its ability to propagate found blocks as it has in Era 1 (5.4% uncle rate), the total supply will not be less than 198.5M ETH. This provides for an incentive to miners and client developers to maintain high standards and maintenance of their hardware and software they introduce into the network.

* The 5M model provides a balance between providing an acceptable depreciating distribution rate for rewarding high risk investment into the system and maintaining an active supply production over time. Maintaining this future supply rate keeps the potential price of the ethereum token suppressed enough to ensure transaction prices can remain lower than if the supply were to reduce to zero at an earlier date. This serves as a "blow off valve" for price increases in the case that a dynamic gas model cannot be implemented for the foreseeable future. 

* Having the monetary policy begin at 5M provides a balance between delaying the implementation to provide enough time for code development and testing, and accelerating the implementation to provide an incentive to potential early adopters and high risk investors. Based on community discussion, beginning before block 4M is too soon for development, testing, and implementation of the policy, and later than block 6M is too long to interest many potential early adopters/investors. 

* Not changing the monetary policy of ETH provides no benefit to risk taking early on in the life of the system, speculation wise. It will be difficult for the network to bootstrap its security. While bitcoin has what is considered to be the generally accepted ideal monetary policy, with its 50% reduction every four years, this model is not likely to yield optimal investment for ETH. If ETH were to adopt the bitcoin halving model, it is arguable that too much of the supply would be produced too soon: 50% of the estimated total ETH supply would be mined 75% sooner than traditional bitcoin because of the pre-mine of 72M ETH that was initially created in the genesis block. While the 5M model does not completely eliminate the effects of the premine, since 50% of total estimated production occurs sooner than would the bitcoin model, it makes up for this, to an extent, with its lengthening of the time until 90%, 99% and 100% of bitcoin are mined. The tail end of ETH production is longer and wider than bitcoin. 

* In the current ETH reward schedule, the total reward for uncles is higher than the reward received by the miner who also includes uncles. In this state, a miner is significantly diluting the value of his reward by including these uncled blocks. By equalizing the rewards to uncle block miners with the rewards to miners who include an uncle block, the reward structure is more fairly distributed. In addition, equalizing the uncle rewards reduces the incentive for miners to set up an ETH "uncle farm," and instead drives them to better secure the network by competing for the latest "real block." 

* Because the rate at which uncled blocks can vary with extreme, reducing the reward for uncle blocks assists considerably with being able to forecast the true upper bound of the total ETH that will ultimately exist in the system. 

* The model is the best attempt at balancing the needs to incentivize high risk investment into the system in order to bootstrap security and create a potential user base, be easy to understand, include a reduction to the rate of production of ETH over time, include an upper bound on supply, provide for a long term production of the ETH token, and allow enough time for development, adoption, and awareness. 

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
* > Once a predetermined number of coins have entered
circulation, the incentive can transition entirely to transaction fees and be completely inflation
free. [6. Intentive. Bitcoin White Paper](https://bitcoin.org/bitcoin.pdf)
* [ECIP-2017](https://github.com/ethereumproject/ECIPs/blob/master/ECIPs/ECIP-1017.md)


## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
