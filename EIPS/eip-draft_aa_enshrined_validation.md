---
title: Standardized Account Abstraction with Onchain Key Configurations
description: Enable account abstraction through onchain account configurations.
author: Chris Hunter (@_chunter)
discussions-to: TBD
status: Draft
type: Standards Track
category: Core
created: 2025-10-14
requires: 2718, 2930, 7702
---

## Abstract

This proposal introduces a standardized validation mechanism for account abstraction, utilizing onchain account configurations to define accepted keys and key types. Unlike EIP-7701/RIP-7560, which permits arbitrary validation code, this approach restricts validation to a predefined set of key types and rules, ensuring protocol simplicity and secure account abstraction without requiring EVM code execution. A new transaction type leverages this new validation mechanism and includes support for native gas abstraction. This design aims to maintain the simplicity of block builder's validation logic to ensure block building can operate without heavy mempool restrictions or DoS risks. It also maintains compatibility with existing account abstraction mechanisms, such as EIP-7702 and ERC-4337 and future integration of quantum-safe cryptographic algorithms.


## Motivation

Account abstraction (AA) has been a long-standing goal for Ethereum, aiming to provide users with more flexible and secure account management. This proposal aims to enable all the benefits of account abstraction—including batching, gas sponsorship, custom authentication and programable account logic—while addressing critical implementation challenges that have hindered adoption of existing solutions.

### Existing Solutions

| Solution | Approach | Limitations |
|----------|----------|-------------|
| [EIP-4337](./eip-4337.md) | Application-layer abstraction | Complex mempool rules ([ERC-7562](./erc-7562.md)), high gas overhead, entrypoint contract costs, separate infrastructure |
| [EIP-7701](./eip-7701.md) | Protocol-level with arbitrary validation code | Complex mempool rules ([ERC-7562](./erc-7562.md)), major protocol changes, complex block building |

This proposal addresses these limitations by:
- **Simplifying AA Validation**: Uses predefined key types, eliminating EVM execution during validation
- **Enhancing Block Building**: Block builders validate transactions with only state lookups
- **Maintaining AA Benefits**: Preserves all standard account abstraction benefits
- **Reducing Gas Costs**: Eliminates entrypoint contracts and associated overheads
- **Minimal EVM Changes**: Only new opcodes for transaction context
- **Ensuring Extensibility**: Supports future quantum-safe algorithms via new key types
- **Maintaining Compatibility**: Coexists with EIP-7702 and ERC-4337
- **Improving Compressibility**: Structured validation fields reduce calldata costs for L2 rollups


## Specification

### Constants

| Name                     | Value             | Comment |
|--------------------------|-------------------|---------|
| `AA_TX_TYPE`             | TBD               | [EIP-2718](./eip-2718.md) transaction type |
| `AA_BASE_COST`           | 15000             | Base intrinsic gas cost for AA transaction |
| `ACCOUNT_CONFIG_PRECOMPILE` | TBD            | Address of the Account Configuration precompile |
| `MAX_REQUIRED_PRESTATE_ENTRIES` | 3         | Maximum number of required_pre_state conditions per transaction |
| `PRESTATE_ENTRY_BASE_COST` | 100            | Base gas cost per required_pre_state entry |


### Account Configuration

Each account can optionally configure a list of authorized keys that are permitted to sign transactions on its behalf. This configuration consists of an ordered array of key entries, where each entry specifies a key type and the public key data.

Account configurations are stored and managed through a canonical **Account Configuration Precompile** at a designated address (TBD).

It provides key management with access control only provided to `msg.sender`, enabling all account types to manage their auth config. 

The account configuration precompile is chosen over:
1. Having each account use a storage slot at its address, or
2. Modifying the account node to include a new entry for configurations

Reasons:
- **Compatibility**: Works immediately on all chains that adopt this EIP without requiring new opcodes
- **Performance**: The precompile address can be kept warm for cheap lookups during validation
- **Standardization**: Provides a canonical interface that wallets, block builders, and tooling can rely on across all chains
- **Efficiency**: Dedicated storage optimized for key configurations, separate from contract storage

Note that though tx validation is done outside of execution, modification to the account configuration is done within execution.

#### Account Configuration Precompile

The Account Configuration precompile provides a standardized interface for managing authentication keys per account. Access control is enforced at the protocol level - only `msg.sender` can modify their own account configuration.

**Precompile Address**: `ACCOUNT_CONFIG_PRECOMPILE` (TBD)

**Critical Design Principle**: The protocol performs validation **outside of EVM execution** by reading storage directly at known slots. The precompile interface is used by accounts during execution to manage their keys, but the protocol never calls into the EVM during transaction validation.

##### Storage Layout

The precompile uses a deterministic storage layout that the protocol can read directly during validation:

```
Base slot for account: keccak256(account_address || ACCOUNT_CONFIG_PRECOMPILE)

Slot layout:
- base_slot + 0: key_count (uint8)
- base_slot + 1 + (index * 2) + 0: key_type[index] (uint8) 
- base_slot + 1 + (index * 2) + 1: key_data[index] (bytes)
```

For example, to get key at index 2 for an account:
```
base = keccak256(account_address || ACCOUNT_CONFIG_PRECOMPILE)
key_type = SLOAD(base + 1 + (2 * 2) + 0) = SLOAD(base + 5)
key_data = SLOAD(base + 1 + (2 * 2) + 1) = SLOAD(base + 6)
```

This layout enables:
- **Two sequential lookups for key**: Read slots `base + 1 + (index * 2)` and `base + 1 + (index * 2) + 1` to get both type and data
- **Predictable addresses**: Protocol can compute slots without EVM execution
- **Efficient validation**: Block builders warm the base slot and read sequentially

**Protocol Validation Flow**:
1. Compute `base_slot = keccak256(account_address || ACCOUNT_CONFIG_PRECOMPILE)`
2. Read `key_count` from `base_slot + 0`
3. If signature uses key_index N, read:
   - `key_type` from `base_slot + 1 + (N * 2) + 0`
   - `key_data` from `base_slot + 1 + (N * 2) + 1`
4. Validate signature using the key_type algorithm and key_data

##### Solidity Interface

The following interface is provided for **account management** within EVM execution.

```solidity
/// @title IAccountConfig
/// @notice Interface for the Account Configuration precompile
interface IAccountConfig {
    
    /// @notice Represents a single authentication key entry
    /// @param keyType The cryptographic algorithm identifier (K1=0x01, R1=0x02, WEBAUTHN=0x03, BLS=0x04, DELEGATE=0x05)
    /// @param publicKey The public key data, format depends on keyType
    struct AuthKey {
        uint8 keyType;
        bytes publicKey;
    }
    
    /// @notice Emitted when a key is added to an account's configuration
    /// @param account The account that added the key
    /// @param keyIndex The index where the key was added
    /// @param keyType The type of key added
    /// @param publicKey The public key data
    event KeyAdded(address indexed account, uint8 keyIndex, uint8 keyType, bytes publicKey);
    
    /// @notice Emitted when a key is removed from an account's configuration
    /// @param account The account that removed the key
    /// @param keyIndex The index of the removed key
    event KeyRemoved(address indexed account, uint8 keyIndex);
    
    /// @notice Emitted when an account's configuration is cleared
    /// @param account The account that cleared their configuration
    event ConfigurationCleared(address indexed account);
    
    /// @notice Add a new authentication key to the caller's configuration
    /// @dev Only callable by the account itself (msg.sender)
    /// @param keyType The cryptographic algorithm type
    /// @param publicKey The public key data
    /// @return keyIndex The index of the newly added key
    function addKey(uint8 keyType, bytes calldata publicKey) external returns (uint8 keyIndex);
    
    /// @notice Remove a key at the specified index from the caller's configuration
    /// @dev Only callable by the account itself (msg.sender)
    /// @dev Removes the key and shifts all subsequent keys down by one index
    /// @param keyIndex The index of the key to remove
    function removeKey(uint8 keyIndex) external;
    
    /// @notice Get authentication key information at the specified index
    /// @param account The account to query
    /// @param keyIndex The index of the key to retrieve
    /// @return keyType The cryptographic algorithm type (0 if index out of bounds)
    /// @return publicKey The public key data (empty if index out of bounds)
    function getKey(address account, uint8 keyIndex) external view returns (uint8 keyType, bytes memory publicKey);
    
    /// @notice Get the total number of configured keys for an account
    /// @param account The account to query
    /// @return count The number of keys in the account's configuration
    function getKeyCount(address account) external view returns (uint8 count);
    
    /// @notice Get all authentication keys for an account
    /// @param account The account to query
    /// @return keys Array of all configured authentication keys
    function getAllKeys(address account) external view returns (AuthKey[] memory keys);
    
    /// @notice Validate if a signature is authorized for an account at a specific key index
    /// @dev Helper function for smart contracts to check signature validity during execution
    /// @param account The account to validate against
    /// @param keyIndex The index of the key to use for validation (0xFF means EOA key)
    /// @param messageHash The hash of the message that was signed
    /// @param signature The signature data
    /// @return isValid True if the signature is valid for the specified key
    function validateSignature(
        address account, 
        uint8 keyIndex, 
        bytes32 messageHash, 
        bytes calldata signature
    ) external view returns (bool isValid);
}
```

#### Default Configuration

**The default configuration for an account is an empty array `[]`.**

When an account has an empty configuration (no configured keys), only the account's standard EOA key (the key derived from the account address) can authorize transactions. This ensures backward compatibility—existing EOAs work without any configuration.

#### EOA Key Always Valid

**Important: The account's original EOA key always has authorization, regardless of the configured key list.**

Even if an account configures additional keys, the standard ECDSA key associated with the account address can always sign transactions. This ensures that EOA behaviour is preserved and accounts can recover with privileged de-escalation.

When validating a transaction signature, the protocol checks:
1. First, if the signature is valid for the account's EOA key
2. If not, check if the signature matches any configured key in the account's key list

Note we expect this behaviour to be removed in the future during any EOA deprecation.


### Key Types

This proposal enshrines support for specific cryptographic signature algorithms which is expected to be expanded upon in the future. Each key type has a unique identifier and defined signature format. The protocol validates signatures according to the specified key type.

The following key types are supported:

| Key Type | ID | Algorithm | Public Key Size | Signature Size | Intrinsic Gas Cost |
|----------|-----|-----------|-----------------|----------------|-------------------|
| `K1` | `0x01` | secp256k1 (ECDSA) | 33 bytes (compressed) or 65 bytes (uncompressed) | 65 bytes (r, s, v) | 7000 |
| `R1` | `0x02` | secp256r1 / P-256 (ECDSA) | 33 bytes (compressed) or 65 bytes (uncompressed) | 64 bytes (r, s) | 8000 |
| `WEBAUTHN` | `0x03` | WebAuthn / Passkey | 65 bytes (uncompressed P-256) | Variable (includes authenticator data) | 15000 |
| `BLS` | `0x04` | BLS12-381 | 48 bytes (compressed G1) | 96 bytes (G2 signature) | 9000 | 
| `DELEGATE` | `0x05` | Delegated validation | 20 bytes (account address) | Variable (depends on delegated account) | 5000 + delegated sig |

- **BLS**: Supports signature aggregation for data availability efficiency. Nodes can reduce intrinsic gas costs for this or cut L1 data fees if relevant.
- **Extensibility**: New key types can be added via future EIPs.

#### DELEGATE Key Type

The `DELEGATE` key type allows an account to delegate its validation to another account's configuration. This enables shared key management across multiple accounts.

**Validation Rules**:

1. Read the delegated account address from `key_data` (20 bytes)
2. Load the delegated account's auth configuration from the precompile
3. **Loop prevention**: If the delegated account has a `DELEGATE` key at the signing index, validation **FAILS**. Only 1 hop is permitted.
4. Validate the signature against the delegated account's keys (K1, R1, WebAuthn, BLS, or EOA)

**Example**:
```
Account A config: [{ type: DELEGATE, data: Account_B_address }]
Account B config: [{ type: R1, data: passkey_pubkey }]

Transaction for Account A signed with Account B's passkey → VALID
Transaction for Account A signed with Account B's EOA key → VALID
```

**Use Cases**:
- Shared organization keys across multiple accounts
- Key management delegation to a dedicated "keyring" account
- Future integration with cross-chain key registries (e.g., Keyspace rollup)


### New AA Transaction Type

A new [EIP-2718](./eip-2718.md) transaction with type `AA_TX_TYPE` is introduced.
Transactions of this type are referred to as "AA transactions".

The transaction payload should be interpreted as:

```
AA_TX_TYPE || rlp([
  chain_id,
  from,
  payer,
  nonce_key,          // 2D nonce: channel key (uint192)
  nonce_sequence,     // 2D nonce: sequence within channel (uint64)
  expiry,
  gas_price,
  gas_limit,
  access_list,
  authorization_list,
  calldata,
  required_pre_state,
  sender_signature,
  payer_signature
])
```

#### Intrinsic Gas Calculation

The total intrinsic gas for an AA transaction is calculated as:

```
intrinsic_gas = AA_BASE_COST + sender_key_cost + payer_key_cost + calldata_cost
```

Where `sender_key_cost` and `payer_key_cost` are determined by the key types used for each signature (see [Key Types](#key-types) table).

#### Transaction Fields

**`chain_id`** (uint256): The chain ID as defined in [EIP-155](./eip-155.md). The transaction is only valid on the specified chain.

**`from`** (address): The account that is sending the transaction. This account's validation configuration determines which keys can authorize the transaction.

**`payer`** (address): The account that will pay for the transaction's gas costs. This can be the same as `from` (self-paying) or a different account (sponsored transaction). The payer must also provide a valid signature. If empty, defaults to `from`.

**`nonce_key`** (uint192): The 2D nonce channel key. Allows parallel transaction processing across different keys.

**`nonce_sequence`** (uint64): The sequence number within the nonce channel. Must be exactly `current_sequence` for the given `(from, nonce_key)` pair. Incremented by the protocol after successful execution.

The 2D nonce system enables parallel transactions: different `nonce_key` values can be processed independently, while transactions with the same `nonce_key` are ordered by `nonce_sequence`. Note that the `payer` account does not use its own nonce.

**`expiry`** (uint64): Unix timestamp after which the transaction is no longer valid. This allows transactions to have built-in time limits, preventing stale transactions from being executed.

**`gas_price`** (uint256): The price per unit of gas the payer is willing to pay.

**`gas_limit`** (uint64): The maximum amount of gas the transaction can consume.

**`access_list`** (list): [EIP-2930](./eip-2930.md) style access list for pre-warming storage slots and addresses.

**`authorization_list`** (list): [EIP-7702](./eip-7702.md) standard authorization list for setting account code.

**`calldata`** (bytes): The data to be delivered to the `from` account. The interpretation depends on the account's implementation. For smart accounts, this typically encodes the operations to perform.

**`required_pre_state`** (list): Optional list of state conditions that must be satisfied for the transaction to be valid. Each entry specifies a slot and expected value. Limited to `MAX_REQUIRED_PRESTATE_ENTRIES` entries. Used by payers to protect against griefing.

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
  nonce_key,
  nonce_sequence,
  expiry,
  gas_price,
  gas_limit,
  access_list,
  authorization_list,
  calldata
]))
```

**Payer signature** is computed over the same payload, ensuring both parties agree on all transaction parameters.

#### Required Pre-State

The `required_pre_state` field allows payers to specify conditions that must hold for the transaction to be valid. Each entry is:

```
{
  address: address,      // Must be from, payer, or reference from/payer
  slot: bytes32,         // Storage slot to check
  expected_value: bytes32 // Required value
}
```

**Gas Costs**:

| Component | Gas Cost |
|-----------|----------|
| Base cost per entry | 100 |
| Cold address access | 2600 (per [EIP-2929](./eip-2929.md)) |
| Warm address access | 100 |
| Cold slot read | 2100 |
| Warm slot read | 100 |

Each `required_pre_state` entry adds to the transaction's intrinsic gas. Addresses and slots in the `access_list` are considered warm.

**Restrictions**:
- Address must be `from`, `payer`, or contain `from`/`payer` address in the slot computation
- Maximum `MAX_REQUIRED_PRESTATE_ENTRIES` (3) entries per transaction
- Prevents mass invalidation attacks by limiting what can be checked

**Use Cases**:
- Verify wallet implementation (code hash)
- Check ERC-20 balance for payment
- Ensure account hasn't been modified

Payers can alternatively use `eth_sendRawTransactionConditional` or builder revert protection for more flexibility.


### 2D Nonce System

This proposal uses a two-dimensional nonce system to enable parallel transaction processing. Instead of a single sequential nonce, each account has multiple nonce channels identified by a `nonce_key`.

#### Storage Layout

Nonces are stored in the Account Configuration precompile:

```
Base slot: keccak256(account_address || ACCOUNT_CONFIG_PRECOMPILE || "nonce")
Nonce slot: base_slot + nonce_key
Value: current_sequence (uint64)
```

#### Validation

For a transaction to be valid:
- `nonce_sequence` must equal the current sequence for `(from, nonce_key)`
- The protocol increments `current_sequence` after the transaction is included in a block

**Nonce increment happens regardless of execution outcome**. If the transaction is included but execution reverts, the nonce is still incremented and gas is charged. This matches standard Ethereum transaction behavior.

#### Benefits

- **Parallel transactions**: Different `nonce_key` values can be processed independently
- **No blocking**: A pending transaction on key 0 doesn't prevent transactions on key 1
- **Per-channel ordering**: Within a channel, transactions are still strictly ordered
- **Backwards compatible**: Using `nonce_key = 0` behaves like traditional sequential nonces

#### Example

```
User sends 3 transactions simultaneously:
  - (key: 0, seq: 5) → swap on DEX
  - (key: 1, seq: 3) → mint NFT  
  - (key: 2, seq: 0) → transfer tokens

All can be included in the same block without waiting for sequential confirmation.
```


### New Opcodes for Transaction Context

To allow wallet code to access transaction context, two new opcodes are introduced:

| Opcode | Value | Gas | Description |
|--------|-------|-----|-------------|
| `AAPAYER` | TBD | 2 | Returns the payer address from current AA transaction |
| `AASIGNER` | TBD | 2 | Returns the key index used by sender (0xFF = EOA key) |

**`AAPAYER`**: Pushes the `payer` address onto the stack. Returns `from` address if not an AA transaction (self-paying).

**`AASIGNER`**: Pushes the key index used to sign the transaction. Returns `0xFF` if the EOA key was used, or the configured key index otherwise. Returns `0xFF` if not an AA transaction.

These opcodes allow wallet implementations to:
- Implement payer-specific logic (e.g., transfer tokens to payer)
- Enforce key-based permissions (e.g., session keys with limited capabilities)
- Log which key authorized an action


### Gas Abstraction

This proposal enables native gas abstraction through the separation of the transaction sender (`from`) and the gas payer (`payer`). This allows third-party accounts to sponsor transactions outright or in exchange for payment in ERC-20 tokens or other assets.

Payers can protect themselves from griefing via:
1. **`required_pre_state`**: Validate wallet implementation and balances in transaction
2. **`eth_sendRawTransactionConditional`**: Builder-level conditional inclusion
3. **Builder revert protection**: Rely on builders to not include reverting txs

**Payer Security Note**: Payers should initially use **EOA keys** (not rotatable auth config keys) to prevent mass invalidation attacks where a payer could change their keys and invalidate many sponsored transactions in the mempool.


### Pure Smart Account Initialization

This proposal introduces a mechanism for creating new smart accounts with pre-configured authentication keys, similar to [EIP-7702](./eip-7702.md) but for account creation.

#### Authorization Tuple

A new authorization tuple format enables account creation within an AA transaction:

```
account_init_auth = rlp([
  chain_id,
  salt,              // Salt for address derivation
  initial_keys,      // Array of AuthKey structs to configure
  code_hash,         // Hash of the wallet bytecode to deploy
  key_index,         // Index into initial_keys for signature verification
  signature          // Signature over this tuple (excluding signature field)
])
```

The target `address` is derived from `(salt, initial_keys, code_hash)` as shown in [Counterfactual Addresses](#counterfactual-addresses).

The `signature` must be valid for the key at `key_index` within `initial_keys`. This proves the account creator controls at least one of the authorized keys.

**Signature payload** for account init:
```
keccak256(rlp([chain_id, salt, initial_keys, code_hash, key_index]))
```

#### Address Derivation

The target address is derived deterministically using CREATE2-style derivation:

```
address = keccak256(0xff || ACCOUNT_CONFIG_PRECOMPILE || salt || keccak256(abi.encode(initial_keys, code_hash)))[12:]
```

See [Counterfactual Addresses](#counterfactual-addresses) for the full computation.

#### Initialization Flow

When an AA transaction includes an account initialization authorization:

1. **Validate Authorization**: 
   - Verify `chain_id` matches
   - Derive target address from `(salt, initial_keys, code_hash)`
   - Verify target address has no code and account nonce is 0
   - Verify `key_index` is valid (< length of `initial_keys`)
   - Verify signature is valid for `initial_keys[key_index]`

2. **Deploy Account**:
   - Set the account's auth configuration to `initial_keys` via the precompile
   - Deploy wallet bytecode at the target address (similar to CREATE2)
   - Account is now ready to receive the transaction's calldata

3. **Execute Transaction**:
   - Deliver `calldata` to the newly created account
   - Account processes the calldata using its deployed code

This enables **single-transaction account creation and first operation**—users don't need a separate transaction to deploy their wallet before using it.

#### Counterfactual Addresses

Wallet providers can compute account addresses before creation:

```solidity
function computeAddress(
    AuthKey[] memory initialKeys,
    bytes32 codeHash,
    bytes32 salt
) public pure returns (address) {
    bytes32 data = keccak256(abi.encode(initialKeys, codeHash));
    return address(uint160(uint256(keccak256(
        abi.encodePacked(bytes1(0xff), ACCOUNT_CONFIG_PRECOMPILE, salt, data)
    ))));
}
```

The `salt` parameter allows wallet providers to generate unique addresses from the same key configuration. Users can receive funds at their counterfactual address before the account is deployed.

**Note**: The `salt` used in the actual `account_init_auth` must match the salt used to derive the address. This is typically derived from or equal to a user-provided value.


### Transaction Validation and Execution Flow

#### Mempool Acceptance

When a transaction is received by a node:

1. **Signature Validation**: Both sender and payer signatures are validated against onchain account configurations by checking configured keys or EOA keys.
2. **Nonce Check**: Sender's nonce must be valid.
3. **Balance Check**: Payer account must have sufficient ETH balance to cover `gas_limit * gas_price`
4. **Required Pre-State Check**: All `required_pre_state` conditions must be satisfied
5. **Expiry Check**: Current timestamp must be before transaction `expiry`
6. **Mempool Threshold Check**: Payer's pending sponsored transaction count must be below the mempool limit

If all checks pass, the transaction is accepted into the mempool and propagated to peers.

#### Block Inclusion

When a block builder selects a transaction for potential inclusion it revalidates all conditions against current state. If all conditions hold it can be included in the block.

#### Execution

Once included in a block:

1. **Gas Deduction**: Total gas spent is deducted from the `payer` account (not the `from` account)
2. **Authorization Processing**: If `authorization_list` is non-empty, process 7702 authorizations
3. **Account Initialization**: If account init authorization is present, deploy the new account
4. **Call Context**: `tx.origin` is set to the `from` address
5. **Calldata Delivery**: The `calldata` is delivered to the `from` address via a call where `msg.sender` = `from` (self-call)
6. **Standard Execution**: Follows standard EVM execution rules


### Arbitrary Execution

While this proposal constrains **validation** to enshrined key types, it does not constrain **execution** logic. Accounts are completely free to implement whatever execution logic they desire.

#### Separation of Validation and Execution

**Validation (Enshrined)**:
- Authorization of the transaction is determined by the account's configured keys
- Must pass validation before any execution begins
- Ensures gas payment authorization is clear to block builders

**Execution (Arbitrary)**:
- Once validated, the account's code can implement any logic
- Supports multisig, timelock, spending limits, session keys, or any custom logic
- The `calldata` field is always delivered TO the `from` account

#### Calldata Delivery

The `calldata` field in an AA transaction is **always delivered to the `from` account** via a message call with the following parameters:

| Parameter | Value |
|-----------|-------|
| `to` | `from` address |
| `msg.sender` | `from` address (self-call) |
| `msg.value` | 0 |
| `data` | `calldata` field from transaction |
| `gas` | Remaining gas after intrinsic costs |

**Behavior by account type**:

- **EOA (no code)**: Call succeeds immediately with no effect. Calldata is ignored.
- **Smart contract account**: Execution begins at the contract's code entry point. The contract interprets `calldata` according to its implementation (typically ABI-encoded function calls).

**Return data and logs** from the call are captured in the transaction receipt as normal.

**Why self-call?** This ensures:
1. `msg.sender` is the account itself, maintaining expected access control patterns
2. Wallet code can trust that authorized keys approved the calldata
3. No external caller can inject calldata directly into the wallet

This also maintains the ability of the wallet developer to create fully programmable accounts. If the calldata could be sent elsewhere with `tx.origin` being the account address, it could bypass wallet-level controls.


### Standard RPCs

Standard Ethereum RPC methods work seamlessly with AA transactions with minimal modifications:

#### `eth_estimateGas`

Works as-is with AA transactions. Accounts can estimate gas for their transaction using the standard RPC call. For accounts that have not yet been initialized, wallet providers can use state overrides to temporarily inject the wallet code during estimation.

#### `eth_sendRawTransaction`

Works as-is using the new transaction type envelope once nodes support.

#### `eth_getTransactionReceipt`

Works as-is but **SHOULD** include an additional `payer` field in the receipt to indicate which address paid for the transaction gas.


## Rationale

### Why a Precompile Instead of Account Storage?

Using a dedicated precompile rather than per-account storage slots provides:

1. **Cross-chain consistency**: Same precompile address on all chains adopting this EIP
2. **Tooling simplicity**: Single canonical location for key lookups across all accounts
3. **No storage conflicts**: Auth configuration is separate from account's contract storage
4. **Warmth optimization**: Precompile address can be kept warm for efficient validation

Alternative approaches considered:
- **Per-account storage slots**: Would conflict with contract storage and complicate tooling
- **New account trie field**: Would require deeper protocol changes and client modifications

### Why Enshrine Specific Key Types?

Enshrining specific key types (K1, R1, WebAuthn, BLS) rather than allowing arbitrary validation code:

1. **Mempool safety**: Validation is deterministic and bounded—no unbounded computation
2. **Block builder efficiency**: No EVM execution during validation phase
3. **Security auditability**: Well-known cryptographic algorithms vs arbitrary code
4. **Extensibility preserved**: New key types can be added via future EIPs without breaking changes

The tradeoff is reduced flexibility in validation logic, but this is acceptable because:
- Most wallet implementations use standard signature schemes
- Complex validation logic can still be implemented in the execution phase
- Session keys and spending limits work via execution-layer enforcement

### Why 2D Nonces?

Traditional sequential nonces create head-of-line blocking where a pending transaction prevents subsequent transactions from being processed. The 2D nonce system allows:

1. **Parallel transaction streams**: Different nonce keys can be processed independently
2. **No blocking**: A stuck transaction on key 0 doesn't prevent transactions on key 1
3. **Backwards compatible**: Using `nonce_key = 0` behaves identically to traditional nonces
4. **Application flexibility**: Apps can use dedicated nonce keys for specific workflows

### Why Separate Sender and Payer?

Separating the transaction sender (`from`) from the gas payer (`payer`) enables:

1. **Native sponsorship**: Third parties can pay gas without intermediary contracts
2. **Reduced overhead**: No entrypoint contract or bundler infrastructure required
3. **Clear authorization**: Both parties explicitly sign the same transaction parameters
4. **Atomic operations**: Sponsorship and execution happen in a single transaction

### Why Deliver Calldata to `from` Only?

The `calldata` is always delivered to the `from` address rather than allowing arbitrary targets because:

1. **Security**: Prevents bypassing wallet-level access controls
2. **Simplicity**: Clear execution model—wallet receives and interprets calldata
3. **Compatibility**: Wallets can implement any dispatch logic they need internally
4. **No privilege escalation**: `tx.origin` checks remain meaningful


## Test Cases

*Test cases will be provided in a reference implementation. Key scenarios to test:*

1. **Basic AA Transaction**: Self-paying transaction with EOA key
2. **Sponsored Transaction**: Separate payer with valid signature
3. **Multi-Key Validation**: Transaction signed with configured key (not EOA)
4. **Key Rotation**: Add/remove keys and verify validation changes
5. **2D Nonce**: Parallel transactions with different nonce keys
6. **DELEGATE Key**: Validation delegated to another account
7. **Account Initialization**: New account creation with initial keys
8. **Required Pre-State**: Transaction with state conditions
9. **Expiry**: Transaction rejected after expiry timestamp
10. **Invalid Signatures**: Various rejection scenarios


## Backwards Compatibility

This proposal introduces a new transaction type and precompile but does not break compatibility with existing accounts or contracts.

**No Breaking Changes**: Existing EOAs and smart contracts continue to function exactly as before. The proposal is fully opt-in:

- **Existing EOAs**: Can continue to send standard transactions without any changes
- **Existing Smart Contracts**: Are unaffected and continue to operate normally
- **Account Abstraction Solutions**: [EIP-4337](./eip-4337.md) infrastructure continues to work as-is. This proposal provides a complementary native alternative

**Opt-In Adoption**: Accounts only gain AA capabilities when they:
1. Configure additional keys through the Account Configuration precompile, OR
2. Send transactions using the new AA transaction type (only EOAs have this path by default)

**Tooling Impact**: Wallets and infrastructure that wish to support AA transactions will need to:
- Implement signing logic for the new transaction type
- Support account configuration management
- Handle the optional payer field for gas sponsorship

The upgrade requires network-wide adoption through a scheduled hard fork to enable the new transaction type and precompile, but no individual accounts are forced to change their behavior.


## Security Considerations

### Validation & Replay Protection

**Enshrined Validation**: Validation logic is enshrined at the protocol level and cannot be bypassed. Signature verification happens before any EVM execution begins, using well-established cryptographic algorithms (ECDSA for K1/R1, BLS12-381 for BLS, WebAuthn standards for passkeys). If validation fails, the transaction is rejected before entering the mempool—no gas is consumed and no state changes occur.

**Replay Protection**: Transactions include `chain_id`, `nonce`, and `expiry` fields:
- `chain_id` prevents cross-chain replay attacks
- `nonce` provides standard Ethereum sequential replay protection
- `expiry` prevents stale transactions from being executed indefinitely and allows users to limit exposure to delayed execution attacks

### Authorization & Key Management

**Account Control**: Account owners maintain full control over their authentication configuration through the Account Configuration precompile. Keys can be added or removed at any time, with access control enforced by the protocol—only `msg.sender` can modify their own configuration.

**EOA Recovery**: The account's original EOA key always retains authorization regardless of configuration changes, providing a guaranteed recovery mechanism. Accounts cannot be permanently locked out through misconfiguration.

**Delegation Risks**: The `DELEGATE` key type delegates validation to another account (limited to 1 hop). Accounts should carefully consider security implications before delegating validation authority.

**Gas Spending Risk**: Compromised keys can authorize transactions with excessively high gas values, putting the account's ETH at risk. Multisigs holding large ETH balances should implement appropriate mitigations in their execution layer.

**Quantum-Safe Migration**: The extensible key type system allows adding post-quantum signature schemes (SPHINCS+, Dilithium) as new key types—users can register quantum-safe keys alongside existing ones.

### Stakeholder Protections

**Payer Security**: Gas sponsors receive protection through `required_pre_state` mechanism. By validating wallet implementations and account state (such as ERC-20 balances), payers can ensure sufficient funds exist for compensation. Payers should only sponsor transactions for trusted wallet implementations.

**Block Builder Security**: Builders validate transactions using the warm Account Configuration precompile address, enabling fast validation without EVM execution. The `required_pre_state` conditions allow simple storage reads to verify validity. The constrained validation model prevents DoS attacks where malicious transactions consume builder resources without paying for gas.

### Interaction with Other Proposals

**EIP-7702 Compatibility**: This proposal works well with [EIP-7702](./eip-7702.md). EOAs can use 7702 to set code, enabling smart wallet functionality. The Account Configuration precompile provides authentication while 7702 provides execution logic.

**EIP-4337 Coexistence**: [EIP-4337](./eip-4337.md) infrastructure continues to operate unchanged. Both can coexist and accounts can use both pathways if desired.

**Contract Assumptions**: Existing contracts that make assumptions about `tx.origin` or `msg.sender` behavior continue to work correctly. The `tx.origin` is always the `from` address in AA transactions.


## Future Considerations

A dedicated **payer configuration precompile** could be introduced to reduce the calldata overhead of `required_pre_state` checks. By allowing payers to register commonly-used state validation conditions onchain, transactions could reference these configurations by ID rather than including full condition data in each transaction. This would significantly reduce calldata costs and potentially enable permissionless payer models where standardized validation patterns can be shared across the network.


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
