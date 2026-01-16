# Account Abstraction: Design Rationale

## Goal

Replace ERC-4337 with native account abstraction where transaction validation occurs **outside the EVM**. The protocol must understand account structures without executing arbitrary code.

---

## Prior Art

### Tempo Transactions

| Feature | Description |
|---------|-------------|
| 2D Nonces | Parallelizable nonces |
| Fee Abstraction | Pay gas in stablecoins via TIP-20 |
| Multi-Signature Types | K1, P256, WebAuthn |
| Default Account | Pre-assigned wallet code for all EOAs |

**Limitations**: TIP-20 token standard is rigid; no key rotation independent of 7702; existing 4337 accounts cannot migrate.

### Minimal Approach (gakonst)

| Feature | Description |
|---------|-------------|
| Sender/Payer Split | Separate `from` and `payer` addresses |
| Native Gas Sponsorship | Payer signs to authorize gas payment |
| K1 Only | Standard secp256k1 signatures |

**Limitations**: No ERC-20 payments; no key rotation; no passkeys; no 4337 migration path.

---

## Key Decisions

### Decision 1: Auth Config Precompile

**Choice**: Canonical precompile for key management.

**Rationale**:
- Enables key rotation without changing account address
- Enables 4337 smart account migration (any `msg.sender` can register keys)
- Enables subaccounts/session keys via `DELEGATE` key type / onchain permissions
- Enables multiple signature types (K1, R1, WebAuthn, BLS)
- Provides quantum-safe migration path (add post-quantum key types later)
- Provides Keyspace integration path (delegate to cross-chain key registry)
- Works on all chains without new opcodes

**Rejected alternatives**:
| Alternative | Why Rejected |
|-------------|--------------|
| 7702-only key management | EOA key always has ultimate authority; can't truly rotate |
| Per-account storage slots | Storage conflicts with contract code; no canonical interface |
| New account trie field | Requires deeper protocol changes |

### Decision 2: Token Registry + Per-Payer Oracles

**Choice**: Token registry stores metadata (balance slots, decimals, blocklist); each payer configures their own oracle per token.

**Rationale**:
- Does not enshrine a specific token standard (vs TIP-20)
- Tokens opt-in by declaring balance/blocklist slots
- **Per-payer oracles** create a competitive gas market—payers compete on pricing
- No protocol governance of "which oracle"—each payer chooses
- Risk isolation: bad oracle only affects users of that payer
- Payers can use Chainlink, Uniswap TWAP, custom feeds, or promotional rates
- Wallet-layer curation handles discovery of good payers
- `max_amount` provides hard protection against overcharging

**Design flexibility**:
| Approach | Use Case |
|----------|----------|
| Permissionless Payers | Each payer sets own oracle; competes on margin; can sweep tokens via DeFi |
| Native Payer | Optional integration point for native DEX/AMM features |
| Hybrid | Native Payer as default, permissionless payers for competition/additional tokens |

**Token registration** is initially permissioned (chain allowlists USDC, USDT, etc.). Permissionless registration with stake + verification can be added later.

### Decision 3: Flexible Payer Modes

**Choice**: Support signature-based (permissioned), config-based (permissionless), and native payer modes.

| Mode | payer_auth | Use Case |
|------|-----------|----------|
| Self-pay | Empty | User pays ETH |
| Permissioned | 65-byte K1 signature | Trusted sponsors, private relays |
| Permissionless | 20-byte address | Public gas markets, custom payers |
| Native | `NATIVE_PAYER` address or empty | Chain-operated gas abstraction; address enables unified onchain lookup |

**Rationale**:
- Permissioned mode for trusted relationships (app subsidizing users)
- Permissionless mode enables open gas markets without signatures
- **Native mode** provides always-available gas payment when chain operator deploys native AMM
- Payers register accepted tokens; protocol enforces balance/blocklist checks
- Payers can sweep accumulated tokens via Uniswap/Aerodrome
- Users can pay with tokens without finding a sponsor (just set `payment_token`)

---

## Solution Summary

### Transaction Type

```
AA_TX_TYPE || rlp([
  chain_id, from, nonce_key, nonce_sequence, expiry,
  gas_price, gas_limit, access_list, authorization_list,
  calldata, payment_token, sender_signature, payer_auth
])
```

### Validation (Outside EVM)

1. Validate `sender_signature` against auth precompile config (or EOA key)
2. Resolve payer from `payer_auth` (defaults to `NATIVE_PAYER` if empty with `payment_token`)
3. Verify 2D nonce, payer ETH balance, expiry
4. If token payment: verify registration, balance, blocklist, max_amount
5. Mempool threshold for sponsored txs (not applicable for native payer)

All checks are **pure slot reads**—no EVM execution.

### Token Payment Flow

```
1. Read exchange rate from payer's oracle config
2. Compute: token_cost = ceil(gas_cost * exchange_rate / 10^18)
3. Validate: token_cost ≤ max_amount
4. Check: sender balance and blocklist
5. Direct slot update: sender ↓, payer ↑
6. Emit Transfer event
```

### Execution

1. Token transfer (if applicable)
2. Gas deducted from payer
3. 7702 authorizations processed
4. Account initialization (if applicable)
5. Deliver calldata to `from` via self-call

**Validation is constrained; execution is not.** Wallet code can implement any logic.

---

## Comparison

| Feature | EIP-4337 | EIP-7701 | Simple | Tempo | This Proposal |
|---------|----------|----------|--------|-------|---------------|
| Native Gas Sponsorship | ❌ (via Paymaster) | ✅ | ✅ | ✅ | ✅ |
| ERC-20 Gas Payment | ❌ (app layer) | ❌ | ❌ | ✅ (TIP-20) | ✅ (registry) |
| Native AMM Option | ❌ | ❌ | ❌ | ❌ | ✅ (per chain) |
| Key Rotation | ✅ (contract) | ✅ (contract) | ❌ | ❌ | ✅ |
| Multiple Sig Types | ✅ (contract) | ✅ (contract) | ❌ | ✅ | ✅ |
| Passkeys/WebAuthn | ✅ (contract) | ✅ (contract) | ❌ | ✅ | ✅ |
| 2D Nonces | ✅ | ✅ | ❌ | ✅ | ✅ |
| Legacy 4337 Migration | N/A | ✅  | ❌ | ❌ | ✅ |
| No EVM in Validation | ❌ | ❌ | ✅ | ✅ | ✅ |
| Protocol Complexity | Low (app layer) | High (new opcodes) | Low | Medium | Medium |
| Mempool Rules | Complex (ERC-7562) | Complex | Simple | Simple | Simple |

### EIP-4337 vs EIP-7701 vs This Proposal

| Aspect | EIP-4337 | EIP-7701 | This Proposal |
|--------|----------|----------|---------------|
| **Layer** | Application (EntryPoint contract) | Protocol (new tx type + opcodes) | Protocol (new tx type + precompile) |
| **Validation Logic** | Arbitrary EVM (gas-bounded) | Arbitrary EVM (gas-bounded) | Predefined key types only |
| **New Opcodes** | None | `CURRENT_ROLE`, `ACCEPT_ROLE`, `TXPARAM*` | None (optional `AAPAYER`, `AASIGNER`) |
| **Gas Overhead** | High (EntryPoint calls) | Medium | Low |
| **Block Builder Complexity** | High (ERC-7562 rules) | High (role management) | Low (state lookups only) |
| **Extensibility** | High (any validation logic) | High (any validation logic) | Medium (new key types) |
| **Quantum Migration** | Contract upgrade | Contract upgrade | Add key type |

---

## Expert Questions & Open Issues

### DELEGATE Key Type

**Q**: For DELEGATE, if I store `[DELEGATE, 0x12...34]` at `key_index=2`, would my signature look like `0xff | 0x02 | 0xff | 0x01 | signature`, where `0xff | 0x01 | signature` is passed to address `0x12...34`?

**A**: Yes. Example:
- Account A has pubkey in slot 2
- Account B has DELEGATE in slot 3 pointing to Account A
- Account B accepts signatures like: `0xff | 3 | [valid Account A signature]` = `0xff | 3 | [0xff | 2 | sig]`

The nested signature is validated against the delegated account's config. 1-hop limit prevents loops.

**Status**: ✅ Clarified

---

### Multisig Support

**Observation**: No native multisig in auth structure (only BLS threshold schemes).

**Response**: Correct—no native multisig support at the gas payment layer. Accounts can implement multisig features at the execution layer because they are aware of the signing key index via `getCurrentSigner()`.

**Consideration**: May want to add either:
- Native multisig support in auth config
- Account-level config to mitigate gas overspending / ERC-20 token spend bypass (e.g., disable unsponsored tx or token tx entirely)

**Status**: Not a blocker. Design intentionally constrains validation, not execution.

---

### 2D Nonce Storage Costs

**Concern**: 2D nonces introduce unbounded storage per account; we'd likely need to charge `SSTORE` equivalent gas for a previously unseen `nonce_key`.

**Response**: Yes, new nonce keys would incur 20k gas (`SSTORE_SET_GAS`). Subsequent increments cost `SSTORE_RESET_GAS` (2,900 gas).

**Additional consideration**: Could bound the keyspace to reduce state bloat:
- 1024 nonce keys seems sufficient for most use cases
- Bounded keyspace = bounded storage per account

**Status**: ✅ Confirmed gas cost. Bounded keyspace under consideration.

---

### Smart Wallet Migration

| Question | Answer |
|----------|--------|
| **Move auth to account config?** | Yes, 4337 smart wallets migrate by calling the auth precompile to add their keys. This enables the new AA tx type. Migration happens in execution. |
| **How to prevent non-AA txs if keys are in config?** | Any contract calling the precompile can add keys. An EOA can set this by calling the auth precompile directly. The EOA key always retains authorization for recovery. |
| **2 signatures if both checks retained?** | No. Smart wallets already accept calls from themselves or the EntryPoint (see [CoinbaseSmartWallet](https://github.com/coinbase/smart-wallet/blob/main/src/CoinbaseSmartWallet.sol#L228-L246)). The same pattern applies. |
| **2 updates for key rollover?** | No. The smart contract wallet should be upgraded to use the precompile as its source of truth. It can call `getKey()` / `validateSignature()` for 4337 compatibility and native AA. Single source of truth. |

**Recommendation**: Wallet contracts should use `getCurrentSigner()` and `getCurrentPayer()` for all authorization checks, avoiding duplicate key storage.

---

### Token Payment Questions

**Payment Mode Matrix**:

| Case | `payer_auth` | `payment_token` |
|------|--------------|-----------------|
| Sender pays ETH | Empty | Empty |
| Sponsor pays ETH | Payer's EOA signature (65 bytes) | Empty |
| Sponsor pays ETH, receives token | Payer's EOA signature (65 bytes) | `[token_address, max_amount]` |
| Permissionless sponsor | Payer address (20 bytes, config required) | `[token_address, max_amount]` |
| Native AMM pays | `NATIVE_PAYER` address OR empty | `[token_address, max_amount]` |

**Oracle System Options**:

| Oracle Type | Description |
|-------------|-------------|
| **Chainlink feed** | Standard price feed integration |
| **Operator-run oracle** | Top-of-block updates by payer |
| **DeFi-integrated oracle** | Permissionless updates from DEX pools |

**Recommended design**: Non-upgradable contract with DeFi integrations. Anyone can call `update(tokenAddress)` to query configured pool for current price. May drift between updates, but allows payers to build systems for important tokens and works permissionlessly for all registered tokens.

**Status**: ✅ Clarified

---

### Complexity vs EVM Validation Trade-off

**Observation**: 
> "There's quite a bit of logic happening in the validation flow; there's set inclusions, signature recoveries, balance checks, oracle price conversion / AMM calculation, etc. What we're really gaining here is a bounded amount of execution... which could also be achieved using EVM validation with a gas limit."

**Response**:

| Aspect | EIP-7701 (EVM validation) | This Proposal (Enshrined validation) |
|--------|---------------------------|--------------------------------------|
| **Validation complexity** | Arbitrary (gas-bounded) | Fixed (predefined key types) |
| **Block builder simulation** | Must execute EVM to validate | Pure state reads, no EVM |
| **Mempool rules** | Complex (storage access restrictions) | Simple (can validate from state) |
| **Invalidation risk** | Any state change can invalidate | Only key/nonce/balance changes |
| **Extensibility** | Infinite (any contract logic) | Bounded (add key types via hardfork) |

**Trade-off**: We accept reduced validation flexibility in exchange for dramatically simpler block building and mempool rules. The "bounded execution" in EVM validation still requires:
- Simulating contract execution
- Tracking storage access patterns
- Complex invalidation rules (ERC-7562)

This proposal eliminates those requirements entirely.

---

### EIP-7701 Simplification Ideas

**Suggestions from experts**:
1. Reuse same calldata for validation and execution
2. Use EVM context to determine mode (validation vs execution)  
3. Single new opcode to "pass validation" instead of full opcode family

**Analysis**:

[RIP-7560](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7560.md) is a less opcode-heavy design for L2s, but still has complexity.

**Alternative approach**: Enshrine a custom EntryPoint:
- New tx type where validation revert = invalid tx (cannot land)
- PVG (Pre-Verification Gas) calculation baked into protocol
- No new opcodes required
- Simpler than EIP-7701 while preserving EVM validation flexibility

**Comparison**:

| Approach | Opcodes | Complexity | Flexibility |
|----------|---------|------------|-------------|
| EIP-7701 (current) | 5+ new opcodes | High | Maximum |
| RIP-7560 (L2 variant) | Fewer opcodes | Medium-High | High |
| Enshrined EntryPoint | 0 new opcodes | Medium | High |
| This Proposal | 0-2 optional opcodes | Low | Medium |

**Open question**: Is enshrined EntryPoint (EVM validation, no new opcodes) the right middle ground, or does the fully enshrined approach provide enough flexibility while maintaining simplicity?

---

## Security Considerations

### Mass Invalidation

**Sponsored transactions** risk mass invalidation if a payer changes state.

| Mitigation | Description |
|------------|-------------|
| Mempool limits | Cap sponsored txs per payer |
| EOA keys for payers | Payers use EOA keys (not rotatable auth config) |
| Future: staking | Payers stake; slashed on mass invalidation |

### Blocklist Enforcement

Token transfers happen outside EVM, so protocol must enforce blocklists. Each token registers its blocklist slot; protocol checks before transfer.

---

## Future: Keyspace Integration

The auth precompile design enables future cross-chain key management via the `DELEGATE` key type:

```
Account config: [{DELEGATE, KEYSPACE_ADDRESS}]
```

**Incremental path**:
1. **Phase 1**: Per-chain auth precompile (this proposal)
2. **Phase 2**: Chains implement Keyspace state verification
3. **Phase 3**: Users delegate to Keyspace
4. **Phase 4**: Keyspace becomes canonical source

Users opt-in when ready. The `DELEGATE` type makes migration seamless.

---

## Open Items

| Item | Status | Notes |
|------|--------|-------|
| Default account | Consideration | Enables native AA without 7702 delegation. All EOAs get AA capabilities by default. |
| Key-bound token spend limits | Consideration | Per-key, per-token limits in auth config. Required for session keys with spending caps. See below. |
| Permissionless token registration | Future | Start with chain allowlist, add stake-based registration later |

### Token Spend Protection

**Problem**: Token gas payments occur at protocol level, before wallet code executes. Wallet-level spend limits cannot protect against gas overspending.

```
1. Signature validated
2. Token transfer for gas ← protocol level, BEFORE wallet code
3. Wallet code executes ← spend limits checked here (too late)
```

#### Option A: Key-Bound Token Limits

Per-key, per-token limits in auth config:

```
AuthKey {
    keyType,
    publicKey,
    tokenLimits: { token_address -> max_per_tx }
}
```

**Rationale:**
- Session keys need spending caps
- Different keys have different trust levels (main key: unlimited; session key: 10 USDC max)
- Gas limit (wei) doesn't map directly to token cost (exchange rates vary)

**Validation**: Protocol checks `token_cost <= key.tokenLimits[token]` before transfer.

#### Option B: Trusted Payers List

Account-level list of trusted payers:

```
Account Config:
  trustedPayers: [payer_address, ...]
```

Only payers on this list can be used for gas payment from this account.

**Security model** - attack requires ALL of:
1. Key compromise
2. Compromised payer (must be on trusted list)
3. Compromised oracle (for overcharge)

**Rationale:**
- Simpler than per-token limits
- Leverages trust relationship with known payers
- User chooses payers they trust (app sponsor, known relayer, `NATIVE_PAYER`)

#### Option C: Combined

Both mechanisms together:
- Trusted payers list (account-level) - which payers allowed
- Token limits (key-level) - spending caps per key

Maximum protection for high-value accounts.

#### Comparison

| Approach | Complexity | Attack Surface | Best For |
|----------|------------|----------------|----------|
| Token limits | Higher | Caps per-tx and cumulative drain | Session keys, fine-grained control |
| Trusted payers | Lower | Requires payer+oracle compromise | Simple setup, known sponsors |
| Combined | Highest | Maximum protection | High-value accounts |

#### Attack Analysis

**Nature of attack**: Primarily griefing, not direct theft. Tokens go to payer for gas, not attacker's wallet.

**MEV vector**: Attacker could profit if they control the payer—overcharge via oracle manipulation, extract value through gas payments.

**Mitigation comparison**:
- **Trusted payers**: Blocks unknown payers entirely. Natural choices: `NATIVE_PAYER`, app sponsors, onchain standards (e.g., Aerodrome-based payer).
- **Spend limits**: Caps damage per-tx. Prevents siphoning over many transactions even with compromised key.

**Recommendation**: Trusted payers as baseline (simple, effective). Token limits for session keys requiring fine-grained caps.

---

## References

- [EIP Draft: Standardized AA with Onchain Key Configs](./EIPS/eip-draft_aa_enshrined_validation.md)
- [Tempo Transaction Spec](https://docs.tempo.xyz/protocol/transactions/spec-tempo-transaction)
- [Simple Approach (gakonst)](https://gist.github.com/gakonst/00117aa2a1cd327f515bc08fb807102e)
- [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702) - EOA code delegation
- [EIP-4337](https://eips.ethereum.org/EIPS/eip-4337) - Account Abstraction via EntryPoint
- [EIP-7701](https://eips.ethereum.org/EIPS/eip-7701) - Native Account Abstraction (EVM validation)
- [RIP-7560](https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7560.md) - Native Account Abstraction (L2 variant)
- [ERC-7562](https://eips.ethereum.org/EIPS/eip-7562) - Account Abstraction Validation Scope Rules
- [EIP-7796](https://eips.ethereum.org/EIPS/eip-7796) - eth_sendRawTransactionConditional
- [Keyspace Docs](https://docs.key.space) - Cross-chain key management
 