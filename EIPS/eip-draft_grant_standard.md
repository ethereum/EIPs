---
eip: <to be assigned>
title: Grant Standard
author: Arnaud Brousseau (@ArnaudBrousseau), James Fickel (@JFickel), Noah Marconi (@NoahMarconi), Ameen Soleimani (@ameensol)
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2019-04-30
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
This document outlines a standard interface to propose, vote on, and distribute grants.

## Abstract
This standard specifies a way for Ethereum users to propose, vote on, and manage the distribution of grants. It allows for multiple grant recipients to be listed and receive rewards through one smart contract. The author of the contract may specify certain conditions such as requiring atomic grants (i.e. raise all or none), a voting threshold with Ether or other tokens, and grant manager(s) that can release funds over time.


## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->

In short, the motivation is greater social scalability for grants. We believe that a grant standard is necessary to coordinate grant efforts across the Ethereum community. A specified interface will enable wallets, DAOs and other blockchain UI providers to integrate with a broader grants ecosystem.

The current process for grants in the Ethereum ecosystem is for membership organizations like the Ethereum Foundation or MolochDAO (https://github.com/MolochVentures/moloch) to internally weigh and process grants. In the Ethereum Foundation's case, grants lack transparency by not leaving an audit trail of funds sent and the results of votes. In MolochDAO's case, there is transparency and an audit trail, but only members can propose and vote on grants, which limits the scalability of grants efforts. This standard would enable the broader Ethereum community to transparently participate in grants and voluntary governance through voting and awarding funds.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->


NOTE: We use the term `GRAINS` to refer to the smallest denomination of an ERC20 `currency` similar to how `WEI` is used to denote the smallest denomination of Ether.



### Types

#### Grantee
```
struct Grantee {
    uint256 targetFunding;   // Funding amount targeted for Grantee.
    uint256 totalPayed;      // Cumulative funding received by Grantee.
    uint256 payoutApproved;  // Pending payout approved by Manager.
}
```

#### Donor
```
struct Donor {
    uint256 funded;          // Total amount funded.
    uint256 refunded;        // Cumulative amount refunded.
}
```

### Getter Methods

#### manager
Returns the multisig, EOA (External Owned Account), or other address responsible for managing the grant. 
```
function manager() public view returns(address)
```

#### currency
Returns the grant currency. If null, amount is in wei, otherwise address of ERC20-compliant (or other currency) contract.
```
function currency() public view returns(address)
```

#### targetFunding
Returns the grant funding threshold required to begin releasing funds.
```
function targetFunding() public view returns(uint256)
```

#### fundingExpiration
Returns the date after which funding must be complete.
```
function fundingExpiration() public view returns(uint256)
```

#### contractExpiration
Returns the date after which payouts must be complete or anyone can trigger refunds.
```
function contractExpiration() public view returns(uint256)
```

#### grantCancelled
Returns a flag to indicate whether or not grant is cancelled.
```
function grantCancelled() public view returns(bool)
```

#### grantees
Returns Grantee.
```
function grantees(address) public view returns(Grantee)
```

#### donors
Returns Donor.
```
function donors(address) public view returns(Donor)
```

#### getAvailableBalance
Get available grant balance.
```
function getAvailableBalance() public view returns(uint256);
```

#### totalFunding
Cumulative funding donated by donors.
```
function totalFunding() public view returns(uint256);
```

#### totalPayed
Cumulative funding payed to grantees.
```
function totalPayed() public view returns(uint256);
```

#### totalRefunded
OPTIONAL: If refunds permitted, cumulative funding refunded to donors.
```
function totalRefunded() public view returns(uint256);
```

#### pendingPayments
OPTIONAL: If pull payments used, payments approved to grantees but not yet withdrawn.
```
function totalRefunded() public view returns(uint256);
```



#### canFund
Funding status check. true if can fund grant.
```
function canFund() public view returns(bool);
```

### Initialization Methods

#### constructor

Grants are initialized on creation using the constructor. 

```{sol}
constructor(
    address[] memory _grantees,
    uint256[] memory _amounts,
    address _manager,
    address _currency,
    uint256 _targetFunding,
    uint256 _fundingExpiration,
    uint256 _contractExpiration
)
```

### State Modifying Methods

#### fund
Fund a grant proposal. `value` in WEI or GRAINS to fund.

NOTE: This method is not `payable`. When funding with Ether, use fallback function to dispatch the `fund` method. 
```
function fund(uint256 value) public returns (bool);
```

#### approvePayout
OPTIONAL: If managed by a `manager` this method approves payment to a grantee. If using push payouts, will also send payment.

OPTIONAL ARG: Pay to a single `Grantee` when `grantee` address specified otherwise spit payout among `Grantee`s.
```
function approvePayout(uint256 value, address grantee) public returns (bool);
```

#### withdrawPayout
OPTIONAL: If using pull payments, withdraws portion of the contract's available balance.
```
function withdrawPayout(uint256 value, address grantee) public returns (bool);
```

#### approveRefund
OPTIONAL: If refunds permitted, approve refunding a portion of the contract's available balance.

OPTIONAL ARG: If `grantee` address specified, reduce `Grantee`'s  `targetFunding`.
```
function approveRefund(uint256 value, address grantee) public;
```

#### withdrawRefund
Withdraws portion of the contract's available balance to `donor` address.
```
function withdrawRefund(address donor) public returns(bool);
```

#### cancelGrant
Cancel grant and enable refunds.
```
function cancelGrant() public;
```

### Events

#### LogFundingComplete
OPTIONAL: If funding threshold enforced, funding target reached event.
```
event LogFundingComplete();
```

#### LogGrantCancellation
OPTIONAL: If cancellation permitted, Grant cancellation event.
```
event LogGrantCancellation();
```

#### LogFunding
Grant received funding. Logs address of `donor` along with the `value` funded.
```
event LogFunding(address indexed donor, uint256 value);
```

#### LogRefund
Grant refunding funding. Logs address of `donor` along with the `value` refunded.
```
event LogRefund(address indexed donor, uint256 value);
```

#### LogPayment
Grant paying `grantee`. Logs address of `grantee` along with the value payed.
```
event LogPayment(address indexed grantee, uint256 value);
```

#### LogPaymentApproval
OPTIONAL: If using pull payments, manager approving a payment. Logs address of `grantee` along with the value to be payed.
```
event LogPaymentApproval(address indexed grantee, uint256 value);
```

#### LogRefundApproval
OPTIONAL: If refunds permitted, Manager approving a refund. Logs `amount` of refund approved along with the cumulative `totalRefunded`.
```
event LogRefundApproval(uint256 amount, uint256 totalRefunded);
```


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

#### What other options did we leave out while designing the interface above?

The interface separates `signaling` from `voting`. Signals have no impact on the functions of the grant contract, however, are useful for offchain decision making. Signal and voting standards / conventions may be paired with the grant standard to satisfy this need.


* Carbon Vote: https://github.com/EthFans/carbonvote
  * Simple contract to signal, tally offline
  * modified version used in Grant Standard reference implementation

* Poll Standard: http://eips.ethereum.org/EIPS/eip-1417
  * Variety of tally methods

* Voting Standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1202.md
  * Simple fixed weighting of votes

* Security Tokens: https://github.com/HarbourProject/protocol/tree/development/contracts/Voting
  * Tightly coupled with token contract

* DAICO / Interactive Coin Offering: https://ethresear.ch/t/explanation-of-daicos/465, https://medium.com/truebit/an-intro-to-truebits-interactive-coin-offering-e6d1dae36090, https://medium.com/daox/how-daox-works-part-1-a1d2a456cbe7

The standard further delegates `voting` on payouts/refunds to the `manager` which can be an EOA or Contract (e.g. Multisig contract as `manager` or a DAO contract such as Moloch acting as `manager`). See discussion with [@NickSzabo4](https://twitter.com/NickSzabo4/) and [@ameensol](https://twitter.com/ameensol)


<blockquote class="twitter-tweet"><p lang="en" dir="ltr">On-chain pools bring additional trust-minimization properties to cash distributions above doing a bunch of simple 1-to-1 payments. For example prevents payor from discriminating between payees: once sufficient funds are in the pool everybody gets their cash flow.</p>&mdash; Nick Szabo 🔑 (@NickSzabo4) <a href="https://twitter.com/NickSzabo4/status/1173281662718726145?ref_src=twsrc%5Etfw">September 15, 2019</a></blockquote> 

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">You&#39;re right, I should have been more general. The grants *standard* defines the minimum set of functions for pooling resources. Our reference implementation chose &quot;grantees can be cut off&quot;. But you could write the function your way and prevent additional categories of abuse. <a href="https://t.co/eNk6YmRPLH">pic.twitter.com/eNk6YmRPLH</a></p>&mdash; Ameen Soleimani 👹 (@ameensol) <a href="https://twitter.com/ameensol/status/1173317866801770496?ref_src=twsrc%5Etfw">September 15, 2019</a></blockquote>


#### Why do we think the current interface is the best?

The current interface supports managed and unmanaged grants (unmanaged being a completely trustless variety), various funding threshold and expiry schemes, and flexibility to award to multiple grantees and respond if one or more grantees misbehaves. The standard offers flexibility in implementation and a consistent interface.  

#### Why do we think the parts we left out should be left out?

The interface focused on requesting funds, funding, releasing / refunding funds. All other responsibilities are left out of the standard.

Multiple grants are not handled within the standard and are instead managed using a factory contract. See the [reference implementation](https://github.com/NoahMarconi/grant-contracts/) for an example. 



## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->

N/A

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->

[Reference Implementation](https://github.com/NoahMarconi/grant-contracts)

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
[Reference Implementation](https://github.com/NoahMarconi/grant-contracts)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
