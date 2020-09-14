---
sip: 85
title: Ether Collateral v0.3
status: Proposed
author: Clinton Ennis (@hav-noms), Jackson Chan (@jacko125)
discussions-to: https://research.synthetix.io/

created: 2020-09-08
requires:
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary

<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->

The first iteration of [Ether collateral](./sip-35.md) allowed borrowers to lock their ETH to borrow sETH. This SIP proposes to introduce borrowing and issuing sUSD against ether collateral (Multi Collateral Synths). This solution allows the synth sUSD supply to grow to meet demand and introduces leverage opportunity and liquidations. The result is a system that augments the Synth supply, enables easier and more efficient access to sX and does not dilute SNX value capture.

## Abstract

<!--A short (~200 word) description of the technical issue being addressed.-->

Ether collateral v0.3 will allow Ether to be locked to mint sUSD. This sUSD debt will be backed by the Ether locked and over-collateralised up to 150%. This allows the supply of synths to be more flexible to meet demand for sUSD, keeping the sUSD peg closer to $1, and the ability for borrowing interest fees to be paid to SNX stakers.

There are interest fees associated with opening an ETH backed sUSD loan, an interest rate (APR) calculated per second based on the block timestamp is calculated on the sUSD amount borrowed. The interest charged (sUSD) on the loan will be paid to SNX Minters into the fee pool when the loan is repaid.

The ETH collateral backing the sUSD loan will be open for liquidations when the collateral value is 150% or less. There will be a liquidation penalty for liquidated loans paid to liquidators.

Initially there will be a supply cap / ceiling of 10m sUSD that can be issued and can be increased via governance and is based on the sUSD peg being maintained.

## Motivation

<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->

The addition of Ether collateral sUSD loans extends the original Ether collateral trial to allow borrowers to issue sUSD and leverage against their ETH. The demand on sUSD synths in the Curve sUSD pool and other yield farming opportunities has seen a premium of 2-5% for sUSD (\$1.02-1.05) above the peg over a number of weeks.

The Synthetix protocol voted to reduce the SNX issuance ratio from 750% to 600% to increase the supply of synths to alleviate the peg deviation but has had limited impact on the \$40m+ shortfall compared to the USDC / USDT pools in the curve pool which causes sUSD to be exchanged at a premium.

Borrowing sUSD against ETH collateral will allow the synth supply to grow by issuing more sUSD supply to meet the demand for sUSD. Having sUSD at a 2-5% premium affects the stability of the base asset for Synthetix Exchange, affecting traders who wish to exchange synths and also over-values other synths that are denominated in sUSD.

The interest rate charged on the sUSD borrowed will be payable to SNX holders into the fee pool which ensures that SNX holders benefit from the growth in sUSD borrowed against ETH.

## Specification

<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->

### Overview

<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->

#### Liquidations

Loans will be open for liquidations when the ETH value (collateral ratio) backing the loan drops below the liqudation ratio. The default liquidation ratio will be at 150%. The ETH price will be read from the `ExchangeRates` contract which is using the Chainlink `ETH-USD` oracle.

The Collateral ratio of a loan can be calculated as: `ETH-USD value * ETH locked as collateral / sUSD loan value + interest fees accrued`.

When loans are liquidated they will incur a liquidation penalty taken out of the remaining ETH collateral.

### Rationale

<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

The rationale of implementing sUSD borrowing using ETH as collateral allows Synthetix to increase the supply of sUSD synths.

Updating the existing Ether Collateral trial to issue sUSD allows borrowers to leverage their ETH for sUSD while maintaining price exposure to ETH. As the loan is denominated in sUSD instead of sETH, it is necessary to introduce a liquidation mechanism for loans that fall below the liquidation ratio determined by the ETH-USD value of the collateral. For example, a loan with a 150% liquidation ratio will require a minimum of $1.50 of collateral value for every $1 of sUSD borrowed.

The liquidation mechanism ensures that the issued sUSD is always fully backed by ETH collateral and can be redeemed for ETH.

#### Liquidations ####

Liquidators can liquidate a loan when the collateral value drops below the liquidation ratio. The default liquidation ratio for ETH collateral is 150%.

The liquidation penalty is payable to liquidators out of the collateral value. For example, when a loan of $1000 is liquidated, the liquidator will recieve `$1000 * 1.10 = $1100` worth of the underlying collateral.

The remaining collateral can be withdrawn by the loan creator after the loan has been liquidated.

#### Partial Liquidations ####

sUSD loans that fall below the liquidation ratio can be partially liquidated to fix the collateral ratio. The liquidation penalty (`default 10%`) will be paid out of the remaining ETH collateral to the liquidator who repays the sUSD.

The amount of sUSD loan that can be liquidated will be capped to the `loan value that needs to be liquidated plus the liquidation penalty` to restore the `collateral value` back to or above the liquidation ratio.

The amount of sUSD that can be liquidated to fix a loan is calculated based on the formula:

- V = Value of ETH Collateral
- D = sUSD loan balance
- t = Liquidation Ratio
- S = Amount of sUSD debt to liquidate
- P = Liquidation Penalty %

\\[
S = \frac{t * D - V}{t - (1 + P)}
\\]

The loan's `collateralAmount` and `loanAmount` will be updated after a partial liquidation to reflect the remaining `collateral amount` and `loan amount` that is outstanding.

### Technical Specification

<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

### EtherCollateral sUSD contract

- Requires permision on sUSD to mint directly. (upgrade to sUSD as `multiCollateralSynth` required)
- Ownable, Pausable
- Configuration
  - interestRate: If updated, all new loans will be opened at the new interestRate: default is 5%.
  - issueLimit: Maximum amount of sUSD that can be issued by the EtherCollateral contract. Default 10m sUSD
  - issuanceRatio: Collaterization ratio. Default 150%
  - issueFeeRate: Minting for creating the loan. Default 0 bips.
  - liquidationPenalty: Penalty paid to liquidators when liquidating loan. Default 10%
  - openLoanClosing: Boolean to allow anyone to close the loans with sUSD.
  - minCollateralSize: Minimum amount of ETH to create loan preventing griefing and gas consumption. Min 1ETH

#### Functions

##### `CreateLoan() payable` function

- Require sUSD to mint does not exceed issueLimit
- Require openLoanClosing to be false
- Issue sUSD to c-ratio (150%)
- Store Loan: account address, creation timestamp, sUSD amount issued

```
    // Synth loan storage struct
    struct SynthLoanStruct {
        //  Acccount that created the loan
        address account;
        //  Amount (in collateral token ) that they deposited
        uint256 collateralAmount;
        //  Amount (in synths) that they issued to borrow
        uint256 loanAmount;
        // When the loan was created
        uint256 timeCreated;
        // ID for the loan
        uint256 loanID;
        // When the loan was paidback (closed)
        uint256 timeClosed;
        // Applicable Interest rate
        uint256 loanInterestRate;
        // last timestamp interest amounts accrued
        uint40 lastInterestAccrued;
    }
```

##### `depositCollateral() payable` function

- Deposit more ETH to an open loan to maintain it's collateral ratio above liquidation

##### `withdrawCollateral() payable` function

- Withdraw ETH from an open loan that is above the 150% collateral ratio. Useful when ETH-USD value increases.

###### `CloseLoan()` function

- Require sUSD loan balance + accrued interest(5%) + minting fee (if applicable 0.5%) in wallet
- Fee Distribution. Deduct interest and transfer to fee pool to be distributed to SNX stakers
- Burn all sUSD loaned via ETH collateral.
- Unlock ETH and send ETH back to loan creator.

##### `liquidateLoan(loanCreatorsAddress, loanID, debtToCover)` function

- Using sUSD will repay off the debt of the loan when the loan's collateral value is below the liquidation ratio.

### sUSD contract

- Upgraded to MultiCollateralSynth
- modifier to allow EtherCollateral-sUSD to issue sUSD
- configuration (or contract resolver) for the EtherCollateralsUSD address

### Synthetix contract

- debtBalanceOf / totalIssuedSynthsExcludingEtherCollateral calculation `totalIssuedSynths() - EtherCollateral.totalIssuedSynths() - EtherCollateralsUSD.totalIssuedSynths().`

### FeePool contract

- `FeePool.recordFeePaid(amount)` external function to record fees to distribute for the open fee period.
- modifier to allow EtherCollateral-sUSD to call `FeePool.recordFeePaid(amount)`

### Test Cases

<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

Test cases for an implementation are mandatory for SIPs but can be included with the implementation.

### Configurable Values (Via SCCP)

<!--Please list all values configurable via SCCP under this implementation.-->

Please list all values configurable via SCCP under this implements

1. Supply cap / debt ceiling - 10m sUSD
2. Interest rate - ~5.0%
3. Minting fee - 0 bps
4. Min Collateral size - 1 ETH
5. Liquidation Deadline - 3 months

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
