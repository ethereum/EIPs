---
eip: XXXX
title: ECRECOVER Native Key Awareness
description: Extends ECRECOVER to verify native-key signatures and reject dead ECDSA keys
author: Gregory Markou (@GregTheGreek) <gregorymarkou@gmail.com>, James Prestwich (@prestwich) <james@prestwi.ch>
discussions-to: https://ethereum-magicians.org/t/eip-XXXX-ecrecover-native-key-awareness/XXXXX
status: Draft
type: Standards Track
category: Core
created: 2026-04-11
requires: 2929, 8164
---

## Abstract

This EIP modifies the ECRECOVER precompile (address `0x01`) to support [EIP-8164](./eip-8164.md) native-key accounts. In ECDSA mode, after successful key recovery, the precompile checks whether the recovered address has a native-key delegation (code prefix `0xef0101`–`0xef01ff`); if so, it returns empty rather than the address. In native-key mode, signaled by a `0xff` sentinel in the `v` argument, the precompile accepts a target address and a scheme-specific signature, then verifies the signature against the public key embedded in that account's native-key designation. ML-DSA-44 (`0xef0101`) verification is defined here, and the design is forward-compatible with future native-key schemes.

## Motivation

[EIP-8164](./eip-8164.md) lets EOAs permanently replace their ECDSA signing key with a post-quantum alternative by storing a native-key designation under the `0xef0101`–`0xef01ff` code prefix range. Once an account has a native-key designation, the protocol rejects ECDSA-signed transactions from that account — the ECDSA key is considered dead. The ECRECOVER precompile, however, has no knowledge of this change.

This creates two problems. First, the authority model becomes inconsistent: smart contracts that rely on ecrecover for signature verification — including ERC-20 permit functions, [EIP-2612](./eip-2612.md) gasless approvals, and meta-transaction relayers — continue to accept ECDSA signatures from accounts whose ECDSA keys the protocol no longer recognizes as authoritative. An attacker in possession of a compromised ECDSA private key can exploit this gap even after the account owner has migrated to a native key.

Second, smart contracts have no mechanism to verify signatures produced by native-key accounts. Permit flows, governance votes, and other on-chain signature checks become inaccessible to accounts that have migrated to native keys, effectively forcing a trade-off between post-quantum security and contract interoperability.

This EIP resolves both problems by making ECRECOVER native-key-aware: ECDSA recovery results are gated against the on-chain native-key designation, and a new input mode enables contract-level verification of native-key signatures.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Constants

| Name | Value | Description |
|------|-------|-------------|
| `ECRECOVER_BASE_COST` | `3000` | Existing ECDSA recovery gas cost (unchanged) |
| `ML_DSA_44_VERIFY_COST` | `50000` | Gas for ML-DSA-44 signature verification (matches [EIP-8164](./eip-8164.md)) |

### Input Format

The precompile dispatches on byte 32 of its input:

- If `input[32] != 0xff`: **ECDSA mode.** The input is the standard 128 bytes: `hash (32) || v (32) || r (32) || s (32)`.
- If `input[32] == 0xff`: **Native-key mode.** The input is variable-length: `hash (32) || 0xff (1) || address (20) || signature (variable)`.

The `0xff` sentinel is unambiguous: valid ECDSA `v` values are `27` or `28`. Any input with `0xff` at byte 32 already fails ECDSA recovery under current rules.

In native-key mode, the packing is tight starting at byte 33. The `address` occupies bytes 33 through 52. The `signature` begins at byte 53 and its length is scheme-dependent (2,420 bytes for ML-DSA-44, for a total input length of 2,473 bytes).

### Return Value

Both modes return a 32-byte left-padded Ethereum address on success, or empty output (0 bytes) on failure. This preserves the existing ECRECOVER interface.

### ECDSA Mode

ECDSA recovery proceeds as before, with an additional code check:

1. Recover the address via `ecrecover(hash, v, r, s)`. If recovery fails, return empty.
2. Load the recovered address's account code. The address MUST be added to the transaction's accessed addresses set per [EIP-2929](./eip-2929.md).
3. If the code begins with `0xef01` followed by a nonzero byte (a native-key designation per EIP-8164), return empty.
4. Otherwise, return the recovered address left-padded to 32 bytes.

The code prefix `0xef0100` ([EIP-7702](./eip-7702.md) code delegation) is not a native-key designation. EIP-7702 delegated accounts retain valid ECDSA keys.

### Native-Key Mode

When `input[32] == 0xff`:

1. If the input is fewer than 54 bytes, return empty. No account access occurs.
2. Parse `address = input[33:53]`.
3. Load the account's code. The address MUST be added to the transaction's accessed addresses set per EIP-2929.
4. If the code does not begin with `0xef01` followed by a nonzero byte, return empty.
5. Dispatch to the verification logic for the specific `0xef01XX` prefix. If the prefix has no defined verification logic, return empty.

#### ML-DSA-44 Verification (`0xef0101`)

When the account's code begins with `0xef0101`:

1. Verify the input is exactly 2,473 bytes. Otherwise return empty.
2. Extract `pubkey = code[3:1315]`.
3. Extract `signature = input[53:2473]`.
4. Verify `ML_DSA_44_Verify(pubkey, input[0:32], signature)` per FIPS 204[^1] Section 6 (Algorithm 3). The following strictness requirements apply (matching EIP-8164):
   - All encodings MUST be canonical per FIPS 204. Non-canonical encodings of public keys or signatures MUST be rejected.
   - The signature vector `z` coefficients MUST satisfy the norm bound check as specified in FIPS 204. Implementations MUST NOT skip or relax this check.
   - The hint vector `h` MUST have exactly the number of ones indicated by the signature metadata; duplicate or out-of-order indices MUST be rejected.
   - Implementations MUST produce identical accept/reject decisions for every possible `(pubkey, message, signature)` triple.
5. If verification succeeds, return `address` left-padded to 32 bytes.
6. If verification fails, return empty.

### Gas Cost

#### ECDSA Mode

| Component | Cost |
|-----------|------|
| Base recovery | `ECRECOVER_BASE_COST` (`3000`) |
| Account access (on successful recovery) | `2600` cold / `100` warm per EIP-2929 |

If `ecrecover` itself fails (invalid `v`, `r`, or `s`), no account access occurs and only `ECRECOVER_BASE_COST` is charged.

#### Native-Key Mode

| Component | Cost |
|-----------|------|
| Account access | `2600` cold / `100` warm per EIP-2929 |
| ML-DSA-44 verification (`0xef0101`) | `ML_DSA_44_VERIFY_COST` (`50000`) |

Account access is always charged when the input is at least 54 bytes. If the input is fewer than 54 bytes, the cost is `0`.

Verification cost is charged whenever the account has a recognized native-key delegation and the input is of the expected length for that scheme. It is charged regardless of whether verification succeeds or fails. Future native-key schemes define their own verification costs.

## Rationale

### Modifying ECRECOVER vs. New Precompile

Modifying the existing precompile at address `0x01` gives contracts the ECDSA guard for free. Every contract that calls ecrecover today — ERC-20 permits, meta-transaction verifiers, multisig confirmation checks — automatically rejects dead ECDSA keys after the fork without redeployment. A separate precompile for native-key verification would require every signature-checking contract to be updated, even for the guard behavior.

### The `0xff` Sentinel

The sentinel reuses the existing input layout. Byte 32 is the ECDSA `v` parameter, which is `27` or `28`. The value `0xff` is unambiguous and already causes ECDSA recovery to fail. Tight packing after the sentinel (address at byte 33, signature at byte 53) avoids wasting calldata gas on padding.

### Forward Compatibility

The ECDSA guard checks the full `0xef0101`–`0xef01ff` range, so future native-key schemes are guarded automatically without a precompile update. Verification dispatch, by contrast, requires explicit per-scheme logic — this is intentional. Each scheme has different signature sizes, verification algorithms, and gas costs. A generic dispatch would require either a variable-cost model negotiated at runtime or overly conservative gas pricing.

### Returning Empty on Failure

All failure modes return empty (0 bytes) rather than reverting. This preserves the existing ecrecover interface where callers check for a zero return. Reverting would be a breaking change: existing contracts that use `staticcall` and check the return value would behave differently post-fork.

### Gas Model

The ECDSA path charges account access only after successful recovery. If recovery fails (bad `v`, `r`, `s`), there is no address to look up and no access cost is incurred. The native-key path always charges account access because the target address is explicit in the input. Verification cost is charged on both success and failure to prevent gas-based signature validity oracles — an attacker should not be able to distinguish valid from invalid signatures by observing gas consumption.

## Backwards Compatibility

This EIP introduces a behavioral change to the existing ECRECOVER precompile (address `0x01`) that affects all callers.

In ECDSA mode, a successful recovery now incurs an additional account code lookup, increasing gas cost by 100 (warm) to 2,600 (cold) gas per [EIP-2929](./eip-2929.md). Contracts that pass a hardcoded gas stipend of exactly 3,000 to the precompile fail post-fork. In practice this is uncommon — most contracts forward remaining gas or use a generous allowance.

Contracts that verify ECDSA signatures from accounts that have migrated to a native key (EIP-8164) now receive an empty return where they previously received a valid address. This is intentional: it aligns contract-level signature validation with the protocol's view that the ECDSA key is permanently inert.

ERC-20 permit functions and EIP-2612 contracts benefit from the ECDSA guard automatically. Accepting signatures from native-key accounts requires callers to construct the native-key input format (`0xff` sentinel), which requires contract updates or wrapper contracts.

No new transaction type, opcode, or precompile address is introduced.

## Test Cases

Pending.

## Security Considerations

### ECDSA Key Rejection Consistency

The ECDSA guard must produce results consistent with EIP-8164's transaction-level ECDSA rejection rule. If the precompile accepts an ECDSA signature that transaction validation would reject (or vice versa), contracts and the protocol hold inconsistent views of account authority. Implementations must check the same code prefix range (`0xef0101`–`0xef01ff`) and must not cache or defer the code lookup.

### Account Code TOCTOU

The code lookup and signature verification occur atomically within the precompile call. An account's native-key delegation cannot change mid-execution: delegations are set during authorization list processing, before transaction execution begins. There is no time-of-check-to-time-of-use risk.

### Malleability

The precompile inherits the ML-DSA-44 strictness requirements specified in EIP-8164, including canonical encoding validation, norm bound checking, and hint vector validation. No additional malleability surface is introduced.

### Gas Griefing

An attacker can force a cold account access (2,600 gas) by supplying an arbitrary address in native-key mode. This is comparable to any opcode that touches account state, such as `BALANCE` or `EXTCODESIZE`, and does not represent a novel attack vector.

### Forward Compatibility

When the target account's code begins with an `0xef01XX` prefix that has no defined verification logic, the precompile returns empty. A contract cannot distinguish "no delegation" from "delegation with an unsupported scheme." This is not the ideal default, but it preserves the existing ecrecover interface where all failure modes return empty rather than reverting. Reverting would be a breaking change to the precompile's interface contract.

[^1]:

  ```csl-json
  {
    "type": "standard",
    "id": 1,
    "author": [
      {
        "literal": "National Institute of Standards and Technology"
      }
    ],
    "title": "Module-Lattice-Based Digital Signature Standard",
    "DOI": "10.6028/NIST.FIPS.204",
    "URL": "https://csrc.nist.gov/pubs/fips/204/final",
    "original-date": {
      "date-parts": [
        [2024, 8, 13]
      ]
    }
  }
  ```

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
