---
eip: 8078
title: Contract Event Subscription
description: Allows contracts to subscribe to and react to events emitted by other contracts with gas-bounded execution
author: Lucas Cullen (@bitcoinbrisbane) <lucas@bitcoinbrisbane.com.au>
discussions-to: https://ethereum-magicians.org/t/xxxxx
status: Draft
type: Standards Track
category: Core
created: 2025-11-15
requires:
---

## Abstract

This EIP introduces a mechanism for smart contracts to subscribe to events emitted by other contracts and automatically execute callback functions when those events occur. Subscriptions are paid for by the subscribing contract, execute with bounded gas, and fail gracefully without blocking the original transaction if gas runs out or execution fails.

## Motivation

Currently, smart contracts cannot natively react to events emitted by other contracts. Developers must rely on off-chain infrastructure (indexers, bots, relayers) to listen for events and trigger subsequent transactions. This creates several problems:

1. **Centralization**: Requires trusted off-chain infrastructure
2. **Latency**: Introduces delays between event emission and reaction
3. **Complexity**: Requires maintaining off-chain services and private keys
4. **Cost**: Users must pay for multiple transactions
5. **Atomicity**: Cannot guarantee atomic execution with the original transaction

On-chain event subscriptions would enable:

-   **Reactive DeFi protocols** (automatic liquidations, rebalancing)
-   **Cross-contract coordination** (DAO proposals triggering dependent actions)
-   **Decentralized automation** (eliminating relayer centralization)
-   **Atomic multi-step protocols** (oracle updates triggering derivative settlements)

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119 and RFC 8174.

### Overview

1. Contracts declare subscribable events using enhanced event syntax
2. Contracts subscribe to events using a new `subscribe` keyword
3. When an event is emitted, subscribed callbacks are executed in isolated contexts
4. Each subscription executes with caller-provided gas limits
5. Subscription failures are caught and logged but do not revert the parent transaction

### Solidity Language Changes

#### 1. Subscribable Event Declaration

Events can be marked as `subscribable` to indicate they support on-chain subscriptions:

```solidity
// Basic subscribable event
event subscribable Transfer(address indexed from, address indexed to, uint256 value);

// Event with subscription gas hint
event subscribable PriceUpdated(uint256 price) gasHint(100000);
```

The `gasHint` annotation suggests minimum gas needed for reasonable subscription handling.

#### 2. Subscription Syntax

Contracts subscribe to events using the `subscribe` statement in their constructor or a dedicated subscription management function:

```solidity
contract Subscriber {
    // Subscribe in constructor
    constructor(address targetContract) {
        subscribe targetContract.Transfer(from, to, value)
            with onTransfer(from, to, value)
            gasLimit 150000
            gasPrice 20 gwei;
    }

    // Callback function - MUST be payable to receive gas payment refunds
    function onTransfer(address from, address to, uint256 value)
        external
        payable
        onlyEventCallback
    {
        // Handle the event
        // If this runs out of gas or reverts, the original Transfer event still succeeds
    }

    // Unsubscribe
    function cleanup(address targetContract) external {
        unsubscribe targetContract.Transfer;
    }
}
```

#### 3. Event Callback Modifier

A new modifier `onlyEventCallback` ensures functions can only be called by the EVM's subscription dispatcher:

```solidity
modifier onlyEventCallback {
    require(msg.sender == address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF), "Only event callbacks");
    _;
}
```

The special address `0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF` is reserved for the subscription dispatcher.

#### 4. Subscription Management

```solidity
// Check if subscribed
bool isSubscribed = this.isSubscribedTo(targetContract, "Transfer");

// Get subscription details
(uint256 gasLimit, uint256 gasPrice, address callback) =
    this.getSubscription(targetContract, "Transfer");

// Update subscription gas parameters
updateSubscription(targetContract, "Transfer", newGasLimit, newGasPrice);
```

### EVM Changes

#### 1. New Opcodes

**`SUBSCRIBE` (0x5c)**

-   Stack input: `[target_address, event_signature, callback_address, callback_selector, gas_limit, gas_price]`
-   Stack output: `[subscription_id]`
-   Gas cost: 20,000 + storage costs
-   Creates a subscription record in global subscription storage

**`UNSUBSCRIBE` (0x5d)**

-   Stack input: `[subscription_id]`
-   Stack output: `[success]`
-   Gas cost: 5,000 + storage refund
-   Removes subscription and refunds storage

**`NOTIFYSUBSCRIBERS` (0x5e)**

-   Stack input: `[event_signature, data_offset, data_size]`
-   Stack output: `[num_notified]`
-   Gas cost: 2,000 + (500 \* num_subscribers)
-   Called automatically during LOG operations for subscribable events
-   Schedules callback executions

#### 2. Subscription Storage Model

Subscriptions are stored in a new EVM state trie separate from contract storage:

```
SubscriptionKey = keccak256(target_address, event_signature, subscriber_address)
SubscriptionValue = RLP([callback_address, callback_selector, gas_limit, gas_price, deposit])
```

#### 3. Event Emission Flow

When a subscribable event is emitted:

```
1. Event is logged normally (LOG0-LOG4 opcodes)
2. If event is marked subscribable, NOTIFYSUBSCRIBERS is called
3. For each subscription:
   a. Check subscriber has sufficient deposited gas payment
   b. Deduct gas payment (gas_limit * gas_price) from deposit
   c. Schedule callback execution in isolated context
   d. Execute callback with try-catch semantics
   e. Refund unused gas to subscriber
   f. Log callback success/failure
4. Original transaction continues regardless of callback outcomes
```

#### 4. Callback Execution Context

Callbacks execute in an isolated context:

```
- msg.sender = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF (subscription dispatcher)
- tx.origin = original tx.origin (preserved from parent)
- block.* = same as parent transaction
- Gas limit = subscription gas_limit
- Reverts/failures are caught and logged but don't propagate
- State changes are included if callback succeeds
- DELEGATECALL and CALLCODE are disabled in callbacks
```

#### 5. Gas Accounting

Subscription gas costs are separate from the transaction that emits the event:

1. **Subscription Deposit**: Subscribers must deposit ETH to cover future callback executions
2. **Per-Callback Deduction**: When event is emitted, `gas_limit * gas_price` is deducted from deposit
3. **Refunds**: Unused gas is refunded to subscriber's deposit balance
4. **Insufficient Balance**: If deposit insufficient, callback is skipped and event logged
5. **Withdrawal**: Subscribers can withdraw unused deposits

#### 6. New Precompile: Subscription Manager (0x0a)

Address: `0x000000000000000000000000000000000000000a`

Functions:

-   `deposit(subscription_id)` - Add ETH to subscription deposit
-   `withdraw(subscription_id, amount)` - Withdraw from deposit
-   `getBalance(subscription_id)` - Query deposit balance
-   `getSubscriptionInfo(subscription_id)` - Get subscription details

### Compiler Changes (Solidity)

#### 1. Event Declaration Parsing

The Solidity compiler must:

-   Parse `subscribable` keyword on event declarations
-   Parse optional `gasHint(uint256)` annotation
-   Emit metadata indicating event is subscribable
-   Include subscription hints in contract ABI

```json
{
  "type": "event",
  "name": "Transfer",
  "inputs": [...],
  "subscribable": true,
  "gasHint": 100000
}
```

#### 2. Subscribe Statement Compilation

The `subscribe` statement compiles to:

```
1. Load subscription parameters onto stack
2. Call SUBSCRIBE opcode
3. Store returned subscription_id
4. Emit SubscriptionCreated event for off-chain indexing
```

#### 3. Built-in Subscription Functions

The compiler provides built-in functions:

```solidity
// Automatically available in all contracts
function isSubscribedTo(address target, string memory eventSig) internal view returns (bool);
function getSubscription(address target, string memory eventSig) internal view returns (...);
function updateSubscription(address target, string memory eventSig, uint256 gasLimit, uint256 gasPrice) internal;
```

#### 4. Callback Function Validation

The compiler enforces:

-   Callback functions MUST be `external`
-   Callback functions SHOULD be `payable` to receive gas refunds
-   Callback functions MUST use `onlyEventCallback` modifier or equivalent check
-   Parameter types MUST match subscribed event types

### Client Implementation (Geth)

#### 1. Subscription State Management

New database schema:

```go
type Subscription struct {
    ID              common.Hash
    TargetContract  common.Address
    EventSignature  common.Hash
    SubscriberContract common.Address
    CallbackAddress common.Address
    CallbackSelector [4]byte
    GasLimit        uint64
    GasPrice        *big.Int
    DepositBalance  *big.Int
    Active          bool
}
```

#### 2. EVM Modification

In `core/vm/evm.go`:

```go
// New field in EVM struct
type EVM struct {
    // ... existing fields
    SubscriptionManager *SubscriptionManager
    PendingCallbacks    []*CallbackExecution
}

// Execute callbacks after main execution
func (evm *EVM) ProcessCallbacks() error {
    for _, cb := range evm.PendingCallbacks {
        evm.executeCallback(cb)
    }
    return nil
}

func (evm *EVM) executeCallback(cb *CallbackExecution) {
    // Create isolated context
    snapshot := evm.StateDB.Snapshot()

    // Set special msg.sender
    evm.Context.Origin = cb.OriginalOrigin

    // Execute with try-catch semantics
    ret, gasUsed, err := evm.Call(
        AccountRef(SUBSCRIPTION_DISPATCHER_ADDRESS),
        cb.CallbackAddress,
        cb.CallbackData,
        cb.GasLimit,
        big.NewInt(0),
    )

    if err != nil {
        // Revert callback state changes but continue
        evm.StateDB.RevertToSnapshot(snapshot)
        // Log callback failure
        evm.StateDB.AddLog(&types.Log{
            Address: cb.SubscriberAddress,
            Topics:  []common.Hash{CallbackFailedEvent, cb.SubscriptionID},
            Data:    []byte(err.Error()),
        })
    } else {
        // Refund unused gas
        refund := (cb.GasLimit - gasUsed) * cb.GasPrice
        evm.SubscriptionManager.RefundGas(cb.SubscriptionID, refund)
    }
}
```

#### 3. LOG Opcode Modification

In `core/vm/instructions.go`:

```go
func opLogN(pc *uint64, interpreter *EVMInterpreter, scope *ScopeContext) ([]byte, error) {
    // ... existing LOG implementation

    // Check if event is subscribable
    eventSig := scope.Stack.peek().Bytes32()
    if interpreter.evm.SubscriptionManager.IsSubscribableEvent(scope.Contract.Address(), eventSig) {
        // Notify subscribers
        subscribers := interpreter.evm.SubscriptionManager.GetSubscribers(
            scope.Contract.Address(),
            eventSig,
        )

        for _, sub := range subscribers {
            // Deduct gas from deposit
            if !sub.DeductGas() {
                // Insufficient deposit, skip and log
                interpreter.evm.StateDB.AddLog(insufficientGasLog(sub))
                continue
            }

            // Schedule callback
            callback := &CallbackExecution{
                SubscriptionID:   sub.ID,
                SubscriberAddress: sub.SubscriberContract,
                CallbackAddress:  sub.CallbackAddress,
                CallbackData:     buildCallbackData(sub, logData),
                GasLimit:         sub.GasLimit,
                GasPrice:         sub.GasPrice,
                OriginalOrigin:   interpreter.evm.Context.Origin,
            }
            interpreter.evm.PendingCallbacks = append(
                interpreter.evm.PendingCallbacks,
                callback,
            )
        }
    }

    return nil, nil
}
```

#### 4. State Trie Extension

Add new subscription trie alongside existing state tries:

```go
type StateDB struct {
    // ... existing fields
    subscriptionTrie Trie
    subscriptionCache *lru.Cache
}
```

#### 5. RPC Extensions

New RPC methods:

```go
// Get all subscriptions for an address
eth_getSubscriptions(address) -> []Subscription

// Get subscription details
eth_getSubscription(subscriptionId) -> Subscription

// Get callback execution history
eth_getCallbackHistory(subscriptionId, fromBlock, toBlock) -> []CallbackLog
```

## Rationale

### Design Decisions

**Why isolated execution context?**
Prevents subscription callbacks from blocking or reverting the original transaction. The emitting contract should not care about subscriber behavior.

**Why require payable callbacks?**
Enables gas refunds to be returned to the subscribing contract, improving efficiency.

**Why separate deposit model?**
Prevents DoS attacks where subscriptions drain the emitting contract's gas. Subscribers pay for their own execution.

**Why special dispatcher address?**
Provides a secure, verifiable way for callbacks to know they're being called by the subscription system rather than an attacker.

**Why bounded gas?**
Prevents infinite loops or excessive gas consumption from blocking event emission or consuming unreasonable resources.

**Why not use CREATE2 deterministic callbacks?**
CREATE2 would require deploying a new contract for each subscription, wasting storage and gas. The proposed system is more efficient.

### Alternative Approaches Considered

1. **Event Relayer Precompile**: A precompile that stores events and allows polling. Rejected because it still requires off-chain infrastructure.

2. **Callback in Same Transaction**: Execute callbacks synchronously in the same call frame. Rejected because callback failures would revert the emitting transaction.

3. **Deferred Transaction Queue**: Store callbacks as pending transactions for future blocks. Rejected due to complexity and unpredictable execution timing.

## Backwards Compatibility

This EIP introduces new opcodes and language features but maintains full backwards compatibility:

1. **Existing Contracts**: Continue to work without modification
2. **Existing Events**: Can be emitted normally; `subscribable` is opt-in
3. **Non-upgraded Clients**: Can process blocks but will skip subscription execution (fork required)
4. **ABI Compatibility**: New ABI fields are additive only

### Hard Fork Required

This EIP requires a coordinated hard fork to activate:

-   All clients must implement new opcodes
-   Subscription state trie must be initialized
-   Subscription dispatcher precompile must be activated

## Security Considerations

### 1. Reentrancy Protection

Callbacks execute after the main transaction completes, preventing reentrancy attacks on the emitting contract. The isolated context ensures callbacks cannot call back into the emitter within the same transaction.

### 2. Gas Griefing

**Attack**: Subscribing to popular events with insufficient deposits to waste emitter gas.

**Mitigation**:

-   Subscription notification cost (500 gas per subscriber) is low
-   Insufficient deposits skip execution rather than failing
-   Emitters can limit subscribable events

### 3. DoS via Excessive Subscriptions

**Attack**: Creating millions of subscriptions to slow down event emission.

**Mitigation**:

-   SUBSCRIBE opcode has high base cost (20,000 gas)
-   NOTIFYSUBSCRIBERS charges per subscriber (500 gas each)
-   Practical limit: ~60,000 gas / 500 = ~120 subscribers per event emission
-   Emitters can choose not to mark events as subscribable

### 4. Front-Running Subscriptions

**Attack**: Front-running subscription creation to intercept events meant for others.

**Mitigation**: Subscriptions are public state; this is expected behavior. Sensitive events should not be subscribable.

### 5. Callback Impersonation

**Attack**: Calling a callback function directly, bypassing event emission.

**Mitigation**: The `onlyEventCallback` modifier checks for the special dispatcher address, which cannot be impersonated by user transactions.

### 6. Deposit Draining

**Attack**: Emitting events rapidly to drain subscriber deposits.

**Mitigation**: Subscribers control their gas limits and can withdraw deposits. This is similar to users controlling their own transaction gas.

### 7. State Inconsistency

**Attack**: Callback executes based on stale state if emitter's state changes before callback runs.

**Mitigation**: Callbacks execute immediately after the emitting transaction in the same block. State is consistent within the transaction context.

### 8. Cross-Contract Reentrancy

**Attack**: Callback modifies state that affects other pending callbacks.

**Mitigation**: Callbacks are executed sequentially in the order they were subscribed. Each callback sees the cumulative state changes from previous callbacks (similar to transaction ordering).

## Reference Implementation

### Solidity Example: Price Oracle with Subscribers

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PriceOracle {
    uint256 public price;

    event subscribable PriceUpdated(uint256 newPrice) gasHint(50000);

    function updatePrice(uint256 _price) external {
        price = _price;
        emit PriceUpdated(_price);
        // Subscribers are automatically notified
    }
}

contract DerivedProtocol {
    PriceOracle public oracle;
    uint256 public lastSyncedPrice;
    uint256 public depositBalance;

    event PriceSynced(uint256 price);
    event SubscriptionGasRefund(uint256 amount);

    constructor(address _oracle) payable {
        oracle = PriceOracle(_oracle);

        // Subscribe to price updates
        subscribe oracle.PriceUpdated(newPrice)
            with onPriceUpdate(newPrice)
            gasLimit 100000
            gasPrice 20 gwei;

        // Deposit gas payment
        depositBalance = msg.value;
    }

    // Callback function - automatically called when PriceUpdated is emitted
    function onPriceUpdate(uint256 newPrice)
        external
        payable
        onlyEventCallback
    {
        lastSyncedPrice = newPrice;
        emit PriceSynced(newPrice);

        // Process gas refund if any
        if (msg.value > 0) {
            depositBalance += msg.value;
            emit SubscriptionGasRefund(msg.value);
        }

        // Perform derivative calculations
        // If this reverts, the oracle's updatePrice() still succeeds
        rebalancePositions(newPrice);
    }

    function rebalancePositions(uint256 newPrice) internal {
        // Complex logic that might fail
        // Failures are graceful and logged
    }

    // Withdraw unused deposit
    function withdrawDeposit(uint256 amount) external {
        require(depositBalance >= amount, "Insufficient balance");
        depositBalance -= amount;
        payable(msg.sender).transfer(amount);
    }
}
```

### Geth Implementation Sketch

```go
// core/vm/subscription_manager.go
package vm

type SubscriptionManager struct {
    stateDB StateDB
    subscriptions map[common.Hash]*Subscription
    subscriptionsByEvent map[common.Hash][]*Subscription
}

func (sm *SubscriptionManager) Subscribe(
    target common.Address,
    eventSig common.Hash,
    subscriber common.Address,
    callback common.Address,
    selector [4]byte,
    gasLimit uint64,
    gasPrice *big.Int,
) (common.Hash, error) {
    // Create subscription ID
    subID := crypto.Keccak256Hash(
        target.Bytes(),
        eventSig.Bytes(),
        subscriber.Bytes(),
    )

    // Create subscription record
    sub := &Subscription{
        ID:              subID,
        TargetContract:  target,
        EventSignature:  eventSig,
        SubscriberContract: subscriber,
        CallbackAddress: callback,
        CallbackSelector: selector,
        GasLimit:        gasLimit,
        GasPrice:        gasPrice,
        DepositBalance:  big.NewInt(0),
        Active:          true,
    }

    // Store in state
    sm.subscriptions[subID] = sub

    // Index by event
    eventKey := crypto.Keccak256Hash(target.Bytes(), eventSig.Bytes())
    sm.subscriptionsByEvent[eventKey] = append(
        sm.subscriptionsByEvent[eventKey],
        sub,
    )

    // Persist to trie
    sm.stateDB.SetSubscription(subID, sub)

    return subID, nil
}

func (sm *SubscriptionManager) NotifySubscribers(
    target common.Address,
    eventSig common.Hash,
    eventData []byte,
) []*CallbackExecution {
    eventKey := crypto.Keccak256Hash(target.Bytes(), eventSig.Bytes())
    subscribers := sm.subscriptionsByEvent[eventKey]

    callbacks := make([]*CallbackExecution, 0, len(subscribers))

    for _, sub := range subscribers {
        if !sub.Active {
            continue
        }

        // Calculate gas cost
        gasCost := new(big.Int).Mul(
            new(big.Int).SetUint64(sub.GasLimit),
            sub.GasPrice,
        )

        // Check deposit balance
        if sub.DepositBalance.Cmp(gasCost) < 0 {
            // Insufficient balance, skip
            sm.stateDB.AddLog(&types.Log{
                Address: sub.SubscriberContract,
                Topics:  []common.Hash{
                    InsufficientDepositEvent,
                    sub.ID,
                },
            })
            continue
        }

        // Deduct gas
        sub.DepositBalance.Sub(sub.DepositBalance, gasCost)
        sm.stateDB.SetSubscription(sub.ID, sub)

        // Build callback data
        callbackData := append(sub.CallbackSelector[:], eventData...)

        // Create callback execution
        callbacks = append(callbacks, &CallbackExecution{
            SubscriptionID:     sub.ID,
            SubscriberAddress:  sub.SubscriberContract,
            CallbackAddress:    sub.CallbackAddress,
            CallbackData:       callbackData,
            GasLimit:           sub.GasLimit,
            GasPrice:           sub.GasPrice,
            OriginalOrigin:     common.Address{}, // Set by caller
        })
    }

    return callbacks
}
```

## Test Cases

### Test Case 1: Basic Subscription and Callback

```solidity
function testBasicSubscription() public {
    // Deploy oracle
    PriceOracle oracle = new PriceOracle();

    // Deploy subscriber with gas deposit
    DerivedProtocol subscriber = new DerivedProtocol{value: 1 ether}(
        address(oracle)
    );

    // Verify subscription created
    assertTrue(subscriber.isSubscribedTo(address(oracle), "PriceUpdated"));

    // Emit event
    oracle.updatePrice(1000);

    // Verify callback executed
    assertEq(subscriber.lastSyncedPrice(), 1000);
}
```

### Test Case 2: Callback Out of Gas

```solidity
function testCallbackOutOfGas() public {
    // Create subscription with insufficient gas
    DerivedProtocol subscriber = new DerivedProtocol{value: 1 ether}(
        address(oracle)
    );
    subscriber.updateSubscription(address(oracle), "PriceUpdated", 10000, 20 gwei); // Too low

    // Emit event
    oracle.updatePrice(1000);

    // Verify original transaction succeeded
    assertEq(oracle.price(), 1000);

    // Verify callback failed gracefully
    assertEq(subscriber.lastSyncedPrice(), 0); // Not updated

    // Verify failure was logged
    // (check logs for CallbackFailed event)
}
```

### Test Case 3: Insufficient Deposit

```solidity
function testInsufficientDeposit() public {
    DerivedProtocol subscriber = new DerivedProtocol{value: 0.001 ether}(
        address(oracle)
    );

    // Emit events until deposit exhausted
    for (uint i = 0; i < 100; i++) {
        oracle.updatePrice(i);
    }

    // Verify early events succeeded
    assertTrue(subscriber.lastSyncedPrice() > 0);

    // Verify later events skipped due to insufficient deposit
    assertLt(subscriber.lastSyncedPrice(), 99);
}
```

### Test Case 4: Multiple Subscribers

```solidity
function testMultipleSubscribers() public {
    PriceOracle oracle = new PriceOracle();

    DerivedProtocol sub1 = new DerivedProtocol{value: 1 ether}(address(oracle));
    DerivedProtocol sub2 = new DerivedProtocol{value: 1 ether}(address(oracle));
    DerivedProtocol sub3 = new DerivedProtocol{value: 1 ether}(address(oracle));

    // Emit event
    oracle.updatePrice(500);

    // Verify all callbacks executed
    assertEq(sub1.lastSyncedPrice(), 500);
    assertEq(sub2.lastSyncedPrice(), 500);
    assertEq(sub3.lastSyncedPrice(), 500);
}
```

### Test Case 5: Unsubscribe

```solidity
function testUnsubscribe() public {
    DerivedProtocol subscriber = new DerivedProtocol{value: 1 ether}(
        address(oracle)
    );

    // Verify subscribed
    assertTrue(subscriber.isSubscribedTo(address(oracle), "PriceUpdated"));

    // Unsubscribe
    subscriber.cleanup(address(oracle));

    // Verify unsubscribed
    assertFalse(subscriber.isSubscribedTo(address(oracle), "PriceUpdated"));

    // Emit event
    oracle.updatePrice(1000);

    // Verify callback not executed
    assertEq(subscriber.lastSyncedPrice(), 0);
}
```

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
