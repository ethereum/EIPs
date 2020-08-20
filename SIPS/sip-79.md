---
sip: 79
title: Deferred Transaction Gas Tank 
status: WIP
author: Anton Jurisevic (@zyzek), Clément Balestrat (@clementbalestrat), Clinton Ennis (@hav-noms)
discussions-to: <Create a new thread on https://research.synthetix.io and drop the link here> 

created: 2020-08-19
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->
A persistent gas tank allows users to submit transactions to be executed at a later time by keepers, paying those keepers out of the user's balance.

## Abstract
<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->

A new `GasTank` contract will be deployed that does the following:

* Holds a balance of ether for users to pay for deferred transactions
* Allows users to deposit and withdraw their balance
* Listens to current gas prices from an oracle
* Permits approved contracts to spend ether out of the user's balance for an execution at the current gas price, including a configurable keeper fee
* Allows users to set a maximum gas price they are willing to spend for a transaction
* Enables users to delegate privileged operations to other accounts

## Motivation
<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->

There are a number of proposed operations in the Synthetix ecosystem which require transactions to be executed after a
delay. Such operations include:

* Limit orders and other future triggered orders
* Futures contract order confirmations
* Fee reclamation settlements

Users cannot be expected to monitor prices for limit orders, or tediously execute the transaction sequences required
by frontrunning protection.
This gas tank mechanism allows keepers to execute such deferred transactions and be reimbursed for the gas cost of
executing them. It is intended that this will significantly reduce UX friction for users, as they will not have to
execute these advanced operations themselves.
Having a balance in the gas tank will not be required for standard exchange operations that do not need it.

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

Any operation that needs to be deferred and executed by a keeper must measure its own gas consumption, reporting this 
quantity to the gas tank contract at the end of its execution. The gas tank will then consult the latest fast gas price
from [Chainlink](https://feeds.chain.link/fast-gas-gwei), ensure that this does not exceed the user's configured
maximum gas price, and reimburse the keeper from the user's balance, along with a fee to incentivise the execution.

### Rationale

The gas tank addresses the question of incentivising keepers to perform actions for users that it would otherwise be too inconvenient for
them to perform for themelves. Several different incentive schemes were considered.

#### SNX incentives

A gas tank could be avoided altogether by minting SNX to incentivise keepers, but this runs into several issues:

* the responsiveness of keepers is influenced by volatility in the SNX price
* the incentive level has to be set carefully to prevent reward farming
* There are potentially macro-economic consequences, as SNX supply expansion depends upon system demand

#### Synth incentives

Users could deposit synths in their gas tank instead, but this would add additional gas cost to transactions, and
necessitate keepers to exchange their earnings. If keeper incentives are paid in ether, then they need never
top up their own balances in order to continue operating.

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->

#### Least Privilege

Only contracts that absolutely need it should have the ability to invoke this functionality, and therefore the gas tank
contract should verify that those attempting to spend user's ether are the correct contracts known to the [`AddressResolver`](https://github.com/Synthetixio/synthetix/blob/1ed6657a4af2e80d0fcc844ce4e381831ef7b931/contracts/AddressResolver.sol).
Therefore, this contract will need to inherit [`MixinResolver`](https://github.com/Synthetixio/synthetix/blob/bf5ea7a433aaab83b9fbaca92f152a52b07b20c5/contracts/MixinResolver.sol).

#### Upgradeability

The gas tank contract should not operate if the system is suspended, and should itself be pausable for upgrades.
For the same reason, it should have a separated state contract that holds user balances and ether; the two contracts
should retrieve each other's address through the `AddressResolver`.

#### Execution Fee

Each execution by a keeper will be incentivised by flat SCCP-configurable keeper fee, stored as a global system setting.
This should be retrievable from the by a new [`SystemSettings.keeperFee()`](https://github.com/Synthetixio/synthetix/blob/bf5ea7a433aaab83b9fbaca92f152a52b07b20c5/contracts/SystemSettings.sol) function.
This will return the USD value of ether to be awarded to keepers, and should generally be kept as low as possible while
still being incentivising for keepers to operate.

#### Delegation

In order to support delegation of gas tank management, the [`DelegateApprovals`](https://github.com/Synthetixio/synthetix/blob/4beaa8e00c8226646b5a718cc9e5d1f6f864e751/contracts/DelegateApprovals.sol)
contract will need to be updated with a new `canManageGasTankFor` function.

---

### Function API

#### `isApprovedContract`

**Signature:** `function isApprovedContract(bytes32 contractName) returns (bool isApproved)`

Returns true if and only if the provided contract is approved to spend gas for deferred transactions.

#### `approveContract`

**Signature:** `function approveContract(bytes32 contractName, bool approve) external`

Allows a contract to be approved or disapproved to spend gas for deferred transactions.

This function should revert if either:

* `contractName` is not an identifier recognised by the [`AddressResolver`](https://github.com/Synthetixio/synthetix/blob/1ed6657a4af2e80d0fcc844ce4e381831ef7b931/contracts/AddressResolver.sol).
* `msg.sender` is not the contract owner.

#### `balanceOf`

**Signature:** `function balanceOf(address account) external view returns (uint balance)`

Returns the remaining deposited ether in a given account.

#### `depositEtherOnBehalf`

**Signature:** `function depositEtherOnBehalf(address account, uint value) external payable`

Increases an account's ether balance.
This function should revert if either:

* `tx.value != value`
* `account != msg.sender && !DelegateApprovals.canManageGasTankFor(account, msg.sender)`

#### `depositEther`

**Signature:** `function depositEther(uint value) external payable`

Equivalent to `depositEtherOnBehalf(msg.sender, value)`.

#### `withdrawEtherOnBehalf`

**Signature:** `function withdrawEtherOnBehalf(address account, address payable recipient, uint value) external`

Reduces an account's ether balance, remitting the withdrawn ether to the `recipient` address.
This function should revert if:

* `balanceOf(msg.sender) < value`
* `account != msg.sender && !DelegateApprovals.canManageGasTankFor(account, msg.sender)`

#### `withdrawEther`

**Signature:** `function withdrawEther(address payable recipient, uint value) external`

Equivalent to `withdrawEtherOnBehalf(msg.sender, recipient, value)`.

#### `maxGasPriceOf`

**Signature:** `function maxGasPriceOf(address account) external view returns (uint maxGasPriceWei)`

Returns the account's configured maximum gas price in wei.

#### `setMaxGasPriceOnBehalf`

**Signature:** `function setMaxGasPriceOnBehalf(address account, uint maxGasPriceWei) external`

Allows a user to set the maximum gas price that they are willing to pay for any deferred transaction.

This should revert if:

* `account != msg.sender && !DelegateApprovals.canManageGasTankFor(account, msg.sender)`

#### `setMaxGasPrice`

**Signature:** `function setMaxGasPrice(uint maxGasPriceWei) external`

Equivalent to `setMaxGasPriceOnBehalf(msg.sender, maxGasPriceWei)`

#### `currentGasPrice`

**Signature:** `function currentGasPrice() external view returns (uint currentGasPriceWei)`

Fetches the current fast gas price from Chainlink's [Fast Gas / Gwei aggregation](https://feeds.chain.link/fast-gas-gwei),
returning it as a quantity of wei.

#### `currentEtherPrice`

**Signature:** `function currentEtherPrice() external view returns (uint currentEtherPrice)`

Fetches the current ether price from Chainlink's [ETH / USD aggregation](https://feeds.chain.link/eth-usd).

#### `executionCost`

**Signature:** `function executionCost(uint gas) external returns (uint etherCost)`

Returns the cost in ether to spend a given quantity of gas at the current gas price, plus the keeper fee,
plus the execution cost of an invocation of the `spendGas` function.
That is, this returns `gas * currentGasPrice() + SystemSettings.keeperFee() / currentEtherPrice() + cost(spendGas)`.

#### `spendGas`

**Signature:** `function payGas(address spender, address payable recipient, uint gas) external returns (uint etherSpent)`

Allows privileged system smart contracts to reimburse an executing address for executions of a spender's
deferred transactions at the current fast gas price.

Provided there is sufficient balance in the spender's account, and the transaction was executed at a gas price in the
correct range, `executionCost(gas)` of ether will be transferred to the `recipient` address, and deducted from the spender's
balance.

This function should revert if any of the following is satisfied:

* `msg.sender` is not an approved contract
* `balanceOf(spender) < executionCost(gas)`
* `tx.gasprice < currentGasPrice()`
* `maxGasPriceOf(spender) < tx.gasprice`
* The function call is [reentrant](https://docs.openzeppelin.com/contracts/3.x/api/utils#ReentrancyGuard)

### Event API

#### `ContractApproved`

**Signature:** `event ContractApproved(bytes32 contractName, bool approved)`

Records that a contract was approved or disapproved to spend gas.

#### `EtherDeposited`

**Signature:** `event EtherDeposited(address payable indexed spender, uint value)`

Records that a user deposited ether in their gas tank.

#### `EtherWithdrawn`

**Signature:** `event EtherWithdrawn(address indexed spender, address payable indexed recipient, uint value)`

Records that a user withdrew ether from their gas tank.

#### `EtherSpent`

**Signature:** `event EtherSpent(address indexed spender, address payable indexed recipient, uint value, uint gasPrice)`

Records that an executor was transferred a value of ether by a spender to reimburse the
the execution of a deferred transaction at a certain gas price.

#### `MaxGasPriceSet`

**Signature:** `event MaxGasPriceSet(address indexed account, uint maxGasPriceWei)`

Records that an account set its max acceptable gas price in wei.

---

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->

See implementation.

### Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->

| Value | Type | Description |
| `keeperFee` | `uint` | The usd value of ether to pay keepers when they execute a gas-reimbursed deferred transaction |

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
