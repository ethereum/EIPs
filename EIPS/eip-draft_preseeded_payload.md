---
title: Pre-seeded Encrypted Execution Payloads
description: The builder sends its payload encrypted once the block includes its bid, and the reveal is a 32-byte key.
author: Csaba Kiraly (@cskiraly)
discussions-to: https://ethereum-magicians.org/t/eip-xxxx-pre-seeded-encrypted-execution-payloads/30475
status: Draft
type: Standards Track
category: Networking
created: 2026-11-23
requires: 7732, 8411
---

## Abstract

Under [EIP-7732](./eip-7732.md), the builder reveals the execution payload after the beacon block that includes its bid, and the payload has from the reveal to the payload deadline to reach the network. This EIP lets the builder send the payload before the reveal, encrypted: it pre-seeds the network with the payload.

It defines two chunking schemes for [EIP-8411](./eip-8411.md). Their chunks carry the compressed envelope, encrypted under a 32-byte key, and the bid's chunk root also commits to the key's hash. Once a valid beacon block includes the bid, the builder disseminates the encrypted chunks over Waggle as EIP-8411 specifies. At the reveal, it sends the key on the payload's Waggle object. Nodes check the key against the commitment with one Merkle branch, decrypt, and check the envelope as EIP-8411 specifies.

The payload then has from the block to the deadline, and only the key waits for the reveal. Consensus does not change: the bid's fields, the envelope check and the payload deadline stay as EIP-7732 and EIP-8411 define them.

## Motivation

EIP-7732 separates the beacon block from the execution payload. The block carries the builder's bid, which fixes the payload, and the builder reveals the payload later. A member of the Payload Timeliness Committee (PTC) votes the payload present only if it received it before `PAYLOAD_DUE_BPS`, half of the slot.

A builder has reason not to reveal as soon as the block arrives. Until attestations show that the block will stay, a revealed payload could be unbundled by whoever builds next, so builders are expected to wait. The payload's transfer therefore runs from the reveal to the deadline. The time from the block to the reveal carries nothing of the payload, although the bid has already fixed its contents.

That budget binds as payloads grow and slots shrink. Gas-limit growth makes payloads larger, which motivates EIP-8411. [EIP-7782](./eip-7782.md) proposes 6-second slots, and [EIP-8198](./eip-8198.md) makes the slot duration a schedule and shortens it. With the same fractions of the slot, a 6-second slot leaves 1.5 seconds from the attestation deadline to the payload deadline. EIP-8411 makes the transfer faster, but the transfer still starts at the reveal.

This EIP starts it at the block. Once a valid block includes the bid, the builder sends the payload encrypted, and the reveal shrinks to a 32-byte key.

The author simulated the mechanism with 500 nodes on residential links with 50, 20 or 10 Mbps uplinks and payloads of 1, 2 and 4 MiB, with ten seeds per setting. The block's publication time and the attesters' vote times were drawn from mainnet measurements, and each hop of the block took 20 or 60 milliseconds beyond the link's latency. The broadcast simulated was SEACAST, and the baseline was the same broadcast sending the payload at the reveal. The simulation carries no attestation traffic on the links, and its 6-second slots halve the block's publication time but keep the votes' delay after the block. In it, the median gain over nodes and slots was the payload's transfer time less the key's spread, about 0.1 seconds, up to the head start between the block and the reveal. On 12-second slots it was about 0.4 seconds for 1 MiB at 50 Mbps, and 0.6 to 0.8 seconds for 2 MiB at 50 Mbps and for 1 MiB at 20 Mbps. Where the gain reached the head start, it was about 0.8 to 1.7 seconds, depending on when the builder reveals and how fast the block spreads. With 6-second slots and a reveal once half of the attestations are in, for 1 MiB at 10 Mbps, 2 MiB at 20 Mbps and 4 MiB at 50 Mbps, the pre-seeded payload reached more than half of the nodes by the deadline in 70 to 89 percent of the drawn slots with 20 milliseconds per hop, and in 65 to 78 percent with 60 milliseconds. Sent at the reveal, it did so in 1 to 26 percent and under 4 percent of the slots. Pre-seeded, most slots ended with at least 90 percent of the nodes holding the payload or at most 10 percent.

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174).

This EIP extends EIP-8411. Its names (`PayloadChunksDescriptor`, `PayloadChunk`, `ChunkMetadata`, `piecesMetadata`, the plain and coded schemes and their functions) refer to that EIP.

### Relation to EIP-8411

This EIP assigns, in EIP-8411's message format:

- the chunking scheme identifiers `2` and `3`;
- the leaf at index `chunk_count` of the chunk root under these two schemes, which EIP-8411 otherwise sets to zero;
- the `piecesMetadata` kind `1`, which EIP-8411 reserves for later mechanisms.

It requires EIP-8411 to let an EIP that requires it make these assignments. For its two schemes it also changes one rule of EIP-8411: the builder disseminates the ciphertext chunks from the block on, and only the key waits for the reveal (see Dissemination).

### Parameters

| Constant | Value |
| --- | --- |
| `CHUNKING_SCHEME_ENCRYPTED_PLAIN` | `ChunkingScheme(2)` |
| `CHUNKING_SCHEME_ENCRYPTED_RS` | `ChunkingScheme(3)` |
| `PAYLOAD_KEY_KIND` | `1` |

The encrypted plain scheme uses `PLAIN_CHUNK_SIZE`, and the encrypted coded scheme uses `RS_CHUNK_SIZE` and the code of EIP-8411. `PAYLOAD_KEY_KIND` is a kind of `piecesMetadata`.

### Encryption

The builder compresses the serialized envelope with Snappy block compression and encrypts the result with ChaCha20 as defined in [RFC 8439](https://www.rfc-editor.org/rfc/rfc8439), section 2.4, with a 32-byte key, a nonce of twelve zero bytes and an initial block counter of zero. Decryption is the same operation.

```python
def encrypt_payload(data: bytes, key: Bytes32) -> bytes:
    return chacha20_encrypt(key=key, counter=0, nonce=Bytes12(), plaintext=data)


def compute_payload_ciphertext(envelope: ExecutionPayloadEnvelope, key: Bytes32) -> bytes:
    data = serialize(envelope)
    assert len(data) <= MAX_PAYLOAD_SIZE
    compressed = snappy_compress(data)
    assert len(compressed) <= max_compressed_len(MAX_PAYLOAD_SIZE)
    return encrypt_payload(compressed, key)
```

Any valid Snappy block encoding of the serialized envelope is allowed whose length is at most `max_compressed_len(MAX_PAYLOAD_SIZE)`. A receiver does not compress the envelope again; it checks what it decrypts (see Reconstruction).

The builder MUST draw the key uniformly at random for each envelope it encrypts, and MUST NOT use a key to encrypt two different byte strings.

### Chunks and commitment

The encrypted schemes split the ciphertext as the plain and coded schemes split the serialized envelope. The chunk root covers the chunks and, in the first leaf after them, the SHA-256 hash of the key.

```python
def is_encrypted_chunking_scheme(scheme: ChunkingScheme) -> bool:
    return scheme in (CHUNKING_SCHEME_ENCRYPTED_PLAIN, CHUNKING_SCHEME_ENCRYPTED_RS)


def compute_byte_chunks(data: bytes, coded: bool) -> List[Chunk, MAX_EXECUTION_PAYLOAD_CHUNKS]:
    if coded:
        k = compute_rs_data_chunk_count(len(data))
        data = uint_to_bytes(uint64(len(data))) + data
        data += b"\x00" * (k * RS_CHUNK_SIZE - len(data))
        data_chunks = [
            Chunk(data[i * RS_CHUNK_SIZE:(i + 1) * RS_CHUNK_SIZE]) for i in range(k)
        ]
        return data_chunks + rs_encode(data_chunks)
    return [
        Chunk(data[start:start + PLAIN_CHUNK_SIZE])
        for start in range(0, len(data), PLAIN_CHUNK_SIZE)
    ]


def compute_encrypted_chunks_root(chunks: Sequence[Chunk], key_hash: Bytes32) -> Root:
    leaves = [hash(chunk) for chunk in chunks] + [key_hash]
    leaves += [Bytes32()] * (MAX_EXECUTION_PAYLOAD_CHUNKS - len(leaves))
    return hash_tree_root(Vector[Bytes32, MAX_EXECUTION_PAYLOAD_CHUNKS](leaves))


def compute_encrypted_payload_chunks_descriptor(
    chunks: Sequence[Chunk],
    scheme: ChunkingScheme,
    key: Bytes32,
) -> PayloadChunksDescriptor:
    assert is_encrypted_chunking_scheme(scheme)
    return PayloadChunksDescriptor(
        scheme=scheme,
        chunk_count=len(chunks),
        chunk_size=RS_CHUNK_SIZE if scheme == CHUNKING_SCHEME_ENCRYPTED_RS else PLAIN_CHUNK_SIZE,
        chunks_root=compute_encrypted_chunks_root(chunks, hash(key)),
    )
```

Before signing the bid, the builder constructs the envelope, draws the key and computes `ciphertext = compute_payload_ciphertext(envelope, key)` and `chunks = compute_byte_chunks(ciphertext, scheme == CHUNKING_SCHEME_ENCRYPTED_RS)`. It sets `bid.payload_chunks` to `compute_encrypted_payload_chunks_descriptor(chunks, scheme, key)` and `bid.envelope_root` to `hash_tree_root(envelope)`, the root of the envelope in plaintext. EIP-8411's `compute_payload_chunks` and `compute_payload_chunks_descriptor` apply to its plain and coded schemes only.

Each chunk travels in a `PayloadChunk` with its inclusion proof, as in EIP-8411. The leaf at index `chunk_count` is the key's hash, and no chunk has that index.

The encrypted schemes are known chunking schemes, and their descriptors are checked as follows. The bound on the ciphertext's length is the worst case of Snappy compression, `max_compressed_len`, as defined for gossipsub. The count leaves room for the key's leaf.

```python
def is_known_chunking_scheme(scheme: ChunkingScheme) -> bool:
    # [Modified in this EIP]
    return scheme in (CHUNKING_SCHEME_PLAIN, CHUNKING_SCHEME_RS) or is_encrypted_chunking_scheme(scheme)


def is_valid_encrypted_payload_chunks_descriptor(descriptor: PayloadChunksDescriptor) -> bool:
    max_length = max_compressed_len(MAX_PAYLOAD_SIZE)
    if not 0 < descriptor.chunk_count < MAX_EXECUTION_PAYLOAD_CHUNKS:
        return False
    if descriptor.scheme == CHUNKING_SCHEME_ENCRYPTED_RS:
        return (
            descriptor.chunk_size == RS_CHUNK_SIZE
            and descriptor.chunk_count % 2 == 0
            and descriptor.chunk_count // 2 <= compute_rs_data_chunk_count(max_length)
        )
    # CHUNKING_SCHEME_ENCRYPTED_PLAIN
    return (
        descriptor.chunk_size == PLAIN_CHUNK_SIZE
        and descriptor.chunk_count <= compute_plain_chunk_count(max_length)
    )
```

`is_valid_payload_chunks_descriptor` returns `is_valid_encrypted_payload_chunks_descriptor(descriptor)` for an encrypted scheme, after the checks on the format's limits. At the size limit, the encrypted plain scheme uses 747 chunks and the encrypted coded scheme 1,494.

`is_valid_chunk_length` applies the rules of the plain scheme to the encrypted plain scheme, and those of the coded scheme to the encrypted coded scheme.

### Key

The builder reveals by sending the key with its inclusion proof:

```python
class PayloadKey(Container):
    key: Bytes32
    key_proof: Vector[Bytes32, CHUNK_INCLUSION_PROOF_DEPTH]


def verify_payload_key(payload_key: PayloadKey, descriptor: PayloadChunksDescriptor) -> bool:
    return is_valid_merkle_branch(
        leaf=hash(payload_key.key),
        branch=payload_key.key_proof,
        depth=CHUNK_INCLUSION_PROOF_DEPTH,
        index=descriptor.chunk_count,
        root=descriptor.chunks_root,
    )
```

A `PayloadKey` travels on the payload's Waggle object, in `piecesMetadata` of kind `PAYLOAD_KEY_KIND`: the kind byte, then the `PayloadKey`, SSZ serialized: 385 bytes of `piecesMetadata`.

For a message about the payload of a tracked beacon block `block` that carries a `PayloadKey` `payload_key`, with `descriptor = block.body.signed_execution_payload_bid.message.payload_chunks`, a node applies the following checks after EIP-8411's checks on all messages:

- _[REJECT]_ The payload's scheme is encrypted: `is_encrypted_chunking_scheme(descriptor.scheme)`.
- _[REJECT]_ The sender has not sent the node a valid `PayloadKey` about this payload before.
- _[REJECT]_ The key is the committed one: `verify_payload_key(payload_key, descriptor)`.

A `PayloadKey` that passes these checks is valid at the node, even if the message is dropped because its `PayloadChunk` fails EIP-8411's checks on chunks. At the builder, the key becomes valid when the builder decides to publish it. If a message is dropped because its `PayloadKey` fails these checks, a `PayloadChunk` in it that passes EIP-8411's checks on chunks MAY still be used and forwarded, under the conditions EIP-8411 sets for a message whose `ChunkMetadata` fails its checks.

A node that does not implement this EIP does not know the kind, and handles the message as EIP-8411 specifies for an unknown kind.

### Dissemination

The ciphertext chunks are disseminated as EIP-8411 disseminates chunks, except for when the builder starts. EIP-8411 has the builder track the payload as a node that holds none of its chunks until it reveals the payload. Under an encrypted scheme, the builder instead holds all ciphertext chunks as valid from the moment it validates a beacon block that contains its bid, and disseminates them. This is the pre-seeding: it does not wait for its decision to reveal.

What EIP-8411 ties to the reveal applies to the key. The builder publishes the key when it would broadcast its envelope under [EIP-7732](./eip-7732.md), and may withhold it in the same case. The builder MUST keep the key secret until it first publishes it. Until it publishes the key for a block, it MUST NOT return that block's envelope in `ExecutionPayloadEnvelopesByRange` or `ExecutionPayloadEnvelopesByRoot` responses. A proposer that builds its own payload and reveals it with its block gains nothing from encryption, and SHOULD use a plain or coded scheme. If it uses an encrypted scheme, it constructs the envelope, the key, the descriptor and `envelope_root` as the builder does, before it signs the block, and follows the builder's rules for the chunks and the key.

A node disseminates the key of each tracked payload as follows:

- When the key becomes valid at the node, the node SHOULD send it right away to every peer that is known to track the payload, has not sent the node a valid key and was not sent the key by the node. It SHOULD send the key ahead of the chunks it has queued for that peer.
- When a peer starts to track the payload, which the node learns from its first `ChunkMetadata` about the payload, the node SHOULD send the peer the key if it holds a valid key, under the same conditions.
- A node MUST NOT send the key to a peer that sent no `ChunkMetadata` about the payload, or that the node sent the key to before.

### Reconstruction

A node reconstructs the envelope of an encrypted payload once it holds the key and either all `chunk_count` chunks under the encrypted plain scheme or any `K = chunk_count // 2` chunks under the encrypted coded scheme. This replaces step 1 of EIP-8411's Payload state for these schemes. The node performs the following checks in order. If any fails, the chunk set is invalid, and the node follows EIP-8411's failure procedure.

1. Under the encrypted plain scheme, concatenate the chunks in index order to give the ciphertext `C`, and check `len(C) <= max_compressed_len(MAX_PAYLOAD_SIZE)`. Under the encrypted coded scheme, recover the `K` data chunks with `rs_decode`, read the ciphertext length `L` from the first 8 bytes as a little-endian integer, check `0 < L <= max_compressed_len(MAX_PAYLOAD_SIZE)` and `compute_rs_data_chunk_count(L) == K`, and take the `L` bytes after the length as `C`.
2. Under the encrypted coded scheme, check that `compute_encrypted_chunks_root(compute_byte_chunks(C, True), hash(key))` equals `descriptor.chunks_root`.
3. Decrypt `C` with `encrypt_payload(C, key)`. Check that the uncompressed length in the result's Snappy header is at most `MAX_PAYLOAD_SIZE` before decompressing it. Check that the result decompresses as one Snappy block that uses every byte and gives exactly that length.
4. Check that the result deserializes as an `ExecutionPayloadEnvelope`.

The node then continues with steps 2 to 4 of EIP-8411's Payload state, whose step 3 checks `hash_tree_root(envelope) == bid.envelope_root`. Under the encrypted coded scheme, EIP-8411's step 5 applies with the tree rebuilt in step 2 above: once the envelope passes step 3, the chunks the node lacked become valid, with their inclusion proofs from that tree, and the node announces, pushes and serves them as EIP-8411's Dissemination section specifies.

Before the key arrives, a node holds and disseminates only the chunks it received, each valid by its own inclusion proof. EIP-8411's rule to stop requesting chunks once the node holds enough to reconstruct the payload counts chunks only: all `chunk_count` chunks under the encrypted plain scheme, or `K` under the encrypted coded scheme, whether or not the node holds the key.

### Payload timeliness

This EIP changes neither `PAYLOAD_DUE_BPS` nor how a PTC member votes. As EIP-8411 specifies, a member sets `payload_present` according to when the envelope passed the checks. Under an encrypted scheme, reconstructing the envelope from chunks requires the key and enough chunks before the deadline. Without a valid key a node cannot reconstruct the envelope, but it may still obtain it by request as EIP-8411 specifies.

## Rationale

**Why encrypt, when the block already commits to the payload.** The bid fixes the payload, but the block can still be dropped until it is attested. A payload sent in plaintext at block time would then show its contents to whoever builds next, which is why an EIP-7732 builder is expected to wait before it reveals. Encryption keeps waiting safe: if the block is dropped, the payload's contents stay hidden as long as the key stays secret, as an EIP-7732 builder's do when it withholds, though its ciphertext has been sent (see Security Considerations). The builder's choice stays with the builder, and the bytes travel early.

**Why a 32-byte symmetric key.** The reveal has to be small to be fast: the key's spread, rather than the payload's transfer, is what remains after the reveal. In the simulation's model, a key of 32 bytes reached the median node about 0.11 seconds after the builder sent it. Symmetric encryption is fast at both ends, and a 256-bit key keeps a margin against quantum search.

_A one-time pad._ It hides perfectly only if it is as long as the payload, so the reveal would be as large as the payload.

_Pre-seeding all but one chunk of a code._ With a Reed-Solomon code over `k` data chunks, `k - 1` chunks cannot be decoded. But at every symbol position they are `k - 1` equations in `k` unknowns. They leave one unknown per position, and one more symbol at that position, from any other source, decodes it, and some of the payload is public already, from the bid's fields to transactions in the mempool. Mazorra, Öz, Schlegel and Wu (_The Free Option Problem of ePBS_, 2025) describe the same move for blob columns as a way to lengthen the builder's option.

**Why ChaCha20.** It needs no hardware support to be fast and constant-time, and RFC 8439 defines it with test vectors. AES-256 in counter mode would serve equally where hardware supports it. No authenticated encryption is needed: the chunk root authenticates the ciphertext, and `envelope_root` the plaintext. A fresh key for every envelope makes a fixed nonce safe.

**Why compress before encrypting.** Ciphertext does not compress, and EIP-8411 compresses each chunk on the wire. Encrypting the serialized envelope would therefore send it at its uncompressed size. Compressing first keeps the encrypted payload as small as the compressed one.

Compressors can produce different bytes for the same envelope. EIP-8411 discusses two ways for a scheme that compresses before coding to say which sets are valid. The encrypted schemes take the second: a set is valid when its chunks verify against the root, its parity follows from its data, and the plaintext decompresses to the envelope committed by `envelope_root`. No receiver compresses the envelope, and no client has to reproduce another's compressor. A node that holds only the envelope cannot rebuild the committed chunks, which it does not need: it can serve the envelope by request.

**Why the key's commitment is a leaf under the chunk root.** The bid already commits to the chunk root, so the key's hash under it changes neither the bid nor consensus. A node checks a key with one Merkle branch against the bid of the validated block, as it checks a chunk. The key needs no signature: the bid authenticates the root, and only the committed key matches its leaf.

_A field in the bid._ A key hash of its own in the bid would be equally simple to check. It would change the bid's layout, which needs a fork, for a field that consensus never reads.

_A hash in the first chunk._ A node could check a key only once it held that chunk.

_No commitment._ A node could check a key only by decrypting the whole payload, so every forged key would cost a decryption.

**Why the key travels on the payload's Waggle object.** The peers that track the payload are the ones that need its key, and they already exchange its chunks. A kind of `piecesMetadata` adds a message without a new topic, and EIP-8411 reserves kinds for such mechanisms. A node that does not know the kind ignores it. A gossipsub topic of its own would also work and would not depend on Waggle's connections. It would add a topic, a message ID and duplicate suppression for a message that every node needs once per payload.

**Without EIP-8411.** Pre-seeding needs three things: a commitment to the ciphertext that nodes can check before the reveal, a commitment to the key, and the base protocol's check of the decrypted envelope. The chunk root in EIP-8411's bid provides the first two, which is why this EIP builds on it. On EIP-7732 alone, the builder could instead sign a message once its bid is included, naming the beacon block's root and carrying the hashes of the ciphertext and of the key, along with the ciphertext of its signed envelope. Nodes would check the signature against the builder of the bid and the ciphertext against its signed hash before forwarding it, then the key against its signed hash, and the decrypted envelope as EIP-7732 specifies. This would not change the bid either. It costs one more signature check per payload and a gossip topic for each of the two messages, and the ciphertext would travel as a single message, without EIP-8411's faster dissemination. In exchange, the signature binds the key's commitment to the named block, and the decrypted envelope, signed as under EIP-7732, names that block.

**The builder's free option.** Under EIP-7732, the builder can still decide not to reveal after its bid is included, for example if prices moved against its trades. If the beacon block gathers enough attestation weight, the proposer is paid the bid either way: EIP-7732 calls this the proposer's unconditional payment. When the builder decides, the bid is therefore sunk. Withholding costs it nothing more than revealing, and it withholds whenever the payload has become worth less than nothing to it. The cost falls on the chain's users, as a slot without a payload. EIP-7732's Security Considerations name this the free option problem. Mazorra, Öz, Schlegel and Wu find that the option's value, and how often it is exercised, grow with the window in which the builder can still decide.

The window in which the builder can decide without showing the payload ends at the latest reveal that still reaches the PTC before the payload deadline. Under EIP-7732 that is the deadline less the payload's transfer time. Under this EIP, once the ciphertext has arrived, it is the deadline less the key's spread. This EIP therefore lengthens the window by about the transfer time it saves. In the simulation, the median transfer time of a payload sent at the reveal, less the key's modeled 0.11 seconds, was about 0.4 seconds for 1 MiB at 50 Mbps, 1.4 seconds for 1 MiB at 10 Mbps and 2.4 seconds for 2 MiB at 10 Mbps; the simulation did not measure the latest reveal that still reaches the PTC.

Three facts bound what this changes:

- A small payload already reaches the PTC quickly, so its builder can already decide until shortly before the deadline. This EIP gives large payloads the window that small ones already have.
- A builder with a private blob can already decide until the blob data is due, at three quarters of the slot. This EIP does not move that.
- A payload the builder never reveals stays hidden either way: an EIP-7732 builder that withholds never sends the envelope, and a builder under this EIP never sends the key, though its ciphertext is then public (see Security Considerations).

The designs considered:

- _Keep the deadline, and accept the longer window._ This EIP does so. All of the time saved goes to the payload's delivery.
- _Move `PAYLOAD_DUE_BPS` earlier by the time saved._ The window and the delivery stay as under EIP-7732, and the time saved goes to after the deadline, for execution or towards shorter slots. One deadline cannot match a saving that depends on the payload's size and the network's links. Mazorra et al. also note that tightening the PTC's deadlines costs scalability, here by as much as this EIP gains.
- _A separate, earlier deadline for the key._ The ciphertext would still have until `PAYLOAD_DUE_BPS`, and the key would have to reach the PTC by an earlier deadline. That caps the key's route whatever the payload's size, and delivery keeps the gain as long as the builder reveals at least the key's spread before that deadline. A builder can still hold back ciphertext instead of the key. Holding back all of it is EIP-7732's route, once the key has met its deadline. Holding back only the last chunks needed to reconstruct the envelope keeps the decision open until the payload deadline less those chunks' spread, but once the key is out, the chunks already sent show part of the payload: a chunk of the encrypted plain scheme, or a data chunk of the encrypted coded scheme, decrypts on its own, and parity chunks decode wherever enough symbols at the same position are known, as for pre-seeding all but one chunk of a code above. Such a deadline therefore caps the growth for every builder only if enough chunks to reconstruct the envelope, or the envelope itself, are due with the key; otherwise it constrains only a builder that cannot accept showing part of its payload. It costs a parameter and a second timeliness check for PTC members, which has to say how an envelope obtained by request counts, since under this EIP such an envelope counts without the key. It also leaves an honest builder whose block arrived late less time to decide: if the block arrives too late for the key to meet its deadline, the key's route is closed even where a plaintext envelope would still be in time. With the key's deadline at `PAYLOAD_DUE_BPS`, and an envelope obtained by request counting as under this EIP, it is this EIP, so it can be added later without changing anything else.
- _Take the key out of the builder's hands._ The key could be threshold-encrypted to the PTC, as Shutter (2025) proposed for the whole payload, so that the committee opens it if the builder withholds after the block is attested. This takes the key out of the builder's hands, but not the ciphertext, which the builder can still hold back, all of it or only the last chunks needed to reconstruct the envelope, as above. It needs threshold cryptography and key setup in consensus, and it must open the key only if the block stays, to keep the honest builder's reason to wait. It composes with this EIP: only 32 bytes need threshold encryption.
- _Penalize exercised options._ EIP-7732's Security Considerations mention variable penalties for builders whose payload is missing, and Mazorra et al. discuss penalizing exercised options. Such penalties apply to all of ePBS, and they hit honest withholding after a late block unless that is carved out. They work unchanged with this EIP.

**Why the gain depends on the reveal.** The time gained is the time from each node's receipt of the block to the reveal, up to the payload's transfer time. EIP-7732 leaves the reveal to the builder. In the simulation, on 12-second slots, the median gain stopped growing at about 0.8 seconds when the builder reveals once half of the attestations are in, at 1.0 to 1.3 seconds when it reveals at a quarter of the slot, and at 1.4 to 1.7 seconds when it reveals 0.4 seconds later. The lower ends are for a block that spreads more slowly, at 60 rather than 20 milliseconds per hop.

A block that reaches the builder late leaves no head start. If the builder reveals as soon as it sees the block, the ciphertext and the key leave together, and each node waits for the block before it accepts chunks. A plaintext payload waits the same way: EIP-7732 ignores, and may queue, an envelope whose block a node has not seen, and EIP-8411 sends chunks only to nodes that track the payload. A fallback to plaintext for late blocks would therefore save nothing, and this EIP has none. If a plaintext path that also waits for the block delivered its chunks at the same times, the encrypted path would wait longer for the network only where the key reaches a node after the chunks it needs to reconstruct the envelope. In the simulation's late blocks, the baseline that waits for the block used the same chunk arrival times as the encrypted path, and at every node the key arrived by the time the node held those chunks.

**Why the deadline is unchanged.** Where the payload deadline should sit once the payload no longer waits for the reveal is a question for the slot's timeline as a whole, together with EIP-7782 and EIP-8198. This EIP takes no position on it, and leaves `PAYLOAD_DUE_BPS` as EIP-7732 sets it.

**Blobs and the block-level access list.** Encrypted blob data would fail the KZG checks, which are against commitments to the plaintext, so blobs are out of scope. If the block-level access list of [EIP-7928](./eip-7928.md) travels as a plaintext sidecar from the block on, as [EIP-8146](./eip-8146.md) proposes, only the rest of the payload needs encrypting, and the two share the links from the block on. Such an access list shows the block's state accesses and post-transaction changes before the reveal, even if the block is dropped.

**Related work.** Sending a block encrypted and revealing a short key once it has spread goes back to bloXroute (Klarman, Basu, Kuzmanovic and Sirer, 2018). In Ethereum, encrypting the payload before its reveal has been proposed to take a choice away from the MEV-Boost relay (Luhn, 2022; Noyes and Policharla, 2024) and from the ePBS builder (Shutter, 2025). Buterin (2022) placed encrypted coded chunks with a committee before the proposal. LUCID (2026) spreads sealed transactions ahead of a key revealed once the beacon block is trusted, and Blob Streaming (2026) moves public blob data ahead of the critical path. This EIP applies the idea to the whole payload, under the builder's own key, so that the payload's transfer runs ahead of the reveal.

## Backwards Compatibility

This EIP adds chunking schemes and a kind of `piecesMetadata` to EIP-8411, and changes no consensus rule. A node that does not implement it ignores bids that use an encrypted scheme and does not track their payloads, as EIP-8411 specifies for unknown schemes, and it ignores the key messages of unknown kind. It can still request the envelope after the reveal. Builders have an incentive to wait until most nodes implement the encrypted schemes before they use them, since a PTC member that cannot reconstruct the envelope in time votes it absent.

## Test Cases

To be added: vectors for the encryption, the chunks and their root with the key's leaf, the key's inclusion proof, and the reconstruction checks.

## Reference Implementation

To be added.

## Security Considerations

**Confidentiality before the reveal** rests on ChaCha20 with a 256-bit key drawn for each envelope. A key used for two byte strings would let anyone combine the two ciphertexts into the combination of the two plaintexts, which is why the builder draws a fresh key for each envelope. The ciphertext's length shows the compressed envelope's length. The descriptor shows it to whole chunks, and one chunk shows it exactly: the last chunk under the encrypted plain scheme, or the first under the encrypted coded scheme, whose length prefix is not encrypted. The bid commits to the key's hash before the reveal, so confidentiality also rests on the preimage resistance of SHA-256 for a uniformly random key.

**The key is bound by the commitment.** A key that verifies against the chunk root of the bid in a validated block is the committed key, unless SHA-256 has a second preimage, or, for the builder itself, a collision. A forged key fails one Merkle branch and is rejected, and a node accepts at most one valid key from each peer per payload.

**Post-quantum security.** This EIP adds only symmetric encryption and hashing, and no signature or other public-key operation. Against a quantum adversary, Grover's search leaves about 2^128 sequential evaluations both to find the 256-bit key and to find a second preimage of SHA-256 for a forged key. A revealed payload is public within seconds of its dissemination, so storing its ciphertext to decrypt it later gains nothing. A withheld payload's ciphertext stays public, and its secrecy rests on ChaCha20 and on the builder keeping the key, for as long as its contents matter. The key is authenticated by its Merkle branch to the chunk root that the bid commits to. The root of trust is therefore the builder's signature on the bid, or the proposer's on the block for a self-build, as in EIP-7732 and EIP-8411. These are BLS signatures, which a quantum adversary could forge, but a forged bid breaks EIP-7732 whether or not this EIP is in use. When post-quantum signatures replace them, this EIP carries over unchanged, and the key's `piecesMetadata` entry stays at 385 bytes, where a signature on the key would add hundreds to thousands of bytes.

**The key names no block.** Like EIP-8411's envelope, which carries no beacon block root, a key verifies against the bid of any block that carries the same chunk root and chunk count. If a proposer equivocates with two blocks that carry the same bid, a key the builder publishes for one block is valid for the other, and anyone can forward it there. Under EIP-7732 the builder signs its envelope for one block root. This EIP inherits the case from EIP-8411 and adds one thing to it: the other block's nodes may already hold the ciphertext, so the key's 385 bytes complete the payload there. A signature binding the key message to one block would not prevent this, since the disclosed key decrypts the same ciphertext wherever it is held. Whatever EIP-8411 settles for the envelope applies to the envelope reconstructed with the key.

**A builder can commit to chunks or a key that do not decrypt to the envelope** committed by `envelope_root`. Each node may then carry the whole ciphertext and spend a decryption and a decompression before it finds out. Descriptor validation bounds the chunk count from `max_compressed_len(MAX_PAYLOAD_SIZE)`, counting parity under the encrypted coded scheme. Reconstruction checks the ciphertext's exact length against that bound, and the declared length bounds the decompression. The node treats the set as invalid without penalizing its peers, as EIP-8411 does for a mismatched envelope. The payload is then missing unless a node can obtain a valid envelope by request, and the builder pays its bid if the block gathers enough attestation weight.

**A withheld key leaves every node carrying a ciphertext it cannot use.** A builder that withholds under EIP-7732 sends nothing, so these bytes are a new cost. The descriptor's limits bound them, they travel only for the bid that a validated block includes, and the builder pays its bid as above.

**Decompression** happens only after the key has verified, and only up to `MAX_PAYLOAD_SIZE` bytes, checked against the Snappy header before decompressing.

**The builder's free option** grows by the transfer time this EIP saves, as discussed in the Rationale.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).
