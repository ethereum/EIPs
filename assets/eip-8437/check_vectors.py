#!/usr/bin/env python3
"""Check EIP-8437 eth/75 encoding fixtures and message rules.

Synthetic envelopes and witnesses do not test execution, cryptographic validity,
KZG verification or client state. Requires Python 3.9+, pycryptodome and rlp.
Run: python3 assets/eip-8437/check_vectors.py
"""

import json
from hashlib import sha256
from pathlib import Path

from Crypto.Hash import keccak
from rlp import decode

SOFT_RESPONSE_LIMIT = 2097152
MAX_WRAPPER_BYTES = SOFT_RESPONSE_LIMIT
MAX_ANNOUNCEMENT_BYTES = 2**21
MAX_ANNOUNCEMENTS = 64
MAX_WRAPPERS_PER_REQUEST = 32
LEANSPHINCS_SCHEME = 0x10
FRAME_TX_TYPE = b"\x06"
CELLS_PER_EXT_BLOB = 128
# Fixed transport threshold, independent of EIP-8288 validity limits.
MAX_INLINE_TRANSACTIONS = 17
METADATA_FIELDS = 5
SYNTHETIC_FRAME_GAS = 100000
FIXTURE_FEE_FIELDS = 3


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



def frame_payload(encoded):
    # The EIP-8141 payload, unwrapped from the blob network form if present.
    transaction_hash(encoded)
    payload = decode(encoded[1:], strict=True)
    return payload[0] if len(payload) == 5 else payload



def frame_gas(payload):
    # The sum of the frames' execution and state limits. Synthetic frames carry
    # no limits, so fixtures use a fixed stand-in.
    return SYNTHETIC_FRAME_GAS



def transaction_metadata(envelopes):
    # All wrappers carry EIP-8141 frame transactions; no type or nonce hint.
    payloads = [frame_payload(tx) for tx in envelopes]
    return [[len(tx) for tx in envelopes],
            [transaction_hash(tx) for tx in envelopes],
            [payload[2] for payload in payloads],
            [[int.from_bytes(fee, "big") for fee in payload[5]] for payload in payloads],
            [frame_gas(payload) for payload in payloads]]


def inline_metadata(item):
    # Shared dependencies allow larger mode 0 wrappers, announced without metadata.
    if item[1] == 0 and len(item[0]) <= MAX_INLINE_TRANSACTIONS:
        return transaction_metadata(item[0])
    return []



def check_claims(serving_peer, item, claims, expected):
    # Metadata is kept per peer: the wrapper is checked against its serving
    # peer's claim, and other peers' claims found false count against them.
    assert claims[serving_peer] == expected(item), "announced transaction metadata"
    return sorted(peer for peer, claim in claims.items() if claim != expected(item))



def mismatched_held_transactions(meta, held):
    # Source, fees and gas are hash-bound; the pooled encoding's size is not.
    mismatches = []
    for i, digest in enumerate(meta[1]):
        if digest not in held:
            continue
        envelope = held[digest]
        assert transaction_hash(envelope) == digest, "held transaction hash"
        expected = transaction_metadata([envelope])
        if any(meta[field][i] != expected[field][0] for field in (2, 3, 4)):
            mismatches.append(digest)
    return mismatches


def reply_for(request_id, wrappers):
    return [request_id, [[h(rlp(item)), item] for item in wrappers]]



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



def expect_error(reason, fn, *args):
    try:
        fn(*args)
    except (ValueError, AssertionError) as error:
        assert str(error) == reason, (reason, str(error))
        return
    raise AssertionError("accepted invalid input: " + reason)



def check_metadata(meta, length, limit=MAX_INLINE_TRANSACTIONS):
    assert isinstance(meta, list) and len(meta) == METADATA_FIELDS, "metadata fields"
    sizes, hashes, sources, fees, gas = meta
    assert isinstance(hashes, list) and 1 <= len(hashes) and (limit is None or len(hashes) <= limit), "metadata count"
    assert all(isinstance(field, list) and len(field) == len(hashes) for field in meta), "metadata lengths"
    assert all(isinstance(size, int) and size >= 1 for size in sizes) and sum(sizes) < length, "metadata size"
    assert all(isinstance(digest, bytes) and len(digest) == 32 for digest in hashes), "metadata hash"
    assert hashes == sorted(set(hashes)), "metadata order"
    assert all(isinstance(source, bytes) and len(source) == 20 for source in sources), "metadata source"
    assert all(isinstance(fee, list)
               and all(isinstance(value, int) and 0 <= value < 2**256 for value in fee) for fee in fees), "metadata fees"
    assert all(isinstance(value, int) and 0 <= value < 2**64 for value in gas), "metadata gas"


def describe(mode, body, txs_meta=()):
    assert mode == 0, "wrapper mode"
    assert 1 <= len(body) <= MAX_WRAPPER_BYTES, "wrapper size"
    return [mode, len(body), h(body), list(txs_meta)]


def wrapper_items():
    deps = sorted(bytes(31) + bytes([LEANSPHINCS_SCHEME]) + h(b"message %d" % i) + uint(i + 1, 32)
                  for i in range(2))
    envelopes = sorted((transaction(i) for i in range(2)), key=transaction_hash)
    return {
        "mode0": [envelopes, 0, [deps, [b"witness 0", b"witness 1"]]],
        "blob_mode0": [sorted(envelopes + [FRAME_TX_TYPE + rlp(blob_transaction())],
                              key=transaction_hash), 0, [deps, [b"witness 0", b"witness 1"]]],
    }


def metadata_for(item):
    return (item[1], len(rlp(item)), inline_metadata(item))


def check_announcement_size(payload):
    assert len(payload) <= MAX_ANNOUNCEMENT_BYTES, "announcement bytes"


def check_announcements(entries):
    assert 1 <= len(entries) <= MAX_ANNOUNCEMENTS, "announcement count"
    for entry in entries:
        assert isinstance(entry, list) and len(entry) == 4, "announcement fields"
        mode, length, digest, meta = entry
        assert isinstance(mode, int) and mode >= 0, "announcement mode"
        assert isinstance(length, int) and 1 <= length <= MAX_WRAPPER_BYTES, "announcement length"
        assert isinstance(digest, bytes) and len(digest) == 32, "announcement hash"
        assert isinstance(meta, list), "announcement metadata"
        if mode == 0 and meta:
            check_metadata(meta, length)
    hashes = [entry[2] for entry in entries]
    assert hashes == sorted(set(hashes)), "announcement order"
    check_announcement_size(rlp(entries))
    return [entry for entry in entries if entry[0] == 0]


def check_request_message(message, received_announcements):
    assert isinstance(message, list) and len(message) == 2, "request fields"
    request_id, hashes = message
    assert isinstance(request_id, int) and 0 <= request_id < 2**64, "request id"
    assert isinstance(hashes, list) and 1 <= len(hashes) <= MAX_WRAPPERS_PER_REQUEST, "request count"
    assert all(isinstance(digest, bytes) and len(digest) == 32 for digest in hashes), "request hash"
    assert len(set(hashes)) == len(hashes), "request duplicates"
    assert all(digest in received_announcements for digest in hashes), "unannounced wrapper"


def check_wrapper_shape(item):
    # Dependency-union equality and execution/cryptographic validity are not checked.
    assert isinstance(item, list) and len(item) == 3, "wrapper fields"
    envelopes, mode, content = item
    assert mode == 0, "wrapper mode"
    assert isinstance(content, list) and len(content) == 2, "wrapper content"
    deps, proofs = content
    assert isinstance(deps, list) and deps, "wrapper dependencies"
    assert all(isinstance(dep, bytes) and len(dep) == 96 for dep in deps), "dependency length"
    assert deps == sorted(set(deps)), "dependency order"
    assert isinstance(proofs, list) and len(proofs) == len(deps), "direct proofs"
    assert all(isinstance(witness, bytes) for witness in proofs), "direct witness"
    assert isinstance(envelopes, list) and envelopes, "wrapper envelopes"
    hashes = [transaction_hash(tx) for tx in envelopes]
    assert hashes == sorted(set(hashes)), "transaction order"


def check_wrapper_response(request_id, requested, announced_metadata, reply, verify=None):
    assert isinstance(reply, list) and len(reply) == 2, "response fields"
    assert reply[0] == request_id, "response id"
    assert isinstance(reply[1], list), "response fields"
    positions = {digest: i for i, digest in enumerate(requested)}
    previous = -1
    for entry in reply[1]:
        assert isinstance(entry, list) and len(entry) == 2, "response entry"
        digest, item = entry
        assert isinstance(digest, bytes) and digest in positions, "response hash"
        assert positions[digest] > previous, "response order"
        previous = positions[digest]
        mode, length, meta = announced_metadata[digest]
        body = rlp(item)
        assert 1 <= len(body) <= MAX_WRAPPER_BYTES, "wrapper length"
        assert h(body) == digest, "response hash"
        check_wrapper_shape(item)
        assert item[1] == mode, "announced mode"
        assert len(body) == length, "announced length"
        assert meta == inline_metadata(item), "announced transaction metadata"
        # Unsupported schemes are discarded after transport checks, without
        # treating them as malformed or spending work on witness verification.
        if any(dep[:32] != uint(LEANSPHINCS_SCHEME, 32) for dep in item[2][0]):
            continue
        if verify is not None:
            assert verify(item), "proof verification"


def vector(mode, size):
    announcement = describe(mode, pattern(size))
    return {"mode": mode, "size": size, "content_hash": announcement[2].hex(),
            "announcement_rlp": rlp(announcement).hex()}


def wrapper_vectors():
    items = wrapper_items()
    out = {"deps": [dep.hex() for dep in items["mode0"][2][0]],
           "transactions": [tx.hex() for tx in items["mode0"][0]]}
    for name, item in items.items():
        body = rlp(item)
        digest = h(body)
        out[name] = {"body": body.hex(), "content_hash": digest.hex(),
                     "transaction_metadata_rlp": rlp(transaction_metadata(item[0])).hex(),
                     "announcement_rlp": rlp(describe(0, body, inline_metadata(item))).hex(),
                     "response_rlp": rlp(reply_for(7, [item])).hex(),
                     "request_rlp": rlp([8, [digest]]).hex(),
                     "transaction_hashes": [transaction_hash(tx).hex() for tx in item[0]]}
    return out


def main():
    assert h(b"").hex() == "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    assert rlp(0) == b"\x80" and rlp([]) == b"\xc0"
    assert rlp(b"dog").hex() == "83646f67"
    for expected in json.loads(Path(__file__).with_name("announcement-vectors.json").read_text()):
        assert vector(expected["mode"], expected["size"]) == expected
    assert wrapper_vectors() == json.loads(Path(__file__).with_name("wrapper-vectors.json").read_text())
    entries = [[0, MAX_WRAPPER_BYTES, uint(i + 1, 32), []] for i in range(65)]
    hashes = [entry[2] for entry in entries]
    assert len(rlp(entries[:64])) == 2563
    assert len(rlp([2**64 - 1, hashes[:32]])) == 1071
    check_announcements(entries[:64])
    for bad, reason in [([], "announcement count"), (entries, "announcement count"),
                        (entries[:2][::-1], "announcement order"), (entries[:1] * 2, "announcement order"),
                        ([[0, 1, bytes(31), []]], "announcement hash"),
                        ([[0, 1, bytes(32), b""]], "announcement metadata"),
                        ([[0, 1, bytes(32), bytes(32), bytes(32), []]], "announcement fields")]:
        expect_error(reason, check_announcements, bad)
    for mode in (1, 2, 256):
        unknown = [mode, 1, bytes(32), []]
        assert check_announcements([unknown, entries[0]]) == [entries[0]]
        expect_error("announcement order", check_announcements, [entries[0], unknown])
        expect_error("announcement length", check_announcements, [[mode, MAX_WRAPPER_BYTES + 1, bytes(32), []]])
    for length in (0, MAX_WRAPPER_BYTES + 1):
        expect_error("announcement length", check_announcements, [[0, length, bytes(32), []]])
    for request, reason in [([7, 0, hashes[:1]], "request fields"), ([7, []], "request count"),
                            ([7, hashes[:33]], "request count"), ([7, hashes[:1] * 2], "request duplicates"),
                            ([7, [bytes(31)]], "request hash"), ([7, [bytes(32)]], "unannounced wrapper"),
                            ([-1, hashes[:1]], "request id"), ([2**64, hashes[:1]], "request id")]:
        expect_error(reason, check_request_message, request, set(hashes))
    check_request_message([0, hashes[:2][::-1]], set(hashes))
    check_request_message([2**64 - 1, hashes[:32]], set(hashes))
    mode0, blob0 = wrapper_items().values()
    for count in (17, 18):
        item = [sorted((transaction(i) for i in range(count)), key=transaction_hash), 0, mode0[2]]
        body = rlp(item)
        meta = inline_metadata(item)
        assert bool(meta) == (count <= 17)
        check_announcements([describe(0, body, meta)])
        check_wrapper_response(7, [h(body)], {h(body): metadata_for(item)}, reply_for(7, [item]))
        wrong_meta = [] if meta else transaction_metadata(item[0])
        expect_error("announced transaction metadata", check_wrapper_response, 7, [h(body)],
                     {h(body): (0, len(body), wrong_meta)}, reply_for(7, [item]))
    widest_hashes = sorted(h(uint(i, 1)) for i in range(17))
    widest = [[(MAX_WRAPPER_BYTES - 1) // 17] * 17, widest_hashes,
              [b"\xff" * 20] * 17, [[2**256 - 1] * 3] * 17, [2**64 - 1] * 17]
    widest_entries = [[0, MAX_WRAPPER_BYTES, uint(i + 1, 32), widest] for i in range(64)]
    check_announcements(widest_entries)
    assert len(rlp(widest_entries)) == 186436
    # Fee-list length is variable, but the entire announcement is byte-bounded.
    # Synthetic metadata checks transport only, not the transaction's fee layout.
    large_meta = transaction_metadata([transaction(0)])
    large_meta[3] = [[2**256 - 1] * 60000]
    large_entry = [0, MAX_WRAPPER_BYTES, bytes(32), large_meta]
    remaining = MAX_ANNOUNCEMENT_BYTES - len(rlp([large_entry]))
    large_meta[3][0].extend([2**256 - 1] * (remaining // 33))
    large_meta[3][0].extend([1] * (remaining % 33))
    assert len(rlp([large_entry])) == MAX_ANNOUNCEMENT_BYTES
    check_announcements([large_entry])
    large_meta[3][0].append(1)
    assert len(rlp([large_entry])) == MAX_ANNOUNCEMENT_BYTES + 1
    expect_error("announcement bytes", check_announcement_size, rlp([large_entry]))
    expect_error("announcement bytes", check_announcements, [large_entry])
    large_entry[0] = 2  # Unsupported modes do not bypass the message byte bound.
    expect_error("announcement bytes", check_announcements, [large_entry])
    items = [mode0, blob0]
    bodies = [rlp(item) for item in items]
    requested = [h(body) for body in bodies]
    announced = {h(rlp(item)): metadata_for(item) for item in items}
    for returned in (items, items[:1], items[1:], []):
        check_wrapper_response(7, requested, announced, reply_for(7, returned))
    for returned in (items[::-1], [mode0, mode0]):
        expect_error("response order", check_wrapper_response, 7, requested, announced, reply_for(7, returned))
    expect_error("response id", check_wrapper_response, 7, requested, announced, reply_for(8, items))
    assert answer_request(7, requested, dict(zip(requested, bodies)), {requested[0]}) == rlp(reply_for(7, items[:1]))
    assert answer_request(7, [bytes(32)], dict(zip(requested, bodies)), set(requested)) == rlp([7, []])
    for altered in ([[transaction(99)], 0, mode0[2]],
                    [mode0[0], 0, [mode0[2][0], [b"different", b"witness"]]]):
        expect_error("response hash", check_wrapper_response, 7, requested, announced, reply_for(7, [altered]))
    for wrong, reason in [((0, len(bodies[0]) + 1, inline_metadata(mode0)), "announced length"),
                          ((1, len(bodies[0]), inline_metadata(mode0)), "announced mode")]:
        expect_error(reason, check_wrapper_response, 7, requested,
                     {**announced, requested[0]: wrong}, reply_for(7, [mode0]))
    meta0 = inline_metadata(mode0)
    verification_calls = []
    def invalid_proof(item):
        verification_calls.append(item)
        return False
    for field, value, reason in [(1, [], "metadata count"), (0, [0, 1], "metadata size"),
                                  (1, meta0[1][::-1], "metadata order"), (2, [bytes(19)] * 2, "metadata source"),
                                  (3, [[2**256]] * 2, "metadata fees"), (4, [2**64] * 2, "metadata gas")]:
        bad = list(meta0); bad[field] = value
        expect_error(reason, check_announcements, [describe(0, bodies[0], bad)])
    for field, value in [(0, [n + 1 for n in meta0[0]]),
                         (1, sorted([h(b"other 0"), h(b"other 1")])), (2, [b"\x01" * 20] * 2),
                         (3, [[2, 1, 0]] * 2), (4, [1, 1])]:
        bad = list(meta0); bad[field] = value
        check_announcements([describe(0, bodies[0], bad)])
        expect_error("announced transaction metadata", check_wrapper_response, 7, requested,
                     {**announced, requested[0]: (0, len(bodies[0]), bad)}, reply_for(7, [mode0]), invalid_proof)
    assert not verification_calls
    expect_error("proof verification", check_wrapper_response, 7, requested, announced, reply_for(7, [mode0]), invalid_proof)
    # Generic, mixed and unknown-scheme wrappers remain structurally decodable,
    # but eth/75 never invokes their witness verifier, even if it would accept.
    unsupported_verifications = []
    def accepting_verifier(item):
        unsupported_verifications.append(item)
        return True
    for scheme in (0x11, 0xfe):
        for mixed in (False, True):
            deps = [uint(scheme if i or not mixed else LEANSPHINCS_SCHEME, 32) + dep[32:]
                    for i, dep in enumerate(mode0[2][0])]
            unsupported = [mode0[0], 0, [deps, mode0[2][1]]]
            digest = h(rlp(unsupported))
            metadata = metadata_for(unsupported)
            check_wrapper_shape(unsupported)
            check_wrapper_response(7, [digest], {digest: metadata},
                                   reply_for(7, [unsupported]), accepting_verifier)
            expect_error("announced length", check_wrapper_response, 7, [digest],
                         {digest: (metadata[0], metadata[1] + 1, metadata[2])},
                         reply_for(7, [unsupported]), accepting_verifier)
    assert not unsupported_verifications
    for fees in ([], [7, 3], [7, 3, 0], [7, 3, 0, 0]):
        payload = transaction_body(2**64 - 1); payload[5] = fees
        item = [[FRAME_TX_TYPE + rlp(payload)], 0, mode0[2]]
        body = rlp(item)
        check_announcements([describe(0, body, inline_metadata(item))])
        check_wrapper_response(7, [h(body)], {h(body): metadata_for(item)}, reply_for(7, [item]))
    held = {transaction_hash(tx): tx for tx in mode0[0]}
    false_meta = meta0[:4] + [[n + 1 for n in meta0[4]]]
    assert check_claims("B", mode0, {"A": false_meta, "B": meta0}, inline_metadata) == ["A"]
    assert mismatched_held_transactions(false_meta, held) == meta0[1]
    assert mismatched_held_transactions([[n + 1 for n in meta0[0]]] + meta0[1:], held) == []
    for bad, reason in [([[], 0, mode0[2]], "wrapper envelopes"),
                        ([[[h(mode0[0][0])]], 0, mode0[2]], "transaction envelope"),
                        ([mode0[0][::-1], 0, mode0[2]], "transaction order"),
                        ([mode0[0][:1] * 2, 0, mode0[2]], "transaction order"),
                        ([mode0[0], 1, [mode0[2][0], b"proof"]], "wrapper mode"),
                        ([mode0[0], 0, [mode0[2][0], []]], "direct proofs")]:
        expect_error(reason, check_wrapper_shape, bad)
    # Shared dependencies do not create a transport transaction-count ceiling.
    many = [sorted((transaction(i) for i in range(4097)), key=transaction_hash), 0, mode0[2]]
    check_wrapper_response(7, [h(rlp(many))], {h(rlp(many)): metadata_for(many)}, reply_for(7, [many]))
    large = [[mode0[0], 0, [mode0[2][0], [bytes([i]) * 1_000_000, b"witness"]]] for i in range(5)]
    large_bodies = [rlp(item) for item in large]
    assert wrappers_response(7, large_bodies) == splice(7, large_bodies[:3])
    check_wrapper_response(7, [h(body) for body in large_bodies],
                           {h(rlp(item)): metadata_for(item) for item in large}, reply_for(7, large))
    # Both the canonical wrapper and response framing contribute to bytes.
    proof = bytes(1_572_864); payload_size = 500_000
    for _ in range(5):
        tx = transaction_body(0); tx[3] = [bytes(payload_size)]
        boundary = [[FRAME_TX_TYPE + rlp(tx)], 0, [mode0[2][0], [proof, b"witness"]]]
        body = rlp(boundary)
        if len(body) == MAX_WRAPPER_BYTES:
            break
        payload_size += MAX_WRAPPER_BYTES - len(body)
    assert len(body) == MAX_WRAPPER_BYTES
    check_wrapper_response(7, [h(body)], {h(body): metadata_for(boundary)}, reply_for(7, [boundary]))
    assert len(wrappers_response(7, [body])) > SOFT_RESPONSE_LIMIT
    tx[3] = [bytes(payload_size + 1)]
    oversized = [[FRAME_TX_TYPE + rlp(tx)], *boundary[1:]]
    expect_error("wrapper length", check_wrapper_response, 7, [h(rlp(oversized))],
                 {h(rlp(oversized)): metadata_for(oversized)}, reply_for(7, [oversized]))
    blob = blob_transaction()
    assert transaction_hash(FRAME_TX_TYPE + rlp(blob)) == h(FRAME_TX_TYPE + rlp(blob[0]))
    for value in (b"", [bytes(131072)]):
        expect_error("blob data elision", transaction_hash, FRAME_TX_TYPE + rlp(blob[:2] + [value] + blob[3:]))
    expect_error("commitment hash", transaction_hash, FRAME_TX_TYPE + rlp(blob[:3] + [blob[3][::-1], blob[4]]))
    expect_error("cell proof count", transaction_hash, FRAME_TX_TYPE + rlp(blob[:4] + [blob[4][:-1]]))
    print("PASS: eth/75 leanSPHINCS scope, encoding, metadata, full retrieval, ordering, size and blob checks. "
          "Transaction/proof validity, KZG verification and client state are not tested.")


if __name__ == "__main__":
    main()
