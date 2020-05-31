---
eip: <to be assigned>
title: Transaction Deadlines
author: Moody Salem (@moodysalem)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2020-05-31
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Once submitted, pending transactions can stick around for days, while the user's intentions often change after only minutes.
Transactions should have `deadline`s that prevent a transaction from being included in a block after a given timestamp.
This will provide a much-needed improvement to the user experience during times of congestion and volatile gas prices. 

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
Transactions currently have no way to specify for how long they are valid. Once the transaction enters the network's mempool,
it is impossible to forget the transaction. The only current option is to replace the transaction by submitting another
transaction with the same nonce and a higher gas price. However, this is not a deterministic replacement.
Nodes can still include the previously submitted transaction with the lower gas price.
If the transaction appears to be dropped from the mempool (e.g. does not show up in Etherscan),
there is still no guarantee that the transaction will not be included in a future block.
This creates a number of UX issues for pending transactions.

To solve this, transactions should expire after a user specified timestamp. 
This enables the wallet UX to determine that a transaction previously signed will never be included into a block.

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
If a user sets a gas price that is too low, a pending transaction may be stuck in their wallet for days.
Later when the user returns to use their wallet again, the wallet is in a state where it cannot be used until the
previous transaction is replaced with a transaction that has a higher gas price. Few users understand how this works.
Transactions should automatically drop from the mempools after a user specified timestamp. This makes it much simpler
for users to retry after sending a transaction with a bad gas price that gets stuck in the mempool. 

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->

Transactions will have one new optional parameter:

- `DEADLINE`: the maximum block timestamp of a block that can include the transaction, in seconds

Any block that includes transactions with `DEADLINE` > `block.timestamp` will not be considered valid.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
This is one small usability improvement to the situation we see in many dApp support channels, where users end up with
stuck transactions due to highly volatile gas prices. For example, a user may submit a transaction with a "slow" gas price
just before congestion begins, and may not understand that transactions must be ordered by their nonce. When they submit
their next transaction, they are confused that the old and new transaction have been pending for days, even if they
select a much higher gas price for the second transaction.

This partially solves the UX problem by time-boxing how long this situation may continue. Wallets may choose to treat certain
operations as 'hot' operations, or may detect `deadline` parameters from TX arguments and automatically insert them into
the transaction, to significantly improve the UX. Users will no longer have to do the replace by fee dance that is required
once you are stuck in this situation, and will not have to pay gas to cancel transactions they no longer care about,
which will also free up block capacity. And finally, nodes can easily decide whether to drop old pending transactions from the mempool.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
Transactions that do not specify the `DEADLINE` parameter will behave the same as transactions before the EIP.

This is soft-fork compatible; i.e. nodes following pre-EIP rules will always accept blocks validated by post-EIP rules. 

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

TODO

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->

TODO

## Security Considerations
<!--All EIPs must contain a section that discusses the security implications/considerations relevant to the proposed change. Include information that might be important for security discussions, surfaces risks and can be used throughout the life cycle of the proposal. E.g. include security-relevant design decisions, concerns, important discussions, implementation-specific guidance and pitfalls, an outline of threats and risks and how they are being addressed. EIP submissions missing the "Security Considerations" section will be rejected. An EIP cannot proceed to status "Final" without a Security Considerations discussion deemed sufficient by the reviewers.-->

For security considerations, here are some scenarios to consider:

- No timestamp: Same security considerations are current transactions
- Happy path: single pending TX with `deadline` in future
- Invalid TX: TX submitted with `deadline` in past
- Pending TX chain: Multiple TXs submitted with `deadline` in future, increasing nonces-miners can include any of the valid transactions. 
    If a TX is dropped due to `deadline` from the in the middle of the chain, it has no effect on the following transactions. 
- Multiple competing TXs: Multiple TXs submitted with `deadline`s in future and same nonce-miners can include any of the valid transactions 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
