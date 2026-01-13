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

This proposal introduces a standardized validation mechanism for account abstraction using onchain account configurations to define accepted keys and key types. Unlike EIP-7701/RIP-7560 which permit arbitrary validation code, this approach restricts validation to predefined key types, ensuring protocol simplicity and secure account abstraction without EVM execution during validation. A new transaction type leverages this mechanism with native gas abstraction support.

## Motivation

Enable account abstraction benefits—batching, gas sponsorship, custom authentication, programmable logic—while allowing nodes to validate transactions via simple state checks without EVM execution.

### Existing Solutions

| Solution | Approach | Limitations |
|----------|----------|-------------|
| [EIP-4337](./eip-4337.md) | Application-layer abstraction | Complex mempool rules ([ERC-7562](./erc-7562.md)), high gas overhead, entrypoint costs |
| [EIP-7701](./eip-7701.md) | Protocol-level with arbitrary validation | Complex mempool rules, major protocol changes |

This proposal addresses these by:
- **Simplifying Validation**: Predefined key types eliminate EVM execution during validation
- **Enabling Simple Block Building**: Validators use only state lookups
- **Reducing Gas Costs**: No entrypoint contracts or associated overhead
- **Ensuring Extensibility**: Supports future quantum-safe algorithms via new key types
- **Maintaining Compatibility**: Coexists with EIP-7702 and ERC-4337

## Specification

### Constants

| Name | Value | Comment |
|------|-------|---------|
| `AA_TX_TYPE` | TBD | [EIP-2718](./eip-2718.md) transaction type |
| `AA_BASE_COST` | 15000 | Base intrinsic gas cost |
| `ACCOUNT_CONFIG_PRECOMPILE` | TBD | Account Configuration precompile address |
| `TOKEN_PAYMENT_REGISTRY` | TBD | Token Payment Registry address |
| `TOKEN_TRANSFER_COST` | 3000 | Gas cost for token payment transfer |
| `NATIVE_PAYER` | TBD | Native gas payer precompile address |

### Account Configuration

Each account can configure an ordered array of authorized keys through the Account Configuration Precompile at `ACCOUNT_CONFIG_PRECOMPILE`. Only `msg.sender` can modify their own configuration. This enables existing ERC-4337 smart accounts to register keys and migrate to native AA without redeployment.

**Default behavior**: An empty configuration `[]` means only the account's EOA key can authorize transactions. The EOA key always retains authorization regardless of configured keys, ensuring recovery capability.

#### Storage Layout

```
Base slot: keccak256(account_address || ACCOUNT_CONFIG_PRECOMPILE)

Slot layout:
- base_slot + 0: key_count (uint8)
- base_slot + 1 + (index * 2): key_type[index] (uint8)
- base_slot + 1 + (index * 2) + 1: key_data[index] (bytes)
```

The protocol validates signatures by reading these slots directly—no EVM execution required.

#### 2D Nonce Storage

```
Base slot: keccak256(account_address || ACCOUNT_CONFIG_PRECOMPILE || "nonce")
Nonce slot: base_slot + nonce_key
Value: current_sequence (uint64)
```

### Key Types

| Key Type | ID | Algorithm | Public Key Size | Signature Size | Intrinsic Gas |
|----------|-----|-----------|-----------------|----------------|---------------|
| `K1` | `0x01` | secp256k1 (ECDSA) | 33/65 bytes | 65 bytes | 6000 |
| `R1` | `0x02` | secp256r1 / P-256 | 33/65 bytes | 64 bytes | 7000 |
| `WEBAUTHN` | `0x03` | WebAuthn / Passkey | 65 bytes | Variable | 12000 |
| `BLS` | `0x04` | BLS12-381 | 48 bytes | 96 bytes | 8000 |
| `DELEGATE` | `0x05` | Delegated validation | 20 bytes | Variable | 1000 + delegated |

**DELEGATE**: Delegates validation to another account's configuration. The delegated account address is stored in `key_data`. Only 1 hop is permitted—if the delegated account also has a `DELEGATE` key at the signing index, validation fails.

**BLS**: Enables signature aggregation across multiple transactions, reducing data availability costs for rollups and L2s. (impl outside of this scope.)

### AA Transaction Type

A new [EIP-2718](./eip-2718.md) transaction with type `AA_TX_TYPE`:

```
AA_TX_TYPE || rlp([
  chain_id,
  from,
  nonce_key,          // 2D nonce channel (uint192)
  nonce_sequence,     // Sequence within channel (uint64)
  expiry,             // Unix timestamp
  gas_price,
  gas_limit,
  access_list,
  authorization_list, 
  calldata,
  payment_token,      // Optional: [token_address, max_amount] or []
  sender_signature,
  payer_auth          // K1 signature (65 bytes) | payer address (20 bytes) | empty
])
```

#### Intrinsic Gas

```
intrinsic_gas = AA_BASE_COST + sender_key_cost + calldata_cost + token_transfer_cost
```

Where `token_transfer_cost` is `TOKEN_TRANSFER_COST` if `payment_token` is non-empty, otherwise 0.

#### Field Definitions

| Field | Description |
|-------|-------------|
| `chain_id` | Chain ID per [EIP-155](./eip-155.md) |
| `from` | Sending account address |
| `nonce_key` | 2D nonce channel key (uint192) for parallel transaction processing |
| `nonce_sequence` | Must equal current sequence for `(from, nonce_key)`. Incremented after inclusion regardless of execution outcome |
| `expiry` | Transaction invalid after this Unix timestamp |
| `gas_price` | Price per gas unit |
| `gas_limit` | Maximum gas |
| `access_list` | [EIP-2930](./eip-2930.md) access list |
| `authorization_list` | [EIP-7702](./eip-7702.md) authorization list |
| `calldata` | Data delivered to `from` account |
| `payment_token` | Optional `[token_address, max_amount]` for token gas payment |
| `sender_signature` | See [Signature Format](#signature-format) |
| `payer_auth` | **65 bytes**: K1 signature, payer recovered via ecrecover. **20 bytes**: Registered payer address (permissionless mode). **Empty**: If `payment_token` is set, uses `NATIVE_PAYER`; otherwise `from` pays ETH |

#### Signature Format

**EOA key**: Raw 65-byte ECDSA signature `(r || s || v)`

**Configured key**: `0xFF || key_index || signature_data`

The `0xFF` prefix distinguishes configured key signatures from EOA signatures.

#### Signature Payload

Both sender and payer sign the same payload:

```
keccak256(AA_TX_TYPE || rlp([
  chain_id, from, nonce_key, nonce_sequence, expiry,
  gas_price, gas_limit, access_list, authorization_list,
  calldata, payment_token
]))
```

### Token Payments

Tokens must be registered in the Token Payment Registry before use for gas payment.

#### Token Configuration Storage

```
Base slot: keccak256(token_address || TOKEN_PAYMENT_REGISTRY || "config")

- base_slot + 0: balance_slot_index (uint256)
- base_slot + 1: oracle_address (address)
- base_slot + 2: oracle_slot (bytes32)
- base_slot + 3: token_decimals (uint8)
- base_slot + 4: oracle_decimals (uint8)
- base_slot + 5: active (bool)
```

#### Blocklist Storage

```
Blocklist slot: keccak256(token_address || account_address || TOKEN_PAYMENT_REGISTRY || "blocklist")
Value: bool
```

#### Price Calculation

```
oracle_value = SLOAD(oracle_address, oracle_slot)
exchange_rate = oracle_value * 10^token_decimals / 10^oracle_decimals
token_cost = ceil(gas_cost_wei * exchange_rate / 10^18)
```

If oracle returns 0, `token_cost` is 0 (payer assumes this risk).

#### Token Transfer Flow

When `payment_token` is set:

1. Read exchange rate from oracle, compute `token_cost`
2. Validate `token_cost <= max_amount` (if `max_amount > 0`)
3. Check sender token balance and blocklist status
4. Update balances: sender decreases, payer increases
5. Emit `Transfer(from, payer, token_cost)`

Token transfers occur outside EVM execution, before calldata delivery.

### Payer Configuration

Payers can register to accept token payments without signing each transaction (permissionless mode).

#### Storage

```
Base slot: keccak256(payer_address || ACCOUNT_CONFIG_PRECOMPILE || "payer")

- base_slot + 0: active (bool)
- keccak256(token_address || base_slot + 1): accepted (bool)
```

#### Payer Modes

**Permissioned (65-byte signature)**: Payer signs each transaction. Suitable for trusted sponsors.

**Permissionless (20-byte address)**: References registered payer config. Protocol verifies:
- Payer config is active
- Payer accepts the specified token
- Payer has sufficient ETH for gas

**Native (empty with payment_token)**: Defaults to `NATIVE_PAYER` when `payment_token` is set. Protocol handles conversion natively.

This enables permissionless gas sponsorship where payers accept token payments without a signature. Payers can then integrate any code they wish ie. to sweep token to ETH by swapping in defi protocols periodically. 

### Native Payer

The `NATIVE_PAYER` precompile provides protocol-level gas abstraction as the default payer when `payment_token` is set without an explicit payer.

#### Behavior

- **Token Support**: Uses the same Token Payment Registry for token configuration and allowlisting
- **Oracle Integration**: Registered tokens have oracle slots available; the protocol may use these or implement native pricing mechanisms (e.g., integrated AMM)
- **Chain Permissioned**: Configuration and supported tokens are managed at the protocol level
- **Automatic Default**: When `payer_auth` is empty and `payment_token` is non-empty, the native payer is used

#### Usage

Users can pay for gas with tokens without finding a sponsor:

```
payment_token = [usdc_address, max_amount]
payer_auth = []  // Defaults to NATIVE_PAYER
```

The protocol handles token-to-ETH conversion natively, providing always-available gas abstraction for supported tokens.

### Execution

#### Calldata Delivery

The `calldata` is delivered to `from` via self-call:

| Parameter | Value |
|-----------|-------|
| `to` | `from` |
| `tx.origin` | `from` |
| `msg.sender` | `from` |
| `msg.value` | 0 |
| `data` | `calldata` |

For EOAs without code, the call succeeds with no effect. For smart accounts, execution begins at the contract's entry point.

#### Validation vs Execution

This proposal constrains **validation** to enshrined key types but does not constrain **execution**. Once a transaction passes validation, the account's code can implement any logic: multisig, timelocks, spending limits, session keys, or arbitrary business rules. The `calldata` is always delivered to `from` as a self-call, ensuring wallet code controls interpretation.

#### Transaction Context

During execution, accounts can query the precompile for:
- **Payer**: `getCurrentPayer()` returns the gas payer address
- **Signer**: `getCurrentSigner()` returns `(keyIndex, keyType, publicKey)` used for authorization

**Optional opcodes** (`AAPAYER`, `AASIGNER`) may be added for gas-efficient access.

### Account Initialization

New accounts can be created with pre-configured keys in a single transaction:

```
account_init_auth = rlp([
  chain_id,
  salt,
  initial_keys,       // Array of AuthKey structs
  code_hash,          // Wallet bytecode hash
  key_index,          // Index into initial_keys for signature
  signature
])
```

**Address derivation**:
```
address = keccak256(0xff || ACCOUNT_CONFIG_PRECOMPILE || salt || keccak256(abi.encode(initial_keys, code_hash)))[12:]
```

Users can receive funds at counterfactual addresses before deployment.

### Validation Flow

#### Mempool Acceptance

1. Validate `sender_signature` against `from` account's keys
2. Resolve payer from `payer_auth` (defaults to `NATIVE_PAYER` if empty with `payment_token` set)
3. Verify nonce, payer ETH balance, expiry
4. If `payment_token` set: verify token registration, payer acceptance, sender balance/blocklist, max_amount
5. Mempool threshold: payer's pending sponsored transaction count must be below node-configured limits (not applicable for `NATIVE_PAYER`) 

#### Block Execution

1. Token transfer (if applicable)
2. ETH gas deduction from payer
3. Process authorization_list (EIP-7702)
4. Account initialization (if applicable)
5. Deliver calldata to `from` via self-call

### RPC Extensions

**`eth_getTransactionCount`**: Extended with optional `nonceKey` parameter (uint192) to query 2D nonce channels.

**`eth_getTransactionReceipt`**: Should include `payer` field.

## Rationale

### Why a Precompile?

1. **Cross-chain consistency**: Same address on all adopting chains
2. **Tooling simplicity**: Single canonical location for key lookups
3. **No storage conflicts**: Separate from contract storage
4. **Warmth optimization**: Can be kept warm for efficient validation

## Backwards Compatibility

No breaking changes. Existing EOAs and smart contracts function unchanged. Adoption is opt-in:
- EOAs continue sending standard transactions
- EIP-4337 infrastructure continues operating
- Accounts gain AA capabilities by configuring keys or using the new transaction type

## Security Considerations

**Enshrined Validation**: Signature verification uses well-established algorithms before any EVM execution. Failed validation rejects transactions before mempool entry.

**Replay Protection**: Transactions include `chain_id`, 2D nonce, and `expiry`.

**Key Management**: Only `msg.sender` can modify account configuration. EOA key always retains authorization for recovery (if created with an EOA via 7702).

**Delegation**: `DELEGATE` key type limited to 1 hop to prevent loops.

**Gas Spending Risk**: Any authorized key can submit transactions with high gas limits, potentially draining the account's ETH or tokens. Mitigation could be done where max wei / fee is configured in the auth config or token specific limits. 

**Payer Security**: Permissioned payers sign each transaction. Permissionless payers explicitly configure accepted tokens; protocol validates sender balance/blocklist before transfer.

**Oracle Risks**: Price manipulation could cause underpayment. Mitigations: TWAP oracles, multiple sources, payer-set bounds.

**EIP-7702 Compatibility**: Works well together—7702 provides execution logic, this proposal provides authentication.

## Future Considerations

- Permissionless token registration with stake requirements
- Per-token exchange rate bounds in payer configs
- `eth_sendRawTransactionConditional` for custom validation logic

## Appendix: Solidity Interfaces

### IAccountConfig

```solidity
interface IAccountConfig {
    struct AuthKey {
        uint8 keyType;
        bytes publicKey;
    }
    
    event KeyAdded(address indexed account, uint8 keyIndex, uint8 keyType, bytes publicKey);
    event KeyRemoved(address indexed account, uint8 keyIndex);
    
    function addKey(uint8 keyType, bytes calldata publicKey) external returns (uint8 keyIndex);
    function removeKey(uint8 keyIndex) external;
    function getKeyCount(address account) external view returns (uint8);
    function getKey(address account, uint8 keyIndex) external view returns (uint8 keyType, bytes memory publicKey);
    function validateSignature(address account, uint8 keyIndex, bytes32 messageHash, bytes calldata signature) external view returns (bool);
    function getNonce(address account, uint192 nonceKey) external view returns (uint64);
    function getCurrentPayer() external view returns (address);
    function getCurrentSigner() external view returns (uint8 keyIndex, uint8 keyType, bytes memory publicKey);
}
```

### ITokenPaymentRegistry

```solidity
interface ITokenPaymentRegistry {
    event TokenRegistered(address indexed token, uint256 balanceSlotIndex, address oracle, bytes32 oracleSlot, uint8 tokenDecimals, uint8 oracleDecimals);
    event TokenStatusUpdated(address indexed token, bool active);
    event BlocklistUpdated(address indexed token, address indexed account, bool blocked);
    event BlocklistManagerUpdated(address indexed token, address indexed manager, bool authorized);
    
    function registerToken(address token, uint256 balanceSlotIndex, address oracle, bytes32 oracleSlot, uint8 tokenDecimals, uint8 oracleDecimals) external;
    function setTokenActive(address token, bool active) external;
    function setBlocklistManager(address manager, bool authorized) external;
    function setBlocked(address token, address account, bool blocked) external;
    function isTokenActive(address token) external view returns (bool);
    function isBlocked(address token, address account) external view returns (bool);
    function isBlocklistManager(address token, address manager) external view returns (bool);
    function getExchangeRate(address token) external view returns (uint256);
}
```

### IPayerConfig

```solidity
interface IPayerConfig {
    event PayerUpdated(address indexed payer, bool active);
    event PayerTokenUpdated(address indexed payer, address indexed token, bool accepted);
    
    function setPayerActive(bool active) external;
    function setPayerTokenAccepted(address token, bool accepted) external;
    function isPayerActive(address payer) external view returns (bool);
    function isPayerTokenAccepted(address payer, address token) external view returns (bool);
}
```

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
