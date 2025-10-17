---
title: Standardized Account Abstraction with Onchain Key Configurations
description: Enable account abstraction through onchain account configurations.
author: Chris Hunter (@_chunter)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
created: 2025-10-14
requires: 
---

## Abstract

This proposal introduces a standardized validation mechanism for account abstraction, utilizing onchain account configurations to define accepted keys and key types. Unlike EIP-7701, which permits arbitrary validation code, this approach restricts validation to a predefined set of key types and rules, ensuring protocol simplicity and secure account abstraction without requiring EVM code execution. A new transaction type supports native gas abstraction, enabling third-party transaction fee payments. When combined with EIP-7928, this design enhances block building efficiency. It also supports future integration of quantum-safe cryptographic algorithms and maintains compatibility with existing account abstraction mechanisms, such as EIP-7702 and ERC-4337.


## Motivation

Account abstraction has been a long-standing goal for Ethereum, aiming to provide users with more flexible and secure account management. This proposal aims to enable all the benefits of account abstraction—including batching, gas sponsorship, custom authentication and programable account logic—while addressing critical implementation challenges that have hindered adoption of existing solutions.

## Rationale

This solution implements transaction validation at the protocol level, separating account logic from gas payment. It supports arbitrary account code but only post post-gas validation while defining initial transaction inclusion through a predefined, extensible set of per-account authentication standards.

| Solution | Challenges | Limitations |
|----------|------------|-------------|
| [EIP-4337](./eip-4337.md) | Application-layer abstraction | Complex mempool rules ([ERC-7562](./eip-7562.md)), high gas overhead, entrypoint contract costs, separate infrastructure |
| [EIP-7701](./eip-7701.md) | Protocol-level abstraction with arbitrary code | Complex mempool rules ([ERC-7562](./eip-7562.md)), major protocol changes, complex block building |

This proposal addresses these by:
- **Simplifying Validation**: Uses predefined key types, eliminating EVM execution during validation.
- **Enhancing Block Building**: Block builders able to efficiently validate transactions with only state look ups.
- **Maintain AA Benefits** Keep all standard account abstraction benefits.
- **Reducing Gas Costs**: Eliminates entrypoint contracts and gas overheads.
- **No changes to the EVM**: No evm changes required.
- **Ensuring Extensibility**: Supports future quantum-safe algorithms via new key types.
- **Maintaining Compatibility**: Coexists with EIP-7702 and ERC-4337.
- **Improving Compressibility**: Structured validation fields reduce calldata costs for Layer 2 rollups.


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

It provides:
- key management
- account configuration getters

With access control only provided to `msg.sender`, enabling all account types to manage their auth config.


The precompile can also offer initial account creation by providing counter factual addresses and validation.  

**Benefits:**

- **Performance**: The precompile address can be kept warm for cheap lookups during validation
- **Standardization**: Provides a canonical interface that wallets, block builders, and tooling can rely on across all chains
- **Efficiency**: Dedicated storage optimized for key configurations, separate from contract storage
- **Compatibility**: Works immediately on all chains that adopt this EIP without requiring new opcodes


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

- **BLS**: Supports signature aggregation for data availability efficiency.
- **DELEGATE**: Delegates validation to another account (1-hop limit).
- **Extensibility**: New key types can be added via future EIPs.


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

#### Expected Wallet Implementation Requirements

For gas abstraction in exchange for erc20 to work safely, payers should trust who they are sponsoring. In the case they cannot, they can trust a set of wallet implementations. Payers are recommended to trust wallets that follow these guidelines.

**Out-of-Gas Handling**: Wallets should implement early revert logic when detecting insufficient gas to complete execution.

**Revert-Handling**: Wallets must handle reverts safely to protect the payer from losing gas without compensation. This is achieved by separating payer payment from user operation execution.

The key principle: **Payer payment must occur in a non-revertible context, even if user operations fail.** 

This design protects payers from griefing while allowing user operations to fail safely 

#### Payer as Relay

This design naturally supports a payer attaching a sponsorship after the sender signs.

The sender can fill in the payer field and add any conditons to its calldata (ie. send 1 cent to address), sign it and send it to the relayer who will sponsor and then relay the tx to the node reducing 1 typical hop. 
The payer service acts as a relay service that:
- Accepts ERC20 tokens to land it for gas payment
- Faces minimal griefing risk due to `required_pre_state` protections

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
- Must pass validation before any execution begins
- Ensures gas payment authorization is clear to block builders

**Execution (Arbitrary)**:
- Once validated, the account's code can implement any logic
- Supports multisig, timelock, spending limits, session keys, or any custom logic
- The `calldata` field is always delivered TO the `from` account


#### Calldata Delivery

The `calldata` field in an AA transaction is **always delivered to the `from` account**. The account is free to interpret this data however it wishes:

- **EOA (no code)**: Calldata might be ignored (no code to orchestrate actions with)
- **Smart contract account**: Calldata encodes actions for the wallet to take

This unopinionated approach to execution maximizes compatibility and flexibility while maintaining the simplicity of enshrined validation.

This also maintains the ability of the wallet developer to create fully programable accounts, as if the calldata could be sent elsewhere it could bypass those controls. 

### Account Initialization 
Accounts can be initialized by
- calling from an EOA to allow additional auth keys
- calling from an existing smart contract wallet implementation
- setting 7702 code and using an EOA to make first transaction, allowing additional keys

The auth precompile can also enable account initialization by providing counter factual addresses and owner setup.

### Standard RPCs

Standard Ethereum RPC methods work seamlessly with AA transactions with minimal modifications:

#### `eth_estimateGas`

Works as-is with AA transactions. Accounts can estimate gas for their transaction using the standard RPC call. For accounts that have not yet been initialized, wallet providers can use state overrides to temporarily inject the wallet code during estimation.

#### `eth_sendRawTransaction`

Works as-is using the new validation transaction type (`VALIDATION_TX_TYPE`). The RLP-encoded transaction is submitted through the standard RPC endpoint:

#### `eth_getTransactionReceipt`

Works as-is but **SHOULD** include an additional `payer` field in the receipt to indicate which address paid for the transaction gas. This is important for AA transactions where the `from` address may differ from the actual gas payer:

The `payer` field helps wallets, indexers, and users accurately track which account paid for transaction execution.


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

### Validation & Replay Protection

**Enshrined Validation**: Validation logic is enshrined at the protocol level and cannot be bypassed. Signature verification happens before any EVM execution begins, using well-established cryptographic algorithms (ECDSA for K1/R1, BLS12-381 for BLS, WebAuthn standards for passkeys). If validation fails, the transaction is rejected before entering the mempool—no gas is consumed and no state changes occur.

**Replay Protection**: Transactions include `chain_id`, `nonce`, and `expiry` fields:
- `chain_id` prevents cross-chain replay attacks
- `nonce` provides standard Ethereum sequential replay protection
- `expiry` prevents stale transactions from being executed indefinitely and allows users to limit exposure to delayed execution attacks

### Authorization & Key Management

**Account Control**: Account owners maintain full control over their authentication configuration through the Account Configuration precompile. Keys can be added or removed at any time, with access control enforced by the protocol—only `msg.sender` can modify their own configuration.

**EOA Recovery**: The account's original EOA key always retains authorization regardless of configuration changes, providing a guaranteed recovery mechanism. Accounts cannot be permanently locked out through misconfiguration. Users who prefer maximum security can maintain this EOA option, while others can opt into pure smart account implementations.

**Delegation Risks**: The `DELEGATE` key type delegates validation to another account (limited to 1 hop). Accounts should carefully consider security implications before delegating validation authority. Account implementations should also exercise caution with `DELEGATECALL` operations, as delegated code could potentially bypass intended authorization controls.

**Gas Spending Risk**: Compromised keys can authorize transactions with excessively high gas values, putting the account's ETH at risk. Multisigs holding large ETH balances should implement appropriate mitigations in their execution layer.

### Stakeholder Protections

**Payer Security**: Gas sponsors receive strong guarantees through the `required_pre_state` mechanism. By validating wallet implementations and account state (such as ERC-20 balances), payers can ensure the sender's wallet follows expected payment logic, sufficient funds exist for compensation, and transactions will execute as anticipated. Payers should only sponsor transactions for trusted wallet implementations or accounts they control to prevent griefing attacks.

**Block Builder Security**: Builders validate transactions using the warm Account Configuration precompile address, enabling fast validation without EVM execution. The `required_pre_state` conditions allow simple storage reads to verify validity—no arbitrary code execution is required. Mass invalidation is prevented since `required_pre_state` only works for slots that reference the account's address/code. Transactions can be efficiently invalidated by monitoring payer balances, account configuration changes, and `required_pre_state` conditions. This enables efficient mempool management, especially when combined with [EIP-7928](./eip-7928.md) for state diff tracking. The constrained validation model prevents DoS attacks where malicious transactions consume builder resources without paying for gas.

### Interaction with Other Proposals

**EIP-7702 Compatibility**: This proposal works well with [EIP-7702](./eip-7702.md). EOAs can use 7702 to temporarily set code, enabling smart wallet functionality. The Account Configuration precompile provides authentication while 7702 provides execution logic.

**EIP-4337 Coexistence**: [EIP-4337](./eip-4337.md) infrastructure continues to operate unchanged. Both can coexist and accounts can use both pathways if desired.

**Contract Assumptions**: Existing contracts that make assumptions about `tx.origin` or `msg.sender` behavior continue to work correctly. The `tx.origin` is always the `from` address in AA transactions.

## Future Considerations

A dedicated **payer configuration precompile** could be introduced to reduce the calldata overhead of `required_pre_state` checks. By allowing payers to register commonly-used state validation conditions onchain, transactions could reference these configurations by ID rather than including full condition data in each transaction. This would significantly reduce calldata costs and potentially enable permissionless payer models where standardized validation patterns can be shared across the network.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
