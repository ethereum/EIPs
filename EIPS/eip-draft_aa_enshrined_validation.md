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

This proposal introduces a standardized validation mechanism for account abstraction, utilizing onchain account configurations to define accepted keys and key types. Unlike EIP-7701/RIP-7560, which permits arbitrary validation code, this approach restricts validation to a predefined set of key types and rules, ensuring protocol simplicity and secure account abstraction without requiring EVM code execution. A new transaction type leverages this new validation mechanism and includes support for native gas abstraction. This design aims to maintain the simplicity of block builder's validation logic to ensure block building can operate without heavy mempool restrictions or DoS risks. It maintains compatibility with existing account abstraction mechanisms, such as EIP-7702 / ERC-4337 and gives a path to integration of quantum-safe cryptographic algorithms.


## Motivation

This proposal aims to enable all the benefits of account abstraction—including batching, gas sponsorship, custom authentication and programable account logic while enabling the node to operate effectively with simple state checks for validation. Since the node operator can determine transaction validity quickly and operate it's mempool effectively with new proposals like FAL, BAL, there is significantly reduced DoS risks and no risk of unpaid work validating transactions in the EVM (like 4337/7701). 

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
- **No EVM Changes**: No required changes to EVM (can add opcode for some gas improvements)
- **Ensuring Extensibility**: Supports future quantum-safe algorithms via new key types
- **Maintaining Compatibility**: Coexists with EIP-7702 and ERC-4337
- **Potential Compressibility**: Structured validation fields enable potential signature aggregation (BLS)


## Specification

### Constants

| Name                     | Value             | Comment |
|--------------------------|-------------------|---------|
| `AA_TX_TYPE`             | TBD               | [EIP-2718](./eip-2718.md) transaction type |
| `AA_BASE_COST`           | 15000             | Base intrinsic gas cost for AA transaction |
| `ACCOUNT_CONFIG_PRECOMPILE` | TBD            | Address of the Account Configuration precompile |
| `TOKEN_PAYMENT_REGISTRY` | TBD               | Address of the Token Payment Registry |
| `TOKEN_TRANSFER_COST`    | 3000              | Gas cost for token payment transfer |


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

Note that though tx validation is done outside of execution, modification to the account configuration is done within execution, other than on initial deployment. 

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
    
    // ============ Key Management ============
    
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
    
    /// @notice Get the total number of configured keys for an account
    /// @param account The account to query
    /// @return count The number of keys in the account's configuration
    function getKeyCount(address account) external view returns (uint8 count);
    
    /// @notice Get authentication key information at the specified index
    /// @param account The account to query
    /// @param keyIndex The index of the key to retrieve
    /// @return keyType The cryptographic algorithm type (0 if index out of bounds)
    /// @return publicKey The public key data (empty if index out of bounds)
    function getKey(address account, uint8 keyIndex) external view returns (uint8 keyType, bytes memory publicKey);
    
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
    
    // ============ 2D Nonce ============
    
    /// @notice Get the current nonce sequence for an account at a specific nonce key
    /// @param account The account to query
    /// @param nonceKey The 2D nonce channel key
    /// @return sequence The current sequence number for this (account, nonceKey) pair
    function getNonce(address account, uint192 nonceKey) external view returns (uint64 sequence);
    
    // ============ Transaction Context ============
    
    /// @notice Get the payer address for the current AA transaction
    /// @dev Returns tx.origin (self-paying) if not an AA transaction
    /// @return payer The address paying for gas
    function getCurrentPayer() external view returns (address payer);
    
    /// @notice Get the signing key info for the current AA transaction
    /// @dev Returns (0xFF, empty) if not an AA transaction or EOA key was used
    /// @return keyIndex The index of the key used (0xFF for EOA)
    /// @return keyType The type of the signing key
    /// @return publicKey The public key data
    function getCurrentSigner() external view returns (uint8 keyIndex, uint8 keyType, bytes memory publicKey);
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
| `K1` | `0x01` | secp256k1 (ECDSA) | 33 bytes (compressed) or 65 bytes (uncompressed) | 65 bytes (r, s, v) | 6000 |
| `R1` | `0x02` | secp256r1 / P-256 (ECDSA) | 33 bytes (compressed) or 65 bytes (uncompressed) | 64 bytes (r, s) | 7000 |
| `WEBAUTHN` | `0x03` | WebAuthn / Passkey | 65 bytes (uncompressed P-256) | Variable (includes authenticator data) | 12000 |
| `BLS` | `0x04` | BLS12-381 | 48 bytes (compressed G1) | 96 bytes (G2 signature) | 8000 | 
| `DELEGATE` | `0x05` | Delegated validation | 20 bytes (account address) | Variable (depends on delegated account) | 1000 + delegated sig |

- **BLS**: Supports signature aggregation for data availability efficiency. 
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
  nonce_key,          // 2D nonce: channel key (uint192)
  nonce_sequence,     // 2D nonce: sequence within channel (uint64)
  expiry,             
  gas_price,
  gas_limit,
  access_list,
  authorization_list, 
  calldata,
  payment_token,      // Optional: [token_address, max_amount] or empty
  sender_signature,
  payer_auth          // K1 signature (65 bytes) OR payer address (20 bytes)
])
```

#### Intrinsic Gas Calculation

The total intrinsic gas for an AA transaction is calculated as:

```
intrinsic_gas = AA_BASE_COST + sender_key_cost + calldata_cost + token_transfer_cost
```

Where:
- `sender_key_cost` is determined by the key type used for the sender signature (see [Key Types](#key-types) table)
- `token_transfer_cost` is `TOKEN_TRANSFER_COST` if `payment_token` is non-empty, otherwise 0

#### Transaction Fields

**`chain_id`** (uint256): The chain ID as defined in [EIP-155](./eip-155.md). The transaction is only valid on the specified chain.

**`from`** (address): The account that is sending the transaction. This account's validation configuration determines which keys can authorize the transaction.

**`nonce_key`** (uint192): The 2D nonce channel key. Allows parallel transaction processing across different keys.

**`nonce_sequence`** (uint64): The sequence number within the nonce channel. Must be exactly `current_sequence` for the given `(from, nonce_key)` pair. Incremented by the protocol after successful execution.

The 2D nonce system enables parallel transactions: different `nonce_key` values can be processed independently, while transactions with the same `nonce_key` are ordered by `nonce_sequence`.

**`expiry`** (uint64): Unix timestamp after which the transaction is no longer valid. This allows transactions to have built-in time limits, preventing stale transactions from being executed.

**`gas_price`** (uint256): The price per unit of gas the payer is willing to pay.

**`gas_limit`** (uint64): The maximum amount of gas the transaction can consume.

**`access_list`** (list): [EIP-2930](./eip-2930.md) style access list for pre-warming storage slots and addresses.

**`authorization_list`** (list): [EIP-7702](./eip-7702.md) standard authorization list for setting account code.

**`calldata`** (bytes): The data to be delivered to the `from` account. The interpretation depends on the account's implementation. For smart accounts, this typically encodes the operations to perform.

**`payment_token`** (list): Optional token payment specification. If non-empty, contains `[token_address, max_amount]`:
- `token_address` (address): The ERC-20 token to pay with. Must be registered in the Token Payment Registry.
- `max_amount` (uint256): Maximum tokens the sender is willing to pay. Set to 0 for no limit.

When `payment_token` is set, tokens are transferred from `from` to the payer (outside EVM execution) based on the token's configured exchange rate. See [Token Payments](#token-payments).

**`sender_signature`** (bytes): Signature authorizing the transaction from the sender. Encoding is:
- **For EOA key**: Raw 65-byte ECDSA signature `(r || s || v)` where r and s are 32 bytes each, v is 1 byte
- **For configured key**: `0xFF || key_index || signature_data` where:
  - `0xFF` is a 1-byte prefix indicating configured key signature
  - `key_index` (uint8): Index into the sender's configured key list  
   - `signature_data` (bytes): The actual signature data, format depends on the key type at that index

The `0xFF` prefix distinguishes configured key signatures from EOA signatures (which never start with `0xFF` since `r` values are always less than the curve order).

**`payer_auth`** (bytes): Payer authorization. Interpretation depends on length:
- **65 bytes (K1 signature)**: Permissioned mode. Payer address is recovered via `ecrecover`. Payer signs same payload as sender.
- **20 bytes (address)**: Permissionless mode. Address references a registered payer configuration. See [Payer Configuration](#payer-configuration).
- **Empty**: Self-paying transaction. `from` pays gas in ETH (no token payment allowed).

#### Signature Payloads

**Sender signature** is computed over:
```
keccak256(AA_TX_TYPE || rlp([
  chain_id,
  from,
  nonce_key,
  nonce_sequence,
  expiry,
  gas_price,
  gas_limit,
  access_list,
  authorization_list,
  calldata,
  payment_token
]))
```

**Payer signature** (when `payer_auth` is 65 bytes) is computed over the same payload, ensuring both parties agree on all transaction parameters including the token payment terms.


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


### Token Payments

This proposal enables gas payment in ERC-20 tokens through a slot-based token registry. Tokens must be registered before they can be used for gas payment.

#### Token Payment Registry

The Token Payment Registry at `TOKEN_PAYMENT_REGISTRY` stores token configuration and blocklist data. It maintains a mapping from token addresses to their payment configuration.

##### Token Configuration Storage

```
Base slot: keccak256(token_address || TOKEN_PAYMENT_REGISTRY || "config")

Slot layout:
- base_slot + 0: balance_slot_index (uint256)
- base_slot + 1: oracle_address (address)
- base_slot + 2: oracle_slot (bytes32)
- base_slot + 3: token_decimals (uint8)
- base_slot + 4: oracle_decimals (uint8)
- base_slot + 5: active (bool)
```

##### Blocklist Storage

The blocklist is stored in the Token Payment Registry precompile, managed by the token or its authorized managers:

```
Blocklist slot: keccak256(token_address || account_address || TOKEN_PAYMENT_REGISTRY || "blocklist")
Value: bool (true if blocked)
```

##### Blocklist Manager Storage

Tokens can authorize additional addresses to manage their blocklist:

```
Manager slot: keccak256(token_address || manager_address || TOKEN_PAYMENT_REGISTRY || "manager")
Value: bool (true if authorized)
```

##### Access Control

| Function | Who Can Call |
|----------|--------------|
| `registerToken` | Chain operator (permissioned) OR token contract (permissionless) |
| `setTokenActive` | Chain operator (permissioned) OR token contract (permissionless) |
| `setBlocked` | Token address OR authorized manager |
| `setBlocklistManager` | Token address only |

##### Token Payment Registry Interface

```solidity
/// @title ITokenPaymentRegistry
/// @notice Interface for the Token Payment Registry precompile
interface ITokenPaymentRegistry {
    
    /// @notice Emitted when a token is registered or updated
    event TokenRegistered(
        address indexed token,
        uint256 balanceSlotIndex,
        address oracle,
        bytes32 oracleSlot,
        uint8 tokenDecimals,
        uint8 oracleDecimals
    );
    
    /// @notice Emitted when a token's active status changes
    event TokenStatusUpdated(address indexed token, bool active);
    
    /// @notice Emitted when an address is added/removed from a token's blocklist
    event BlocklistUpdated(address indexed token, address indexed account, bool blocked);
    
    /// @notice Emitted when a blocklist manager is added/removed
    event BlocklistManagerUpdated(address indexed token, address indexed manager, bool authorized);
    
    // ============ Chain Operator Functions (Permissioned) ============
    
    /// @notice Register a token for gas payments
    /// @dev Only callable by chain operator
    /// @param token The token address
    /// @param balanceSlotIndex The storage slot index for balanceOf mapping
    /// @param oracle The oracle contract address
    /// @param oracleSlot The storage slot to read exchange rate from
    /// @param tokenDecimals The token's decimals
    /// @param oracleDecimals The oracle's decimals (e.g., 8 for Chainlink)
    function registerToken(
        address token,
        uint256 balanceSlotIndex,
        address oracle,
        bytes32 oracleSlot,
        uint8 tokenDecimals,
        uint8 oracleDecimals
    ) external;
    
    /// @notice Set token active status
    /// @dev Only callable by chain operator
    /// @param token The token address
    /// @param active Whether the token is active for gas payments
    function setTokenActive(address token, bool active) external;
    
    // ============ Token Functions ============
    
    /// @notice Add or remove a blocklist manager for the caller's token
    /// @dev Only callable by the token contract itself (msg.sender == token)
    /// @param manager The manager address to authorize/revoke
    /// @param authorized Whether the manager is authorized
    function setBlocklistManager(address manager, bool authorized) external;
    
    /// @notice Add or remove an address from the caller's blocklist
    /// @dev Callable by token address OR authorized manager
    /// @param token The token address
    /// @param account The account to block/unblock
    /// @param blocked Whether the account should be blocked
    function setBlocked(address token, address account, bool blocked) external;
    
    // ============ View Functions ============
    
    /// @notice Check if a token is registered and active
    /// @param token The token address
    /// @return active Whether the token is active
    function isTokenActive(address token) external view returns (bool active);
    
    /// @notice Check if an address is blocked for a token
    /// @param token The token address
    /// @param account The account to check
    /// @return blocked Whether the account is blocked
    function isBlocked(address token, address account) external view returns (bool blocked);
    
    /// @notice Check if an address is an authorized blocklist manager
    /// @param token The token address
    /// @param manager The manager address to check
    /// @return authorized Whether the manager is authorized
    function isBlocklistManager(address token, address manager) external view returns (bool authorized);
    
    /// @notice Get the current exchange rate for a token (tokens per ETH)
    /// @param token The token address
    /// @return rate The exchange rate normalized to token's smallest units per ETH
    function getExchangeRate(address token) external view returns (uint256 rate);
}
```

**Token Registration**: Registration is initially permissioned by the chain operator. Permissionless registration may be added in future upgrades with appropriate safeguards.

#### Price Oracle

The protocol reads the exchange rate directly from the configured `oracle_address` at `oracle_slot`, then normalizes it using the stored decimals:

```
oracle_value = SLOAD(oracle_address, oracle_slot)
exchange_rate = oracle_value * 10^token_decimals / 10^oracle_decimals
token_cost = ceil(gas_cost_wei * exchange_rate / 10^18)
```

This enables direct compatibility with Chainlink price feeds (which use 8 decimals for most USD pairs).

If the oracle returns 0 or is unavailable, `token_cost` is 0 (effectively a free transaction—payer assumes this risk).

#### Token Transfer Flow

When `payment_token` is set and `payer_auth` specifies a valid payer:

1. **Read exchange rate** from oracle slot and normalize with decimals
2. **Compute token cost**: `ceil(gas_cost_wei * exchange_rate / 10^18)`
3. **Validate max_amount**: If `max_amount > 0`, require `token_cost <= max_amount`
4. **Check sender balance**: Read from token's `balance_slot_index`
5. **Check blocklist**: Read from `TOKEN_PAYMENT_REGISTRY` blocklist storage, reject if blocked
6. **Transfer tokens**: Direct slot update—decrease sender balance, increase payer balance
7. **Emit Transfer event**: `Transfer(from, payer, token_cost)` for indexer compatibility

Token transfers occur **outside EVM execution**, before calldata delivery.


### Payer Configuration

Payers can register configurations to accept token payments without signing each transaction (permissionless mode).

#### Payer Configuration Interface

```solidity
/// @title IPayerConfig
/// @notice Interface for payer configuration in the Account Configuration precompile
interface IPayerConfig {
    
    /// @notice Emitted when payer configuration is updated
    /// @param payer The payer address
    /// @param active Whether the payer is active
    event PayerUpdated(address indexed payer, bool active);
    
    /// @notice Emitted when a payer's accepted token list changes
    /// @param payer The payer address
    /// @param token The token address
    /// @param accepted Whether the token is now accepted
    event PayerTokenUpdated(address indexed payer, address indexed token, bool accepted);
    
    /// @notice Enable or disable the caller as a permissionless payer
    /// @param active Whether to accept sponsored transactions
    function setPayerActive(bool active) external;
    
    /// @notice Set whether a token is accepted for payment by the caller
    /// @param token The token address
    /// @param accepted Whether to accept this token
    function setPayerTokenAccepted(address token, bool accepted) external;
    
    /// @notice Check if a payer is active
    /// @param payer The payer address to query
    /// @return active Whether the payer is accepting sponsored transactions
    function isPayerActive(address payer) external view returns (bool active);
    
    /// @notice Check if a payer accepts a specific token
    /// @param payer The payer address to query
    /// @param token The token address to check
    /// @return accepted Whether the payer accepts this token
    function isPayerTokenAccepted(address payer, address token) external view returns (bool accepted);
}
```

#### Payer Config Storage

Payer configurations are stored in the Account Configuration precompile:

```
Base slot: keccak256(payer_address || ACCOUNT_CONFIG_PRECOMPILE || "payer")

Slot layout:
- base_slot + 0: active (bool)
- base_slot + 1 + token_index: accepted_tokens mapping
  - Key: keccak256(token_address || base_slot + 1)
  - Value: bool (true if accepted)
```

#### Permissionless Payer Flow

When `payer_auth` is 20 bytes (an address):

1. **Load payer config**: Read from precompile storage
2. **Verify active**: Payer config must be active
3. **Verify token accepted**: `accepted_tokens[payment_token.token]` must be true
4. **Verify payer ETH balance**: Payer must have sufficient ETH for gas
5. **Process token transfer**: As described in [Token Transfer Flow](#token-transfer-flow)
6. **Deduct ETH gas**: From payer's balance

This enables **permissionless gas sponsorship**: anyone can deploy a payer contract, register accepted tokens, and earn fees by accepting token payments. The payer contract can implement withdrawal logic, periodic swaps to ETH via Uniswap/Aerodrome, or other treasury management.


### Transaction Context Access

AA transactions expose additional context that wallet code may need during execution. This information is available through two mechanisms:

#### Context Fields

| Field | Description |
|-------|-------------|
| **Payer** | The address paying for gas. Set per transaction via `payer_auth`. |
| **Signer Key** | The key used to sign the transaction: key index (uint8) and public key data (bytes). |

**Payer**: The resolved payer address from the transaction's `payer_auth` field. Returns `from` address for self-paying transactions.

**Signer Key**: The key that authorized the transaction. Returns the key index (`0xFF` for EOA key, or the configured key index) along with the public key data used for signature verification.

#### Access Methods

This context can be accessed via:

1. **Precompile queries** (always available): Call `getKey(from, keyIndex)` on the Account Configuration precompile during execution
2. **Optional opcodes** (gas optimization): If implemented, dedicated opcodes provide cheaper access

#### Optional Opcodes

The following opcodes MAY be added for gas-efficient access to transaction context. If not implemented, the same information is accessible via the Account Configuration precompile.

| Opcode | Value | Gas | Description |
|--------|-------|-----|-------------|
| `AAPAYER` | TBD | 2 | Returns the payer address from current AA transaction |
| `AASIGNER` | TBD | 2 | Returns (key_index, public_key) used by sender |

**`AAPAYER`**: Pushes the `payer` address onto the stack. Returns `from` address if not an AA transaction (self-paying).

**`AASIGNER`**: Pushes the key index and public key data used to sign the transaction onto the stack. Returns `(0xFF, ecrecover_address)` if the EOA key was used. Returns `(0xFF, 0x)` if not an AA transaction.

#### Use Cases

These fields enable wallet implementations to:
- Enforce key-based permissions (e.g., session keys with limited capabilities, multisig, subaccounts)
- Log which key authorized an action


### Gas Abstraction

This proposal enables native gas abstraction through two payer modes:

#### Permissioned Mode (Signature-based)

Payer provides a K1 signature (65 bytes) in `payer_auth`. The payer address is recovered via `ecrecover`. This mode is suitable for:
- Trusted sponsors (e.g., application subsidizing users)
- Private relay relationships
- One-off sponsorships

**Security Note**: Permissioned payers should use EOA keys only (not rotatable auth config keys) to prevent mass invalidation attacks.

#### Permissionless Mode (Config-based)

Payer address (20 bytes) in `payer_auth` references a registered payer configuration. This mode enables:
- **Pseudo-AMM**: Permissionless gas payment acceptors
- **Token-for-gas swaps**: Users pay tokens, payer provides ETH

Payers can protect themselves via:
1. **Token registration**: Only accept tokens they've explicitly configured
2. **Balance verification**: Protocol performs transfer, tx invalid if token balance insufficient 
3. **Blocklist enforcement**: Tokens can maintain blocklists for compliance
4. **`eth_sendRawTransactionConditional`**: Builder-level conditional inclusion (for additional checks)


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

1. **Sender Signature Validation**: Validate `sender_signature` against `from` account's configured keys or EOA key
2. **Payer Resolution**:
   - If `payer_auth` is 65 bytes: recover payer address via `ecrecover`, validate signature
   - If `payer_auth` is 20 bytes: use as payer address, verify payer config exists and is active
   - If `payer_auth` is empty: payer = `from` (self-paying)
3. **Nonce Check**: Sender's nonce must be valid for the given `(from, nonce_key)`
4. **Balance Check**: Payer must have sufficient ETH for `gas_limit * gas_price`
5. **Token Payment Validation** (if `payment_token` is set):
   - Token must be registered in Token Payment Registry
   - Payer config must accept the token (permissionless mode) or payer signed (permissioned mode)
   - Sender must have sufficient token balance
   - Sender must not be on token's blocklist
   - Token cost must not exceed `max_amount` (if set)
6. **Expiry Check**: Current timestamp must be before transaction `expiry`
7. **Mempool Threshold Check**: Payer's pending sponsored transaction count must be below limits

If all checks pass, the transaction is accepted into the mempool and propagated to peers.

#### Block Inclusion

When a block builder selects a transaction for potential inclusion, it revalidates all conditions against current state. All slot reads for validation are performed outside EVM execution.

#### Execution

Once included in a block:

1. **Token Transfer** (if `payment_token` is set):
   - Read exchange rate from oracle slot
   - Compute `token_cost = ceil(gas_cost * exchange_rate / 10^18)`
   - Update sender token balance: `balance -= token_cost`
   - Update payer token balance: `balance += token_cost`
   - Emit `Transfer(from, payer, token_cost)` event
2. **Gas Deduction**: Total gas spent is deducted from the payer's ETH balance
3. **Authorization Processing**: If `authorization_list` is non-empty, process 7702 authorizations
4. **Account Initialization**: If account init authorization is present, deploy the new account
5. **Call Context**: `tx.origin` is set to the `from` address
6. **Calldata Delivery**: The `calldata` is delivered to the `from` address via a call where `msg.sender` = `from` (self-call)
7. **Standard Execution**: Follows standard EVM execution rules


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
| `tx.origin` | `from` address |
| `msg.sender` | `from` address (self-call) |
| `msg.value` | 0 |
| `data` | `calldata` field from transaction |
| `gas` | Remaining gas after intrinsic costs |

**Behavior by account type**:

- **EOA (no code)**: Call succeeds immediately with no effect. Calldata is ignored. Note a chain operator can consider a default account. 
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

#### `eth_getTransactionCount`

Extended with an optional `nonceKey` parameter to support the 2D nonce system:

**Parameters**:
1. `address` - The account address
2. `blockNumber` - Block number, or "latest", "pending", "earliest"
3. `nonceKey` - (optional) The 2D nonce channel key (uint192, hex-encoded)

**Returns**: `uint64` - The nonce/sequence number

**Behavior**:
- **Without `nonceKey`**: Returns the standard account nonce (used by legacy, EIP-1559, EIP-4844 transactions). Fully backwards compatible.
- **With `nonceKey`**: Returns the 2D nonce sequence from the Account Configuration precompile for the given `(account, nonceKey)` channel. Used for AA transactions.

**Note**: The standard account nonce and 2D precompile nonces are **independent systems**. An EOA sending legacy transactions uses the account nonce, while the same EOA sending AA transactions uses the 2D nonce in the precompile. They do not affect each other.

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

**Gas Spending Risk**: Compromised keys can authorize transactions with excessively high gas values, putting the account's ETH / tokens at risk. 

**Quantum-Safe Migration**: The extensible key type system allows adding post-quantum signature schemes (SPHINCS+, Dilithium) as new key types—users can register quantum-safe keys alongside existing ones.

### Stakeholder Protections

**Payer Security**: 
- **Permissioned mode**: Payers sign each transaction, maintaining full control over what they sponsor
- **Permissionless mode**: Payer configs explicitly list accepted tokens. Protocol validates sender balance and blocklist status before transfer. Payers should use EOA keys to prevent mass invalidation.

**Token Payment Security**:
- **Oracle manipulation**: Attackers could manipulate oracle prices to underpay. Mitigations include TWAP oracles, multiple oracle sources, or payer-set exchange rate bounds.
- **Zero exchange rate**: If oracle returns 0, token cost is 0 (free gas). This is a feature for promotional tokens but payers should be aware.
- **Blocklist enforcement**: Protocol checks token blocklist before transfer, ensuring sanctioned addresses cannot use token payments.

**Block Builder Security**: Builders validate transactions using slot reads from warm precompile addresses, enabling fast validation without EVM execution. The constrained validation model prevents DoS attacks where malicious transactions consume builder resources without paying for gas.

### Interaction with Other Proposals

**EIP-7702 Compatibility**: This proposal works well with [EIP-7702](./eip-7702.md). EOAs can use 7702 to set code, enabling smart wallet functionality. The Account Configuration precompile provides authentication while 7702 provides execution logic.

**EIP-4337 Coexistence**: [EIP-4337](./eip-4337.md) infrastructure continues to operate unchanged. Both can coexist and accounts can use both pathways if desired.

**Contract Assumptions**: Existing contracts that make assumptions about `tx.origin` or `msg.sender` behavior continue to work correctly. The `tx.origin` is always the `from` address in AA transactions.


## Future Considerations

**Permissionless Token Registration**: Initially, token registration in the Token Payment Registry is permissioned by the chain (allowlisted tokens only). Future upgrades could enable permissionless registration with:
- Stake requirements for token registrants
- Verification that declared slots match actual `balanceOf()` behavior
- Compatibility markers in token storage

**Payer Configuration Enhancements**: Payer configs could be extended to include:
- Per-token exchange rate bounds (max rate payer will accept)

**Alternative State Validation**: For use cases requiring state checks beyond token payments (e.g., verifying wallet code hash), applications can use `eth_sendRawTransactionConditional` at the builder level. This approach doesn't enshrine any token standard and provides flexibility for custom validation logic.


## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
