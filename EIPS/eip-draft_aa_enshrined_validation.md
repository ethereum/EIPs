---
title: Account Abstraction via Account Configurations
description: Enable account abstraction through account configurations.
author: Chris Hunter (@)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2025-10-14
requires: 
---

## Abstract

We propose a validation mechanism for account abstraction that enshrines wallet validation standards through account configuration. Each account specifies its accepted keys and key types through an onchain configuration rather than arbitrary validation code. A new transaction type enables native gas abstraction, allowing transactions to be paid for by parties other than the sender.

Unlike [EIP-7701](./eip-7701.md), which supports arbitrary code for validation, this approach is defines what validation logic is possible. By constraining validation to a well-defined set of key types and validation rules, the proposal maintains protocol simplicity while enabling secure account abstraction and effective block building as no code is needed to be executed within the evm. The block building advantages are especially apparent when paired with [EIP-7928](./eip-7928). This design also provides a clear path for future expansion to quantum-safe cryptographic algorithms and is compatible with existing AA mechanisms like EIP-7702 and ERC-4337.



## Motivation

Account abstraction has been a long-standing goal for Ethereum, aiming to provide users with more flexible and secure account management. This proposal aims to enable all the standard benefits of account abstraction—including batching, gas sponsorship, privilege de-escalation, and custom authentication—while addressing critical implementation challenges that have hindered adoption of existing solutions.

### Problems with Existing Approaches

Current account abstraction implementations face several significant challenges:

**[EIP-4337](./eip-4337.md)** provides account abstraction at the application layer but introduces substantial complexity:
- Requires complex [ERC-7562](./eip-7562.md) validation rules for mempool operation
- Adds significant gas overhead through UserOperation validation, execution, and post-operation phases
- Introduces an entrypoint contract that adds gas costs to every transaction
- Creates a separate infrastructure/protocol that must be maintained alongside the standard transaction pool

**[EIP-7701](./eip-7701.md)** enable protocol-level account abstraction but allow arbitrary validation code:
- Block builders must execute arbitrary EVM code before knowing who will pay for gas, creating DoS attack vectors
- Unpredictable gas costs during validation complicate block building
- Difficult to optimize transaction ordering and parallel execution
- Complex interaction with block building optimizations like [EIP-7928](./eip-7928.md)

### Goals of This Proposal

This proposal takes an intentionally constrained approach to address these issues while maintaining the key benefits of account abstraction:

#### 1. Simple Block Building

By enshrining specific validation logic rather than supporting arbitrary code, block builders can validate transactions without calling into the EVM prior to gas payment. The payer is deterministically known when the transaction is included in the block, eliminating DoS risks where malicious transactions could consume builder resources without paying.

#### 2. Simple Mempool Operation

Unlike arbitraty code excution AA protocols, this proposal does not require complex [ERC-7562](./eip-7562.md) validation rules. Mempool operators can validate transactions using simple, well-defined rules that are part of the protocol, not application-level heuristics. They only need access to onchain state.

#### 3. Standardized Authentication Mechanisms

Rather than allowing arbitrary validation code, this proposal enshrines a well-defined set of key types and validation mechanisms. This approach:
- Ensures best practices for signature validation are followed
- Makes security auditing and formal verification more tractable
- Reduces implementation complexity and bug surface area
- Provides a clear framework for adding new key types (including quantum-safe algorithms) through protocol upgrades

#### 4. Gas Efficiency

By eliminating the need for:
- Separate validation and post-operation execution phases
- Entrypoint contract overhead
- Extra CALL operations for validation logic

This proposal reduces the gas cost of account abstraction transactions compared to other approaches.

#### 5. Transaction Compressibility

The structured, predictable format of validation configuration enables better transaction compression, which is particularly valuable for Layer 2 rollups where calldata costs dominate. Unlike arbitrary validation code, enshrined validation fields can be efficiently compressed and deduplicated. 

The new transaction type structure allows for transaction data to be effectively compressed enabling large data availability savings, furthermore the protocol supports aggregatable signatures (BLS).

### Key Features

This proposal enables:
- **Key management**: Accounts can specify multiple authorized keys with different key types, enabling key rotation and recovery without changing the account address
- **Gas sponsorship**: Transactions can be paid for by accounts other than the sender. The payer is able to ensure they will not be griefed.
- **Unopinionated execution**: The proposal does not prescribe execution logic—batching and other execution features are supported at the wallet implementation level, providing maximum flexibility.
- **Compatibility**: Works alongside existing account abstraction frameworks including [EIP-7702](./eip-7702.md) and [EIP-4337](./eip-4337.md). Support for [ERC-1271](./eip-1271.md) remains.

## Specification

### Constants

| Name                     | Value             | Comment |
|--------------------------|-------------------|---------|
| `AA_TX_TYPE`             | TBD               | [EIP-2718](./eip-2718.md) transaction type |
| `AA_BASE_COST`           | 15000             | Base intrinsic gas cost for AA transaction |
| `ACCOUNT_CONFIG_PRECOMPILE` | TBD            | Address of the Account Configuration precompile |
| `MAX_REQUIRED_PRESTATE_ENTRIES` | 3         | Maximum number of required_pre_state conditions per transaction |

#### Intrinsic Gas Calculation

The total intrinsic gas for an AA transaction is calculated as:

```
intrinsic_gas = AA_BASE_COST + sender_key_cost + payer_key_cost
```

Where `sender_key_cost` and `payer_key_cost` are determined by the key types used for each signature (see [Key Types](#key-types) table). For example, a transaction with both sender and payer using `K1` keys would have:

```
intrinsic_gas = 15000 + 3000 + 3000 = 21000
```

This matches the standard Ethereum transaction cost when using secp256k1 keys for both parties.

### Account Configuration

Each account can optionally configure a list of authorized keys that are permitted to sign transactions on its behalf. This configuration consists of an ordered array of key entries, where each entry specifies a key type and the public key data.

#### Configuration Format

The account configuration is stored as an array of key entries:

```
[
  (key_type_0, public_key_0),
  (key_type_1, public_key_1),
  ...
  (key_type_n, public_key_n)
]
```

Where:
- `key_type` (uint8): The cryptographic algorithm type (see [Key Types](#key-types) section)
- `public_key` (bytes): The public key data, format depends on the key type

#### Default Configuration

**The default configuration for an account is an empty array `[]`.**

When an account has an empty configuration (no configured keys), only the account's standard EOA key (the key derived from the account address) can authorize transactions. This ensures backward compatibility—existing EOAs work without any configuration.

#### EOA Key Always Valid

**Important: The account's original EOA key always has authorization, regardless of the configured key list.**

Even if an account configures additional keys, the standard ECDSA key associated with the account address can always sign transactions. This ensures:
- Accounts cannot be locked out by misconfiguration
- Existing EOA behavior is preserved
- Recovery is always possible using the original key

When validating a transaction signature, the protocol checks:
1. First, if the signature is valid for the account's EOA key
2. If not, check if the signature matches any configured key in the account's key list

Note we expect this behaviour to be removed in the future during quantum migration. 

#### Configuration Storage

Account configurations are stored and managed through a canonical **Account Configuration Precompile** at a designated address (TBD).

**Interface:**

```solidity
interface IAccountConfiguration {
    /// @notice Set or update a key at the specified index
    /// @dev Restricted to msg.sender (accounts can only configure themselves)
    function setKey(uint8 index, uint8 keyType, bytes calldata publicKey) external;
    
    /// @notice Remove a key at the specified index
    function removeKey(uint8 index) external;
    
    /// @notice Get the complete configuration for an account
    function getConfiguration(address account) external view returns (
        uint8[] memory keyTypes,
        bytes[] memory publicKeys
    );
    
    /// @notice Get a specific key by index
    function getKey(address account, uint8 index) external view returns (
        uint8 keyType,
        bytes memory publicKey
    );
}
```

The precompile can also offer initial account creation by providing counter factual addresses and validation.  

**Benefits:**

- **Performance**: The precompile address is kept warm in the access list, minimizing gas costs for configuration reads during validation
- **Standardization**: Provides a canonical interface that wallets, block builders, and tooling can rely on across all chains
- **Efficiency**: Dedicated storage optimized for key configurations, separate from contract storage
- **Compatibility**: Works immediately on all chains that adopt this EIP without requiring new opcodes

**Access Control:**

Only `msg.sender` can modify their own configuration. Calls to `setKey` or `removeKey` revert if `msg.sender != account` being configured. This prevents unauthorized modification while allowing smart contract wallets to manage their own keys through their execution logic.

### Key Types

This proposal enshrines support for specific cryptographic signature algorithms which is expected to be expanded upon in the future. Each key type has a unique identifier and defined signature format. The protocol validates signatures according to the specified key type.

The following key types are supported:

| Key Type | ID | Algorithm | Public Key Size | Signature Size | Intrinsic Gas Cost |
|----------|-----|-----------|-----------------|----------------|-------------------|
| `K1` | `0x01` | secp256k1 (ECDSA) | 33 bytes (compressed) or 65 bytes (uncompressed) | 65 bytes (r, s, v) | 3000 |
| `R1` | `0x02` | secp256r1 / P-256 (ECDSA) | 33 bytes (compressed) or 65 bytes (uncompressed) | 64 bytes (r, s) | 5000 |
| `WEBAUTHN` | `0x03` | WebAuthn / Passkey | 65 bytes (uncompressed P-256) | Variable (includes authenticator data) | 7000 |
| `BLS` | `0x04` | BLS12-381 | 48 bytes (compressed G1) | 96 bytes (G2 signature) | 7000 |
| `DELEGATE` | `0x05` | Delegated validation | 20 bytes (account address) | Variable (depends on delegated account) | 5000 |

#### Additional information

##### `BLS` - BLS12-381 (0x04)

BLS signature using the BLS12-381 curve. This signature scheme enables signature aggregation, allowing multiple signatures to be combined into a single signature for DA efficiency.

##### `DELEGATE` - Delegated Validation (0x05)

Delegates signature validation to another account. The "public key" is actually an Ethereum address, and validation is performed by checking if that account's authentication configuration accepts the provided signature.

Note: Only 1 hop is allowed. (If other account specifies external as well, it will fail)


#### Adding New Key Types

New key types can be added through subsequent EIPs following this specification pattern. Each new key type must define:
- Unique identifier (uint8)
- Public key format and size
- Signature format and size
- Validation algorithm
- Intrinsic gas cost

This extensibility enables the protocol to adopt quantum-safe cryptographic algorithms in the future without requiring fundamental changes to the account abstraction mechanism.


### New Transaction Type

A new [EIP-2718](./eip-2718.md) transaction with type `AA_TX_TYPE` is introduced.
Transactions of this type are referred to as "AA transactions".

The transaction payload should be interpreted as:

```
AA_TX_TYPE || rlp([
  chain_id,
  from,
  payer,
  nonce,
  expiry,
  gas_price,
  gas_limit,
  access_list,
  required_pre_state,
  calldata,
  sender_signature,
  payer_signature
])
```

#### Transaction Fields

**`chain_id`** (uint256): The chain ID as defined in [EIP-155](./eip-155.md). The transaction is only valid on the specified chain.

**`from`** (address): The account that is sending the transaction. This account's validation configuration determines which keys can authorize the transaction.

**`payer`** (address): The account that will pay for the transaction's gas costs. This can be the same as `from` (self-paying) or a different account (sponsored transaction). The payer must also provide a valid signature.

**`nonce`** (uint64): The transaction nonce from the `from` account. This follows standard Ethereum nonce semantics for replay protection. Note that the `payer` account does not use a nonce.

**`expiry`** (uint64): Unix timestamp after which the transaction is no longer valid. This allows transactions to have built-in time limits, preventing stale transactions from being executed.

**`gas_price`** (uint256): The price per unit of gas the payer is willing to pay. This can be lower than, equal to, or higher than the base fee.

**`gas_limit`** (uint64): The maximum amount of gas the transaction can consume.

**`access_list`** (list): [EIP-2930](./eip-2930.md) style access list for pre-warming storage slots and addresses.

**`required_pre_state`** (list): State conditions that must be satisfied for the transaction to be valid. Each entry can be either a standard or explicit condition. This is only used for payer sponsored transactions and is only signed by the payer.

**Standard Condition** (3 elements, ~53 bytes):
```
(condition_id, address, value)
```

Where `condition_id` is a uint16 (2 bytes) encoding the check type:
- **First byte**: Base type
- **Second byte**: Specific check

Standard conditions use enshrined logic to validate common patterns efficiently:

| Condition ID | First Byte | Second Byte | Description | Address Field | Value Field | Comparison |
|--------------|------------|-------------|-------------|---------------|-------------|------------|
| `0x0000` | `0x00` (special) | `0x00` | Wallet implementation | Account to check | Expected implementation address or code hash | `==` |
| `0x0100` | `0x01` (mapping) | `0x00` | Mapping at slot 0 | Contract address | Minimum value | `>=` |
| `0x0101` | `0x01` (mapping) | `0x01` | Mapping at slot 1 | Contract address | Minimum value | `>=` |
| `0x0102` | `0x01` (mapping) | `0x02` | Mapping at slot 2 | Contract address | Minimum value | `>=` |
| ... | ... | ... | ... | ... | ... | ... |
| `0x01FF` | `0x01` (mapping) | `0xFF` | Mapping at slot 255 | Contract address | Minimum value | `>=` |

**Base Type `0x00` (Special Checks)**:
- `0x0000`: Wallet implementation check via EIP-7702 delegation, ERC-1967 proxy slot, or direct code comparison

**Base Type `0x01` (Mapping Checks)**:

For mapping conditions, the actual storage slot is calculated as:
```
actual_slot = keccak256(from_address || base_slot)
```

Where `base_slot` is the second byte of the condition ID (e.g., `0x0100` → slot 0, `0x0101` → slot 1, etc.) and `from_address` is the transaction sender. This enables efficient validation of ERC-20 balances and similar mapping-based checks.

All mapping conditions use `>=` comparison, checking that the value at the computed slot is at least the specified minimum.

**Extensibility**: The 2-byte encoding provides 256 base types with 256 variants each, allowing future EIPs to define additional standard condition types (e.g., `0x02XX` for different patterns).

**Note**: Chains MAY choose to support explicit conditions at some mass invalidation risk. 
**Explicit Condition** (4 elements, 85 bytes):
```
(address, slot, value, comparison)
```

- `address` (address): The account to check
- `slot` (uint256): The storage slot to check
- `value` (uint256): The expected value
- `comparison` (uint8): Comparison operator (`0x00` = `==`, `0x01` = `>=`, `0x02` = `<=`)

If any condition fails, the transaction is invalid and may be dropped from the mempool.

**`calldata`** (bytes): The data to be executed. The interpretation depends on the `from` account's implementation. For EOAs with AA configuration, this typically specifies the operations to perform.
The calldata is sent to the `from` address from itself (tx.orgin is `from` address as well).

**`sender_signature`** (bytes): Signature authorizing the transaction from the sender. Encoding is:
- **For EOA key**: Raw 65-byte ECDSA signature `(r || s || v)` where r and s are 32 bytes each, v is 1 byte
- **For configured key**: `0xFF || key_index || signature_data` where:
  - `0xFF` is a 1-byte prefix indicating configured key signature
  - `key_index` (uint8): Index into the sender's configured key list  
   - `signature_data` (bytes): The actual signature data, format depends on the key type at that index

The `0xFF` prefix distinguishes configured key signatures from EOA signatures (which never start with `0xFF` since `r` values are always less than the curve order).

**`payer_signature`** (bytes): Signature from the payer authorizing gas payment. Uses the same encoding as `sender_signature`. If the `payer` field is empty (self-paying transaction), this field MUST be empty bytes `0x`.

#### Signature Payloads

**Sender signature** is computed over:
```
keccak256(AA_TX_TYPE || rlp([
  chain_id,
  from,
  payer,
  nonce,
  expiry,
  gas_price,
  gas_limit,
  access_list,
  calldata
]))
```

**Payer signature** is computed over:
```
keccak256(AA_TX_TYPE || rlp([
  chain_id,
  from,
  payer,
  nonce,
  expiry,
  gas_price,
  gas_limit,
  access_list,
  required_pre_state,
  calldata
]))
```

Note that the payer signature includes the `required_pre_state` field, allowing the payer to commit to specific state conditions that must be met. This protects the payer from griefing attacks where the sender could manipulate state to cause the payer to pay for a failing transaction.

The nonce is always taken from the `from` address. The `payer` account does not increment a nonce, allowing flexible gas sponsorship without nonce coordination. 


### Gas Abstraction

This proposal enables native gas abstraction through the separation of the transaction sender (`from`) and the gas payer (`payer`). This allows third-party accounts to sponsor transactions outright or in exchange for payment in ERC-20 tokens or other assets.

#### Payer Protection Mechanism

The critical challenge with gas abstraction is preventing **griefing attacks** where a malicious sender causes the payer to spend gas without receiving payment. This proposal solves this through the `required_pre_state` field, which gives the payer strong guarantees about the transaction's execution environment.

#### Typical Protection Pattern

A payer typically uses `required_pre_state` to verify two critical conditions before agreeing to pay for a transaction:

**1. Wallet Code Implementation**

The payer checks that the `from` account uses an approved wallet implementation:

```python
required_pre_state.append({
  'address': from_account,
  'slot': code_hash_slot,  # Storage slot containing code hash or implementation pointer
  'value': approved_wallet_code_hash,
  'condition': 0x00  # Equal
})
```

By validating the wallet implementation, the payer ensures:
- The wallet follows expected payment logic
- The wallet implements proper OOG (out-of-gas) error handling
- The wallet will not maliciously consume gas without paying

**2. ERC-20 Balance**

The payer checks that the `from` account has sufficient ERC-20 token balance to pay for the transaction:

```python
required_pre_state.append({
  'address': erc20_token_address,
  'slot': balance_slot_for_from_account,  # Computed storage slot for balance mapping
  'value': minimum_payment_amount,
  'condition': 0x01  # Greater than or equal
})
```

This ensures the sender has funds available to pay the payer for the gas sponsorship.

#### Wallet Implementation Requirements

For gas abstraction to work safely, payers should trust who they are sponsoring. In the case they cannot, they can trust a set of wallet implementations. Payers are recommended to trust wallets that follow these guidelines:

**Out-of-Gas Handling**: Wallets should implement early revert logic when detecting insufficient gas to complete execution. This prevents situations where:
- The wallet starts executing the calldata
- Runs out of gas mid-execution
- Reverts without completing the payment to the payer
- The payer loses gas without compensation

This pattern ensures that if the transaction doesn't have enough gas, it fails early before consuming significant gas, or if it does proceed, it reserves enough gas to complete the payment to the payer.

**Revert-Handling**: Wallets must handle reverts safely to protect the payer from losing gas without compensation. This is achieved by separating payer payment from user operation execution.

The key principle: **Payer payment must occur in a non-revertible context, even if user operations fail.** 

This design protects payers from griefing while allowing user operations to fail safely 

#### Payer Profitability Guarantees

With `required_pre_state` enforcing:
1. Known wallet implementation (with proper OOG handling)
2. Sufficient ERC-20 balance

The payer can be confident that:
- **Payment is guaranteed**: The wallet code will execute the payment logic
- **No griefing**: The wallet will revert early if it cannot complete + pay
- **Predictable costs**: The wallet implementation's gas usage is known
- **Profitable operation**: The ERC-20 payment exceeds the gas costs

#### Payer as Relay

This design naturally supports a **payer + relay model**:

1. User signs transaction with their key (sender signature) and specifies the relayer's payer address as payer.
2. User sends transaction to relayer service off-chain
3. Payer validates the transaction would be profitable and either adds `required_pre_state` conditions or is interacting with a node that has revert protection or eth_sendRawTransactionConditional capabilities that it can leverage. 
    1. conditions are expected to ensure sender's ERC20 balance does not drop below send amount, the wallet implemenation doesn't change and is in a trusted set to the payer. 
4. Paymaster adds their signature (payer signature) and submits to mempool
5. Transaction executes, wallet pays paymaster in ERC-20
6. Payer has paid ETH for gas, received ERC-20 payment

The payer service acts as a relay service that:
- Accepts ERC20 tokens to land it for gas payment
- Faces minimal griefing risk due to `required_pre_state` protections

#### Required Pre-State Limitations

To prevent DoS attacks on block builders, the `required_pre_state` field is limited:

- **Maximum entries**: `MAX_REQUIRED_PRESTATE_ENTRIES` (3 entries per transaction)
- **Maximum total size**: ~255 bytes (3 entries × 85 bytes per entry)

**Typical Entry Sizes:**

Each `required_pre_state` entry consists of:
- `address`: 20 bytes
- `slot`: 32 bytes
- `value`: 32 bytes
- `condition`: 1 byte
- **Total per entry**: 85 bytes (plus minimal RLP encoding overhead)

**L2 Considerations:**
If the block builder provides other endpoints such as revert protection, eth_sendRawTransactionConditional this can be skipped for save on data usage but the payer should just relay the transaction itself. 
(todo - could also have configurations.)

#### Consideration: Payer Configuration Precompile

A Payer Configuration Precompile at `PAYER_CONFIG_PRECOMPILE` can compress `required_pre_state` from 170 bytes to ~1-4 bytes via reusable config references. This may also enable a type of permissionless sponsorship in the future where an account can specify its required_pre_state in onchain configuration with calldata requirements and then have a no-op signature only for gas sponsorship. 

Details can be specified in a follow-up EIP.

#### Mass Invalidation Mitigation

**Attack vector:** A malicious payer could sponsor many transactions, then change state to invalidate them all simultaneously, wasting block builder resources.

**Key mitigation:** `required_pre_state` checks are unique per sender. This makes attacks expensive:

- **Sender ERC-20 balance**: Payer cannot directly change sender's token balance
- **Sender wallet implementation**: Payer cannot change sender's code/proxy

To invalidate transactions, an attacker would need to:
1. Control or manipulate multiple sender accounts (expensive/difficult)
2. Coordinate state changes across many accounts simultaneously

**Additional protections:**

**Mempool limits per payer:**
```
max_sponsored_txs = min(
    payer_eth_balance / avg_gas_cost,
    MAX_SPONSORED_PER_PAYER  // e.g., 1000
)
```

Block builders limit pending sponsored transactions based on payer's ETH balance, ensuring payers can cover at least some portion of pending transactions.

**Restricted condition types (initial deployment):**

To further reduce attack surface, initial deployment could restrict `required_pre_state` to:
- Sender ERC20 balance checks (any slot) via mapping(address) calculation
- Sender wallet implementation checks

This prevents payer-controlled state from being used in conditions, eliminating the most direct invalidation vector. Future EIPs can expand allowed conditions after observing usage patterns.

**EIP-7928 synergy:** Transaction invalidation tracking combined with simple state lookups makes mempool management efficient even with sponsored transactions.

#### Block Builder 
Block builders validate `required_pre_state` conditions via storage reads without EVM execution. Combined with mempool limits and EIP-7928, this enables efficient handling of sponsored transactions. 


### Transaction Validation and Execution Flow

#### Mempool Acceptance

When a transaction is received by a node:

1. **Signature Validation**: Both sender and payer signatures are validated against onchain account configurations (checking configured keys or EOA keys)
2. **State Condition Checks**: All `required_pre_state` conditions are verified against current state
3. **Balance Check**: Payer account must have sufficient ETH balance to cover `gas_limit * gas_price`
4. **Mempool Threshold Check**: Payer's pending sponsored transaction count must be below the mempool limit
5. **Nonce Check**: Sender's nonce must match the transaction nonce
6. **Expiry Check**: Current timestamp must be before transaction `expiry`

If all checks pass, the transaction is accepted into the mempool and propagated to peers via p2p gossip.

Note that as state is modified during execution, tx may become invalid and be removed from the mempool. This is efficient as each block can emit its state diff via EIP-7928.

#### Block Inclusion

When a block builder selects a transaction for inclusion:

1. **Re-validation**: all conditions are rechecked again against the current state to ensure the transaction is still valid
2. **Inclusion**: If valid, the transaction is included in the block

#### Execution

Once included in a block:

1. **Gas Deduction**: Total gas spent is deducted from the `payer` account (not the `from` account)
2. **Call Context**: `tx.origin` is set to the `from` address
3. **Calldata Delivery**: The `calldata` is delivered to the `from` address via a call from the `from` address (is to itself)
4. **Standard Execution**: Follows standard EVM execution


### Arbitrary Execution

While this proposal constrains **validation** to enshrined key types, it does not constrain **execution** logic. Accounts are completely free to implement whatever execution logic they desire.

#### Separation of Validation and Execution

**Validation (Enshrined)**:
- Authorization of the transaction is determined by the account's configured keys
- Uses protocol-defined signature verification for specific key types
- Must pass validation before any execution begins
- Ensures gas payment authorization is clear to block builders

**Execution (Arbitrary)**:
- Once validated, the account's code can implement any logic
- Supports multisig, timelock, spending limits, session keys, or any custom logic
- The `calldata` field is always delivered TO the `from` account
- The account interprets and executes the calldata as it sees fit


#### Calldata Delivery

The `calldata` field in an AA transaction is **always delivered to the `from` account**. The account is free to interpret this data however it wishes:

- **EOA (no code)**: Calldata might be ignored (no code to orchastrate actions with)
- **Smart contract account**: Calldata encodes actions for the wallet to take

This unopinionated approach to execution maximizes compatibility and flexibility while maintaining the simplicity of enshrined validation.

This also maintains the ability of the wallet developer to create fully programable accounts, as if the calldata could be sent elsewhere it could bypass those controls. 

### Account Initialization 
Accounts can be initialized by
- calling from an EOA to allow additional auth keys
- calling from an existing smart contract wallet implementation
- setting 7702 code and using an EOA to make first transaction, allowing additional keys

The auth precompile can also enable account initialization by providing counter factuctual addresses and owner setup.

### Standard RPCs

Standard Ethereum RPC methods work seamlessly with validation transactions with minimal modifications:

#### `eth_estimateGas`

Works as-is with validation transactions. Accounts can estimate gas for their transaction using the standard RPC call. For accounts that have not yet been initialized, wallet providers can use state overrides to temporarily inject the wallet code during estimation.

#### `eth_sendRawTransaction`

Works as-is using the new validation transaction type (`VALIDATION_TX_TYPE`). The RLP-encoded transaction is submitted through the standard RPC endpoint:

#### `eth_getTransactionReceipt`

Works as-is but **SHOULD** include an additional `payer` field in the receipt to indicate which address paid for the transaction gas. This is important for validation transactions where the `from` address may differ from the actual gas payer:

The `payer` field helps wallets, indexers, and users accurately track which account paid for transaction execution.

### Security Properties

This proposal provides security guarantees for three key participants: senders, payers, and block builders.

#### Sender Security

**Account Control**: Senders maintain full control over their account's authentication configuration. The account owner can add or remove keys at any time through the Account Configuration precompile.

**EOA Privilege**: The account's original EOA key always retains authorization regardless of configuration changes. This provides a guaranteed recovery mechanism—accounts cannot be permanently locked out through misconfiguration. Users who prefer maximum security can choose to maintain this EOA option, while others can opt into pure smart account implementations that do not have this property.

**Delegation Safety**: Account implementations should exercise caution with `DELEGATECALL` operations, as delegated code could potentially bypass intended authorization controls. Standard wallet implementations should follow security best practices and undergo thorough auditing.

**Replay Protection**: Transactions include `chain_id` and `nonce` fields, providing standard Ethereum replay protection. The `expiry` field adds time-based replay protection, preventing old transactions from being executed indefinitely.

#### Payer Security

**Execution Guarantees**: Payers receive strong guarantees through the `required_pre_state` mechanism. By validating both the wallet implementation and account state (such as ERC-20 balances), payers can ensure:
- The sender's wallet follows expected payment logic
- Sufficient funds exist to compensate the payer
- The transaction will execute as anticipated

**State and Code Validation**: The combination of wallet implementation checks and state conditions gives payers confidence that they will receive payment for their gas sponsorship. 

**Extensibility**: While initially designed for ERC20 token transfers in exchange for sponsorship, the model extends to other payment mechanisms and use cases. Any account can act as a sponsor.

**Payment Flexibility**: On cost-efficient Layer 2 networks where gas costs are minimal (e.g., $0.01 per transaction), simple transfer-based payment models become practical. Wallet/sponsor pairs may implement refund mechanisms for unused gas, or use fixed-price sponsorship models depending on their business requirements.

#### Block Builder Security

**Efficient Validation**: Block builders validate transactions using the warm Account Configuration precompile address, minimizing gas costs and enabling fast validation without EVM execution.

**Simple State Checks**: The `required_pre_state` conditions allow builders to verify transaction validity through simple storage reads. No arbitrary code execution is required before determining if gas will be paid.

**Efficient Invalidation Tracking**: Transactions can be efficiently invalidated by monitoring:
- Payer balance updates
- Account authentication configuration changes  
- Any `required_pre_state` condition changes

This enables efficient mempool management, especially when combined with [EIP-7928](./eip-7928.md) for state diff tracking.

**DoS Protection**: The constrained validation model prevents DoS attacks where malicious transactions consume builder resources without paying for gas. The payer is always known before execution begins, and signature validation is performed using enshrined logic rather than arbitrary code. Mass invalidation is difficult due to restricted prestateChecks where multiple accounts won't be marking the same slot.

#### Gas Abstraction Security

**Payer Protection Model**: Gas sponsors are expected to ensure they receive adequate compensation to cover gas costs. The `required_pre_state` mechanism provides the tools to enforce this:
- Validate wallet implementation is trusted
- Verify sufficient token balance exists
- Confirm other critical state conditions (in the future)

**Griefing Resistance**: Properly configured `required_pre_state` conditions prevent griefing attacks where senders might attempt to cause payers to waste gas without receiving payment. Payers should only sponsor transactions for trusted wallet implementations or accounts they control.

**Mempool Economics**: Mempool operators limit pending sponsored transactions per payer based on the payer's ETH balance, preventing a single payer from flooding the mempool with transactions they cannot afford to execute.

## Backwards Compatibility

This proposal introduces a new transaction type and precompile but does not break compatibility with existing accounts or contracts.

**No Breaking Changes**: Existing EOAs and smart contracts continue to function exactly as before. The proposal is fully opt-in:

- **Existing EOAs**: Can continue to send standard transactions without any changes
- **Existing Smart Contracts**: Are unaffected and continue to operate normally
- **Account Abstraction Solutions**: [EIP-4337](./eip-4337.md) infrastructure continues to work as-is. This proposal provides a complementary native alternative

**Opt-In Adoption**: Accounts only gain AA capabilities when they:
1. Configure additional keys through the Account Configuration precompile, OR
2. Send transactions using the new AA transaction type. Note only EOAs have this path by default. 

**Tooling Impact**: Wallets and infrastructure that wish to support AA transactions will need to:
- Implement signing logic for the new transaction type
- Support account configuration management
- Handle the optional payer field for gas sponsorship

**Migration Path**: Users can incrementally adopt AA features:
- Start with standard EOA transactions
- Add additional authentication keys when desired
- Begin using AA transactions for advanced features like gas sponsorship

The upgrade requires network-wide adoption through a scheduled hard fork to enable the new transaction type and precompile, but no individual accounts are forced to change their behavior.


## Security Considerations

### Validation Security

**Protection from Bypass**: Validation logic is enshrined at the protocol level and cannot be bypassed. Signature verification happens before any EVM execution begins, ensuring that only authorized keys can create valid transactions. The Account Configuration precompile enforces access controls—only `msg.sender` can modify their own configuration.

**Validation Failure**: If signature validation fails, the transaction is rejected before entering the mempool or being included in a block. No gas is consumed and no state changes occur. This is a clean rejection at the protocol level.

**Replay Protection**: Transactions include `chain_id`, `nonce`, and `expiry` fields:
- `chain_id` prevents cross-chain replay attacks
- `nonce` provides standard Ethereum sequential replay protection
- `expiry` prevents stale transactions from being executed indefinitely

**Front-Running**: Standard MEV front-running concerns apply as with any Ethereum transaction. The `expiry` field allows users to limit the time window during which their transaction is valid, reducing exposure to delayed execution attacks.

### Gas Security

**Bounded Validation Costs**: Gas consumption for validation is bounded by enshrined intrinsic gas costs for each key type. Block builders can compute exact validation costs without executing arbitrary code.

**No Arbitrary Execution Before Payment**: Unlike proposals with arbitrary validation code, this proposal ensures the gas payer is known before any EVM execution occurs. This prevents DoS attacks where malicious transactions consume validator resources without paying.

**Payer Griefing Protection**: The `required_pre_state` mechanism protects payers from griefing:
- Payers verify wallet implementation is trusted before sponsoring
- State conditions ensure sender has funds to compensate payer
- Wallet implementations should handle out-of-gas conditions safely

**Mempool DoS Protection**: Mempool operators limit pending sponsored transactions per payer based on ETH balance, preventing spam attacks with unpayable transactions.

### Authorization Security  

**Signature Verification**: All signatures are verified using enshrined cryptographic algorithms with well-established security properties. Verification follows standard practices for each key type (ECDSA for K1/R1, BLS12-381 for BLS, WebAuthn standards for passkeys).

**Key Management**: Account owners maintain full control over their key configuration. Keys can be added or removed at any time. The original EOA key always retains authorization as a recovery mechanism, preventing permanent lockout from misconfiguration.

**Multi-Key Security**: When multiple keys are configured, any single authorized key can sign transactions. Account implementations should implement additional logic (multisig, thresholds, etc.) in their execution layer if multiple approvals are desired.

**Delegation Risks**: The `DELEGATE` key type delegates validation to another account. This delegation is limited to 1 hop to prevent complex delegation chains. Accounts should carefully consider the security implications before delegating validation authority.

### MEV Considerations

**Standard MEV Risks**: AA transactions face standard MEV risks including front-running, back-running, and sandwich attacks. The `expiry` field provides some protection by allowing users to specify time bounds.

**Sponsored Transaction MEV**: Gas-sponsored transactions may create MEV opportunities:
- Payers might selectively delay transactions to optimize their own profitability
- Payers could potentially censor transactions that compete with their interests
- Users should consider these risks when choosing sponsors


### Interaction Risks

**EIP-7702 Compatibility**: This proposal works well with [EIP-7702](./eip-7702.md). EOAs can use 7702 to temporarily set code, enabling smart wallet functionality. The Account Configuration precompile provides authentication while 7702 provides execution logic.

**EIP-4337 Coexistence**: [EIP-4337](./eip-4337.md) infrastructure continues to operate unchanged. Some users may prefer native AA transactions for gas efficiency, while others may prefer 4337's application-layer approach. Both can coexist and accounts can use both pathways if desired.

**Contract Assumptions**: Existing contracts that make assumptions about `tx.origin` or `msg.sender` behavior continue to work correctly. The `tx.origin` is always the `from` address in AA transactions.

**State Dependencies**: Contracts relying on `required_pre_state` should understand that transactions may be invalidated if state changes. This is similar to standard transaction nonce invalidation but extends to storage slot monitoring.

### Implementation Risks

**Wallet Implementation Security**: The security of gas-sponsored transactions depends heavily on wallet implementation quality:

**Out-of-Gas Handling**: Wallets must implement proper OOG protection to prevent griefing payers

**Payment Logic**: Payer payment must occur in a non-revertible context

**DELEGATECALL Safety**: Wallets using `DELEGATECALL` must carefully audit delegated code. Malicious delegated code could bypass authentication controls or manipulate payment logic.

### Quantum Resistance

**Future-Proofing**: The design explicitly supports adding new key types through future EIPs. When quantum-safe cryptographic algorithms are needed, they can be added as new key types without changing the core AA mechanism.

**Migration Path**: When quantum threats become imminent, the EOA key default authorization may need to be phased out, as noted in the specification. Users would transition to quantum-safe key types through the configuration mechanism.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
