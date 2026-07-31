---
eip: plain-ml-dsa
title: Precompiles for ML-DSA verification
description: Three precompiles verifying ML-DSA signatures from a concatenated public key, signature, and trailing message
author: Danno Ferrin (@shemnon)
discussions-to: https://ethereum-magicians.org/t/eip-precompiles-for-ml-dsa-verification/29211
status: Draft
type: Standards Track
category: Core
created: 2026-07-30
---

## Abstract

Three precompiles verify ML-DSA signatures[^fips204] at NIST security levels II,
III, and V, corresponding to parameter sets ML-DSA-44, ML-DSA-65, and ML-DSA-87.
Each precompile takes a single concatenated input of the form `pubkey ++
signature ++ message` with no length prefixes. The public key and the signature
have fixed lengths defined by the parameter set, so the message is exactly the
trailing bytes. Each precompile returns a 32-byte left-padded word: one on a
valid signature and zero otherwise.

## Motivation

Ethereum needs a post-quantum signature verifier that a delegated account can
use as its authenticator. [EIP-8051](./eip-8051.md) proposes ML-DSA
verification, but two of its choices do not serve that use. This proposal
differs from it in these two ways.

First, this EIP covers NIST security levels III and V in addition to level II.
EIP-8051 specifies only ML-DSA-44, which targets 128-bit classical security. An
account authenticator is long-lived and holds funds for years, so it wants
margin above 128 bits, and ML-DSA-65 and ML-DSA-87 are the higher tiers NIST
recommends for exactly that reason.

Second, it places a variable-length message last and infers its length from the
total input size, where EIP-8051 fixes the message at a 32-byte pre-hash. ML-DSA
is not a fixed-length message scheme: FIPS 204 defines signing and verification
over a message of any length, and the signature and public key are the only
fixed-size values in the algorithm. A verifier that accepts exactly 32 bytes
implements a strict subset of the scheme and forces every caller holding a longer
message to pre-hash it first. Taking the message as the trailing bytes restores
the full domain at no cost, since the two fixed-size fields precede it and its
length follows by subtraction.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described
in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119)
and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

### Precompile addresses

Three precompiles are added at a contiguous block of addresses.

| Precompile       | Address   | Level | Parameter set |
|------------------|-----------|-------|---------------|
| `VERIFY_MLDSA44` | `<TBD>`   | II    | ML-DSA-44     |
| `VERIFY_MLDSA65` | `<TBD>+1` | III   | ML-DSA-65     |
| `VERIFY_MLDSA87` | `<TBD>+2` | V     | ML-DSA-87     |

### Sizes

Public keys use the standard compressed FIPS 204 encoding `pk = (ρ, t1)`, and
signatures use the standard FIPS 204 signature encoding.

| Parameter set | `PK_LEN` | `SIG_LEN` | Minimum input |
|---------------|----------|-----------|---------------|
| ML-DSA-44     | 1312     | 2420      | 3732          |
| ML-DSA-65     | 1952     | 3309      | 5261          |
| ML-DSA-87     | 2592     | 4627      | 7219          |

### Input format

The input is a single byte string, big-endian throughout, with no header and no
length fields.

```
offset 0                : pubkey     (PK_LEN bytes)
offset PK_LEN           : signature  (SIG_LEN bytes)
offset PK_LEN+SIG_LEN   : message    (len(input) - PK_LEN - SIG_LEN bytes)
```

Let `L = len(input)`. If `L < PK_LEN + SIG_LEN` the call MUST fail, returning 32
zero bytes without reverting. A message of length zero is permitted, so
`L == PK_LEN + SIG_LEN` is a valid input; FIPS 204 admits the empty message.
Otherwise the fields are `pubkey = input[0 : PK_LEN]`,
`signature = input[PK_LEN : PK_LEN + SIG_LEN]`, and
`message = input[PK_LEN + SIG_LEN : L]`.

The input carries no context string; the precompile always uses the empty
context
`ctx = ""` that FIPS 204 § 5.3 gives as the default. Callers that need domain
separation MUST place it in the message itself.

### Semantics

The precompile computes `ML-DSA.Verify(pubkey, message, signature)` per FIPS 204
over the raw message, performing the matrix expansion `Â = ExpandA(ρ)` and the
internal `μ = H(BytesToBits(tr) ‖ M')` hashing itself. It returns success if and
only if verification passes.

Malformed encodings, including out-of-range coefficients, a non-canonical hint
`h`, and a `‖z‖` bound failure, MUST return failure rather than revert, so that
a caller can treat "invalid signature" as a boolean.

### Output

The precompile always returns exactly 32 bytes. The value `0x00..01` indicates a
valid signature. The value `0x00..00` indicates a signature that is invalid or
malformed, or an input shorter than `PK_LEN + SIG_LEN`.

The precompile never reverts on cryptographic failure or invalid calldata; only
exhausting gas ends the call abnormally. Caller code can therefore branch on the
returned word with `ISZERO`.

### Gas cost

Gas is `BASE + 6 * ceil(len(message) / 32)`, where `BASE` depends on the
parameter set.

| Precompile       | Base gas | Per message word |
|------------------|----------|------------------|
| `VERIFY_MLDSA44` | 6500     | 6                |
| `VERIFY_MLDSA65` | 9000     | 6                |
| `VERIFY_MLDSA87` | 13500    | 6                |

The base cost dominates and covers the matrix expansion and the NTT verification
work. The small linear term covers hashing the message, which is cheap relative
to the lattice arithmetic.

## Rationale

### Message last, with no length field

Placing the message last and omitting a length field keeps the delegated-account
verification loop tight. The two fixed-size fields come first, so a caller
appends the public key, then the signature, then streams the message to the end
of its buffer and calls the precompile with the resulting size. There is no
length word to compute, place, or get wrong.

### Variable-length messages

Accepting a message of any length, rather than the fixed 32 bytes of EIP-8051,
also keeps the precompile inside FIPS 204. A 32-byte input can only be a digest,
so that design forces every caller into pre-hashing, and FIPS 204 § 5.4 makes
pre-hashing a distinct construction: HashML-DSA binds the digest to the
identifier of the hash function that produced it, so a signature over a digest
cannot be reinterpreted as one over a different message under a different hash.
A bare 32-byte message carries no such binding, and a 32-byte-only precompile
cannot verify a HashML-DSA signature either, since the encoded identifier and
domain separator push the message representative past 32 bytes. What remains is
neither pure ML-DSA nor HashML-DSA, but an unnamed third construction whose
security argument the caller must supply. Callers remain free to pass a digest
and take on that obligation, as a caller that holds only a digest must, but the
precompile should not force it on callers who can sign a message directly.

### Empty context string

FIPS 204 lets an application pass a context string of up to 255 bytes, bound
into the message representative and empty by default. Fixing it to empty follows
the profiles that use ML-DSA: the X.509 certificate and TLS specifications both
leave the context at its default and rely on the surrounding protocol for domain
separation. This precompile is in the same position, since the message it
verifies is already a protocol-specific commitment, and a caller wanting further
separation can prefix it onto the message.

A context field would also be length-tagged, reintroducing the header this
layout exists to avoid, and it would cost more than its bytes. Not every
cryptographic library exposes the parameter; several widely used ones verify
with the empty context only and document application-supplied contexts as future
work. Accepting a context would push clients built on those libraries onto a
hand-rolled verifier, for a field the deployed protocols leave empty anyway.

### One address per parameter set

Three separate addresses were chosen over a single precompile switching on a
leading selector byte. Each address then has a fixed input shape and its own
flat gas cost, with no branch byte to parse and no ambiguity between a level
selector and the first byte of a public key. Separate addresses also let a chain
enable and meter the levels independently. The addresses are left unassigned
here and should be allocated as a contiguous block during standardization,
alongside or after the EIP-8051 precompile.

### Compressed public keys

Taking the compressed public key rather than a pre-expanded one reverses the
EIP-8051 tradeoff deliberately. EIP-8051 accepts a 20512-byte key with the
matrix materialized and `t1` in the NTT domain, letting its precompile skip the
expansion. Here the public key lives in the account's delegation trailing data
as restated by [EIP-7819](./eip-7819.md), where every byte is persistent state.
A 2592-byte compressed ML-DSA-87 key is tolerable in that position and a
20512-byte expanded key is not, so the gas schedule prices in the expansion work
instead. A chain wanting the expanded-key tradeoff could add sibling precompiles
for it.

### Gas schedule

The base costs are higher than the 4500 gas EIP-8051 charges because these
precompiles expand the matrix from `ρ` rather than receiving it pre-expanded.
The linear term exists only to price the SHAKE256 pass over the message, which
is why it is small relative to the base. The figures given here require
benchmarking against a reference implementation before they are final; they are
sized to sit modestly above equivalent-work pairing checks.

### Implementation maturity

Unlike a novel curve or a bespoke construction, ML-DSA already has high-quality
implementations in every language an execution-layer client is written in, and
in the browser tier that light clients and dapps run in. Clients can bind to a
vetted implementation rather than write lattice code from scratch, which makes
shipping the precompile low-risk. At the time of writing:

- **Java** has native key generation and signature support for all three
  parameter sets in the SUN provider, as of JDK 24 and JDK 25.
- **Rust** has several pure-Rust crates, including one that is no-`std`, no-
  `unsafe`, and constant-time, and another that is formally verified and ships
  an AVX2 backend.
- **Go** carries an internal FIPS 204 implementation with a public
  standard-library package targeted for a near-term release, and a widely used
  third-party module is available today.
- **C# and .NET** expose a native ML-DSA type with platform-backed providers, as
  of .NET 10.
- **C** has a portable, security-focused C90 implementation alongside the
  reference implementation and liboqs.
- **JavaScript and WebAssembly** have high-quality libraries today, and native
  ML-DSA is specified for the Web Cryptography API with browser rollout in
  progress.

The point is not any single library but the breadth: every consensus client
language, and the web platform, can source a maintained ML-DSA verifier.

## Backwards Compatibility

The precompiles occupy previously unassigned addresses, so no existing behavior
changes. Before the activation fork a call to one of those addresses returns
empty output; afterwards it returns a 32-byte word and charges the schedule
above. No deployed contract is known to depend on the prior behavior.

## Security Considerations

Because field lengths are inferred rather than declared, a caller that lets an
attacker control the total input length can shift the boundaries between the
public key, the signature, and the message. Callers MUST fix `PK_LEN` and
`SIG_LEN` by choosing the precompile address for a known parameter set, and MUST
source the public key from a trusted location such as the account's own trailing
code data rather than from caller-supplied input.

Verifying under an empty context string, the precompile provides no domain
separation of its own. If a key is ever used across schemes, the caller MUST
domain-separate within the message. An authentication contract built on
[EIP-8141](./eip-8141.md) satisfies this by signing over the frame hash, which
already commits to the frame being authorized.

Failure is returned as a value rather than a revert, so callers MUST inspect the
returned word. A `STATICCALL` that succeeds says nothing about whether the
signature was valid.

Clients MUST charge the full gas cost before performing any verification work.
The cost depends only on the input length, so it can be computed and deducted up
front. Metering afterwards would let an attacker obtain the work for free in a
transaction that runs out of gas, a denial-of-service surface.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).

[^fips204]:
    ```csl-json
    {
        "id": "https://doi.org/10.6028/NIST.FIPS.204",
        "type": "report",
        "title": "Module-Lattice-Based Digital Signature Standard",
        "author": [
            { "literal": "National Institute of Standards and Technology" }
        ],
        "issued": {
            "date-parts": [[2024, 8, 13]]
        },
        "publisher": "National Institute of Standards and Technology",
        "publisher-place": "Gaithersburg, MD",
        "collection-title": "Federal Information Processing Standards Publication",
        "number": "204",
        "URL": "https://doi.org/10.6028/NIST.FIPS.204",
        "DOI": "10.6028/NIST.FIPS.204"
    }
    ```
