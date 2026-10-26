#!/usr/bin/env python3
"""Check EIP-8437 encoding fixtures and message rules on decoded values.

Scalars are represented as Python integers. This checks encoding and blob
metadata binding, not transaction execution, proof validity or client state.

Requires Python 3.9+, pycryptodome and rlp. Run with:
    python3 assets/eip-8437/check_vectors.py
"""

import json
from hashlib import sha256
from pathlib import Path

from Crypto.Hash import keccak
from rlp import decode

SOFT_RESPONSE_LIMIT = 2097152
MAX_WRAPPER_BYTES = SOFT_RESPONSE_LIMIT
MAX_ANNOUNCEMENTS = 64
MAX_WRAPPERS_PER_REQUEST = 32
LEANSPHINCS_SCHEME = 0x10
FRAME_TX_TYPE = b"\x06"
CELLS_PER_EXT_BLOB = 128


def h(data):
    return keccak.new(digest_bits=256, data=data).digest()


def uint(value, width):
    return value.to_bytes(width, "big")


def rlp(value):
    if isinstance(value, int):
        if value < 0:
            raise ValueError("negative integer")
        return rlp(uint(value, (value.bit_length() + 7) // 8))
    if isinstance(value, list):
        payload = b"".join(rlp(item) for item in value)
        offset = 0xc0
    else:
        payload = value
        offset = 0x80
        if len(payload) == 1 and payload[0] < 0x80:
            return payload
    if len(payload) < 56:
        return bytes([offset + len(payload)]) + payload
    size = uint(len(payload), (len(payload).bit_length() + 7) // 8)
    return bytes([offset + 55 + len(size)]) + size + payload


def pattern(size):
    return (bytes(range(251)) * ((size + 250) // 251))[:size]


def describe(mode, body):
    # Each NewProofWrapperHashes entry is [mode, length, hash].
    if mode not in (0, 1):
        raise ValueError("wrapper mode")
    if not 1 <= len(body) <= MAX_WRAPPER_BYTES:
        raise ValueError("wrapper size")
    return [mode, len(body), h(body)]


def versioned_hash(commitment):
    return b"\x01" + sha256(commitment).digest()[1:]


def transaction_body(nonce, commitments=()):
    # Structurally encoded frame payload, not an executable valid transaction.
    return [1, nonce, bytes(20), [bytes(32)], [], [1, 1, int(bool(commitments))],
            [versioned_hash(c) for c in commitments]]


def transaction(nonce):
    return FRAME_TX_TYPE + rlp(transaction_body(nonce))


def blob_transaction(nonce=2):
    # Synthetic KZG encodings: these are not curve points or valid cell proofs.
    commitments = [bytes([i + 1]) * 48 for i in range(2)]
    proofs = [bytes([i % 251]) * 48 for i in range(2 * CELLS_PER_EXT_BLOB)]
    return [transaction_body(nonce, commitments), 1, [], commitments, proofs]


def transaction_hash(encoded):
    assert isinstance(encoded, bytes) and len(encoded) > 1 and encoded[:1] == FRAME_TX_TYPE, "transaction envelope"
    payload = decode(encoded[1:], strict=True)
    assert isinstance(payload, list), "transaction payload"
    if len(payload) == 5:
        body, version, blobs, commitments, proofs = payload
        assert isinstance(body, list) and len(body) == 7, "transaction payload"
        assert version == b"\x01", "blob wrapper version"
        assert blobs == [], "blob data elision"
        hashes = body[6]
        assert isinstance(hashes, list) and hashes, "blob hashes"
        assert isinstance(commitments, list) and len(commitments) == len(hashes), "commitment count"
        assert all(isinstance(c, bytes) and len(c) == 48 for c in commitments), "commitment encoding"
        assert [versioned_hash(c) for c in commitments] == hashes, "commitment hash"
        assert isinstance(proofs, list) and len(proofs) == CELLS_PER_EXT_BLOB * len(commitments), "cell proof count"
        assert all(isinstance(p, bytes) and len(p) == 48 for p in proofs), "cell proof encoding"
    else:
        body = payload
        assert len(body) == 7, "transaction payload"
        assert body[6] == [], "missing blob metadata"
    return h(FRAME_TX_TYPE + rlp(body))


def wrapper_items():
    deps = sorted(bytes(31) + bytes([LEANSPHINCS_SCHEME]) + h(b"message %d" % i) + uint(i + 1, 32)
                  for i in range(2))
    envelopes = sorted((transaction(i) for i in range(2)), key=transaction_hash)
    return {
        "mode0": [envelopes, 0, [deps, [b"witness 0", b"witness 1"]]],
        "mode1": [envelopes, 1, [deps, b"aggregate proof"]],
        "blob_mode1": [sorted(envelopes + [FRAME_TX_TYPE + rlp(blob_transaction())],
                              key=transaction_hash), 1, [deps, b"aggregate proof"]],
    }


def wrapper_vectors():
    items = wrapper_items()
    out = {
        "deps": [d.hex() for d in items["mode0"][2][0]],
        "transactions": [x.hex() for x in items["mode0"][0]],
    }
    for name, item in items.items():
        body = rlp(item)
        announcement = describe(item[1], body)
        out[name] = {
            "body": body.hex(),
            "content_hash": announcement[2].hex(),
            "announcement_rlp": rlp(announcement).hex(),
            "response_rlp": rlp(reply_for(7, [item])).hex(),
            "compact_response_rlp": rlp([7, [[announcement[2], compact_wrapper(item, {h(tx) for tx in item[0]})]]]).hex(),
            "full_request_rlp": rlp([8, 1, [announcement[2]]]).hex(),
            "encoding_hashes": [h(tx).hex() for tx in item[0]],
            "transaction_hashes": [transaction_hash(tx).hex() for tx in item[0]],
        }
    return out


def check_announcements(entries):
    assert 1 <= len(entries) <= MAX_ANNOUNCEMENTS, "announcement count"
    for entry in entries:
        assert isinstance(entry, list) and len(entry) == 3, "announcement fields"
        mode, length, digest = entry
        assert isinstance(mode, int) and mode in (0, 1), "announcement mode"
        assert isinstance(length, int) and 1 <= length <= MAX_WRAPPER_BYTES, "announcement length"
        assert isinstance(digest, bytes) and len(digest) == 32, "announcement hash"
    hashes = [entry[2] for entry in entries]
    assert hashes == sorted(set(hashes)), "announcement order"


def check_request(request_id, hashes, received_announcements, full=0):
    assert type(full) is int and full in (0, 1), "request full flag"
    assert isinstance(request_id, int) and 0 <= request_id < 2**64, "request id"
    assert 1 <= len(hashes) <= MAX_WRAPPERS_PER_REQUEST, "request count"
    assert all(isinstance(digest, bytes) and len(digest) == 32 for digest in hashes), "request hash"
    assert len(set(hashes)) == len(hashes), "request duplicates"
    assert all(digest in received_announcements for digest in hashes), "unannounced wrapper"


def check_wrapper_shape(item):
    # Envelope structure and blob metadata binding are checked; EIP-8141
    # execution, dependency-union equality and cryptographic validity are not.
    assert isinstance(item, list) and len(item) == 3, "wrapper fields"
    envelopes, mode, content = item
    assert isinstance(content, list) and len(content) == 2, "wrapper content"
    deps, proof = content
    assert isinstance(mode, int) and mode in (0, 1), "wrapper mode"
    assert isinstance(deps, list) and deps, "wrapper dependencies"
    assert all(isinstance(dep, bytes) and len(dep) == 96 for dep in deps), "dependency length"
    assert deps == sorted(set(deps)), "dependency order"
    if mode == 0:
        assert isinstance(proof, list) and len(proof) == len(deps), "direct proofs"
        assert all(isinstance(witness, bytes) for witness in proof), "direct witness"
    else:
        assert isinstance(proof, bytes) and proof, "aggregate proof"
    assert isinstance(envelopes, list) and envelopes, "wrapper envelopes"
    hashes = [transaction_hash(tx) for tx in envelopes]
    assert hashes == sorted(set(hashes)), "transaction order"


def reply_for(request_id, wrappers):
    return [request_id, [[h(rlp(item)), item] for item in wrappers]]


def compact_wrapper(item, delivered):
    # delivered tracks exact encodings sent in full on this connection.
    txs = [[h(tx)] if h(tx) in delivered and len(rlp([h(tx)])) < len(rlp(tx)) else tx
           for tx in item[0]]
    return [txs, *item[1:]]


def reconstruct(item, full, cache, length):
    assert isinstance(item, list) and len(item) == 3, "wrapper fields"
    assert isinstance(item[0], list), "wrapper envelopes"
    assert 1 <= len(rlp(item)) <= length <= MAX_WRAPPER_BYTES, "wrapper length"
    txs = []
    missing = False
    expanded_size = len(rlp(item))
    for entry in item[0]:
        if isinstance(entry, list):
            assert not full, "reference in full response"
            assert len(entry) == 1 and isinstance(entry[0], bytes) and len(entry[0]) == 32, "encoding reference"
            tx = cache.get(entry[0])
            if tx is None:
                missing = True
                continue
            assert isinstance(tx, bytes) and h(tx) == entry[0], "encoding hash"
            assert len(rlp(entry)) < len(rlp(tx)), "reference size"
            expanded_size += len(rlp(tx)) - len(rlp(entry))
            assert expanded_size <= length, "wrapper length"
        else:
            tx = entry
        txs.append(tx)
    if missing:
        return None
    result = [txs, *item[1:]]
    assert len(rlp(result)) <= length, "wrapper length"
    return result


def check_wrapper_response(request_id, requested, announced_metadata, reply, full=0, cache=None):
    assert isinstance(reply, list) and len(reply) == 2, "response fields"
    assert reply[0] == request_id, "response id"
    assert isinstance(reply[1], list), "response fields"
    positions = {digest: i for i, digest in enumerate(requested)}
    previous = -1
    retries = []
    for entry in reply[1]:
        assert isinstance(entry, list) and len(entry) == 2, "response entry"
        digest, wire_item = entry
        assert isinstance(digest, bytes) and digest in positions, "response hash"
        assert positions[digest] > previous, "response order"
        previous = positions[digest]
        mode, length = announced_metadata[digest]
        item = reconstruct(wire_item, full, cache or {}, length)
        assert wire_item[1] == mode, "announced mode"
        if item is None:
            retries.append(digest)
            continue
        body = rlp(item)
        assert h(body) == digest, "response hash"
        check_wrapper_shape(item)
        assert len(body) == length, "announced length"
    return retries


def answer_request(request_id, requested, held, announced):
    return wrappers_response(request_id, [held[digest] for digest in requested
                                         if digest in announced and digest in held])


def wrappers_response(request_id, wrappers):
    # A wrapper is embedded as its RLP item: splice its exact bytes into the list.
    served = []
    for wrapper in wrappers:
        if len(splice(request_id, served)) >= SOFT_RESPONSE_LIMIT:
            break
        served.append(wrapper)
    return splice(request_id, served)


def splice(request_id, encoded_items):
    entries = b"".join(rlp_list(rlp(h(item)) + item) for item in encoded_items)
    return rlp_list(rlp(request_id) + rlp_list(entries))


def rlp_list(payload):
    if len(payload) < 56:
        return bytes([0xc0 + len(payload)]) + payload
    size = uint(len(payload), (len(payload).bit_length() + 7) // 8)
    return bytes([0xf7 + len(size)]) + size + payload


def vector(mode, size):
    # Pattern bytes test hash and length encoding, not wrapper validity.
    announcement = describe(mode, pattern(size))
    return {
        "mode": mode,
        "size": size,
        "content_hash": announcement[2].hex(),
        "announcement_rlp": rlp(announcement).hex(),
    }


def expect_error(reason, fn, *args):
    try:
        fn(*args)
    except (ValueError, AssertionError) as error:
        assert str(error) == reason, (reason, str(error))
        return
    raise AssertionError("accepted invalid input: " + reason)


def main():
    assert h(b"").hex() == "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    assert rlp(0) == b"\x80" and rlp([]) == b"\xc0"
    assert rlp(b"dog").hex() == "83646f67"
    assert rlp([0, 1, bytes(32)]).hex() == "e38001a0" + "00" * 32
    assert rlp([1, 1, bytes(32)]).hex() == "e30101a0" + "00" * 32
    vectors = json.loads(Path(__file__).with_name("announcement-vectors.json").read_text())
    for expected in vectors:
        assert vector(expected["mode"], expected["size"]) == expected, expected["size"]
    wrappers = json.loads(Path(__file__).with_name("wrapper-vectors.json").read_text())
    assert wrapper_vectors() == wrappers

    # A maximum-length announcement entry encodes in 39 bytes in either mode.
    assert MAX_WRAPPER_BYTES == SOFT_RESPONSE_LIMIT
    for mode in (0, 1):
        assert len(rlp([mode, MAX_WRAPPER_BYTES, bytes(32)])) == 39

    # Announcement count, fields and strict hash ordering.
    announced = [[i % 2, MAX_WRAPPER_BYTES, uint(i + 1, 32)] for i in range(65)]
    check_announcements([[0, 1, bytes(32)]])
    check_announcements(announced[:64])
    expect_error("announcement count", check_announcements, [])
    expect_error("announcement count", check_announcements, announced)
    expect_error("announcement order", check_announcements, announced[:2][::-1])
    expect_error("announcement order", check_announcements, announced[:1] * 2)
    for length in (0, MAX_WRAPPER_BYTES + 1):
        expect_error("announcement length", check_announcements, [[0, length, bytes(32)]])
    for mode in (-1, 2, 256, b"\x01"):
        expect_error("announcement mode", check_announcements, [[mode, 1, bytes(32)]])
    expect_error("announcement hash", check_announcements, [[0, 1, bytes(31)]])
    expect_error("announcement fields", check_announcements, [[0, 1, bytes(32), b""]])
    expect_error("announcement fields", check_announcements, [[1, bytes(32)]])

    # Request bounds, uniqueness and received announcements; IDs need not increase.
    assert rlp([7, 0, [bytes(32)]]).hex() == "e40780e1a0" + "00" * 32
    for full in (0, 1):
        check_request(7, [bytes(32)], {bytes(32)}, full)
    for full in (-1, 2, b"", True):
        expect_error("request full flag", check_request, 7, [bytes(32)], {bytes(32)}, full)
    max_id = 2**64 - 1
    hashes = [entry[2] for entry in announced]
    check_request(max_id, hashes[:32], set(hashes))
    check_request(0, hashes[:2][::-1], set(hashes))  # Requests need not be sorted.
    for request_id in (-1, 2**64):
        expect_error("request id", check_request, request_id, hashes[:1], set(hashes))
    expect_error("request count", check_request, 7, [], set(hashes))
    expect_error("request count", check_request, 7, hashes[:33], set(hashes))
    expect_error("request duplicates", check_request, 7, hashes[:1] * 2, set(hashes))
    expect_error("request hash", check_request, 7, [bytes(31)], set(hashes))
    expect_error("unannounced wrapper", check_request, 7, [bytes(32)], set(hashes))
    assert len(rlp(announced[:64])) == 2499
    assert len(rlp([max_id, 1, hashes[:32]])) == 1072

    # Complete envelopes are part of the canonical wrapper and its identity.
    mode0, mode1, blob_mode1 = wrapper_items().values()
    for item in (mode0, mode1, blob_mode1):
        check_wrapper_shape(item)
        decoded = decode(rlp(item), strict=True)
        assert len(decoded) == 3 and decoded[0] == item[0]
        assert decoded[1] == (b"\x01" if item[1] else b"")
        assert decoded[2] == item[2]
    expect_error("wrapper fields", check_wrapper_shape, mode1[:2])
    expect_error("wrapper content", check_wrapper_shape, [mode1[0], 1, mode1[2][:1]])
    expect_error("wrapper fields", check_wrapper_shape, [1, mode1[2][0], mode1[2][1], mode1[0]])
    expect_error("wrapper envelopes", check_wrapper_shape, [[], *mode1[1:]])
    expect_error("transaction envelope", check_wrapper_shape, [[bytes(32)], *mode1[1:]])
    expect_error("transaction envelope", check_wrapper_shape, [[[1, 2]], *mode1[1:]])
    expect_error("transaction order", check_wrapper_shape, [mode1[0][::-1], *mode1[1:]])
    expect_error("transaction order", check_wrapper_shape, [[mode1[0][0]] * 2, *mode1[1:]])
    expect_error("wrapper dependencies", check_wrapper_shape, [mode1[0], 1, [[], mode1[2][1]]])

    # Decoded response items, correlation, hashes, lengths and ordering.
    items = [mode0, mode1, blob_mode1]
    encoded = [rlp(item) for item in items]
    requested = [h(body) for body in encoded]
    metadata = {h(body): (item[1], len(body)) for item, body in zip(items, encoded)}
    check_request(7, requested, set(requested))
    expect_error("unannounced wrapper", check_request, 7, requested, {requested[0]})
    held = dict(zip(requested, encoded))
    assert answer_request(7, requested, held, set(requested)) == rlp(reply_for(7, items))
    assert answer_request(7, requested, held, {requested[1]}) == rlp(reply_for(7, items[1:2]))
    assert answer_request(7, [bytes(32)], held, set(requested)) == rlp([7, []])
    assert answer_request(7, requested, {}, set(requested)) == rlp([7, []])
    for returned in (items, items[:1], items[1:], []):
        check_wrapper_response(7, requested, metadata, reply_for(7, returned))
    expect_error("response id", check_wrapper_response, 7, requested, metadata, reply_for(8, items))
    expect_error("response fields", check_wrapper_response, 7, requested, metadata, [7, items, b""])
    expect_error("response entry", check_wrapper_response, 7, requested, metadata, [7, encoded])
    expect_error("response order", check_wrapper_response, 7, requested, metadata, reply_for(7, items[::-1]))
    expect_error("response order", check_wrapper_response, 7, requested, metadata, reply_for(7, [mode0, mode0]))
    for altered in ([mode1[0], 1, [mode1[2][0], b"aggregate proog"]],
                    [[transaction(99)], *mode1[1:]],
                    [mode1[0][:1], *mode1[1:]]):
        expect_error("response hash", check_wrapper_response, 7, requested, metadata, reply_for(7, [altered]))
    wrong_length = {**metadata, requested[0]: (0, len(encoded[0]) + 1)}
    expect_error("announced length", check_wrapper_response, 7, requested, wrong_length, reply_for(7, [mode0]))
    for i, item in enumerate(items):
        wrong_mode = {**metadata, requested[i]: (1 - item[1], len(encoded[i]))}
        expect_error("announced mode", check_wrapper_response, 7, requested, wrong_mode, reply_for(7, [item]))
    assert wrappers_response(7, encoded) == rlp(reply_for(7, items))

    # A full 32-hash request can be satisfied in one response for small wrappers.
    small_items = [[[transaction(i)], 0, mode0[2]] for i in range(32)]
    small = [rlp(item) for item in small_items]
    small_hashes = [h(body) for body in small]
    small_metadata = {h(body): (0, len(body)) for body in small}
    check_request(7, small_hashes, set(small_hashes))
    assert len(splice(7, small)) < SOFT_RESPONSE_LIMIT
    assert wrappers_response(7, small) == splice(7, small)
    check_wrapper_response(7, small_hashes, small_metadata, reply_for(7, small_items))

    # Byte-derived transaction count: no independent 4,096-envelope ceiling.
    many_envelopes = sorted((transaction(i) for i in range(4097)), key=transaction_hash)
    many = [many_envelopes, 1, mode1[2]]
    many_body = rlp(many)
    check_wrapper_response(7, [h(many_body)], {h(many_body): (1, len(many_body))}, reply_for(7, [many]))

    # Five fixtures with 1,000,000-byte synthetic proofs; none is a valid proof.
    large_items = [[mode1[0], 1, [mode1[2][0], bytes([i]) * 1_000_000]] for i in range(5)]
    large = [rlp(item) for item in large_items]
    assert all(len(body) <= MAX_WRAPPER_BYTES for body in large)
    assert len(splice(7, large[:2])) <= SOFT_RESPONSE_LIMIT < len(splice(7, large[:3]))
    assert wrappers_response(7, large) == splice(7, large[:3])
    assert len(wrappers_response(max_id, large)) < SOFT_RESPONSE_LIMIT + MAX_WRAPPER_BYTES
    large_hashes = [h(body) for body in large]
    large_metadata = {h(body): (1, len(body)) for body in large}
    check_wrapper_response(7, large_hashes, large_metadata, reply_for(7, large_items[:2]))
    check_wrapper_response(7, large_hashes, large_metadata, reply_for(7, large_items[:3]))
    # The soft limit is not a receiver-side 4 MiB limit.
    assert len(splice(7, large)) > SOFT_RESPONSE_LIMIT + MAX_WRAPPER_BYTES
    check_wrapper_response(7, large_hashes, large_metadata, reply_for(7, large_items))

    # Fill the wrapper to exactly 2 MiB with proof and synthetic envelope bytes.
    # Use a 1.5 MiB proof fixture; only the complete wrapper has a byte ceiling.
    proof = bytes(1_572_864)
    payload_size = MAX_WRAPPER_BYTES - len(proof) - 1024
    for _ in range(5):
        tx_body = transaction_body(0)
        tx_body[3] = [bytes(payload_size)]
        at_limit = [[FRAME_TX_TYPE + rlp(tx_body)], 1, [mode1[2][0], proof]]
        body = rlp(at_limit)
        if len(body) == MAX_WRAPPER_BYTES:
            break
        payload_size += MAX_WRAPPER_BYTES - len(body)
    assert len(body) == MAX_WRAPPER_BYTES
    check_wrapper_response(7, [h(body)], {h(body): (1, len(body))}, reply_for(7, [at_limit]))
    assert wrappers_response(max_id, [body, encoded[0]]) == splice(max_id, [body])
    assert len(splice(max_id, [body])) > SOFT_RESPONSE_LIMIT  # Response framing only.
    tx_body[3] = [bytes(payload_size + 1)]
    oversized = [[FRAME_TX_TYPE + rlp(tx_body)], 1, [mode1[2][0], proof]]
    assert len(rlp(oversized)) == MAX_WRAPPER_BYTES + 1
    expect_error("wrapper length", check_wrapper_response, 7, [h(rlp(oversized))],
                 {h(rlp(oversized)): (1, len(rlp(oversized)))}, reply_for(7, [oversized]))

    # Blob metadata is inside wrapper identity; cells are retrieved separately.
    blob = blob_transaction()
    blob_encoded = FRAME_TX_TYPE + rlp(blob)
    tx_hash = transaction_hash(blob_encoded)
    assert tx_hash == h(FRAME_TX_TYPE + rlp(blob[0])) != h(blob_encoded)
    altered_proofs = [bytes([42]) * 48] + blob[4][1:]
    altered_blob = FRAME_TX_TYPE + rlp(blob[:4] + [altered_proofs])
    assert transaction_hash(altered_blob) == tx_hash
    assert h(rlp([[blob_encoded], *mode1[1:]])) != h(rlp([[altered_blob], *mode1[1:]]))
    expect_error("transaction order", check_wrapper_shape, [[blob_encoded, altered_blob], *mode1[1:]])
    for nonce in range(2, 100):
        blob_items = sorted(mode1[0] + [FRAME_TX_TYPE + rlp(blob_transaction(nonce))], key=transaction_hash)
        raw_hash_order = sorted(blob_items, key=h)
        if raw_hash_order != blob_items:
            break
    assert raw_hash_order != blob_items
    expect_error("transaction order", check_wrapper_shape, [raw_hash_order, *mode1[1:]])
    for value in (b"", [bytes(131072)]):
        expect_error("blob data elision", transaction_hash, FRAME_TX_TYPE + rlp(blob[:2] + [value] + blob[3:]))
    expect_error("missing blob metadata", transaction_hash, FRAME_TX_TYPE + rlp(blob[0]))
    expect_error("blob wrapper version", transaction_hash, FRAME_TX_TYPE + rlp([blob[0], 0] + blob[2:]))
    expect_error("commitment count", transaction_hash, FRAME_TX_TYPE + rlp(blob[:3] + [blob[3][:1], blob[4]]))
    expect_error("commitment encoding", transaction_hash, FRAME_TX_TYPE + rlp(blob[:3] + [[bytes(47)] * 2, blob[4]]))
    expect_error("commitment hash", transaction_hash, FRAME_TX_TYPE + rlp(blob[:3] + [blob[3][::-1], blob[4]]))
    for proofs in (blob[4][:-1], blob[4] + [bytes(48)]):
        expect_error("cell proof count", transaction_hash, FRAME_TX_TYPE + rlp(blob[:4] + [proofs]))
    expect_error("cell proof encoding", transaction_hash, FRAME_TX_TYPE + rlp(blob[:4] + [[bytes(47)] * len(blob[4])]))

    # Compact transport preserves full identity, including blob metadata.
    for item in (mode0, mode1, blob_mode1):
        cache = {h(tx): tx for tx in item[0]}
        digest = h(rlp(item))
        meta = {digest: (item[1], len(rlp(item)))}
        compact = compact_wrapper(item, set(cache))
        assert len(rlp(compact)) < len(rlp(item))
        reply = [7, [[digest, compact]]]
        assert reconstruct(compact, 0, cache, meta[digest][1]) == item
        assert check_wrapper_response(7, [digest], meta, reply, cache=cache) == []
        assert check_wrapper_response(7, [digest], meta, reply) == [digest]
        # Eviction leads to a fresh full request, not a transaction fetch.
        check_request(8, [digest], {digest}, full=1)
        assert check_wrapper_response(8, [digest], meta, reply_for(8, [item]), full=1) == []
        expect_error("reference in full response", check_wrapper_response, 7, [digest], meta, reply, 1, cache)
        assert compact_wrapper(item, set()) == item
        mixed = compact_wrapper(item, {h(item[0][0])})
        assert isinstance(mixed[0][0], list) and isinstance(mixed[0][1], bytes)
        assert check_wrapper_response(7, [digest], meta, [7, [[digest, mixed]]], cache=cache) == []
        partial_cache = dict(cache)
        del partial_cache[h(item[0][0])]
        assert check_wrapper_response(7, [digest], meta, reply, cache=partial_cache) == [digest]
        wrong_cache = {**cache, h(item[0][0]): transaction(999)}
        expect_error("encoding hash", check_wrapper_response, 7, [digest], meta, reply, 0, wrong_cache)
        malformed = [[[bytes(31)], *compact[0][1:]], *compact[1:]]
        expect_error("encoding reference", check_wrapper_response, 7, [digest], meta,
                     [7, [[digest, malformed]]], 0, cache)
        false_digest = h(b"false canonical wrapper")
        expect_error("response hash", check_wrapper_response, 7, [false_digest],
                     {false_digest: meta[digest]}, [7, [[false_digest, compact]]], 0, cache)
    # Same consensus transaction hash does not identify the exact blob encoding.
    assert h(blob_encoded) != h(altered_blob)
    assert compact_wrapper([[blob_encoded], *mode1[1:]], {h(altered_blob)})[0] == [blob_encoded]
    # The compact byte count cannot bypass the canonical 2 MiB bound.
    compact_oversized = compact_wrapper(oversized, {h(tx) for tx in oversized[0]})
    assert len(rlp(compact_oversized)) < MAX_WRAPPER_BYTES
    expect_error("wrapper length", reconstruct, compact_oversized, 0,
                 {h(tx): tx for tx in oversized[0]}, MAX_WRAPPER_BYTES)

    print("PASS: announcement, full-envelope and sparse-blob wrapper encoding vectors; "
          "compact reconstruction and full retries, message counts, ordering, metadata matching, byte limits and response packing. "
          "Transaction/proof validity, KZG verification and client-state sequences are not tested.")


if __name__ == "__main__":
    main()
