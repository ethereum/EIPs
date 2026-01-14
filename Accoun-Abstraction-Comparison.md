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

| Feature | Simple | Tempo | This Proposal |
|---------|--------|-------|---------------|
| Native Gas Sponsorship | ✅ | ✅ | ✅ |
| ERC-20 Gas Payment | ❌ | ✅ (TIP-20) | ✅ (registry) |
| Native AMM Option | ❌ | ❌ | ✅ (per chain) |
| Key Rotation | ❌ | ❌ | ✅ |
| Multiple Sig Types | ❌ | ✅ | ✅ |
| Passkeys/WebAuthn | ❌ | ✅ | ✅ |
| 2D Nonces | ❌ | ✅ | ✅ |
| Legacy 4337 Migration | ❌ | ❌ | ✅ |
| No EVM in Validation | ✅ | ✅ | ✅ |

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
- [EIP-7796](https://eips.ethereum.org/EIPS/eip-7796) - eth_sendRawTransactionConditional
- [Keyspace Docs](https://docs.key.space) - Cross-chain key management
 