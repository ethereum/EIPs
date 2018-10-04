---
eip: 1453
title: A Standard for Tokenized Debt
author: Aaron Diamond-Reivich <aarondia@wharton.upenn.edu>, Gabriel Barros <gbbabarros@gmail.com>, Griffin Anderson <andergri1@gmail.com>
discussions-to: https://github.com/aarondr77/DebtStandard/issues
status: WIP
type: Standards Track
category: ERC
created: 2018-10-03
requires: 721
---

## Simple Summary
The Ethereum community needs a standard for representing debt on the blockchain because most business transactions utilize the tracking of liabilities in order to facilitate interactions that cannot settle using an atomic swap of two assets. The lack of a standard created siloed pools of debt that are not interoperable. The adoption of this standard will allow for the creation of valuable applications and protocols to help users manage user's debt.

## Abstract
From complex transactions like mortgages, to simple transactions like purchasing coffee from Starbucks, there is a period of time when one party has yet to fulfill his/her side of the agreement; that party is in debt. The creation of debt is a method to ensure accountability for these incomplete business transactions.

The Ethereum developer community has adopted the ERC20 and ERC721 token standards as a means of representing assets on the ethereum blockchain. These common standards allow exchanges, wallets, and protocols to facilitate the transfer and custody of these assets. The common interface to enable transfer of ownership of these digital assets is powerful. However, the inclusion of a few optional pieces of data have proven useful as well, namely, token name, symbol, and number of decimals. Incorporating this extra information into the standard makes the aforementioned tools even more powerful.

Although tokens have traditionally been used to represent assets, this is of course not their only use case. Similar to how additional standards have been built on top of the ERC20 token standard, we are proposing an additional standard on top of the ERC721 token standard. Our Debt Standard defines a common interface that is to be implemented by all ERC721 token smart contracts created to represent debt.

By providing this common debt standard, individuals and applications will be able to gain insight into the debt that each token represents in a systematic way - similar to how applications know how to transfer ownership of an ERC20 token. This will allow for the creation of financial management tools that can be used to manage all forms of debt across the ethereum blockchain.

## Motivation
The existing ERC 721 token standard is inadequate for representing debt on the blockchain because, although it does provide a standard for transferring ownership of unique tokens, the standard does not include basic functionality that is common across all debts. Importantly, the ERC 721 token standard does not have a standard for associating a value of debt with each token, nor does it have the necessary functions to gain insight into the what the token represents. Because all forms of debt have a value attached to it, it is beneficial to the ethereum community to agree on a set of basic functions to interact with the value that each debt is worth.

## Specification

### Interface

#### functions

##### fulfill

This function should retrieve information about the debt
and try to fullfil the transfer of value. It can be Ether or ERC223 already deposited
at this contract. It could be Ether being sent with the call, where msg.value must match
the amount owed. Or it could be an ERC20 or ERC721 which will try transferFrom methods, meaning
debtor must have allowed the contract prior to this call.

* @param debtID - is an unique identifier of a debt inside this contract space

```
function fullfill(uint256 debtID) public payable;
```

##### withdraw

This function should transfer the payment of a specific debtID to the ownerOf(debtID)

* @param debtID - is an unique identifier of a debt inside this contract space

```
function withdraw(uint debt) public;
```


##### status

This function should return the status of a debt
based on its time parameters. All created debts are necessarily done by debtor, as such
all are Approved by default. If activation date as passed, it's Materialized. Following,
if due date for fullfiment has passed, it's Defaulted.

* @param debtID - is an unique identifier of a debt inside this contract space

```
function status(uint256 debtID) public view returns (DebtStatus _status);
```

##### info

This function should return the basic static terms of a debt

* @param debtID - is an unique identifier of a debt inside this contract space
```
function info(uint256 debtID) public view returns
(address debtor, address creditor, uint256 amount, address token, uint createdAt, uint validAt, uint defaultedAt);
```

##### calculateFulillment

This function should calculate all specific terms inhenrent to the debt and
return the exact amount one must pay in order to fulfill.

* @param debtID - is an unique identifier of a debt inside this contract space
* @param fulfillmentTime - the period number to check the fulfillment of

```
function calculateFulfillment(uint256 debtID, uint256 fulfillmentTime) public view returns (uint256 amount);
```

##### changeDebtor
This function change the debtor of a debt to msg.sender
It should be used by exchange solutions where their original debtor is
not responsible to pay out the debt anymore.

* @param debtID - is an unique identifier of a debt inside this contract space
* @param newDebtor - the address to make the debtor of all new debt
* @param nonce - a unique uint for this transaction; used to prevent replay attacks
* @param {v,r,s} - ECDSA signature used to verify approval of non-sending party

```
function changeDebtor(
uint256 debtID,
address newDebtor,
uint nonce,
uint8 v,
bytes32 r,
bytes32 s
		)
public
returns (bool success);
```
	
##### changeDebtContractOwner

This function changes the owner of the debt contract to @param newOwner.
It can only be called by the current owner. All future created debt for the
debt contract should default to @param newOwner as the receiver of the payment

* @param debtID - is an unique identifier of a debt inside this contract space
* @param newOwner - the address to make the receiver of all new debt

```
function changeDebtContractOwner (uint256 dbetID, address newOwner) public;
```

#### events

##### Debt Created
```
event DebtCreated(uint indexed subscriptionID, uint indexed debtID, uint referencePeriod);
```

##### Debt Fulfilled
```
event DebtFulfilled(uint indexed subscriptionID, uint indexed debtID);
```

#### State

##### DebtStatus

This user-defined type is used to represent the state of a specific debt.
Approved - An agreement has been made that will result in the debt creation
Materialized - The creditor has upheld his end of the agreement and now the debtor is liable to fulfill his end
Defaulted - The debtor did not uphold his end of the agreement in the agreed upon time
Fulfilled - The debtor fulfilled his terms of the agreement

```
enum DebtStatus { Approved, Materialized, Defaulted, Fulfilled }
```

The above interface should be implemented by all tokens that represent debt of any sort. Additionally, for collateralized debt and interest bearing debt, we propose the following supplemental interfaces.

### Secured Debt
The Secured Standard is used in addition to the debt standard to represent collateralized debt.

#### Events

##### CollateralDeposited
```
event CollateralDeposited(uint indexed reference);
```
##### CollateralWithdrawn
```
event CollateralWithdrawn(uint indexed reference);
```
##### CollateralClaimed
```
event CollateralClaimed(uint indexed reference);
```
#### Functions
##### depositCollateral

This function should enables the deposit of collateral goods for this debt

```
function depositCollateral() public payable;
```
##### withdrawCollateral

This function should allow for return of ownership of collateral
once all debt attached to it is fulfilled

```
function withdrawCollateral() public;
```
##### claimCollateral

This function should transfer the collateral only if debtor defaulted

```
function claimCollateral() public;
```
### Interest

The Interest Standard is used in addition to the debt standard to represent interest bearing debt.
#### Functions

##### amountTowardsPrincipal

This function should return the amount of payments that have been made that has counted against the principal of the debt.

```
function amountTowardsPrincipal() public returns (uint principal);
```

##### totalInterestPaid

This function should return the amount of payments that have been made that has gone towards the interest of the debt.
```
function totalInterestPaid() public returns (uint interest);
```

## Rationale
Each unique debt token is assigned to a unique debt. When that debt is repayed by the borrower, the owner of the token burns his/her debt token in order to receive the payment. This burned token is now an imutable receipt of the fulfilled debt.

Representing the right to claim the payment for a debt as an EIP 721 NFT immiedietly allows the owner of the token to sell the debt through existing protocols like 0x.

The debt standard smart contract can be implemented to accomodate a wide range of business processes. We have tested it out with subscriptions, mortgages, and loans. Because the standard does not dictate the creation of the debt, the developper has the freedom to use this standard across a multitude of different use cases.
## Backwards Compatibility
Backwards Compatible with EIP 721

## Test Cases
WIP

## Implementation
WIP

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
