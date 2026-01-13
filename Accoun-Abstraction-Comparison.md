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
- Enables multiple signature types (K1, R1, WebAuthn, BLS)
- Provides quantum-safe migration path (add post-quantum key types later)
- Works on all chains without new opcodes

**Rejected alternatives**:
| Alternative | Why Rejected |
|-------------|--------------|
| 7702-only key management | EOA key always has ultimate authority; can't truly rotate |
| Per-account storage slots | Storage conflicts with contract code; no canonical interface |
| New account trie field | Requires deeper protocol changes |

### Decision 2: Token Payment Registry + Oracle

**Choice**: Tokens register storage slots; oracle provides exchange rate; payers accept tokens permissionlessly.

**Rationale**:
- Does not enshrine a specific token standard (vs TIP-20)
- Tokens opt-in by declaring balance/blocklist slots
- Oracle-based pricing allows any price feed (Native Oracle / Chainlink compatible)
- Permissionless payers system can leverage existing defi/AMM allowing integrations across the space
- Payers can implement custom logic (sweep tokens via DeFi)

**Rejected alternatives**:
| Alternative | Why Rejected |
|-------------|--------------|
| Native AMM | Enshrines ERC-20 at protocol level; picks winner; potentially pulls liquidity from DeFi, stifling innovation |
| TIP-20 only | Rigid; existing tokens can't participate. Note: TIP-403 blocklist concept is adopted via per-token blocklist slots |
| In-TX state checks only, EVM execution | Higher calldata cost; no protocol enforcement |

**Token registration** is initially permissioned (chain allowlists USDC, USDT, etc.). Permissionless registration with stake + verification can be added later.

### Decision 3: Permissioned + Permissionless Payer Modes

**Choice**: Support both signature-based (permissioned) and config-based (permissionless) payers.

| Mode | payer_auth | Use Case |
|------|-----------|----------|
| Self-pay | Empty | User pays ETH |
| Permissioned | 65-byte K1 signature | Trusted sponsors, private relays |
| Permissionless | 20-byte address | Public gas markets, pseudo-AMM |

**Rationale**:
- Permissioned mode for trusted relationships (app subsidizing users)
- Permissionless mode enables open gas markets without signatures
- Payers register accepted tokens; protocol enforces balance/blocklist checks
- Payers can sweep accumulated tokens via Uniswap/Aerodrome

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
2. Resolve payer from `payer_auth`
3. Verify 2D nonce, payer ETH balance, expiry
4. If token payment: verify registration, balance, blocklist, max_amount
5. Mempool threshold for sponsored txs

All checks are **pure slot reads**—no EVM execution.

### Token Payment Flow

```
1. Read exchange rate from oracle
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
| Key Rotation | ❌ | ❌ | ✅ |
| Multiple Sig Types | ❌ | ✅ | ✅ |
| Passkeys/WebAuthn | ❌ | ✅ | ✅ |
| 2D Nonces | ❌ | ✅ | ✅ |
| Legacy 4337 Migration | ❌ | ❌ | ✅ |
| Quantum-Safe Path | ❌ | ❌ | ✅ |
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

| Item | Status |
|------|--------|
| Default account (opt-in wallet code) | Deferred—auth precompile provides most AA benefits |
| Permissionless token registration | Future—start with chain allowlist |
| `eth_sendRawTransactionConditional` | Complementary for non-token state checks |

---

## References

- [EIP Draft: Standardized AA with Onchain Key Configs](./EIPS/eip-draft_aa_enshrined_validation.md)
- [Tempo Transaction Spec](https://docs.tempo.xyz/protocol/transactions/spec-tempo-transaction)
- [Simple Approach (gakonst)](https://gist.github.com/gakonst/00117aa2a1cd327f515bc08fb807102e)
- [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702) - EOA code delegation
- [EIP-4337](https://eips.ethereum.org/EIPS/eip-4337) - Account Abstraction via EntryPoint
- [EIP-7796](https://eips.ethereum.org/EIPS/eip-7796) - eth_sendRawTransactionConditional
- [Keyspace Docs](https://docs.key.space) - Cross-chain key management
