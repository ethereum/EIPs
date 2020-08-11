---
eip: <to be assigned>
title: Update Network Block Rewards to Adhere to "Minimum Viable Issuance" Policy
author: Kevin Owocki <kevin@gitcoin.co>
discussions-to: Pull Request
status: Draft
type: Economic
created: 2020-08-11
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Ethereum's monetary policy is "Minimum Viable Issuance to secure the network". Now that [miners are nearly collecting more ETH from fees than blockrewards](https://twitter.com/econoar/status/1293220294396538880?s=20) I believe we should cut block rewards from 2 ETH/block to 1 ETH/block.

This EIP does not change the monetary policy of "Minimum Viable Issuance to secure the network".


## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
Cut block rewards from 2 ETH/block to 1 ETH/block.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Ethereum's monetary policy is "Minimum Viable Issuance to secure the network". Now that [miners are nearly collecting more ETH from fees than blockrewards](https://twitter.com/econoar/status/1293220294396538880?s=20) I believe we should cut block rewards from 2 ETH/block to 1 ETH/block.

This EIP does not change the monetary policy of "Minimum Viable Issuance to secure the network".


## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
Cut block rewards from 2 ETH/block to 1 ETH/block.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
Now that 
1. [miners are nearly collecting more ETH from fees than blockrewards](https://twitter.com/econoar/status/1293220294396538880?s=20) 
2. ETH is up to $400

we should cut block rewards from 2 ETH/block to 1 ETH/block.


## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
N/A

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
N/A

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
TODO

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
The revenue from miners is important for securing the Ethereum network.  While it is very important that the Ethereum mainnet remain secure from 51% attacks (and other attacks), it is also important that issuance adheres to the specified policy of "Minimum Viable Issuance to secure the network". 

Presently, [Ethereum is the most profitable ETHHash cryptocurrency to mine](https://cointelegraph.com/news/cryptocurrency-mining-profitability-in-2020-is-it-possible), and has become doubly so [since fees increased](https://twitter.com/econoar/status/1293220294396538880?s=20).  Because of this, [hashrate has been on an upward trend](https://etherscan.io/chart/hashrate).

If this EIP is accepted, and assuming that (1) the Ethereum price stay on a level or upward trajectory, and (2) gas prices continue to be [higher than 30 gWei at low times + 110 gWei at peak times](https://gitcoin.co/gas/heatmap), there are no major security risks introduced to the network.

If there is rough consensus that this EIP is directionally correct, I believe that a further economic analysis could be performed to prove to what degree the above assumptions (1) and (2) are correct.


## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
