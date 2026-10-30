---
eip: 0
title: Recent Block Bound Delegation Authorizations
description: Require delegation authorizations to bind to one of the preceding 256 execution block hashes.
author: Joseph Delong (@dangerousfood)
discussions-to: https://ethereum-magicians.org/t/eip-7702-set-eoa-account-code/19923
status: Draft
type: Standards Track
category: Core
created: 2026-10-30
requires: 7702
---

## Abstract

Require every [EIP-7702](./eip-7702.md) authorization to sign an execution block number and its block header hash. An authorization may be applied only when the referenced block is one of the 256 immediate ancestors of the block including the transaction. Authorizations referencing older blocks, the current block, future blocks, or a different history are skipped. Legacy authorizations without a signed block reference are rejected after activation.

This bounds the inclusion window of an unused authorization. It does not impose an expiry on an installed delegation.

## Motivation

An unused delegation authorization can remain usable for an indefinite period if its account nonce remains unchanged. An authorization for a future nonce can also become usable later. Access to a previously signed authorization can therefore allow an attacker to install account code after the signer has stopped expecting that authorization to be used.

A mandatory recent block reference limits this exposure independently of nonce advancement, signature storage policy, and relayer behavior. Once the referenced block falls outside the permitted ancestor window, the authorization cannot be applied on that chain history even if its nonce subsequently matches.

The freshness condition must be enforced during native authorization processing. A deadline checked by delegate code or transaction calldata cannot prevent the protocol from first installing a delegation. Accepting legacy authorizations alongside the new format would leave previously signed authorizations outside the freshness requirement.

## Specification

### Parameters and definitions

| Name | Value |
| --- | --- |
| `AUTHORIZATION_HISTORY_WINDOW` | `256` |
| `SET_CODE_TX_TYPE` | `0x04`, unchanged |
| `MAGIC` | `0x05`, unchanged |

Let `B` be the execution block being processed and `N` its block number. For `0 <= b < N`, `ancestor_hash(B, b)` is the hash of the execution block header at number `b` on the ancestry of `B`. The hash is calculated using the header encoding applicable to that ancestor's fork. It is not a beacon block root, a transaction hash, or an arbitrary header supplied by the transaction sender.

Unless changed below, all transaction validity, authorization processing, signature, nonce, gas, and delegation rules of EIP-7702 continue to apply.

### Authorization encoding

Starting with the network upgrade activating this EIP, each entry in a type `0x04` transaction's `authorization_list` has exactly eight fields:

```text
[
    chain_id,
    address,
    nonce,
    anchor_block_number,
    anchor_block_hash,
    y_parity,
    r,
    s
]
```

The existing fields retain their EIP-7702 encodings and structural bounds. The additional fields are:

- `anchor_block_number`: a canonically RLP-encoded unsigned integer satisfying `0 <= anchor_block_number < 2**256`.
- `anchor_block_hash`: an RLP byte string of exactly 32 bytes.

An incorrect field count, noncanonical encoding, incorrect field type, or violation of a structural bound makes the entire transaction invalid. A legacy six-field authorization entry is invalid after activation, including when mixed with eight-field entries. An absent anchor has no default value or fallback interpretation.

Before activation, the legacy encoding remains in effect. Historical transactions are decoded and validated using the rules applicable to their inclusion block.

### Authorization signing digest

The message used for authority recovery becomes:

```text
authorization_digest = keccak256(
    MAGIC || rlp([
        chain_id,
        address,
        nonce,
        anchor_block_number,
        anchor_block_hash
    ])
)
```

Both anchor fields are covered by the authority's signature. Updating either field requires a new authorization signature.

The outer transaction retains its existing field order and signing procedure:

```text
outer_digest = keccak256(
    SET_CODE_TX_TYPE || rlp([
        chain_id,
        nonce,
        max_priority_fee_per_gas,
        max_fee_per_gas,
        gas_limit,
        destination,
        value,
        data,
        access_list,
        authorization_list
    ])
)
```

The complete, extended authorization entries are included in this outer digest.

### Freshness validation

Authorization processing occurs at the same point as in EIP-7702, after the outer sender's nonce has been incremented and before destination execution.

Before signature recovery or any authority-specific state access for an entry, check, in order:

1. `anchor_block_number < N`.
2. `N - anchor_block_number <= AUTHORIZATION_HISTORY_WINDOW`.
3. `anchor_block_hash == ancestor_hash(B, anchor_block_number)`.

The first check precedes subtraction. These rules admit exactly the ancestor heights in `[max(0, N - 256), N - 1]`. The parent is eligible. An ancestor exactly 256 blocks behind is eligible. An ancestor 257 blocks behind is ineligible. No anchor is eligible when `N == 0`.

If any freshness check fails, stop processing that entry and continue with the next authorization. That entry performs no signature recovery, authority warming, delegation write, authority nonce increment, or authorization refund. The transaction sender still pays the authorization's intrinsic charge.

If all freshness checks pass, process the entry under EIP-7702 using the new authorization digest. Freshness is necessary but does not replace any existing signature, chain ID, authority-code, or nonce check.

The ancestor lookup is part of native transaction processing. It does not execute an EVM instruction or contract call, consume EVM execution gas, or add an account or storage key to an access set. Implementations must obtain the actual referenced ancestor hash; unavailable ancestor data must not be substituted with a sentinel hash.

An expired or mismatched anchor is an authorization failure, not a transaction validity failure. Consequently, an otherwise valid transaction whose authorizations are all skipped may still execute its destination and succeed. Existing delegation on an authority is not removed by skipping an entry.

### Gas accounting

This EIP adds no separate gas surcharge. EIP-7702's `PER_EMPTY_ACCOUNT_COST`, `PER_AUTH_BASE_COST`, and authorization refund calculation remain unchanged. Every structurally valid authorization entry is charged, including entries that fail freshness validation. Any other gas rules activated by the network remain applicable.

### Setting and clearing delegation

The signed anchor is mandatory both when installing or replacing delegation and when clearing delegation by authorizing the zero address. There is no unanchored revocation exception.

An authorization that passes all checks has the same state effects as under EIP-7702. In particular, installed delegation persists after the anchor expires, and successful authorization processing is not rolled back when destination execution reverts.

### Activation

The extended authorization schema and freshness checks activate together at a coordinated execution-layer network upgrade. There is no grace period accepting legacy authorizations after activation. Pre-activation ancestors within the 256-block window are eligible anchors immediately at activation.

## Rationale

### Block number and block hash

The hash commits the authorization to a recent execution history. The number identifies the ancestor with a single indexed lookup and makes the window boundary explicit. Signing both prevents a submitter from changing the reference to extend validity.

A signed expiry height alone would permit signatures to be prepared arbitrarily far in advance. A recent ancestor hash ties validity to a particular recent chain history, subject to the usual cryptographic assumptions about block hashes.

### A 256-block window

The window matches the existing recent-ancestor interval of `BLOCKHASH` (`0x40`). It requires no new history-retention horizon. This specification does not change that instruction's implementation or gas rules.

[EIP-2935](./eip-2935.md) makes a longer hash history available from state. Availability of that longer history does not extend authorization validity beyond 256 blocks. Implementations may reuse existing infrastructure while enforcing this EIP's shorter interval.

### Retaining the transaction type and magic

The proposal changes the authorization schema at a fork while retaining the outer transaction format. Canonical RLP encoding distinguishes the new five-element signed message from the legacy three-element signed message. Retaining `MAGIC = 0x05` does not make a legacy signature valid for its original authority under the new digest, absent a cryptographic break.

This choice requires clients and tooling to support fork-dependent decoding for type `0x04`. It avoids allocating another transaction type and leaves no legacy transaction path for applying unanchored authorizations after activation.

### Skipping failed authorizations

Skipping a semantically invalid entry preserves EIP-7702's authorization-list behavior. It allows one transaction to carry authorizations for several authorities without making their combined inclusion contingent on every anchor remaining eligible. Structural errors still invalidate the transaction.

### Mandatory migration

Optional anchors would not bound the lifetime of existing signatures. Rejecting the legacy schema makes the freshness requirement universal for authorizations applied after activation. Existing installed delegations require no migration because this change governs authorization application rather than continued account execution.

## Backwards Compatibility

This is a consensus-breaking change requiring a network upgrade. Wallets, hardware signers, signing services, libraries, RPC implementations, explorers, and relayers that create or interpret type `0x04` transactions must support the extended authorization schema.

Previously signed authorizations cannot be submitted using their legacy encoding after activation. Pending transactions containing such entries must be rebuilt and signed again. Offline signing and recovery procedures that depend on long-lived, unused authorizations must obtain fresh anchors and signatures.

Existing account code, storage, balances, and installed delegation indicators are unaffected by activation. Normal transactions without an EIP-7702 authorization list retain their existing rules.

## Test Cases

For the following cases, let `N = 1000`, let `H(b)` be the correct ancestor hash at number `b`, and assume all other authorization and transaction checks pass. `X` is any 32-byte hash different from `H(b)`.

| Anchor number | Anchor hash | Expected result |
| --- | --- | --- |
| `999` | `H(999)` | Apply authorization |
| `745` | `H(745)` | Apply authorization; age 255 |
| `744` | `H(744)` | Apply authorization; age 256 |
| `743` | `H(743)` | Skip authorization; age 257 |
| `1000` | Any 32-byte hash | Skip authorization; current block |
| `1001` | Any 32-byte hash | Skip authorization; future block |
| `2**256 - 1` | Any 32-byte hash | Structurally valid number; skip before subtraction or lookup, without truncation |
| `999` | `X` | Skip authorization; wrong history |

Additional consensus cases:

| Condition | Expected result |
| --- | --- |
| `N = 1`, anchor `(0, H(0))` | Apply authorization |
| `N = 0`, any structurally valid anchor | Skip authorization |
| Anchor number `2**256`, 31-byte hash, noncanonical integer, or wrong field type | Invalid transaction |
| Six-field legacy entry after activation, alone or in a mixed list | Invalid transaction |
| Eight-field entry before activation | Invalid transaction under legacy rules |
| Either signed anchor field altered without re-signing | Signature does not authenticate the original authority; cannot apply to it |
| Fresh anchor with incorrect authority nonce or chain ID | Skip under inherited checks |
| Two entries for the same authority; first expired, second fresh at the current nonce | First skipped without consuming an authority nonce; second applies |
| Two fresh entries for the same authority at consecutive valid nonces | Both apply in list order; final delegation reflects the last applied entry |
| Expired entry for an otherwise cold authority | Authority remains cold due to that entry |
| All entries expired; destination execution succeeds | Transaction can succeed; no authorization is applied |
| Fresh zero-address delegation authorization | Clear delegation under inherited rules |
| Fresh applied authorization followed by destination execution reverting | Authorization effects persist |
| Anchor expires after delegation installation | Installed delegation persists |
| Activation block references an eligible pre-activation ancestor | Anchor accepted |
| Reorganization removes the anchor from the ancestry | Skip on the new branch |
| Reorganization restores the anchor and an eligible age | Freshness may pass again; other checks still apply |

## Reference Implementation

The following Python-like predicate specifies only the additional freshness test. Parsing, signature recovery, gas accounting, and state transitions remain governed by the rules above and EIP-7702.

```python
def authorization_is_fresh(block, authorization, ancestor_hash):
    number = authorization.anchor_block_number
    block_hash = authorization.anchor_block_hash

    if number >= block.number:
        return False
    if block.number - number > 256:
        return False
    return block_hash == ancestor_hash(block, number)
```

The predicate assumes canonical, structurally valid input, including a nonnegative anchor number and a 32-byte hash. It must run before authority recovery for each entry.

## Security Considerations

### Scope of protection

The proposal limits delayed use of unused authorizations. It does not prevent malicious signing, phishing, compromise of a signing service or private key, or submission of a fresh malicious authorization within the remaining window. It does not restrict ordinary signed transfers.

An installed malicious delegation retains access after its authorization's anchor expires. Recovery still requires replacing or clearing that delegation. Delegate-contract access control and initialization safety remain necessary.

### Chain progress and reorganizations

The limit measures produced execution blocks, not elapsed time or signature age. A chain halt does not age an anchor. A reorganization can remove an anchor, change its age, or make an expired authorization eligible again on a lower-height branch. A common ancestor does not distinguish competing branches that still share it.

EIP-7702's `chain_id = 0` behavior is retained. Such an authorization can be usable on multiple chains if they share the signed ancestor within their respective windows and all other checks pass. Chain-specific signing remains preferable when cross-chain use is unnecessary.

### Wallets and relayers

Signers should select anchors from a trustworthy view of the intended chain and leave sufficient time for inclusion. Older anchors provide less remaining inclusion headroom. Relayers must account for expiry and reorganizations and verify that the intended authorizations applied; a successful transaction receipt alone does not establish this.

### Resource costs

The additional fields increase transaction size and signature-hashing work, and each entry requires a bounded ancestor lookup. Client benchmarks and worst-case block-size analysis are needed to validate the unchanged authorization gas schedule before deployment. Any concurrent authorization-gas or transaction-content repricing must account for the extended encoding.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
