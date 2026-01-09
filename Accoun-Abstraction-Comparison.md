# Account Abstraction: Alignment Document

## Goal

Replace ERC-4337 with a native, performant account abstraction solution where transaction validation occurs **outside the EVM**. This requires the protocol to understand account structures without executing arbitrary code.

---

## 1. Approaches Overview

### Tempo Transactions

Tempo introduces a native AA transaction type with the following key features:

| Feature | Description |
|---------|-------------|
| **Batched Calls** | Multiple contract calls in a single transaction |
| **2D Nonces** | Parallelizable nonces for concurrent tx processing |
| **Fee Abstraction** | Pay gas in stablecoins (not just native token) |
| **Fee Payer Pattern** | Third parties can sponsor gas costs |
| **Time-Based Validity** | Transactions have activation/expiration times |
| **Multi-Signature Types** | secp256k1, P256, WebAuthn passkeys |
| **EIP-7702 Delegation** | Uses 7702 for smart account code assignment |
| **Default Account** | Pre-assigned wallet code for all EOAs without explicit delegation |

**TIP-20 & TIP-403 Policies**: Tempo defines standardized token policies that allow the protocol to validate token transfers without running EVM code—balance slot locations are known ahead of time.

**Default Account**: Tempo assigns a default smart wallet implementation to every EOA that hasn't set explicit 7702 delegation. This means every address can immediately use AA features (batching, sponsorship) without any setup transaction. The protocol knows the wallet code structure upfront.

### Minimal Approach

This proposes a minimal native AA transaction type:

| Feature | Description |
|---------|-------------|
| **New TX Type** | Native transaction type with AA fields |
| **Sender/Payer Split** | Separate `from` and `payer` addresses |
| **Native Gas Sponsorship** | Payer signs to authorize gas payment |
| **Single Signature Type** | Standard secp256k1 (EOA keys only) |
| **Minimal Protocol Changes** | No new precompiles or storage layouts |

**Philosophy**: Keep it simple. Use existing EOA infrastructure where possible.

---

## 2. Key Differences between Tempo / Minimal

| Aspect | Tempo | Simple Approach |
|--------|-------|-----------------|
| **Signature Types** | K1, P256, WebAuthn | K1 only (EOA) |
| **Key Management** | Via 7702 delegation | None (EOA key only) |
| **Token Payments** | Native via TIP-20 slots | Not supported |
| **Account Creation** | 7702 + delegation | 7702 |
| **Default Account** | Yes (pre-assigned wallet code) | No |
| **Parallelization** | 2D nonces | Sequential nonces |
| **Complexity** | Higher (policies, delegation) | Minimal |

---

## 3. What's Missing

### From the Simple Approach

| Gap | Why It Matters |
|-----|----------------|
| **No ERC-20 Gas Payments** | Users must hold native token; payers can't receive payment atomically |
| **No Key Rotation** | Compromised key = lost account |
| **No P256/WebAuthn** | Can't use passkeys or secure enclaves |

### From Tempo

| Gap | Why It Matters |
|-----|----------------|
| **No Key Rotation** | Still relies on 7702 delegation for key changes; delegation itself can't be rotated without changing the account |
| **7702 Dependency** | Account logic requires 7702 assignment; no native key registry |
| **No Legacy Smart Account Migration** | Existing 4337 smart accounts (non-EOA) cannot adopt this system |
| **Policy Rigidity** | TIP-20/TIP-403 are specific to Tempo's token implementations |

---

## 4. Filling the Gaps

### 4.1 ERC-20 Gas Payments & State Preconditions

**Problem**: Users want to pay with an ERC20 token (stablecoins). 

To do so, chain needs to either accept the token, have a sponsor that will be paid in erc20 or have a Native AMM. Note that we want this to be a garantee that a tx is valid (can pay) **without EVM code execution**. Sanctions list make this more complex. 

#### Approaches Comparison

| Approach | Protocol Change | Tradeoff |
|----------|-----------------|----------|
| **Tempo (TIP-20)** | Enshrine specific ERC20 standard | Only works for TIP-20 tokens; rigid |
| **Native AMM** | Enshrine token swap mechanism | Big gas/DA win; but enshrines ERC20 concept |
| **Onchain Payer Config** | Payers register accepted tokens + conditions | Saves gas vs in-tx; flexible |
| **In-TX State Checks** | Include conditions in tx payload | Most flexible; higher calldata cost |
| **eth_sendRawTransactionConditional** | None (builder-level) | Relies on builder support |

#### State Preconditions: Beyond ERC-20

Having **explicit state checks in the transaction** enables any condition, not just token balances:
- User owns a specific NFT (access control)
- User has sufficient ERC-20 balance
- User is not on a blocklist
- Any arbitrary state condition

**Onchain Configuration** (payer registers conditions ahead of time) **saves gas/DA** compared to including conditions in every transaction.

#### The Native AMM Question

**Tempo's approach**: Native AMM enables seamless `token → gas` conversion. Protocol knows token's slots (TIP20), can execute swap without EVM.

**Alternative (Permissioned Payer System)**:
Without native AMM, payers can achieve similar UX by:
1. Enforcing wallet code (known implementation)
2. Checking user balance
3. Requiring first intent be ERC-20 transfer to payer

This works but is **more expensive** (gas + DA) since conditions are checked/encoded per-tx.

**The Open Question**: 

Do we enshrine ERC-20 at protocol level, or use a more abstract approach?

| Option | Description |
|--------|-------------|
| **Enshrine ERC-20** | Protocol understands ERC-20 balance slots directly; enables native AMM |
| **Abstract AMM as Payer** | AMM is a special payer that validates: `(has_balance AND not_blocklisted)` with price set by AMM state |

The abstract approach keeps the protocol more generic—AMM is just another payer with specific validation logic—but may sacrifice some gas efficiency.

**Recommendation**: Start with `eth_sendRawTransactionConditional` as baseline. Evaluate native AMM as a future optimization once usage patterns are clear.

**Note on Public vs Private Mempool**:
- **Private relay/bundler**: `eth_sendRawTransactionConditional` is sufficient—the relay checks conditions before submitting, so no onchain config needed
- **Public mempool**: Onchain config becomes important because the tx could be submitted without the conditional check. The protocol-level `required_pre_state` ensures conditions are enforced regardless of submission path

#### Token Slot Declaration (Future: Phase 2/3)

For native token transfers (without EVM execution), tokens opt-in by declaring their storage slots:

```
Token calls: NativePayRegistry.declareSlots(balanceSlotIndex, blocklistSlotIndex, decimals)
Registry stores: token → { balanceSlot, blocklistSlot, decimals, active }
```

Once declared, the protocol can directly read/write those slots for transfers. No interface required—just a one-time slot declaration.

**Risks**:
| Risk | Description | Mitigation |
|------|-------------|------------|
| **Wrong Slots** | Token declares incorrect slots; protocol corrupts state | Verify by comparing `balanceOf()` to slot read at registration |
| **Proxy Upgrades** | Token upgrades change storage layout | Re-verification required post-upgrade; or restrict to immutable tokens |
| **Non-standard Tokens** | Rebasing/fee-on-transfer tokens have complex balance logic | Exclude from registration; use permissioned model instead |
| **Non-ERC20 Tokens** | Protocol assumes ERC20 semantics | Require compatibility marker (see below) |

**Compatibility Enforcement**:
- Protocol must verify the token follows ERC20 balance semantics
- **Option**: Tokens store a compatibility marker at a known slot (e.g., `keccak256("NATIVE_PAY_COMPATIBLE")`) indicating they've opted in and are ERC20-compliant
- Existing tokens would need to upgrade to set this marker

**Recommendation**: Initially permissioned by the chain—only allowlisted tokens enabled. Permissionless registration (with compatibility marker + verification) can be added later.

### 4.2 Key Rotation

**Problem**: Users need to change keys without losing account identity or funds.

**Why 7702 Isn't Enough**: 7702 assigns code to an EOA, but the EOA's private key remains the ultimate authority. To truly rotate keys, you need the protocol to recognize multiple keys per account.

**Solution**: **Onchain Key Configuration**

```
Account → [Key₁, Key₂, ..., Keyₙ]
```

Each key entry specifies:
- `keyType`: K1, P256, WebAuthn, BLS, Delegate
- `publicKey`: The actual key data

**Storage**: A canonical **Auth Precompile** stores configurations at deterministic slots:
```
base_slot = keccak256(account || AUTH_PRECOMPILE)
key_count = SLOAD(base_slot)
key_type[i] = SLOAD(base_slot + 1 + i*2)
key_data[i] = SLOAD(base_slot + 1 + i*2 + 1)
```

**Why a Precompile?**
- Works on all chains without new opcodes
- Canonical interface for wallets, builders, tooling
- Can be kept warm for cheap validation reads
- No storage conflicts with account code
- **Quantum-Safe Migration Path**: The extensible key type system allows adding post-quantum signature schemes (SPHINCS+, Dilithium) as new key types without protocol changes—users simply register new quantum-safe keys alongside existing ones

### 4.3 Account Deployment

**Problem**: New accounts need code + auth config before first tx.

**Solution: 7702-like Initialization Authorization**

Similar to how 7702 allows EOAs to authorize code delegation, we introduce an init auth tuple:

```
account_init_auth = rlp([
  chain_id,
  salt,           // For deterministic address derivation
  initial_keys,   // AuthKey[] to configure
  code_hash,      // Wallet bytecode hash
  key_index,      // Which key in initial_keys signs this
  signature       // Proves control of initial_keys[key_index]
])
```

**Key Insight**: The signature validates against `initial_keys[key_index]`. This proves the account creator controls at least one authorized key—no EOA required. Address is derived from `(salt, initial_keys, code_hash)`.

| Approach | Description | Tradeoff |
|----------|-------------|----------|
| **7702-like Init Auth** | Signature by `initial_keys` authorizes creation | Single-tx; proves key ownership |
| **Factory Pattern** | Use existing CREATE2 factories | Extra tx; not atomic |
| **7702 + Precompile** | 7702 sets code, then call precompile | Two-step; EOA privileged |

**Recommendation**: 7702-like init auth enables **single-transaction account creation and first operation**. Address derived deterministically—users can receive funds at counterfactual addresses before deployment.

### 4.4 Legacy Smart Account Migration

**Problem**: Existing 4337 smart accounts (with non-EOA signers) can't use native AA.

**Critical Limitation of Tempo & Simple Approach**: Both require an EOA or 7702-delegated account as the starting point. **Accounts that were never EOAs cannot migrate**—they have no private key to sign 7702 authorizations.

**Migration Path for 4337 Accounts**:

With the auth precompile approach, existing 4337 smart accounts can migrate by:
1. Calling into the auth precompile to register their existing signer keys
2. Adopting the new key rotation scheme
3. From then on, using native AA transactions instead of bundlers

This works because the auth precompile accepts configuration from `msg.sender`—any contract can set its own auth config.

**Options**:

| Approach | Description | Tradeoff |
|----------|-------------|----------|
| **Auth Precompile Registration** | Existing smart account calls `addKey()` to register signers | Requires one migration tx; then fully native |
| **DELEGATE Key Type** | Account A delegates to Account B's auth config | 1-hop indirection; useful for shared signers |
| **Custom Relayer** | Continue using 4337-style bundlers for these accounts | Fragmented ecosystem |
| **No Migration** | Legacy accounts stay on 4337 | Doesn't address quantum concerns |

**Recommendation**: Auth precompile registration is the primary path. Existing 4337 accounts execute a migration transaction that registers their current signers, then can use native AA going forward. The `DELEGATE` key type provides additional flexibility for accounts wanting to share signer configurations.

### 4.5 Blocklist Enforcement

**Problem**: Sanctioned addresses must be blocked from receiving funds, but EVM execution is too late.

**Why This Is Critical for Off-EVM Validation**: If the protocol performs token transfers outside EVM execution (e.g., known balance slot updates for standardized tokens), there's no opportunity for token contract logic to enforce blocklists. The protocol itself must enforce these restrictions.

**Solution**: Protocol-level blocklist (similar to TIP-403):
- Blocklist stored onchain at a canonical, known location
- Protocol checks blocklist **before** executing any transfer (both ETH and standardized tokens)
- Blocklist lookups are pure state reads—no EVM execution needed
- Works for both sender and recipient addresses

**Implementation**:
```
BLOCKLIST_PRECOMPILE || keccak256(address) → bool (blocked)
```

**Governance**: The blocklist is **set by each token contract**, not globally. Token contracts register their blocklist with the protocol precompile, enabling role-based access control for updates. This means:
- Each token controls its own blocklist
- Existing tokens would need to **upgrade** to integrate with the protocol-level enforcement
- Supports different governance models per token (multisig, DAO, compliance oracle)

---

## 5. Proposed Solution: Auth Configuration EIP

Combine the simplicity of the Simple Approach with necessary extensions:

### Transaction Type

```
AA_TX_TYPE || rlp([
  chain_id,
  from,
  payer,              // Optional: defaults to from
  nonce_key,          // 2D nonce: channel key (uint192)
  nonce_sequence,     // 2D nonce: sequence within channel (uint64)
  expiry,             // Time-bound validity
  gas_price,
  gas_limit,
  access_list,
  authorization_list, // 7702 compatibility
  calldata,           // Data delivered to from account
  required_pre_state, // Config ID + dynamic params
  sender_signature,
  payer_signature     // Optional: if payer != from
])
```

**Calldata Delivery**: The `calldata` is delivered directly to the `from` account. The account interprets it however it wants—this is **unopinionated execution**. No protocol-level intent processing or revert handling. Wallet code decides what to do.

**Required Pre-State**: Payer protection via state conditions. Two modes:

1. **Inline conditions**: Up to 3 slot → expected value checks in the tx
2. **Config reference**: Reference a global config by ID + dynamic params

### Global Config Registry

Instead of each payer defining conditions, use a **shared global registry**:

```
┌─────────────────────────────────────────────────────────┐
│  CONFIG REGISTRY (Global)                               │
├─────────────────────────────────────────────────────────┤
│  configId (content hash) → conditions[]                 │
│  configId → stake amount                                │
└─────────────────────────────────────────────────────────┘
```

**Anyone can register** reusable validation patterns:

```solidity
// Register a config (one-time)
configRegistry.register([
    Condition(WALLET_CODE, SAFE_WALLET_HASH, EQ),
    Condition(TOKEN_BALANCE, USDC, GTE, DYNAMIC),  // min amount from tx
    Condition(NOT_BLOCKLISTED, USDC_BLOCKLIST)
]);
// Returns configId = keccak256(conditions) — content-addressed
```

**Transaction references config:**
```
required_pre_state: {
    configId: 0xabc123...,      // Global config ID
    params: [minUsdcBalance]    // Dynamic values
}
```

**Condition types** (developer-friendly, not raw slots):

| Type | Description | Example |
|------|-------------|---------|
| `WALLET_CODE` | Check account code hash | Must be Safe wallet |
| `TOKEN_BALANCE` | Check ERC-20 balance ≥ threshold | Has ≥ 10 USDC |
| `NOT_BLOCKLISTED` | Check not on blocklist | Not sanctioned |
| `SLOT_VALUE` | Raw slot check (escape hatch) | Custom condition |

Protocol expands these to actual slot reads internally.

### Staking for Mempool Priority

To prevent spam configs and align incentives:

| Stake Level | Mempool Limit |
|-------------|---------------|
| No stake | 4 pending txs using this config |
| 1 ETH staked | 100 pending txs |
| 10 ETH staked | 1000 pending txs |

**Benefits of global configs + staking:**
- **Shared patterns**: Common configs (USDC, Safe wallet) registered once, used by all payers
- **Reduced calldata**: Reference by ID instead of full conditions
- **Spam prevention**: Stake required for high-volume usage
- **Economic alignment**: Popular configs worth staking for
- **Automatic dedup**: Content-addressed IDs mean same conditions = same ID

### Validation vs Execution (Separation of Concerns)

| Component | Responsibility | When |
|-----------|---------------|------|
| **Auth Precompile** | **Who can sign** — validates signatures against registered keys | Before EVM execution |
| **Wallet Code** | **What happens** — interprets calldata and executes operations | During EVM execution |

This separation means:
- You can have auth config **without** custom wallet code (use default or 7702)
- Validation is decoupled from execution logic
- Wallet implementations can vary while auth stays standardized

### Validation (Outside EVM)

1. **Signature Check**: Validate against auth precompile config (or EOA key if no config)
2. **2D Nonce Check**: Validate `(key, sequence)` pair hasn't been used
3. **Balance Check**: Payer has `gas_limit * gas_price` ETH
4. **Expiry Check**: `block.timestamp < expiry`
5. **Required Pre-State**: All conditions in `required_pre_state` must hold

All checks are **pure state reads**—no EVM execution. Nonces updated at protocol level (not within EVM).

### 2D Nonce System

Instead of a single sequential nonce, use a **two-dimensional nonce** `(key, sequence)`:

```
nonce: {
    key: uint192,      // Channel/parallel key
    sequence: uint64   // Sequential within channel
}
```

**Benefits:**
- **Parallel transactions**: Different keys can process independently
- **No blocking**: Tx on key 1 doesn't block tx on key 2
- **Per-key ordering**: Within a key, transactions still ordered

**Example:**
```
User sends 3 transactions simultaneously:
  - (key: 0, seq: 5) → swap on Uniswap
  - (key: 1, seq: 3) → mint NFT
  - (key: 2, seq: 0) → transfer tokens

All can be included in same block—no waiting for sequential confirmation.
```

**Storage** (in auth precompile):
```
account → key → current_sequence
```

**Protocol updates nonce** after tx execution (not within EVM), ensuring atomic increment.

### Key Types

| Type | ID | Use Case |
|------|-----|----------|
| K1 | 0x01 | Standard EOA (secp256k1) |
| R1 | 0x02 | Secure enclave (secp256r1) |
| WEBAUTHN | 0x03 | Passkeys |
| BLS | 0x04 | Aggregatable signatures |
| DELEGATE | 0x05 | Delegate to another account's config |

**DELEGATE Key Type Details**:

The DELEGATE type enables one account to use another account's auth configuration for validation:

```
Account A config: [{DELEGATE, Account B}]
                          ↓
         Validation looks up Account B's auth config
                          ↓
         Any key valid for B is valid for A
```

**Mechanics**:
- **1-hop limit**: Delegation doesn't chain (A→B→C not allowed). Prevents infinite loops.
- **Validation only**: A's wallet code still executes; only signature validation is delegated.

**Use Cases**:
- **Shared org keys**: Multiple accounts delegate to a single key-holding account
- **Keyspace integration**: Delegate to Keyspace precompile for cross-chain keys
- **Recovery**: Delegate to a recovery account controlled by guardians

### New Opcodes for Transaction Context

Since calldata is delivered directly to the account (no entrypoint), wallet code needs a way to access transaction context:

| Opcode | Gas | Returns |
|--------|-----|---------|
| `AAPAYER` | 2 | Payer address (or `from` if self-paying) |
| `AASIGNER` | 2 | Key index used to sign (0xFF = EOA key) |

**Use Cases**:
- `AAPAYER`: Transfer tokens to payer as payment for sponsorship
- `AASIGNER`: Enforce key-based permissions (session keys with limited capabilities)

### Account Initialization (7702-like)

New accounts can be created within an AA transaction using an authorization tuple:

```
account_init_auth = rlp([
  chain_id,
  salt,           // For deterministic address derivation
  initial_keys,   // AuthKey[] to configure
  code_hash,      // Wallet bytecode hash
  key_index,      // Which key in initial_keys signs this
  signature       // Proves control of initial_keys[key_index]
])
```

**Key Insight**: The signature validates against `initial_keys[key_index]`. This proves the creator controls at least one authorized key—enabling **single-transaction account creation and first operation**.

Address is derived deterministically: `keccak256(0xff || PRECOMPILE || salt || keccak256(initial_keys || code_hash))`

### Execution Flow

1. Gas deducted from `payer`
2. Process 7702 authorizations if present
3. Process account initialization if present
4. `tx.origin` = `from`
5. Deliver `calldata` to `from` (self-call where `msg.sender` = `from`)
6. Account code processes calldata however it wants

**No entrypoint contract**—calldata goes directly to the account.

### Security: Mass Invalidation

**Context**: With 7702 already live, mass invalidation risks exist today—any transaction can change an account's balance, invalidating pending txs.

**Unsponsored Transactions**: Mass invalidation is not a concern. The sender's own txs are invalidated, affecting only themselves.

**Sponsored Transactions**: A payer sponsoring many transactions could trigger mass invalidation (e.g., by changing their auth config). Mitigations:

| Mitigation | Description |
|------------|-------------|
| **Payer Staking** | Payers with large mempool presence must stake; slashed on mass invalidation |
| **EOA Keys for Payers** | Payers should use standard EOA keys (not rotatable auth config) to prevent self-invalidation |
| **Mempool Limits** | Cap sponsored txs per payer without stake |

**Recommendation**: Payers should initially be required to use **EOA keys** (not auth precompile keys) to prevent mass invalidation attacks. This can be relaxed later with staking mechanisms.

---

## 6. Comparison Summary

| Feature | Simple | Tempo | Proposed |
|---------|--------|-------|----------|
| Native Gas Sponsorship | ✅ | ✅ | ✅ |
| ERC-20 Gas Payment | ❌ | ✅ (TIP-20 only) | ✅ (flexible payer pattern) |
| Key Rotation | ❌ | ❌ | ✅ |
| Multiple Sig Types | ❌ | ✅ | ✅ |
| Passkeys/WebAuthn | ❌ | ✅ | ✅ |
| BLS Aggregation | ❌ | ❌ | ✅ |
| 2D Nonces | ❌ | ✅ | ✅ |
| Account Deployment | ❌ | 7702 | 7702-like init auth |
| Default Account | ❌ | ✅ | ⚠️ (opt-in TBD) |
| Legacy 4337 Migration | ❌ | ❌ | ✅ (precompile registration) |
| Non-EOA Migration | ❌ | ❌ | ✅ |
| Cross-Chain Keys | ❌ | ❌ | 🔬 (via Keyspace delegation) |
| Quantum-Safe Path | ❌ | ❌ | ✅ (extensible key types) |
| No EVM in Validation | ✅ | ✅ | ✅ |
| Minimal Protocol Change | ✅ | ❌ | ⚠️ (precompile) |

---

## 7. Future: Keyspace Rollup Integration

The **Keyspace Rollup** is a future cross-chain authentication layer—a unified source of truth for account keys across all compatible chains. See [Appendix A](#appendix-a-keyspace-rollup-research) for full research details.

### Delegation to Keyspace

The auth precompile design enables seamless Keyspace adoption via the `DELEGATE` key type:

```
Account auth config: [{DELEGATE, KEYSPACE_PRECOMPILE}]
                              ↓
                    Keyspace verifies signature
                              ↓
                    Returns valid/invalid to chain
```

**Migration Path**:
1. Chains mark themselves as **Keyspace-compatible** (implement Keyspace state verification)
2. User updates their auth config: `addKey(DELEGATE, KEYSPACE_ADDRESS)`
3. All future txs validate against Keyspace
4. User manages keys in one place; works on all compatible chains

**New Chain Initialization**: When a user interacts with a new Keyspace-compatible chain for the first time, their Keyspace config can be proven via **ZKP**—no need to register keys on each chain individually.

**Key Insight**: We **ship per-chain auth precompile now**, and Keyspace becomes an **opt-in upgrade later**. The DELEGATE key type makes this migration seamless—users choose when to adopt Keyspace.

---

## 8. Feature Analysis: Tempo's Default Account

### What It Does

Tempo assigns a **default smart wallet implementation** to every EOA that hasn't explicitly set 7702 delegation. This means:

- Every address can use AA features (batching, sponsorship) immediately
- No "activation" transaction needed for first use
- Protocol knows the wallet structure → can validate without EVM execution

### Benefits

| Benefit | Impact |
|---------|--------|
| **Zero Setup** | New users get smart wallet features instantly |
| **Predictable Validation** | All accounts use known wallet code |
| **Simplified UX** | No confusing "upgrade your account" step |
| **Gas Efficiency** | No deployment tx for first-time users |

### Tradeoffs

| Concern | Details |
|---------|---------|
| **Wallet Lock-in** | Users stuck with default implementation unless they 7702 override |
| **Upgrade Path** | What happens when default wallet has bugs? |
| **Customization** | Power users may want different wallet logic |

### Should We Add This?

**Arguments For**:
- Dramatically improves onboarding UX
- Makes AA the default, not opt-in
- Aligns with "every EOA is a smart account" vision

**Arguments Against**:
- Adds protocol complexity (must define and maintain default code)
- May conflict with existing 7702 delegations
- Less flexibility than explicit account creation

**Recommendation**: Consider a "default account" feature where accounts can **explicitly opt-in** to using the default wallet implementation. This provides:
- **Gas savings**: No deployment transaction needed—protocol knows the code
- **Explicit choice**: Users specify they want default wallet, rather than implicit assignment
- **Upgrade flexibility**: Users can later switch to custom implementations

The auth precompile already provides most AA benefits (key rotation, sponsorship validation). The default account feature primarily saves gas on initial deployment for users who don't need custom wallet logic.

---

## 9. Next Steps

1. **Gas Payment Architecture**: Decide between enshrining ERC-20 (native AMM) vs abstract payer model. Evaluate gas/DA tradeoffs.
2. **Define key types**: Which signature algorithms to enshrine initially?
3. **Spec the precompile**: Finalize storage layout and interface
4. **Migration strategy**: How do existing 4337 users transition?
5. **Default account spec**: Define the default wallet implementation for opt-in gas savings
6. **Keyspace research**: Prototype cross-chain key sync; evaluate proof systems

---

## References

- [Tempo Transaction Spec](https://docs.tempo.xyz/protocol/transactions/spec-tempo-transaction)
- [Simple Approach EIP (gakonst)](https://gist.github.com/gakonst/00117aa2a1cd327f515bc08fb807102e)
- [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702) - EOA code delegation
- [EIP-4337](https://eips.ethereum.org/EIPS/eip-4337) - Account Abstraction via EntryPoint
- [EIP-7796](https://eips.ethereum.org/EIPS/eip-7796) - eth_sendRawTransactionConditional
- [Draft: Standardized AA with Onchain Key Configs](./EIPS/eip-draft-aa-account-configuration.md)
- [Keyspace Docs](https://docs.key.space) - Cross-chain key management (research)
- [Post-Quantum Cryptography](https://csrc.nist.gov/projects/post-quantum-cryptography) - NIST PQC standards



---
## Appendix A: Keyspace Rollup Research

### The Vision

The **Keyspace Rollup** represents the ideal end-state: a minimal rollup that serves as a **unified source of truth for authentication** across all chains adopting this standard.

### Why Keyspace Matters

| Problem | Current State | Keyspace Solution |
|---------|---------------|-------------------|
| **Key Sync** | User must register keys on each chain separately | Single registration propagates everywhere |
| **Key Rotation** | Must rotate on every chain; risk of inconsistent state | Rotate once, effective everywhere |
| **Cross-Chain UX** | Different accounts/keys per chain | Same account, same keys, everywhere |
| **Quantum Migration** | Must upgrade every chain's auth independently | Single upgrade path for all chains |

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    KEYSPACE ROLLUP                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │  Account → [Key₁, Key₂, ..., Keyₙ]                      ││
│  │  Canonical source of truth for all auth configs         ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
              │              │              │
         State Root     State Root     State Root
              │              │              │
              ▼              ▼              ▼
         ┌────────┐    ┌────────┐    ┌────────┐
         │   L1   │    │   L2   │    │  L2'   │
         │Ethereum│    │ (Base) │    │(Arb...)│
         └────────┘    └────────┘    └────────┘
```

### Signature Evolution

With a dedicated auth rollup, signatures can evolve beyond traditional ECDSA:

| Signature Type | Properties | Use Case |
|----------------|------------|----------|
| **KZG Proofs** | Succinct, aggregatable | Prove key membership without revealing key |
| **ZK Proofs** | Privacy-preserving | Prove authorization without revealing signer |
| **Post-Quantum** | SPHINCS+, Dilithium | Future-proof against quantum attacks |

**Critical Requirement**: Any signature scheme must have a **quantum-secure variant** or migration path. The Keyspace design should not lock us into schemes that will break under quantum computing.

### L1 and L2 Integration

**L1 (Ethereum)**:
- Could host the Keyspace rollup as a validium/rollup
- Alternatively, L1 reads Keyspace state via bridge proofs
- Settlements and high-value txs verify against Keyspace

**L2s**:
- Subscribe to Keyspace state roots
- Verify auth proofs against committed roots
- Can operate with slight delay (acceptable for most use cases)

### Research Questions

1. **Proof System**: KZG commitments? SNARKs? STARKs (quantum-resistant)?
2. **Liveness**: What happens if Keyspace is unavailable? Fallback to local config?
3. **Latency**: How fast do key updates propagate? Is real-time needed?
4. **Governance**: Who operates the Keyspace rollup? Decentralized sequencer set?
5. **Bootstrapping**: How do existing accounts migrate to Keyspace?
6. **New Chain Init**: How does ZKP-based config proof work for first interaction?

### Incremental Path

We don't need Keyspace on day one. The auth precompile design is **Keyspace-compatible**:

1. **Phase 1**: Per-chain auth precompile (this proposal)
2. **Phase 2**: Chains mark themselves Keyspace-compatible
3. **Phase 3**: Users delegate to Keyspace via `DELEGATE` key type
4. **Phase 4**: Full Keyspace rollup as canonical source

Each phase delivers value independently. Users opt-in to Keyspace when ready.
 