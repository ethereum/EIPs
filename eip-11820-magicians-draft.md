# EIP-11820: Post-Quantum Keystore for Stateful Keys

*Draft for the Ethereum Magicians forum. Suggested category: **EIPs**. Suggested tags: `keystore`, `post-quantum`, `xmss`, `lean`.*

---

## Summary

This thread is for discussion of a new Standards Track (Core) EIP that defines a keystore format for **stateful hash-based signing keys** — XMSS as used by the lean Ethereum consensus layer (referred to as `leanxmss`).

It extends [ERC-2335](https://eips.ethereum.org/EIPS/eip-2335) so the encrypted secret may be an XMSS seed, and adds the machinery a *consumable* key requires.

- **Draft PR:** https://github.com/ethereum/EIPs/pull/11820
- **Status:** Draft

## Motivation

[ERC-2335](https://eips.ethereum.org/EIPS/eip-2335) stores a reusable 32-byte BLS scalar. Lean Ethereum replaces BLS validator keys with XMSS for post-quantum security. The XMSS secret reduces to a small seed, so the *container* needs only modest change — but the security model does not.

Each XMSS signature consumes a one-time WOTS+ leaf whose index **MUST NOT** ever be reused; reuse across two distinct messages enables forgery and is key-destroying. That single property breaks three things today's tooling takes for granted:

1. **Immutability** — a 2335 keystore never changes; an XMSS key advances state on every signature.
2. **Free copying** — two copies of a BLS key are harmless; two copies of an XMSS key signing independently will reuse leaves.
3. **Restore-safety** — restoring a *stale* XMSS state rolls back the high-water mark and invites reuse.

For the synchronized variant, "never reuse a leaf" and the [EIP-3076](https://eips.ethereum.org/EIPS/eip-3076) "never double-sign a slot" invariant are identical, so the EIP makes that coupling normative and specifies the off-protocol cases (e.g. builder-bid signing) that fall outside slashing protection.

## What the EIP adds

- An explicit `scheme`-parameter block (immutable; everything needed to regenerate the public key and verify a signature).
- A non-authoritative capacity snapshot for operator visibility.
- Normative rules for **where the authoritative signing state lives** (slashing-protection DB in synchronized mode; a dedicated store in counter mode).
- A **commit-before-sign** durability ordering (persist the advanced high-water mark before releasing a signature).
- **Reserved leaf ranges** for concurrent / high-throughput signers.
- **Import / export** semantics that forbid silently resetting a key's signing position, and a clear distinction between *recover* and *resume signing*.
- Minor encryption upgrades: AES-256 / AEAD ciphers and an optional `argon2id` KDF.

## Open questions for discussion

1. **Hash function.** The format is intentionally **hash-agnostic** — `scheme.params.hash` records the concrete choice. Poseidon1 (e.g. over the KoalaBear field) is currently being evaluated for consideration as the recommended instantiation. Feedback on the hash choice and on what (if anything) the EIP should recommend vs. leave open is welcome.
2. **Scheme parameters.** The example uses leanSig's recommended production set for a 2^32 key lifetime (`dimension = 46`, `winternitz_w`/base `= 8`, `target_sum = 200`, target-sum encoding). Are these the right defaults to surface in the spec?
3. **Parameter naming.** `winternitz_w` is used for the per-chain base; should it instead be named `base` to match the hypercube/target-sum formulation?
4. **Counter-mode state store.** Is the durability/atomicity bar specified for the dedicated counter-mode store sufficient and implementable across clients?
5. **Reserved ranges.** Is range-based partitioning the right mechanism for the builder-bid exhaustion case, or is a different concurrency model preferred?

Feedback, objections, and review on the [draft PR](https://github.com/ethereum/EIPs/pull/11820) are all appreciated.
