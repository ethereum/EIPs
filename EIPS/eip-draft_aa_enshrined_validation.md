---
title: Account Abstraction via Enshrined Validation
description: Enable account abstraction through protocol-level validation mechanisms
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

Unlike [EIP-7702](./eip-7702.md), which supports arbitrary code for validation, this approach is intentionally opinionated and strict about what validation logic is possible. By constraining validation to a well-defined set of key types and validation rules, the proposal maintains protocol simplicity while enabling secure account abstraction and effective block building, especially when paired with [EIP-7928](./eip-7928). This design also provides a clear path for future expansion to quantum-safe cryptographic algorithms and is compatible with existing AA mechanisms like EIP-7702 and ERC-4337.



## Motivation

Account abstraction has been a long-standing goal for Ethereum, aiming to provide users with more flexible and secure account management. This proposal aims to enable all the standard benefits of account abstraction—including batching, gas sponsorship, privilege de-escalation, and custom authentication—while addressing critical implementation challenges that have hindered adoption of existing solutions.

### Problems with Existing Approaches

Current account abstraction implementations face several significant challenges:

**[EIP-4337](./eip-4337.md)** provides account abstraction at the application layer but introduces substantial complexity:
- Requires complex [ERC-7562](./eip-7562.md) validation rules for mempool operation
- Adds significant gas overhead through UserOperation validation, execution, and post-operation phases
- Introduces an entrypoint contract that adds gas costs to every transaction
- Creates a separate infrastructure/protocol that must be maintained alongside the standard transaction pool

**[EIP-7702](./eip-7702.md)** and **[EIP-7701](./eip-7701.md)** enable protocol-level account abstraction but allow arbitrary validation code:
- Block builders must execute arbitrary EVM code before knowing who will pay for gas, creating DoS attack vectors
- Unpredictable gas costs during validation complicate block building
- Difficult to optimize transaction ordering and parallel execution
- Complex interaction with block building optimizations like [EIP-7928](./eip-7928.md)

### Goals of This Proposal

This proposal takes an intentionally constrained approach to address these issues while maintaining the key benefits of account abstraction:

#### 1. Simple Block Building

By enshrining specific validation logic rather than supporting arbitrary code, block builders can validate transactions without calling into the EVM prior to gas payment. The payer is deterministically known when the transaction is included in the block, eliminating DoS risks where malicious transactions could consume builder resources without paying.

#### 2. Simple Mempool Operation

Unlike arbitraty code excution AA protocols, this proposal does not require complex [ERC-7562](./eip-7562.md) validation rules. Mempool operators can validate transactions using simple, well-defined rules that are part of the protocol, not application-level heuristics. This allows standard Ethereum mempools to handle account abstraction transactions without separate infrastructure.

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
- **Compatibility**: Works alongside existing account abstraction approaches including [EIP-7702](./eip-7702.md), [EIP-4337](./eip-4337.md), and [ERC-1271](./eip-1271.md), allowing gradual migration and interoperability

## Specification

### Constants

| Name                     | Value             | Comment |
|--------------------------|-------------------|---------|
| `AA_TX_TYPE`             | TBD               | [EIP-2718](./eip-2718.md) transaction type |
| `AA_BASE_COST`           | TBD               | Base gas cost for AA transaction |


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

> **Open Design Question**: We are seeking feedback on the best approach for storing and managing account configuration.

There are two primary options under consideration:

##### Option 1: New Opcodes and Account State

Add new opcodes for managing authentication configuration:

**`SETAUTH` opcode**:
- Signature: `setAuth(index, key_type, public_key)`
- Restricted to `msg.sender` access only (accounts can only configure themselves)
- Sets or updates the key at the specified index in the account's configuration array
- Gas cost: TBD

**`GETAUTH` opcode**:
- Signature: `getAuth(address) → (uint8 keyType, bytes publicKey)[]`
- Returns the complete authentication configuration for the specified address
- Gas cost: TBD (similar to storage reads based on array size)

The configuration data would be held in a dedicated slot in the account state trie, separate from regular contract storage.

**Advantages**:
- Clean separation between account configuration and contract storage
- Type-safe operations at the protocol level
- Cannot conflict with contract storage layout
- Potentially more efficient gas costs

**Disadvantages**:
- Requires new opcodes and client implementation changes
- More complex upgrade path
- Not be available on all chains immediately
- Wallet providers need to have different implementations for chains

##### Option 2: Standard Account Storage

Use a specific storage slot for authentication configuration:

**Storage Layout**:
- A designated storage slot holds the authentication configuration
- Configuration is encoded as standard storage data (e.g., using SSZ or RLP encoding)
- Accounts update their configuration using standard `SSTORE` operations
- Reading configuration uses standard `SLOAD` operations

**Advantages**:
- No new opcodes needed
- Works on all chains immediately
- Compatible with existing tooling and infrastructure
- Easier to implement and deploy
- Natural compatibility with [EIP-4337](./eip-4337.md) and [ERC-1271](./eip-1271.md)

**Disadvantages**:
- Uses contract storage, which may risk with some contract layouts
- Less explicit/discoverable than dedicated opcodes
- Standard storage gas costs (not optimized for this use case)

##### Recommendation (Pending Feedback)

We are leaning toward **Option 2 (Standard Account Storage)** due to:
- Immediate deployability without client upgrades
- Better compatibility with existing AA infrastructure ([EIP-4337](./eip-4337.md), [ERC-1271](./eip-1271.md))
- Easier for wallets and smart contracts to read configuration on-chain
- Simpler for cross-chain deployments (especially L2s)

However, we welcome community feedback on this decision, particularly regarding:
- Gas efficiency concerns
- Storage slot conflicts
- Developer experience
- Long-term protocol cleanliness

### Key Types

This proposal enshrines support for specific cryptographic signature algorithms which is expected to be expanded upon in the future. Each key type has a unique identifier and defined signature format. The protocol validates signatures according to the specified key type.

The following key types are supported:

| Key Type | ID | Algorithm | Public Key Size | Signature Size | Intrinsic Gas Cost |
|----------|-----|-----------|-----------------|----------------|-------------------|
| `K1` | `0x01` | secp256k1 (ECDSA) | 33 bytes (compressed) or 65 bytes (uncompressed) | 65 bytes (r, s, v) | TBD |
| `R1` | `0x02` | secp256r1 / P-256 (ECDSA) | 33 bytes (compressed) or 65 bytes (uncompressed) | 64 bytes (r, s) | TBD |
| `WEBAUTHN` | `0x03` | WebAuthn / Passkey | 65 bytes (uncompressed P-256) | Variable (includes authenticator data) | TBD |
| `BLS` | `0x04` | BLS12-381 | 48 bytes (compressed G1) | 96 bytes (G2 signature) | TBD |
| `EXTERNAL` | `0x05` | Delegated validation | 20 bytes (account address) | Variable (depends on delegated account) | TBD |

#### Additional information

##### `WEBAUTHN` - WebAuthn / Passkey (0x03)

WebAuthn signature format for passkey authentication. This enables browser-based biometric authentication (Face ID, Touch ID, Windows Hello, etc.) to sign Ethereum transactions directly.

**Public Key Format**: 65 bytes (uncompressed P-256 public key)

**Signature Format**: Variable length, encoded as:
```
TODO
```

##### `BLS` - BLS12-381 (0x04)

BLS signature using the BLS12-381 curve. This signature scheme enables signature aggregation, allowing multiple signatures to be combined into a single signature for DA efficiency.

##### `EXTERNAL` - Delegated Validation (0x05)

Delegates signature validation to another account. The "public key" is actually an Ethereum address, and validation is performed by checking if that account's authentication configuration accepts the provided signature.

Note: Only 1 hop is accepted. (If other account specifies external as well, it will fail)


#### Adding New Key Types

New key types can be added through subsequent EIPs following this specification pattern. Each new key type must define:
- Unique identifier (uint8)
- Public key format and size
- Signature format and size
- Validation algorithm
- Intrinsic gas cost
- Security considerations

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
  signatures
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

**`required_pre_state`** (list): A list of state conditions that must be satisfied for the transaction to be valid. Each entry is a tuple of:
- `address` (address): The account to check
- `slot` (uint256): The storage slot to check
- `value` (uint256): The value to compare against
- `condition` (uint8): The comparison operator:
  - `0x00`: Equal (`==`)
  - `0x01`: Greater than or equal (`>=`)
  - `0x02`: Less than or equal (`<=`)

If any condition in `required_pre_state` is not satisfied when the transaction is executed, the transaction is invalid and cannot be included in a block. Designed for payer conditions. Size of this is limited (detailed later).

**`calldata`** (bytes): The data to be executed. The interpretation depends on the `from` account's implementation. For EOAs with AA configuration, this typically specifies the operations to perform.

**`signatures`** (list): Signatures authorizing the transaction. Contains two entries: `[sender_signature, payer_signature]`.

Each signature can be one of two formats:
1. **EOA signature**: Standard ECDSA signature as `[v, r, s]` for accounts without AA configuration
2. **Configured key signature**: `[key_index, signature_data]` for accounts with AA configuration, where:
   - `key_index` (uint8): Index into the account's configured key list
   - `signature_data` (bytes): The actual signature data, format depends on the key type at that index

If the `payer` field is empty or equals `from`, then only one signature is included and the transaction is self-paying (the `from` address pays gas fees).

#### Signature Payloads

**Sender signature** is computed over:
```
keccak256(AA_TX_TYPE || rlp([
  chain_id,
  from,
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

For gas abstraction to work safely, wallet implementations must follow these guidelines:

**Out-of-Gas Handling**: Wallets should implement early revert logic when detecting insufficient gas to complete execution. This prevents situations where:
- The wallet starts executing the calldata
- Runs out of gas mid-execution
- Reverts without completing the payment to the payer
- The payer loses gas without compensation

This pattern ensures that if the transaction doesn't have enough gas, it fails early before consuming significant gas, or if it does proceed, it reserves enough gas to complete the payment to the payer.

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

This design naturally supports a **paymaster relay model**:

1. User signs transaction with their key (sender signature)
2. User sends transaction to relayer service off-chain
3. Payer validates the transaction would be profitable (checks/adds `required_pre_state` conditions)
4. Paymaster adds their signature (payer signature) and submits to mempool
5. Transaction executes, wallet pays paymaster in ERC-20
6. Payer has paid ETH for gas, received ERC-20 payment

The paymaster acts as a relay service that:
- Converts ERC-20 tokens to ETH for gas payment
- Provides liquidity for users without ETH
- Can operate as a competitive market service
- Faces minimal griefing risk due to `required_pre_state` protections

#### Required Pre-State Limitations

To prevent DoS attacks on block builders, the `required_pre_state` field is limited:

- **Maximum entries**: TBD (suggested: 8 entries per transaction)
- **Maximum total size**: TBD (suggested: 512 bytes)

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

This data should compress well outside of the slot value (32 bytes).

#### Block Builder 
Block builders can validate `required_pre_state` conditions without executing EVM code, simply by reading the specified storage slots and performing comparisons. When combined with EIP-7928, it becomes easy for mempools to maintain valid transaction sets. 

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


#### Example: Multisig Account

A multisig account can be implemented as follows:

1. **Validation layer** (enshrined): Configure multiple keys in the account's key configuration
   - Key 0: Alice's secp256k1 key
   - Key 1: Bob's P-256 key  
   - Key 2: Charlie's BLS key

2. **Execution layer** (arbitrary): Account code implements multisig logic
```solidity
contract MultisigWallet {
    function execute(
        bytes calldata operations,
        uint8[] calldata keyIndices,
        bytes[] calldata signatures
    ) external {
        // The transaction was already validated by ONE key at protocol level
        // Now check if we have enough additional signatures for multisig threshold
        
        require(keyIndices.length >= THRESHOLD, "Insufficient signatures");
        
        // Verify additional signatures against configured keys
        for (uint i = 0; i < keyIndices.length; i++) {
            require(verifySignature(keyIndices[i], signatures[i], operations));
        }
        
        // Execute the operations
        _executeOperations(operations);
    }
}
```

In this example:
- The protocol validates the transaction using one of the configured keys (ensures gas payment is authorized)
- The account's code enforces additional multisig requirements during execution
- This separates protocol-level authorization from application-level policy

#### Benefits of This Separation

**For Simple Accounts**: Just use the enshrined validation, no complex code needed

**For Complex Accounts**: 
- Protocol validation ensures basic authorization and gas payment
- Account code implements sophisticated logic (multisig, policy engines, etc.)
- Best of both worlds: simple validation for builders, flexible execution for users

**For Wallets**:
- Can implement batching: multiple operations in the `calldata`
- Can implement session keys: different keys for different operations
- Can implement spending limits: check amounts before executing
- Can implement any custom logic without protocol constraints

#### Calldata Delivery

The `calldata` field in an AA transaction is **always delivered to the `from` account**. The account is free to interpret this data however it wishes:

- **Simple EOA**: Calldata might be ignored, or trigger a simple operation
- **Smart contract wallet**: Calldata encodes a batch of operations to execute
- **EIP-7702 account**: Calldata is processed by the delegated code
- **EIP-4337 account**: Calldata contains UserOperation execution instructions

This unopinionated approach to execution maximizes compatibility and flexibility while maintaining the simplicity of enshrined validation.


#### Alternatives considered:
- authorization config setting to require to address to be the from address of the transaction.

### Account Initialization 
TODO

### Mutlichain
TODO

### Example Transaction Processing Flow - ERC20 Sponsor





## Rationale


### Design Decisions

[TODO: Explain key design decisions:
- Why this approach over alternatives?
- How does it compare to EIP-7701's role-based system?
- How does it compare to EIP-7702's code delegation?
- What trade-offs were made and why?]

### Comparison to Existing Proposals

This proposal relates to existing account abstraction work:

- **[EIP-4337](./eip-4337.md)**: Application-layer account abstraction using UserOperations and bundlers
  - [TODO: How does your proposal differ? Does it replace, complement, or improve upon 4337?]

- **[EIP-7701](./eip-7701.md)**: Native Account Abstraction with roles and new transaction type
  - [TODO: How does your proposal differ? What advantages/disadvantages?]

- **[EIP-7702](./eip-7702.md)**: Set Code for EOAs to enable temporary code delegation
  - [TODO: How does your proposal differ? Can they work together?]

[TODO: Expand on the unique benefits of your approach]

### Security Properties

[TODO: Describe security properties your design maintains:
- Replay protection
- Authorization guarantees
- Gas payment safety
- DoS resistance]

## Backwards Compatibility

This is a backwards-incompatible change that requires a scheduled network upgrade.

[TODO: Detail specific compatibility concerns:
- Impact on existing EOAs
- Impact on existing smart contracts
- Impact on existing account abstraction solutions (e.g., EIP-4337 infrastructure)
- Migration path for users
- Impact on wallets and tooling]

Existing EOAs and contracts are not affected unless they opt-in to using validation transactions.

[TODO: Clarify opt-in vs. mandatory changes]


## Security Considerations

Correct and secure implementation of validation logic is critical for account security.

[TODO: Address specific security considerations:

### Validation Security
- How is the validation logic protected from bypass?
- What happens if validation logic reverts?
- Can validation be replayed or front-run?

### Gas Security
- Are there gas griefing vectors?
- Can validators DoS the network with expensive validations?
- How is gas consumption bounded?

### Authorization Security  
- How are signatures verified?
- What prevents unauthorized transactions?
- How is key management handled?

### MEV Considerations
- What MEV opportunities does this create?
- How can users protect themselves?

### Interaction Risks
- How does this interact with existing EIPs?
- What are the risks when combined with EIP-7702/7701?
- Impact on contract security assumptions

### Implementation Risks
- What are common implementation pitfalls?
- How can auditors verify correct implementation?]

We expect that compilers targeting EVM will play a major role in enabling and ensuring secure validation implementations.

For smart contract security auditors and security-oriented developer tools, it is crucial to ensure that validation logic is correctly implemented and does not introduce unexpected vulnerabilities.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
