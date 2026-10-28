---
title: Hash-Based Validator Cryptography
description: Keccak-256 hashing, two-layer leanXMSS signatures, and a Merkle-tree VRF for post-quantum validator keys
author: Thomas Coratger (@tcoratger), Kevaundray Wedderburn (@kevaundray), Tom Wambsgans (@TomWambsgans), Justin Drake (@JustinDrake)
discussions-to: https://ethereum-magicians.org/t/TBD/0
status: Draft
type: Standards Track
category: Core
created: 2026-10-27
---

## Abstract

This EIP defines the hash-based cryptography of post-quantum validator keys: a hash function, a stateful signature scheme, and a verifiable random function (VRF). The hash function is Keccak-256. The signature scheme, leanXMSS, is a two-layer XMSS over target-sum Winternitz one-time keys, with a lifetime of `2**32` leaf indices. The VRF is a Merkle tree over `2**32` leaf secrets that fixes one output per index.

The EIP specifies verification, which is consensus-critical, the rules a signer follows to keep its signatures secure, and numbered versions that other EIPs reference. It changes no protocol behavior by itself.

## Motivation

Post-quantum validator keys are registered by [EIP-8450](./eip-8450.md) and used by the fork that switches consensus duties away from BLS. Keystores ([EIP-8310](./eip-8310.md)) and aggregation proofs operate on the same keys and signatures. Defining the primitives once, apart from the protocol changes that use them, gives every consumer the same verification functions, byte layouts, and test vectors, and lets the cryptography be reviewed on its own.

The two primitives cover the two ways the consensus layer uses BLS today. Most messages need a signature, which leanXMSS provides. Selection proofs need an output that the signer cannot choose, which BLS provides because its signatures are unique. leanXMSS signatures are not unique, so the VRF tree provides those outputs.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

All inputs and outputs are byte strings, and every size is fixed. Integers are encoded little-endian unless stated otherwise. `keccak256(data)` is the 32-byte Keccak-256 hash of `data`, as used by the execution layer.

### Hash function

All hashing in this EIP uses `keccak256`, the Keccak-256 hash function of the execution layer, applied to the plain concatenation of its inputs.

### leanXMSS

#### Parameters

leanXMSS is a two-layer XMSS ([RFC 8391](https://www.rfc-editor.org/rfc/rfc8391)) over target-sum Winternitz one-time keys (WOTS+C), in the generalized XMSS framework[^dkkw25]. Its parameters are:

[^dkkw25]:

  ```csl-json
  {
      "id": "https://doi.org/10.62056/aey7qjp10",
      "type": "article-journal",
      "title": "Hash-Based Multi-Signatures for Post-Quantum Ethereum",
      "author": [
          { "given": "Justin", "family": "Drake" },
          { "given": "Dmitry", "family": "Khovratovich" },
          { "given": "Mikhail", "family": "Kudinov" },
          { "given": "Benedikt", "family": "Wagner" }
      ],
      "issued": { "date-parts": [[2025]] },
      "container-title": "IACR Communications in Cryptology",
      "volume": "2",
      "issue": "1",
      "DOI": "10.62056/aey7qjp10",
      "URL": "https://doi.org/10.62056/aey7qjp10",
      "custom": {
          "additional-urls": [ "https://eprint.iacr.org/2025/055" ]
      }
  }
  ```

| Name | Value | Description |
| - | - | - |
| `XMSS_CHAINS` | `58` | Hash chains per one-time key, each with positions `0` to `3` |
| `XMSS_TARGET_SUM` | `106` | Sum of the digits of every codeword |
| `XMSS_TREE_HEIGHT` | `16` | Height of the trees of each layer |
| `XMSS_HASH_SIZE` | `16` | Size of every chain value, Merkle node, public parameter `P`, and randomizer `rho` |
| `XMSS_MESSAGE_SIZE` | `32` | Size of a signed message, for example a message hash |

#### Structure

The key has two layers:

- **The bottom layer** (`layer = 0`) holds `2**32` one-time keys, grouped into `2**16` bottom trees of height 16. One-time key `i` belongs to bottom tree `i >> 16`. Node indices on the bottom layer are global across its trees.
- **The top layer** (`layer = 1`) is one tree of height 16 over `2**16` one-time keys. Top key `t` signs the 16-byte root of bottom tree `t`, and nothing else.
- **The public key** is the root of the top tree followed by the public parameter `P`: 32 bytes.

A signature at leaf index `i` carries `i`, the bottom one-time signature of the message by bottom key `i` with its path, and the top one-time signature of the root of bottom tree `i >> 16` by top key `i >> 16` with its path.

#### Tweakable hash

```python
def th(public_param: bytes, address: bytes, message: bytes) -> bytes:
    """
    Hash one call of a key.

    The public parameter separates keys.

    The address separates the calls within a key.

    The output keeps the first 16 bytes of the hash.
    """
    # Input layout: public parameter (16), address (16), message.
    return keccak256(public_param + address + message)[:XMSS_HASH_SIZE]
```

`public_param` is a 16-byte per-key public parameter. The address names the hash call within the key:

```python
# Types of the hash calls a verifier makes.
ADDRESS_CHAIN = 1
ADDRESS_LEAF = 2
ADDRESS_NODE = 3
ADDRESS_MESSAGE = 12


def xmss_address(kind: int, step: int, layer: int, high: int, low: int) -> bytes:
    """
    Build the 16-byte address of one hash call.

        bytes  0..4   one-time key or node index
        bytes  4..7   tree level, with the layer in the top bit
        byte   7      call type + 32 * chain step
        bytes  8..16  zero

    All integers are little-endian.
    """
    # The top layer sets bit 23 of the 3-byte field.
    high += 2**23 * layer
    return (
        low.to_bytes(4, "little")
        + high.to_bytes(3, "little")
        + bytes([kind + 32 * step])
        + bytes(8)
    )
```

Address types `0`, `5` and `7` are used only by the signer, to derive the chain secrets, the public parameter, and the randomizer.

#### Encoding

| Name | Value | Description |
| - | - | - |
| `XMSS_PUBLIC_KEY_SIZE` | `32` | Size of a public key |
| `XMSS_LAYER_SIGNATURE_SIZE` | `1200` | Size of one layer of a signature: `16 * (1 + 58 + 16)` |
| `XMSS_SIGNATURE_SIZE` | `2404` | Size of a signature: `4 + 2 * 1200` |

A public key is the concatenation:

| Bytes | Field | Description |
| - | - | - |
| `0:16` | top root | Root of the top tree |
| `16:32` | `P` | Public parameter |

A signature is the concatenation:

| Bytes | Field | Description |
| - | - | - |
| `0:4` | leaf index | Leaf index of the signature. The high 16 bits name the bottom tree, the low 16 bits the leaf inside it |
| `4:1204` | bottom layer | One-time signature of the message by bottom key `i`, with its path in the bottom tree |
| `1204:2404` | top layer | One-time signature of the bottom tree's root by top key `i >> 16`, with its path in the top tree |

A layer is the concatenation of 75 values of 16 bytes: the randomizer, then the `XMSS_CHAINS` chain values, one per chain at the position its digit names, then the `XMSS_TREE_HEIGHT` siblings from the leaf up to the root of its tree.

```python
def xmss_signature_index(signature: bytes) -> int:
    """
    Return the leaf index of a signature.
    """
    assert len(signature) == XMSS_SIGNATURE_SIZE
    return int.from_bytes(signature[:4], "little")
```

```python
def xmss_split_layer(layer: bytes) -> Tuple[bytes, Sequence[bytes], Sequence[bytes]]:
    """
    Split one layer of a signature into its randomizer, chain values, and path.
    """
    values = [layer[i:i + XMSS_HASH_SIZE] for i in range(0, len(layer), XMSS_HASH_SIZE)]
    return values[0], values[1:1 + XMSS_CHAINS], values[1 + XMSS_CHAINS:]
```

#### Verification

```python
def xmss_codeword(digest: bytes) -> Optional[Sequence[int]]:
    """
    Read a digest as a codeword, or return None.

    The 16 bytes give 64 base-4 digits, least significant first.

    A codeword has its last 6 digits at zero and its first 58 summing to 106.

    The fixed sum blocks forgeries.

    Raising one digit forces lowering another, which needs a hash preimage.
    """
    # 128 bits become 64 digits of 2 bits each.
    value = int.from_bytes(digest, "little")
    digits = [(value >> (2 * i)) & 3 for i in range(64)]

    # Unused digits must be zero, and the used ones must hit the target sum.
    if any(digits[XMSS_CHAINS:]) or sum(digits[:XMSS_CHAINS]) != XMSS_TARGET_SUM:
        return None
    return digits[:XMSS_CHAINS]
```

```python
def xmss_layer_leaf(
    public_param: bytes, layer: int, key: int, message: bytes, layer_signature: bytes
) -> Optional[bytes]:
    """
    Recover the leaf of one one-time key from its signature of a message.

    Returns None when the message digest is not a codeword.

    Each revealed chain value is walked up to the end of its chain.

    The leaf commits to all 58 chain ends.
    """
    randomness, chain_values, _ = xmss_split_layer(layer_signature)

    # Digest of the message under the signer's randomizer.
    digest = th(
        public_param,
        xmss_address(ADDRESS_MESSAGE, 0, layer, 0, key),
        message + randomness,
    )

    # The digits say which position each chain reveals.
    digits = xmss_codeword(digest)
    if digits is None:
        return None

    ends = b""
    for chain, (digit, value) in enumerate(zip(digits, chain_values)):
        # Walk from the revealed position to the end, position 3.
        #
        #     position:  0    1    2    3
        #     digit 1 :       ^ ---> ---> end   (2 steps)
        for step in range(digit, 3):
            # Each step also hashes the chain number.
            value = th(
                public_param,
                xmss_address(ADDRESS_CHAIN, step, layer, 0, key),
                value + chain.to_bytes(16, "little"),
            )
        ends += value

    # Hash the 58 chain ends into the leaf.
    return th(public_param, xmss_address(ADDRESS_LEAF, 0, layer, 0, key), ends)
```

```python
def xmss_layer_root(
    public_param: bytes, layer: int, key: int, leaf: bytes, path: Sequence[bytes]
) -> bytes:
    """
    Fold an authentication path from a leaf up to the root of its tree.

    The path holds one sibling per level, from the leaf upward.

    On the bottom layer, node indices are global across all bottom trees.
    """
    node = leaf
    for level, sibling in enumerate(path):
        # The key's bit at this level says which side the current node is on.
        #
        #     bit 0: hash(node, sibling)
        #     bit 1: hash(sibling, node)
        pair = node + sibling
        if (key >> level) & 1:
            pair = sibling + node

        # The parent's address names its level and its index at that level.
        address = xmss_address(ADDRESS_NODE, 0, layer, level + 1, key >> (level + 1))
        node = th(public_param, address, pair)
    return node
```

```python
def xmss_verify(public_key: bytes, message: bytes, signature: bytes) -> bool:
    """
    Verify a two-layer leanXMSS signature of a 32-byte message.

        message   --bottom key i-->      root of bottom tree i >> 16
        that root --top key i >> 16-->   top root, compared with the public key

    The signature carries its own leaf index.
    """
    # Inputs of the wrong size are invalid.
    if (
        len(public_key) != XMSS_PUBLIC_KEY_SIZE
        or len(message) != XMSS_MESSAGE_SIZE
        or len(signature) != XMSS_SIGNATURE_SIZE
    ):
        return False

    # The public key is the top root followed by the public parameter.
    top_root, public_param = public_key[:XMSS_HASH_SIZE], public_key[XMSS_HASH_SIZE:]
    index = xmss_signature_index(signature)
    bottom = signature[4:4 + XMSS_LAYER_SIGNATURE_SIZE]
    top = signature[4 + XMSS_LAYER_SIGNATURE_SIZE:]

    # The bottom tree holding this leaf, which is also the top key that certifies it.
    tree = index >> XMSS_TREE_HEIGHT

    # The bottom layer signs the message
    bottom_leaf = xmss_layer_leaf(public_param, 0, index, message, bottom)
    if bottom_leaf is None:
        return False
    _, _, bottom_path = xmss_split_layer(bottom)
    bottom_root = xmss_layer_root(public_param, 0, index, bottom_leaf, bottom_path)

    # The top layer certifies the bottom tree's root
    top_leaf = xmss_layer_leaf(public_param, 1, tree, bottom_root, top)
    if top_leaf is None:
        return False
    _, _, top_path = xmss_split_layer(top)
    return xmss_layer_root(public_param, 1, tree, top_leaf, top_path) == top_root
```

#### Key generation and signing

The secret key is a 32-byte seed. Key generation, signing, and the derivation of `P` and of the randomizer are not consensus-critical: any procedure whose signatures pass `xmss_verify` and satisfy the rules below is valid. Signing is deterministic: signing the same message at the same leaf index twice produces a byte-identical signature. Finding a codeword takes about `2**20` randomizer trials per signature.

A signer MUST NOT sign two different messages at the same leaf index. Each top key MUST sign only the root of its own bottom tree. Bottom trees MUST be derived deterministically from the seed, so that a regenerated bottom tree has the same root and a regenerated certification is byte-identical. How leaf indices are allocated to messages is left to the protocol that uses the key.

### VRF tree

#### Parameters

The VRF tree gives a validator one verifiable random output per index in `[0, 2**32)`. It is a Merkle tree of height `VRF_TREE_HEIGHT` over Keccak-256 with 32-byte nodes. Each leaf commits to a 32-byte leaf secret held by the validator. Opening index `i` reveals the secret of leaf `i` and its authentication path, and the output at index `i` is a hash of that secret. For a given root, each index has a single output unless a Keccak-256 collision is known.

| Name | Value | Description |
| - | - | - |
| `VRF_TREE_HEIGHT` | `32` | Height of the tree, for `2**32` indices |
| `VRF_HASH_SIZE` | `32` | Size of a root, node, leaf secret, and output |
| `VRF_OPENING_SIZE` | `1056` | Size of an opening: `32 * (1 + 32)` |
| `VRF_LEAF_DST` | `b"PQ_VRF_LEAF"` | Prefix of the leaf hash |
| `VRF_NODE_DST` | `b"PQ_VRF_NODE"` | Prefix of the node hash |
| `VRF_OUTPUT_DST` | `b"PQ_VRF_OUTPUT"` | Prefix of the output hash |

#### Encoding

An opening at index `i` is the concatenation:

| Bytes | Field | Description |
| - | - | - |
| `0:32` | secret | Secret of leaf `i` |
| `32:1056` | path | The `VRF_TREE_HEIGHT` siblings from the leaf up to the root, 32 bytes each |

#### Verification

```python
def vrf_verify(root: bytes, index: int, opening: bytes) -> Optional[bytes]:
    """
    Verify an opening of a VRF tree at an index, and return its output.

    Returns None when the opening does not lead to the root.

    The output is a hash of the leaf secret, not the leaf itself.

    An opening reveals the leaf of its sibling index, but not that index's output.
    """
    # Inputs of the wrong size or out of range are invalid.
    if (
        len(root) != VRF_HASH_SIZE
        or len(opening) != VRF_OPENING_SIZE
        or not 0 <= index < 2**VRF_TREE_HEIGHT
    ):
        return None
    secret = opening[:VRF_HASH_SIZE]
    path = [
        opening[i:i + VRF_HASH_SIZE] for i in range(VRF_HASH_SIZE, VRF_OPENING_SIZE, VRF_HASH_SIZE)
    ]

    # The leaf commits to the secret.
    node = keccak256(VRF_LEAF_DST + secret)

    for level, sibling in enumerate(path):
        # The index's bit at this level says which side the current node is on.
        #
        #     bit 0: hash(node, sibling)
        #     bit 1: hash(sibling, node)
        pair = node + sibling
        if (index >> level) & 1:
            pair = sibling + node
        node = keccak256(VRF_NODE_DST + pair)

    if node != root:
        return None

    # The output is a separate hash of the secret.
    return keccak256(VRF_OUTPUT_DST + secret)
```

#### Generation and opening

The leaf secrets are derived by the holder of the tree, and their derivation is not consensus-critical. The holder does not need to store the whole tree: it can keep the top levels and regenerate the subtree of an index when it opens it.

### Versions

Other EIPs reference the primitives by version. A version fixes the hash function and both primitives: every value and function that verification depends on, including the constants, the address layout, and the encoding. Versions are numbered from 1, and are part of the specification, not revisions of this document. A change to any part of a version defines a new version, which restates the parts it keeps unchanged.

| Version | Hash function | leanXMSS | VRF tree |
| - | - | - | - |
| 1 | [Keccak-256](#hash-function) | [leanXMSS](#leanxmss): `XMSS_CHAINS = 58`, `XMSS_TARGET_SUM = 106`, two layers of height `XMSS_TREE_HEIGHT = 16`, 16-byte digests | [VRF tree](#vrf-tree): `VRF_TREE_HEIGHT = 32`, 32-byte nodes |

### Interface

Other EIPs use the primitives only through the following functions, sizes, and properties:

| Item | Guarantee |
| - | - |
| `XMSS_PUBLIC_KEY_SIZE`, `XMSS_SIGNATURE_SIZE` | 32 and 2404 bytes |
| `xmss_verify(public_key, message, signature)` | Takes a 32-byte public key, a 32-byte message, and a 2404-byte signature. Returns `False` on inputs of any other size. Accepts a signature at any leaf index, and is unforgeable as long as the signer follows the leaf-index rules |
| `xmss_signature_index(signature)` | Returns the leaf index of a 2404-byte signature, in `[0, 2**32)` |
| Signing | Deterministic for a given message and leaf index |
| `VRF_HASH_SIZE`, `VRF_OPENING_SIZE` | 32 and 1056 bytes |
| `vrf_verify(root, index, opening)` | Returns the 32-byte output at `index`, or `None`. At most one output per index and root without a Keccak-256 collision |

## Rationale

### One EIP and one version for the hash, signatures, and VRF

The hash function has no consumer outside the two primitives, and the primitives are registered together by [EIP-8450](./eip-8450.md). The most likely change, to the hash function, affects both primitives. A single version number therefore covers all three, and a consumer of one primitive refers to that primitive of a given version. Keeping them in one EIP puts all hash inputs, and the argument that they never collide across primitives, in one place, and gives them one test suite.

### Hash function choice

The hash function is Keccak-256, the hash function of the execution layer. It is the original submission underlying SHA-3 (FIPS 202), differing from SHA3-256 only in its padding. Keccak has been analyzed publicly since the SHA-3 competition, and no collision or preimage attack on full-round Keccak-256 is known. The security of the signature scheme rests on the hash function alone, so this EIP uses a hash function with a long cryptanalytic record that every execution client already implements.

Arithmetization-oriented hashes such as Poseidon are cheaper to prove under some conditions but have a shorter cryptanalytic record. Proving systems over binary fields, such as leanVM, prove standard hash functions such as Keccak-256, so the aggregation proofs do not require an arithmetization-oriented hash.

### A two-layer XMSS key

A flat XMSS tree of height 32 has a smaller signature, but its root depends on all `2**32` one-time keys: key generation takes about `9 * 10**11` Keccak-f permutations. Range keys cover only a window of indices and fill the rest of the tree with pseudo-random nodes. This reduces key generation, but fixes the key's lifetime at registration and still requires one large computation before registration.

The two-layer tree limits each step to `2**16` one-time keys. The single-layer column is derived from the leanXMSS cost formulas with one tree of height 32:

| | Flat tree, height 32 | Two layers, 16 + 16 |
| - | - | - |
| Key generation (public key) | `2**32` one-time keys | `2**16` one-time keys |
| Ongoing work | None | One bottom tree of `2**16` one-time keys per `2**16` leaf indices |
| Signature | 1460 bytes | 2404 bytes |
| Verification | 109 Keccak-f permutations | 186 Keccak-f permutations |

The public key depends only on the `2**16` one-time keys of the top tree. A bottom tree is generated before its first leaf index is used. Hash-based schemes have no threshold variant, so a distributed validator generates and holds the key inside a multi-party computation, which then covers `2**16` one-time keys for the public key, against `2**32` for a flat tree. The leanXMSS specification sketches a threshold signer in which signing uses a threshold pseudorandom function, and multi-party computation is needed only at key generation and once per bottom tree. A signer holds at most the top tree and one bottom tree, each with `2**17 - 1` nodes of 16 bytes.

The cost is one additional one-time signature per message: 944 more bytes of signature and 77 more Keccak-f permutations, so aggregators prove about 1.7 times as many permutations per signature. The split between the two layers is part of version 1, and a later version can change it.

Publishing the root of each bottom tree separately, for example in the beacon state, would keep a one-layer signature, but adds about sixteen certifications per slot with a million validators.

### VRF tree construction

The nodes are 32 bytes, not the 16 bytes of the XMSS digests. Uniqueness has to hold against the validator that built the tree, which only needs a collision, and a 16-byte digest admits a generic collision search of about `2**64` evaluations. The output is a separate hash of the secret because every opening reveals the leaf of its sibling index.

The root depends on all `2**32` leaves, so generating it takes at least `2**33` Keccak-f permutations, one per leaf and one per node, plus the derivation of the secrets. This is about a hundredth of the cost of a flat XMSS tree of the same height, but unlike the two-layer leanXMSS key it cannot be split into steps of `2**16` leaves, since every output has to be fixed at registration.

### Leaf index in the signature

The signature carries its leaf index, so the verifier needs no schedule. The protocol that uses the key decides how leaf indices are allocated to messages, and can change that allocation without changing the verifier.

## Backwards Compatibility

This EIP defines cryptographic primitives only. It changes no protocol behavior until another EIP uses them.

## Test Cases

Test vectors are to be provided in the Ethereum cryptography specifications, covering at least:

- leanXMSS verification: valid signatures at leaf indices `0`, `2**16 - 1`, `2**16`, and `2**32 - 1`, and rejection of a digest that is not a codeword and of a signature whose top layer certifies a different bottom root.
- VRF openings: valid openings at indices `0` and `2**32 - 1`, and rejection of an opening with a wrong secret, a wrong sibling, or the path of another index.
- Deterministic signing: two signatures of the same message at the same leaf index are byte-identical.

## Reference Implementation

leanXMSS over Keccak-256 is specified and implemented in the leanVM repository, with a Lean 4 proof of its classical security.

## Security Considerations

### Leaf reuse

Two different messages signed at the same leaf index reveal enough chain values to forge further signatures at that index. The signer rules in [Key generation and signing](#key-generation-and-signing) prevent this: each leaf index signs at most one message, and each top key certifies only the root of its own deterministically derived bottom tree, since certifying two different roots under the same top key is a leaf reuse.

### Hash function and parameters

The leanXMSS specification proves 127 bits of classical strong unforgeability in the random oracle model, in Lean 4, for the scheme as specified here. The parameters target 64 bits of quantum security, NIST level 1. That target is not a proved bound.

### VRF uniqueness and unpredictability

Each index has a single output unless the validator finds a Keccak-256 collision among the hashes of its tree. With 32-byte nodes, generic collision search costs about `2**128` hash evaluations classically and about `2**85` quantumly with the Brassard–Høyer–Tapp algorithm. Outputs stay unpredictable to others until opened, by the preimage resistance of Keccak-256: an opening reveals the leaf of its sibling index, not its output. A leaked leaf secret lets others predict the output at its index, but not change it.

### Domain separation

leanXMSS hash inputs are 64, 80, or 960 bytes and start with the per-key public parameter. VRF tree inputs are 43, 45, or 75 bytes and start with a fixed prefix. No input of one primitive is an input of the other, and within each primitive the address or prefix separates the calls.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
