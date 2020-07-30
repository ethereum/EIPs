---
sip: 54
title: Limit Orders
status: Implemented
author: Tom Howard (@thowar2), Nour Haridy (@nourharidy)
discussions-to: Discord - limit-orders

created: 2020-04-27
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SIP.-->
This SIP adds limit order functionality to the Synthetix exchange, without modifying the core exchange contracts.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
To keep the integrity of the core Synthetix contracts in place, we propose the creation of a separate layer of “advanced mode” trading contracts to enable additional functionality. The primary contract is a limit order contract. The exchange users can place limit orders on it and send the order source amount to it. Additionally, they specify the parameters of limit orders, including destination asset price and execution fees. Limit orders set by the user are executed at the right time by "execution nodes" that recieve the execution fee in exchange.

## Motivation
<!--The motivation is critical for SIPs that want to change Synthetix. It should clearly explain why the existing protocol specification is inadequate to address the problem that the SIP solves. SIP submissions without sufficient motivation may be rejected outright.-->
To increase the flexibility of the Synthetix exchange, limit order functionality is needed so users can effectively trade synthetic assets. While limit orders can be trivial to implement in the case of centralized exchanges, in the case of a DEX such as Synthetix, limit orders can be challenging in terms of security guarantees and trustlessness due to client unavailability.

## Specification
<!--The technical specification should describe the syntax and semantics of any new feature.-->
### SynthLimitOrder Contracts Spec
*NOTES*:
 - The following specifications use syntax from Solidity `^0.5.16`.
 - In order for these contracts to be able to access user SNX tokens, they must approve the proxy contract address for each token individually using the ERC20 approve() function. We recommend a max uint (2^256 - 1) approval amount.

*Order of deployment*:
 1. The `Implementation` contract is deployed
 2. The `ImplementationResolver` contract is deployed where the address of the `Implementation` contract is provided to the constructor as an `initialImplementation`
 3. The `Proxy` contract is deployed with the address of the `ImplementationResolver` provided to the constructor.
 4. `Implementation.initialize()` is called on the `Proxy` address.
---

#### Implementation Contract

The Implementation contract stores no state and no funds and is never called directly by users. It is meant to only receive forwarded contract calls from the Proxy contract.

All state read and write operations on this contract are stored in the Proxy contract state. In the event of an implementation upgrade, the Proxy state would become automatically accessible to the new `Implementation`.

##### Public Variables

###### latestID

A uin256 variable that tracks the highest orderID stored.

###### synthetix

An address variable that contains the address of the Synthetix exchange contract

###### orders

A mapping between uint256 orderIDs and `LimitOrder` structs


##### Structs

###### LimitOrder
```js
struct LimitOrder {
    address payable submitter;
    bytes32 sourceCurrencyKey;
    uint256 sourceAmount;
    bytes32 destinationCurrencyKey;
    uint256 minDestinationAmount;
    uint256 weiDeposit;
    uint256 executionFee;
    uint256 executionTimestamp;
    uint256 destinationAmount;
    bool executed;
}
```

##### Methods

###### initialize

``` js
function initialize(address synthetixAddress, address _addressResolver) public;
```

This method can only be called once to initialize the proxy instance.

###### newOrder

``` js
function newOrder(bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey, uint minDestinationAmount, uint executionFee) payable public returns (uint orderID);
```

This function allows a `msg.sender` who has already given the `Proxy` contract an allowance of `sourceCurrencyKey` to submit a new limit order.

1. Transfers `sourceAmount` of the `sourceCurrencyKey` Synth from the `msg.sender` to this contract via `transferFrom`.
2. Adds a new limit order using to the `orders` mapping where the key is `latestID + 1`. The order's `executed` property is set to `false`.
3. Increments the global `latestID` variable.
4. Requires a deposited `msg.value` to be more than the `executionFee` in order to refund node operators for their exact gas wei cost in addition to the `executionFee` amount. The remainder will be transferred back to the user at the end of the trade.
5. Emits an `Order` event for node operators including order data and `orderID`.
6. Returns the `orderID`.

###### cancelOrder

``` js
function cancelOrder(uint orderID) public;
```

This function cancels a previously submitted and unexecuted order by the same `msg.sender` of the input `orderID`.

1. Requires the order `submitter` property to be equal to `msg.sender`.
2. Requires the order `executed` property to be equal to be `false`.
3. Refunds the order's `sourceAmount` and deposited `msg.value`
4. Deletes the order using from the `orders` mapping.
5. Emits a `Cancel` event for node operators including the `orderID`

###### executeOrder

``` js
function executeOrder(uint orderID) public;
```

This function allows anyone to execute a limit order.

It fetches the order data from the `orders` mapping and attempts to execute it using `Synthetix.exchange()`, if the amount received is larger than or equal to the order's `minDestinationAmount`:

1. This transaction's submitter address is refunded for this transaction's gas cost + the `executionFee` amount from the user's wei deposit.
2. The remainder of the wei deposit is forwarded to the order submitter's address
3. The order's `executed` property is changed to `true`, the `executionTimestamp` property set to `block.timestamp` and `destinationAmount` set to the received amount.
4. `Execute` event is emitted with the `orderID` for node operators 

If the amount received is smaller than the order's `minDestinationAmount`, the transaction reverts.

###### withdrawOrders

``` js
function withdrawOrders(uint[] orderID) public;
```

This function allows the sender to withdraw funds associated with an array of executed orders as soon as the Synthetix fee reclamation window for each of the order has elapsed.

It iterates over each order's data from the `orders` mapping, if each order's `submitter` is equal to `msg.sender`, has the `executed` property equal to `true` and `executionTimestamp + Exchanger.waitingPeriodSecs() < block.timestamp`:

1. The `destinationAmount` of the `destinationCurrencyKey` is transferred to `msg.sender` using `Synth.transferAndSettle()`
2. The order is deleted using from the `orders` mapping.
3. `Withdraw` event is emitted with the `orderID`.

##### Events

###### Order

``` js
event Order(uint indexed orderID, address indexed submitter, bytes32 sourceCurrencyKey, uint sourceAmount, bytes32 destinationCurrencyKey, uint minDestinationAmount uint executionFee, uint weiDeposit)
```

This event is emitted on each new submitted order. Its primary purpose is to alert node operators of newly submitted orders in realtime.

###### Cancel

``` js
event Cancel(uint indexed orderID);
```

This event is emitted on each cancelled order. Its primary purpose is to alert node operators that a previously submitted order should no longer be watched.

###### Execute

``` js
event Execute(uint indexed orderID, address executor);
```

This event is emitted on each successfully executed order. Its primary purpose is to alert node operators that a previously submitted order should no longer be watched.

###### Withdraw

``` js
event Withdraw(uint indexed orderID, address indexed submitter);
```

This event is emitted on each successfully withdrawn order.

---

#### Proxy Contract
The proxy contract receives all incoming user transactions to its address and forwards them to the current implementation contract. It also holds all deposited token funds at all times including future upgrades.

All calls to this contract address must follow the ABI of the current `Implementation` contract.

##### Constructor

```js
constructor(address ImplementationResolver) public;
```

The constructor sets the `ImplementationResolver` to an internal global variable to be accessed by the fallback function on each future contract call.

##### Fallback function

```js
function() public;
```

Following any incoming contract call, the fallback function calls the `ImplementationResolver`'s `getImplementation()` function in order to query the address of the current `Implementation` contract and then uses `DELEGATECALL` opcode to forward the incoming contract call to the queried contract address.

---

#### ImplementationResolver Contract

This contract provides the current `Implementation` contract address to the `Proxy` contract.
It is the only contract that is controlled by an `owner` address. It is also responsible for upgrading the current implementation address in case new features are to be added in the future.

##### Constructor

```js
constructor(address initialImplementation, address initialOwner) public;
```

The constructor sets the `initialImplementation` address to an internal global variable to be access later by the `getImplementation()` method. It also sets the `initialOwner` address to the `owner` public global variable.

##### Public Variables

###### owner

An address variable that stores the contract owner address responsible for upgrading the implementation contract address.


##### Methods

###### changeOwnership

``` js
function changeOwnership(address newOwner) public;
```

This function allows only the current `owner` address to change the contract owner to a new address. It sets the `owner` global variable to the `newOwner` argument value and emits a `NewOwner` event.

###### upgrade

``` js
function upgrade(address newImplementation) public;
```

This function allows only the current `owner` address to upgrade the contract implementation address.

It sets the internal implementation global variable to the `newImplementation` global variable.

Following the upgrade, the `Upgraded` event is emitted.


#### Events

###### NewOwner

``` js
event NewOwner(address newOwner);
```

This event is emitted when the contract `owner` address is changed.

###### Upgraded

``` js
event Upgraded(address newImplementation);
```

This event is emitted when `finalizeUpgrade()` is called.

### Limit Order Execution Node Spec

#### Introduction

The Limit Order Execution Node is an always-running node that collects `NewOrder` events from the proxy contract and executes each order when its `minDestinationAmount` condition is met by the Synthetix oracle (Synthetix `ExchangeRates.sol` contract).

#### Requirements
* The node collects executable limit orders as soon as their execution conditions are met.
* The node only executes orders that can refund the entire gas cost of the transaction in addition to an `executionFee` equal to or larger than a pre-configured minimum.
* The node attempts to re-execute failing order transactions as soon as their order conditions are met again

#### Components

##### Watcher Service

This service listens for new Ethereum blocks in realtime. On each new block, the service queries the contract for currently executable orders.

If any executable limit orders are found, they are passed to the Execution Service

##### Execution Service

In order to determine whether an `orderID` should be immediately executed, the service follows the following steps:
- Checks a local database for any existing pending transaction previously submitted by the node that executes the same `orderID`. If a record is found, this order will not be submitted.
- Attempts to estimate gas cost for calling the `executeOrder` contract function while passing the `orderID`. If the attempt fails, this is likely because the order's deposited `wei` funds are insufficient to fully recover the gas cost of this transaction + the `executionFee`.
- Checks if the node wallet address owns sufficient `wei` to cover this transaction cost. If the balance is insufficient, an email notification must be sent to the node operator.

After the checks have passed, the order is executed:
- The `orderID` is submitted to the `executeOrder` function in a new transaction
- The `orderID` is temporarily stored in the local database to prevent future duplicate transactions until the transaction is included in a block.

The execution service then listens for the transaction status.
If the transaction is successfully mined and but the EVM execution has failed:
- The service removes both the mapped `orderID` from the local database
- This `orderID` will then be collected again by the Watcher Service as soon as its conditions are met, starting from the next block.

### Client-side Javascript Library Spec

#### Introduction

This library is proposed in order to provide a simple Javascript interface to the limit order functionality of the Synthetix limit order contract.

#### Requirements
The library must allow a simple interface to the following operations:
- Submit a new limit order
- Query the execution status of an active order
- Cancel an active order
- List all active orders submitted by the user's address

#### API

##### Constructor

``` js
const instance = new SynthLimitOrder(ethereumProvider)
```
The library must expose a `SynthLimitOrder` class. The user instantiates a class instance by passing a valid ethereum provider with signing capabilities (e.g. Metamask) to the constructor.

##### submitOrder

``` js
const orderID = await instance.submitOrder({
    sourceCurrencyKey,           // bytes32 string
    sourceAmount,                // base unit string amount
    destinationCurrencyKey,      // bytes32 string
    minDestinationAmount,        // base unit string amount
    weiDeposit,                  // wei string amount
    executionFee                 // wei string amount
})
```
This method allows the user to submit a new limit order on the contract by calling the `newOrder` contract function.

This method also automatically attempts to sign an ERC20 approve transaction for the `sourceCurrencyKey` token if a sufficient allowance is not already present for the contract.

It returns a `Promise<string>` as soon as the transaction is confirmed where the string contains the new order ID.

##### withdraw

``` js
await instance.withdraw()
```
This method allows the user to withdraw funds from all executed orders on the contract that have passed the fee reclamantion duration.

The method fetches all historical `Executed` events from the contract filtered by the user's address as the `submitter` and queries each order's current state using `StateStorage.getOrder`. If the order's `executed` property is `true` and `executedTimestamp + 3 minutes` is larger than the current timestamp, the order is is added to the array of order IDs sent to the Proxy contract's `withdrawOrders` function.

It returns a `Promise<void>` as soon as the transaction is confirmed.

##### cancelOrder

``` js
await instance.cancelOrder(orderID)
```
This method cancels an active order by calling the `cancelOrder` contract function.

It returns a `Promise<void>` as soon as the transaction is confirmed.

##### getOrder

``` js
const order = await instance.getOrder(orderID)
```
This method allows the user to query the contract for a specific order number by querying the `StateStorage` contract `getOrder` function.

It returns a promise that resolves with an `Order` object:
```ts
interface Order {
    submitter: string;
    sourceCurrencyKey: string;
    sourceAmount: string;
    destinationCurrencyKey: string;
    minDestinationAmount: string;
    weiDeposit:string;
    executionFee:string;
    executionTimestamp:string;
    destinationAmount:string;
    executed:boolean;
}
```

##### getAllActiveOrders

``` js
const order = await instance.getAllActiveOrders()
```
This method allows the user to query the contract for an array all active orders submitted by the user's address. This array is constructed by querying a list of all past `Order` contract events filtered by the user's wallet address as the `submitter`. Each `orderID` is passed to the `getOrder` javascript method before being included in the returned array in order to ensure that the order is still active.

It returns a `Promise<Order[]>` where an `Order` follows the interface above.

## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->

### Limit Order Execution Nodes
By allowing anyone to run “limit order execution nodes” and compete for limit order execution fees, we achieve order execution reliability and censorship-resistance through permissionless-ness. These are especially important in the context of limit orders, where censorship or execution delays might cause trading losses.

### Upgradability
We use an upgradable proxy pattern in order to allow a present owner address to upgrade the core implementation contract at any time.

## Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
Test cases to be provided with implemented code.

## Implementation
<!--The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
Not started. Spec complete and ready for community review.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
