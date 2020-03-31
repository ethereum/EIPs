---
eip: tbd
title: Escalator fee market change for ETH 1.0 chain
author: Dan Finlay <dan@danfinlay.com>
discussions-to: https://ethresear.ch/t/another-simple-gas-fee-model-the-escalator-algorithm-from-the-agoric-papers/6399
status: Draft
type: Standards Track
category: Core
created: 2020-03-13
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
The current "first price auction" fee model in Ethereum is inefficient and needlessly costly to users. This EIP proposes a way to replace this with a mechanism that allows dynamically priced transaction fees and efficient transaction price discovery.

## Abstract

Based on [The Agoric Papers](https://agoric.com/papers/incentive-engineering-for-computational-resource-management/full-text/).

Each transaction would have the option of providing parameters that specify an "escalating" bid, creating a time-based auction for validators to include that transaction.

This creates highly efficient price discovery, where the price will always immediately fall to the highest bid price, which is not necessarily that user's highest price they would pay.

![escalator algorithm price chart](https://ethresear.ch/uploads/default/original/2X/0/042795efa4c2680d644bc66386cd2984a70293f8.gif)

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
Ethereum currently prices transaction fees using a simple first-price auction, which leads to well documented inefficiencies (some of which are documented in [EIP-1559](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md)) when users are trying to estimate what price will get a transaction included in a block, especially during times of price volatility and full blocks.

EIP 1559 is currently being championed as an improvement for the Ethereum protocol, and while I agree that the gas market is very inefficient, since a change like this will affect all client and wallet implementations, the Ethereum community should make sure to make a selection based on solid reasoning and justifications, which I believe 1559 is currently lacking.

To facilitate a more productive and concrete discussion about the gas fee market, I felt it was important to present an alternative that is clearly superior to the status quo, so that any claimed properties of EIP-1559 can be compared to a plausible alternative improvement.

I suggest the three gas payment algorithms be compared under all combinations of these conditions:

- Blocks that are regularly half full, Blocks that are regularly less than half full, and blocks that repeatedly full in a surprising ("black swan") series.
- Users that are willing to wait for a price that may be below the market rate, vs users who value inclusion urgently and are willing to pay above market rate.

We should then ask:
- Is the user willing to pay the most in a given scenario also likely to have their transaction processed in a time period they find acceptable?
- Are users who want a good price likely to get included in a reasonable period of time? (Ideally within one block)

I believe that under this analysis we will find that the escalator algorithm outperforms EIP-1559 in both normal and volatile conditions, for both high-stakes transactions and more casual users looking for a good price.

While I think a deeper simulation/analysis should be completed, I will share my expected results under these conditions.

### User Strategies Under Various Conditions and Algorithms

| Gas Strategy                                                        | Current Single-Price                                                                                                                                                    | EIP 1559                                                                                                                                                                       | Escalator                                                                                                                                                                                    |
|---------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Blocks regularly half full, user wants urgent inclusion.            | User bids within the range of prices that have been recently accepted, likely over-pays slightly.                                                                       | User bids one price tier over the current rate, and is likely included.                                                                                                        | User bids a range from the low end of recently included to the high end, and is likely included at the lowest rate possible.                                                                 |
| Blocks regularly half full, user willing to wait for a good price.  | User bids below or near the low end of the recently accepted prices, may need to wait for a while. If waiting too long, user may need to re-submit with a higher price. | User bids under or at the current price tier, and may wait for the price to fall. If waiting too long, user may need to re-submit with a higher price.                         | User bids as low as they'd like, but set an upper bound on how long they're willing to wait before increasing price.                                                                         |
| Blocks regularly full, user wants urgent inclusion.                 | User bids over the price of all recently accepted transactions, almost definitely over-paying significantly.                                                            | User bids over the current price tier, and needs to increase their `tip` parameter to be competitive on the next block, recreating the single-price auction price problem.     | User bids over a price that has been accepted consistently, with an escalating price in case that price is not high enough.                                                                  |
| Blocks regularly full, user willing to wait for a good price.       | User bids below the low end of the recently accepted prices, may need to wait for a while. If waiting too long, user may need to re-submit with a higher price.         | User bids under or at the current price tier, and may wait for the price to fall. If waiting too long, user may need to re-submit with a higher price.                         | User bids as low as they'd like, but set an upper bound on how long they're willing to wait before increasing price.                                                                         |
| Blocks regularly under-full, user wants urgent inclusion.           | User bids within or over the range of prices that have been recently accepted, likely over-pays slightly, and is likely included in the next block.                     | User bids at or over the current price tier, and is likely included in the next block.                                                                                         | User submits bid starting within recently accepted prices, is likely accepted in the next block.                                                                                             |
| Blocks regularly under-full, user willing to wait for a good price. | User bids below the low end of the recently accepted prices, may need to wait for a while. If waiting too long, user may need to re-submit with a higher price.         | User bids at or under the current price tier, and is likely included in the next block. If bidding under and waiting too long, user may need to re-submit with a higher price. | User bids as low as they'd like, but set an upper bound on how long they're willing to wait before increasing price, is likely included in the next few blocks at the lowest possible price. |

### User Results Under Various Conditions and Algorithms



## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

**Client-Wide Parameters**
* `INITIAL_FORK_BLKNUM`: TBD

**Transaction Parameters**
The transaction `gasPrice` parameter is now optional, and if excluded can be replaced by these parameters instead:

* `START_PRICE`: The lowest price that the user would like to pay for the transaction.
* `START_BLOCK`: The first block that this transaction is valid at.
* `MAX_PRICE`: The maximum price the sender would be willing to pay to have this transaction processed.
* `MAX_BLOCK`: The last block that the user is willing to wait for the transaction to be processed in.

**Proposal**

For all blocks where `block.number >= INITIAL_FORK_BLKNUM`:

When processing a transaction with the new pricing parameters, miners now receive a fee based off of the following linear function, where `BLOCK` is the current block number:

* IF `BLOCK > MAX_BLOCK` then `TX_FEE = MAX_PRICE`.
* `TX_FEE = START_PRICE + ((MAX_PRICE - START_PRICE) / (MAX_BLOCK - START_BLOCK) * (BLOCK - START_BLOCK))`

As a JavaScript function:
```javascript
function txFee (startBlock, startPrice, maxBlock, maxPrice, blockNumber) {

  if (blockNumber >= maxBlock) return maxPrice

  const priceRange = maxPrice - startPrice
  const blockRange = maxBlock - startBlock
  const slope = priceRange / blockRange

  return startPrice + (slope * (blockNumber - startBlock))
}
```

## Backwards Compatibility

Since a current `gasPrice` transaction is effectively a flat-escalated transaction bid, it is entirely compatible with this model, and so there is no concrete requirement to deprecate current transaction processing logic, allowing cold wallets and hardware wallets to continue working for the forseeable future.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->
The security considerations for this EIP are:
- None currently known.

## Resources
* [Original Magicians thread](https://ethresear.ch/t/another-simple-gas-fee-model-the-escalator-algorithm-from-the-agoric-papers/6399)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).

