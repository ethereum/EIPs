#!/usr/bin/env python3
"""Check EIP-8518 eth/76 aggregate-wrapper encoding fixtures and message rules.

Scalars are represented as Python integers. This checks encoding and blob
metadata binding, not transaction execution, proof validity or client state.

Requires Python 3.9+, pycryptodome and rlp. Run with:
    python3 assets/eip-8518/check_vectors.py
"""

import json
from pathlib import Path

from rlp import decode

# Reuse EIP-8437's encoding and transaction helpers; its runner is independent
# of this extension. No networking or cryptographic validity is simulated here.
import importlib.util

_base_spec = importlib.util.spec_from_file_location(
    "eth75_vectors", Path(__file__).parents[1] / "eip-8437" / "check_vectors.py")
base = importlib.util.module_from_spec(_base_spec)
_base_spec.loader.exec_module(base)
h = base.h
uint = base.uint
rlp = base.rlp
pattern = base.pattern
versioned_hash = base.versioned_hash
transaction_body = base.transaction_body
transaction = base.transaction
blob_transaction = base.blob_transaction
transaction_hash = base.transaction_hash
frame_payload = base.frame_payload
frame_gas = base.frame_gas
check_claims = base.check_claims
reply_for = base.reply_for
answer_request = base.answer_request
wrappers_response = base.wrappers_response
splice = base.splice
rlp_list = base.rlp_list
expect_error = base.expect_error

SOFT_RESPONSE_LIMIT = 2097152
MAX_WRAPPER_BYTES = SOFT_RESPONSE_LIMIT
MAX_ANNOUNCEMENT_BYTES = 2**21
MAX_ANNOUNCEMENTS = 64
MAX_WRAPPERS_PER_REQUEST = 32
MAX_MANIFESTS_PER_REQUEST = 32
LEANSPHINCS_SCHEME = 0x10
FRAME_TX_TYPE = b"\x06"
CELLS_PER_EXT_BLOB = 128
# Inline-metadata threshold inherited from EIP-8437, independent of
# fork-specific dependency limits and enabled schemes.
MAX_INLINE_TRANSACTIONS = 17
METADATA_FIELDS = 5
SYNTHETIC_FRAME_GAS = 100000


def transaction_metadata(envelopes):
    # All wrappers carry EIP-8141 frame transactions; no type or nonce hint.
    payloads = [frame_payload(tx) for tx in envelopes]
    return [[len(tx) for tx in envelopes],
            [transaction_hash(tx) for tx in envelopes],
            [payload[2] for payload in payloads],
            [[int.from_bytes(fee, "big") for fee in payload[5]] for payload in payloads],
            [frame_gas(payload) for payload in payloads]]

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

def inline_metadata(item):
    if item[1] == 0 and len(item[0]) <= MAX_INLINE_TRANSACTIONS:
        return transaction_metadata(item[0])
    return []


def describe(mode, body, deps_hash, txs_hash, txs_meta=()):
    # Each entry is [mode, length, hash, deps-hash, txs-hash, txs-meta].
    if mode not in (0, 1):
        raise ValueError("wrapper mode")
    if not 1 <= len(body) <= MAX_WRAPPER_BYTES:
        raise ValueError("wrapper size")
    return [mode, len(body), h(body), deps_hash, txs_hash, list(txs_meta)]


# Synthetic fixtures use three fees; transport accepts other fee-list lengths.
FIXTURE_FEE_FIELDS = 3


def check_metadata(meta, txs_hash, length, limit):
    assert isinstance(meta, list) and len(meta) == METADATA_FIELDS, "metadata fields"
    sizes, hashes, sources, fees, gas = meta
    assert isinstance(hashes, list) and 1 <= len(hashes) and (limit is None or len(hashes) <= limit), "metadata count"
    assert all(isinstance(field, list) and len(field) == len(hashes) for field in meta), "metadata lengths"
    assert all(isinstance(size, int) and size >= 1 for size in sizes) and sum(sizes) < length, "metadata size"
    assert all(isinstance(digest, bytes) and len(digest) == 32 for digest in hashes), "metadata hash"
    assert hashes == sorted(set(hashes)), "metadata order"
    assert h(b"".join(hashes)) == txs_hash, "metadata transaction hash"
    assert all(isinstance(source, bytes) and len(source) == 20 for source in sources), "metadata source"
    assert all(isinstance(fee, list)
               and all(isinstance(value, int) and 0 <= value < 2**256 for value in fee) for fee in fees), "metadata fees"
    assert all(isinstance(value, int) and 0 <= value < 2**64 for value in gas), "metadata gas"


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


def coverage(item):
    # Wire hints bind full triples, independently of the circuit digest.
    deps_hash = h(b"".join(item[2][0]))
    txs_hash = h(b"".join(transaction_hash(tx) for tx in item[0]))
    return deps_hash, txs_hash


def metadata_for(item):
    return (item[1], len(rlp(item)), *coverage(item), inline_metadata(item))


def may_skip_fetch(announcement, held_valid_wrappers, needs_direct=False):
    # Caller supplies only wrappers valid under the current rules.
    return any(tuple(announcement[3:5]) == coverage(item)
               for item in held_valid_wrappers if not (needs_direct and announcement[0] == 0 and item[1] != 0))


def wrapper_vectors():
    items = wrapper_items()
    out = {
        "deps": [d.hex() for d in items["mode0"][2][0]],
        "transactions": [x.hex() for x in items["mode0"][0]],
    }
    for name, item in items.items():
        body = rlp(item)
        announcement = describe(item[1], body, *coverage(item), inline_metadata(item))
        out[name] = {
            "body": body.hex(),
            "content_hash": announcement[2].hex(),
            "deps_hash": announcement[3].hex(),
            "txs_hash": announcement[4].hex(),
            "transaction_metadata_rlp": rlp(transaction_metadata(item[0])).hex(),
            "announcement_rlp": rlp(announcement).hex(),
            "response_rlp": rlp(reply_for(7, [item])).hex(),
            "compact_response_rlp": rlp([7, [[announcement[2], compact_wrapper(item, {h(tx) for tx in item[0]})]]]).hex(),
            "compact_request_rlp": rlp([7, 1, [announcement[2]]]).hex(),
            "manifest_request_rlp": rlp([9, [announcement[2]]]).hex(),
            "manifest_response_rlp": rlp(manifests_response(9, [item])).hex(),
            "full_request_rlp": rlp([8, 0, [announcement[2]]]).hex(),
            "encoding_hashes": [h(tx).hex() for tx in item[0]],
            "transaction_hashes": [transaction_hash(tx).hex() for tx in item[0]],
        }
    return out


def check_announcement_size(payload):
    assert len(payload) <= MAX_ANNOUNCEMENT_BYTES, "announcement bytes"


def check_announcements(entries):
    assert 1 <= len(entries) <= MAX_ANNOUNCEMENTS, "announcement count"
    for entry in entries:
        assert isinstance(entry, list) and len(entry) == 6, "announcement fields"
        mode, length, digest, deps_hash, txs_hash, txs_meta = entry
        assert isinstance(mode, int) and mode >= 0, "announcement mode"
        assert isinstance(length, int) and 1 <= length <= MAX_WRAPPER_BYTES, "announcement length"
        assert isinstance(digest, bytes) and len(digest) == 32, "announcement hash"
        assert isinstance(deps_hash, bytes) and len(deps_hash) == 32, "announcement dependency hash"
        assert isinstance(txs_hash, bytes) and len(txs_hash) == 32, "announcement transaction hash"
        assert isinstance(txs_meta, list), "announcement metadata"
        if txs_meta and mode in (0, 1):
            assert mode == 0, "metadata mode"
            check_metadata(txs_meta, txs_hash, length, MAX_INLINE_TRANSACTIONS)
    hashes = [entry[2] for entry in entries]
    assert hashes == sorted(set(hashes)), "announcement order"
    check_announcement_size(rlp(entries))
    return [entry for entry in entries if entry[0] in (0, 1)]


def check_request(request_id, hashes, received_announcements, compact=0):
    assert type(compact) is int and compact in (0, 1), "request compact flag"
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


def compact_wrapper(item, expected_known):
    # Expected cache hits can be inferred from any prior wrapper announcements.
    txs = [[h(tx)] if h(tx) in expected_known and len(rlp([h(tx)])) < len(rlp(tx)) else tx
           for tx in item[0]]
    return [txs, *item[1:]]


def reconstruct(item, compact, cache, length):
    assert isinstance(item, list) and len(item) == 3, "wrapper fields"
    assert isinstance(item[0], list), "wrapper envelopes"
    assert 1 <= len(rlp(item)) <= length <= MAX_WRAPPER_BYTES, "wrapper length"
    txs = []
    missing = False
    expanded_size = len(rlp(item))
    for entry in item[0]:
        if isinstance(entry, list):
            assert compact == 1, "reference in full response"
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


def check_wrapper_response(request_id, requested, announced_metadata, reply, compact=0, cache=None, verify=None,
                           manifests=None):
    # announced_metadata and manifests are those of the peer serving the response.
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
        mode, length, deps_hash, txs_hash, txs_meta = announced_metadata[digest]
        item = reconstruct(wire_item, compact, cache or {}, length)
        assert wire_item[1] == mode, "announced mode"
        if item is None:
            retries.append(digest)
            continue
        body = rlp(item)
        assert h(body) == digest, "response hash"
        check_wrapper_shape(item)
        assert len(body) == length, "announced length"
        # Check wire hints before any proof-verification work.
        actual_deps, actual_txs = coverage(item)
        assert actual_deps == deps_hash, "announced dependency hash"
        assert actual_txs == txs_hash, "announced transaction hash"
        assert txs_meta == inline_metadata(item), "announced transaction metadata"
        if manifests and digest in manifests:
            assert manifests[digest] == [transaction_hash(tx) for tx in item[0]], "manifest transaction hashes"
        if verify is not None:
            assert verify(item), "proof verification"
    return retries


def check_manifest_request(request_id, hashes, received_announcements):
    assert isinstance(request_id, int) and 0 <= request_id < 2**64, "request id"
    assert 1 <= len(hashes) <= MAX_MANIFESTS_PER_REQUEST, "request count"
    assert all(isinstance(digest, bytes) and len(digest) == 32 for digest in hashes), "request hash"
    assert len(set(hashes)) == len(hashes), "request duplicates"
    assert all(digest in received_announcements for digest in hashes), "unannounced wrapper"


def manifests_response(request_id, wrappers):
    served = []
    for item in wrappers:
        if len(rlp([request_id, served])) >= SOFT_RESPONSE_LIMIT:
            break
        served.append([h(rlp(item)), [transaction_hash(tx) for tx in item[0]]])
    return [request_id, served]


def answer_manifest_request(request_id, requested, held, announced):
    return manifests_response(request_id, [held[digest] for digest in requested
                                            if digest in announced and digest in held])


def check_manifest_response(request_id, requested, announced_metadata, reply):
    # Check the hash list against the sender's hint, then against the fetched wrapper.
    assert isinstance(reply, list) and len(reply) == 2, "response fields"
    assert reply[0] == request_id, "response id"
    assert isinstance(reply[1], list), "response fields"
    positions = {digest: i for i, digest in enumerate(requested)}
    previous = -1
    manifests = {}
    for entry in reply[1]:
        assert isinstance(entry, list) and len(entry) == 2, "response entry"
        digest, txhashes = entry
        assert isinstance(digest, bytes) and digest in positions, "response hash"
        assert positions[digest] > previous, "response order"
        previous = positions[digest]
        assert isinstance(txhashes, list) and txhashes, "manifest hashes"
        assert all(isinstance(txhash, bytes) and len(txhash) == 32 for txhash in txhashes), "manifest hash"
        assert txhashes == sorted(set(txhashes)), "manifest order"
        assert len(rlp(txhashes)) < announced_metadata[digest][1], "manifest size"
        assert h(b"".join(txhashes)) == announced_metadata[digest][3], "manifest transaction hash"
        manifests[digest] = txhashes
    return manifests


def vector(mode, size):
    # Pattern bytes test hash and length encoding, not wrapper validity.
    announcement = describe(mode, pattern(size), h(b"dependency hint"), h(b"transaction hint"))
    return {
        "mode": mode,
        "size": size,
        "content_hash": announcement[2].hex(),
        "deps_hash": announcement[3].hex(),
        "txs_hash": announcement[4].hex(),
        "announcement_rlp": rlp(announcement).hex(),
    }


def check_versioned_shape(version, code, message):
    assert version in (75, 76), "protocol version"
    if code == 0x18:
        width = 4 if version == 75 else 6
        assert isinstance(message, list) and all(isinstance(e, list) and len(e) == width for e in message), "announcement fields"
    elif code == 0x19:
        assert isinstance(message, list) and len(message) == (2 if version == 75 else 3), "request fields"
    elif code in (0x1b, 0x1c):
        assert version == 76, "message version"
    else:
        assert code == 0x1a, "message code"


def can_send_wrapper(version, item, enabled_schemes):
    # Protocol eligibility is separate from structural and cryptographic checks.
    schemes = {int.from_bytes(dep[:32], "big") for dep in item[2][0]}
    if not schemes <= enabled_schemes:
        return False
    if version == 75:
        return item[1] == 0 and schemes == {LEANSPHINCS_SCHEME}
    return version == 76 and item[1] in (0, 1)


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

    # RLP prefix expansion makes the maximum entry without metadata 107 bytes in either mode.
    assert MAX_WRAPPER_BYTES == SOFT_RESPONSE_LIMIT
    for mode in (0, 1):
        assert len(rlp([mode, MAX_WRAPPER_BYTES, bytes(32), bytes(32), bytes(32), []])) == 107

    # Announcement count, fields and strict hash ordering.
    announced = [[i % 2, MAX_WRAPPER_BYTES, uint(i + 1, 32), bytes(32), bytes(32), []] for i in range(65)]
    check_announcements([[0, 1, bytes(32), bytes(32), bytes(32), []]])
    check_announcements(announced[:64])
    expect_error("announcement count", check_announcements, [])
    expect_error("announcement count", check_announcements, announced)
    expect_error("announcement order", check_announcements, announced[:2][::-1])
    expect_error("announcement order", check_announcements, announced[:1] * 2)
    for length in (0, MAX_WRAPPER_BYTES + 1):
        expect_error("announcement length", check_announcements, [[0, length, bytes(32), bytes(32), bytes(32), []]])
    for mode in (-1, b"\x01"):
        expect_error("announcement mode", check_announcements, [[mode, 1, bytes(32), bytes(32), bytes(32), []]])
    for mode in (2, 256):
        unknown = [mode, 1, bytes(32), bytes(32), bytes(32), []]
        known = [0, 1, bytes([1]) * 32, bytes(32), bytes(32), []]
        assert check_announcements([unknown]) == []
        assert check_announcements([unknown, known]) == [known]
        expect_error("announcement count", check_announcements, [unknown] * 65)
        expect_error("announcement order", check_announcements, [known, unknown])
        expect_error("announcement length", check_announcements,
                     [[mode, MAX_WRAPPER_BYTES + 1, *unknown[2:]]])
    expect_error("announcement hash", check_announcements, [[0, 1, bytes(31), bytes(32), bytes(32), []]])
    expect_error("announcement fields", check_announcements, [[0, 1, bytes(32), b""]])
    expect_error("announcement fields", check_announcements, [[1, bytes(32)]])
    expect_error("announcement fields", check_announcements, [[0, 1, bytes(32), bytes(32), bytes(32)]])
    expect_error("announcement metadata", check_announcements, [[0, 1, bytes(32), bytes(32), bytes(32), b""]])

    expect_error("announcement dependency hash", check_announcements,
                 [[0, 1, bytes(32), bytes(31), bytes(32), []]])
    expect_error("announcement transaction hash", check_announcements,
                 [[0, 1, bytes(32), bytes(32), bytes(31), []]])

    # A wide fixture with three fees: no fixed fee-list length limits transport.
    widest_hashes = sorted(h(uint(i, 1)) for i in range(MAX_INLINE_TRANSACTIONS))
    widest = [[(MAX_WRAPPER_BYTES - 1) // MAX_INLINE_TRANSACTIONS] * MAX_INLINE_TRANSACTIONS,
              widest_hashes,
              [b"\xff" * 20] * MAX_INLINE_TRANSACTIONS,
              [[2**256 - 1] * FIXTURE_FEE_FIELDS] * MAX_INLINE_TRANSACTIONS,
              [2**64 - 1] * MAX_INLINE_TRANSACTIONS]
    widest_entries = [[0, MAX_WRAPPER_BYTES, uint(i + 1, 32), bytes(32), h(b"".join(widest_hashes)), widest]
                      for i in range(MAX_ANNOUNCEMENTS)]
    check_announcements(widest_entries)
    assert len(rlp(widest_entries)) == 190660
    # Fee-list length is variable, but the entire announcement is byte-bounded.
    # Synthetic metadata checks transport only, not the transaction's fee layout.
    large_meta = transaction_metadata([transaction(0)])
    large_meta[3] = [[2**256 - 1] * 60000]
    large_entry = [0, MAX_WRAPPER_BYTES, bytes(32), bytes(32), h(b"".join(large_meta[1])), large_meta]
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

    # Request bounds, uniqueness and received announcements; IDs need not increase.
    assert rlp([7, 0, [bytes(32)]]).hex() == "e40780e1a0" + "00" * 32
    for flag in (0, 1):
        check_request(7, [bytes(32)], {bytes(32)}, flag)
    for flag in (-1, 2, b"", True):
        expect_error("request compact flag", check_request, 7, [bytes(32)], {bytes(32)}, flag)
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
    assert len(rlp(announced[:64])) == 6851
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
    metadata = {h(body): metadata_for(item) for item, body in zip(items, encoded)}
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
    wrong_length = {**metadata, requested[0]: (0, len(encoded[0]) + 1, *coverage(mode0), inline_metadata(mode0))}
    expect_error("announced length", check_wrapper_response, 7, requested, wrong_length, reply_for(7, [mode0]))
    for i, item in enumerate(items):
        wrong_mode = {**metadata, requested[i]: (1 - item[1], len(encoded[i]), *coverage(item), inline_metadata(item))}
        expect_error("announced mode", check_wrapper_response, 7, requested, wrong_mode, reply_for(7, [item]))
    # Distinct proof bytes can cover identical transactions and dependencies.
    alternative = [mode1[0], 1, [mode1[2][0], b"another aggregate proof"]]
    alt_announcement = describe(1, rlp(alternative), *coverage(alternative))
    assert h(rlp(alternative)) != h(rlp(mode1))
    assert may_skip_fetch(alt_announcement, [mode1])
    # Equal dependencies do not establish equal transaction coverage.
    different_txs = [[transaction(99)], *mode1[1:]]
    different_announcement = describe(1, rlp(different_txs), *coverage(different_txs))
    assert coverage(different_txs)[0] == coverage(mode1)[0]
    assert not may_skip_fetch(different_announcement, [mode1])
    assert not may_skip_fetch(alt_announcement, [])  # No validated coverage.
    for index, reason in [(2, "announced dependency hash"), (3, "announced transaction hash")]:
        wrong = list(metadata[requested[1]])
        wrong[index] = bytes(32)
        expect_error(reason, check_wrapper_response, 7, requested,
                     {**metadata, requested[1]: tuple(wrong)}, reply_for(7, [mode1]))
    # A false hint is rejected even when the proof would fail verification.
    # Stubs test ordering only, not cryptographic correctness.
    verification_calls = []
    def invalid_proof(item):
        verification_calls.append(item)
        return False
    for index, reason in [(2, "announced dependency hash"), (3, "announced transaction hash")]:
        wrong = list(metadata[requested[1]])
        wrong[index] = bytes(32)
        expect_error(reason, check_wrapper_response, 7, requested,
                     {**metadata, requested[1]: tuple(wrong)}, reply_for(7, [mode1]),
                     0, None, invalid_proof)
        assert verification_calls == []
    expect_error("proof verification", check_wrapper_response, 7, requested, metadata,
                 reply_for(7, [mode1]), 0, None, invalid_proof)
    assert verification_calls == [mode1]
    # Unknown schemes remain structurally decodable in either wrapper mode.
    for original in (mode0, mode1):
        unknown_deps = [bytes(31) + b"\xfe" + dep[32:] for dep in original[2][0]]
        unknown = [original[0], original[1], [unknown_deps, original[2][1]]]
        unknown_body = rlp(unknown)
        check_wrapper_shape(unknown)
        expect_error("proof verification", check_wrapper_response, 7, [h(unknown_body)],
                     {h(unknown_body): metadata_for(unknown)}, reply_for(7, [unknown]),
                     0, None, lambda item: False)
    # Changing a scheme changes the wire digest, even if claim/key bytes match.
    changed_deps = [bytes(31) + b"\x11" + dep[32:] for dep in mode1[2][0]]
    changed_scheme = [mode1[0], 1, [changed_deps, mode1[2][1]]]
    assert coverage(changed_scheme)[0] != coverage(mode1)[0]
    # Different verifier outcomes cannot change hints over the same bytes.
    check_wrapper_response(7, requested, metadata, reply_for(7, [mode1]),
                           verify=lambda item: True)
    assert wrappers_response(7, encoded) == rlp(reply_for(7, items))

    # Five metadata lists; all enclosed transactions are frames and nonce hints are absent.
    meta0 = transaction_metadata(mode0[0])
    assert inline_metadata(mode0) == meta0
    assert inline_metadata(mode1) == inline_metadata(blob_mode1) == []
    assert meta0[0] == [len(tx) for tx in mode0[0]]
    assert meta0[1] == [transaction_hash(tx) for tx in mode0[0]]
    check_announcements([describe(0, encoded[0], *coverage(mode0), meta0)])
    check_announcements([describe(1, encoded[1], *coverage(mode1))])
    check_announcements([describe(0, encoded[0], *coverage(mode0))])
    expect_error("metadata mode", check_announcements, [describe(1, encoded[1], *coverage(mode1), meta0)])

    def altered(index, value):
        meta = list(meta0)
        meta[index] = value
        return meta

    for meta, reason in [(meta0[:4], "metadata fields"),
                         (altered(1, []), "metadata count"),
                         (altered(0, meta0[0][:1]), "metadata lengths"),
                         (altered(0, [0] + meta0[0][1:]), "metadata size"),
                         (altered(0, [len(encoded[0])] + meta0[0][1:]), "metadata size"),
                         (altered(1, [bytes(31)] + meta0[1][1:]), "metadata hash"),
                         (altered(1, meta0[1][::-1]), "metadata order"),
                         (altered(1, meta0[1][:1] * 2), "metadata order"),
                         (altered(1, sorted([h(b"other 0"), h(b"other 1")])), "metadata transaction hash"),
                         (altered(2, [bytes(19)] + meta0[2][1:]), "metadata source"),
                         (altered(3, [b""] + meta0[3][1:]), "metadata fees"),
                         (altered(3, [[[]]] + meta0[3][1:]), "metadata fees"),
                         (altered(3, [[-1]] + meta0[3][1:]), "metadata fees"),
                         (altered(3, [[2**256]] + meta0[3][1:]), "metadata fees"),
                         (altered(4, [2**64] + meta0[4][1:]), "metadata gas")]:
        expect_error(reason, check_announcements, [describe(0, encoded[0], *coverage(mode0), meta)])
    for fee_list in ([], [7, 3], [7, 3, 0], [7, 3, 0, 0]):
        payload = transaction_body(2**64 - 1)
        payload[5] = fee_list
        item = [[FRAME_TX_TYPE + rlp(payload)], 0, mode0[2]]
        body = rlp(item)
        check_announcements([describe(0, body, *coverage(item), inline_metadata(item))])
        check_wrapper_response(7, [h(body)], {h(body): metadata_for(item)}, reply_for(7, [item]))
    for index, value in [(0, [meta0[0][0] + 1] + meta0[0][1:]),
                         (2, [b"\x01" * 20] + meta0[2][1:]),
                         (3, [[2, 1, 0]] + meta0[3][1:]),
                         (4, [meta0[4][0] + 1] + meta0[4][1:]), (None, [])]:
        false_meta = [] if index is None else altered(index, value)
        if false_meta:
            check_announcements([describe(0, encoded[0], *coverage(mode0), false_meta)])
        expect_error("announced transaction metadata", check_wrapper_response, 7, requested,
                     {**metadata, requested[0]: (*metadata[requested[0]][:4], false_meta)},
                     reply_for(7, [mode0]), 0, None, invalid_proof)
    assert verification_calls == [mode1]
    sent = transaction_body(5)
    sent[2], sent[5] = b"\x11" * 20, [7, 3, 0]
    assert transaction_metadata([FRAME_TX_TYPE + rlp(sent)])[2:4] == [[b"\x11" * 20], [[7, 3, 0]]]
    claims = {"A": altered(4, [meta0[4][0] + 1] + meta0[4][1:]), "B": meta0}
    assert check_claims("B", mode0, claims, inline_metadata) == ["A"]
    expect_error("announced transaction metadata", check_claims, "A", mode0, claims, inline_metadata)
    held_transactions = {transaction_hash(tx): tx for tx in mode0[0]}
    assert mismatched_held_transactions(meta0, held_transactions) == []
    for index, value in [(2, [b"\x01" * 20] + meta0[2][1:]),
                         (3, [[2, 1, 0]] + meta0[3][1:]),
                         (4, [meta0[4][0] + 1] + meta0[4][1:])]:
        false_meta = altered(index, value)
        assert mismatched_held_transactions(false_meta, held_transactions) == [meta0[1][0]]
        assert mismatched_held_transactions(false_meta, {}) == []
    assert mismatched_held_transactions(altered(0, [meta0[0][0] + 1] + meta0[0][1:]), held_transactions) == []
    expect_error("held transaction hash", mismatched_held_transactions, meta0, {meta0[1][0]: transaction(1000)})
    seventeen, eighteen = ([sorted((transaction(i) for i in range(count)), key=transaction_hash), 0, mode0[2]]
                           for count in (MAX_INLINE_TRANSACTIONS, MAX_INLINE_TRANSACTIONS + 1))
    assert len(inline_metadata(seventeen)[1]) == MAX_INLINE_TRANSACTIONS and inline_metadata(eighteen) == []
    for item in (seventeen, eighteen):
        body = rlp(item)
        check_announcements([describe(0, body, *coverage(item), inline_metadata(item))])
        check_wrapper_response(7, [h(body)], {h(body): metadata_for(item)}, reply_for(7, [item]))
    expect_error("metadata count", check_announcements,
                 [describe(0, rlp(eighteen), *coverage(eighteen), transaction_metadata(eighteen[0]))])
    body = rlp(seventeen)
    expect_error("announced transaction metadata", check_wrapper_response, 7, [h(body)],
                 {h(body): (*metadata_for(seventeen)[:4], [])}, reply_for(7, [seventeen]))
    direct_offer = describe(0, encoded[0], *coverage(mode0), meta0)
    assert may_skip_fetch(direct_offer, [mode1])
    assert not may_skip_fetch(direct_offer, [mode1], needs_direct=True)
    assert may_skip_fetch(direct_offer, [mode0, mode1], needs_direct=True)

    # A full 32-hash request can be satisfied in one response for small wrappers.
    small_items = [[[transaction(i)], 0, mode0[2]] for i in range(32)]
    small = [rlp(item) for item in small_items]
    small_hashes = [h(body) for body in small]
    small_metadata = {h(body): metadata_for(item) for item, body in zip(small_items, small)}
    check_request(7, small_hashes, set(small_hashes))
    assert len(splice(7, small)) < SOFT_RESPONSE_LIMIT
    assert wrappers_response(7, small) == splice(7, small)
    check_wrapper_response(7, small_hashes, small_metadata, reply_for(7, small_items))

    # Synthetic transport-size fixture: no independent 4,096-envelope ceiling.
    # This does not establish EIP-8288 dependency or transaction validity.
    many_envelopes = sorted((transaction(i) for i in range(4097)), key=transaction_hash)
    many = [many_envelopes, 1, mode1[2]]
    many_body = rlp(many)
    check_wrapper_response(7, [h(many_body)], {h(many_body): metadata_for(many)}, reply_for(7, [many]))

    # Manifests list every transaction of an announced wrapper, whatever its
    # mode and transaction count, in request order.
    check_manifest_request(9, requested, set(requested))
    check_manifest_request(max_id, hashes[:32], set(hashes))
    for request_id in (-1, 2**64):
        expect_error("request id", check_manifest_request, request_id, hashes[:1], set(hashes))
    expect_error("request count", check_manifest_request, 9, [], set(hashes))
    expect_error("request count", check_manifest_request, 9, hashes[:33], set(hashes))
    expect_error("request duplicates", check_manifest_request, 9, hashes[:1] * 2, set(hashes))
    expect_error("request hash", check_manifest_request, 9, [bytes(31)], set(hashes))
    expect_error("unannounced wrapper", check_manifest_request, 9, [bytes(32)], set(hashes))
    assert len(rlp([max_id, hashes[:32]])) == 1071
    held_items = dict(zip(requested, items))
    reply = answer_manifest_request(9, requested, held_items, set(requested))
    assert reply == manifests_response(9, items)
    assert answer_manifest_request(9, requested, held_items, {requested[1]}) == manifests_response(9, items[1:2])
    assert answer_manifest_request(9, [bytes(32)], held_items, set(requested)) == [9, []]
    manifests = check_manifest_response(9, requested, metadata, reply)
    assert manifests == {digest: [transaction_hash(tx) for tx in item[0]] for digest, item in zip(requested, items)}
    for returned in (items[:1], items[1:], []):
        check_manifest_response(9, requested, metadata, manifests_response(9, returned))
    check_wrapper_response(7, requested, metadata, reply_for(7, items), manifests=manifests)
    many_manifests = check_manifest_response(9, [h(many_body)], {h(many_body): metadata_for(many)},
                                             manifests_response(9, [many]))
    assert len(many_manifests[h(many_body)]) == 4097
    assert len(rlp(many_manifests[h(many_body)])) == 135205
    expect_error("response id", check_manifest_response, 9, requested, metadata, manifests_response(8, items))
    expect_error("response order", check_manifest_response, 9, requested, metadata, [9, reply[1][::-1]])
    expect_error("response order", check_manifest_response, 9, requested, metadata, [9, reply[1][:1] * 2])
    expect_error("response hash", check_manifest_response, 9, requested, metadata, [9, [[bytes(32), manifests[requested[0]]]]])
    txhashes = manifests[requested[1]]
    false_hashes = sorted([h(b"other 0"), h(b"other 1")])
    for value, reason in [([], "manifest hashes"), (b"", "manifest hashes"),
                           ([bytes(31)], "manifest hash"), (txhashes[::-1], "manifest order"),
                           (txhashes[:1] * 2, "manifest order"), (false_hashes, "manifest transaction hash")]:
        expect_error(reason, check_manifest_response, 9, requested, metadata, [9, [[requested[1], value]]])
    # A dishonest peer can align a false manifest and hint, not the wrapper's hash.
    false_hint = {**metadata, requested[1]: (*metadata[requested[1]][:3], h(b"".join(false_hashes)), [])}
    check_manifest_response(9, requested, false_hint, [9, [[requested[1], false_hashes]]])
    expect_error("announced transaction hash", check_wrapper_response, 7, requested, false_hint,
                 reply_for(7, [mode1]), 0, None, invalid_proof, {requested[1]: false_hashes})
    expect_error("manifest transaction hashes", check_wrapper_response, 7, requested, metadata,
                 reply_for(7, [mode1]), 0, None, invalid_proof, {requested[1]: false_hashes})
    assert verification_calls == [mode1]
    check_wrapper_response(7, requested, metadata, reply_for(7, [mode1]), manifests={requested[1]: txhashes})
    manifest_claims = {"A": false_hashes, "B": txhashes}
    assert check_claims("B", mode1, manifest_claims, lambda item: [transaction_hash(tx) for tx in item[0]]) == ["A"]
    tight = {**metadata, requested[1]: (metadata[requested[1]][0], len(rlp(txhashes)), *metadata[requested[1]][2:])}
    expect_error("manifest size", check_manifest_response, 9, requested, tight, [9, [[requested[1], txhashes]]])
    # The soft limit constrains packing; a complete last manifest may cross it.
    big = [[many_envelopes, 1, [mode1[2][0], b"aggregate proof %d" % i]] for i in range(20)]
    big_hashes = [h(rlp(item)) for item in big]
    packed = manifests_response(9, big)
    assert 1 < len(packed[1]) < len(big)
    assert len(rlp([9, packed[1][:-1]])) < SOFT_RESPONSE_LIMIT <= len(rlp(packed))
    check_manifest_response(9, big_hashes, {digest: metadata_for(item) for digest, item in zip(big_hashes, big)}, packed)

    # Five fixtures with 1,000,000-byte synthetic proofs; none is a valid proof.
    large_items = [[mode1[0], 1, [mode1[2][0], bytes([i]) * 1_000_000]] for i in range(5)]
    large = [rlp(item) for item in large_items]
    assert all(len(body) <= MAX_WRAPPER_BYTES for body in large)
    assert len(splice(7, large[:2])) <= SOFT_RESPONSE_LIMIT < len(splice(7, large[:3]))
    assert wrappers_response(7, large) == splice(7, large[:3])
    assert len(wrappers_response(max_id, large)) < SOFT_RESPONSE_LIMIT + MAX_WRAPPER_BYTES
    large_hashes = [h(body) for body in large]
    large_metadata = {h(body): metadata_for(item) for item, body in zip(large_items, large)}
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
    check_wrapper_response(7, [h(body)], {h(body): metadata_for(at_limit)}, reply_for(7, [at_limit]))
    assert wrappers_response(max_id, [body, encoded[0]]) == splice(max_id, [body])
    assert len(splice(max_id, [body])) > SOFT_RESPONSE_LIMIT  # Response framing only.
    tx_body[3] = [bytes(payload_size + 1)]
    oversized = [[FRAME_TX_TYPE + rlp(tx_body)], 1, [mode1[2][0], proof]]
    assert len(rlp(oversized)) == MAX_WRAPPER_BYTES + 1
    expect_error("wrapper length", check_wrapper_response, 7, [h(rlp(oversized))],
                 {h(rlp(oversized)): metadata_for(oversized)}, reply_for(7, [oversized]))

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

    # Full bytes from peer A populate a node-wide cache used for peer B's aggregate.
    check_wrapper_response(10, [requested[0]], metadata, reply_for(10, [mode0]))
    cache_from_a = {h(tx): tx for tx in mode0[0]}
    compact_from_b = compact_wrapper(mode1, set(cache_from_a))
    assert check_wrapper_response(11, [requested[1]], metadata,
                                  [11, [[requested[1], compact_from_b]]], 1, cache_from_a) == []
    assert check_wrapper_response(11, [requested[1]], metadata,
                                  [11, [[requested[1], compact_from_b]]], 1, {}) == [requested[1]]
    # Compact transport preserves full identity, including blob metadata.
    for item in (mode0, mode1, blob_mode1):
        cache = {h(tx): tx for tx in item[0]}
        digest = h(rlp(item))
        meta = {digest: metadata_for(item)}
        compact = compact_wrapper(item, set(cache))
        assert len(rlp(compact)) < len(rlp(item))
        reply = [7, [[digest, compact]]]
        assert reconstruct(compact, 1, cache, meta[digest][1]) == item
        assert check_wrapper_response(7, [digest], meta, reply, compact=1, cache=cache) == []
        assert check_wrapper_response(7, [digest], meta, reply, compact=1) == [digest]
        # Eviction leads to a fresh full request, not a transaction fetch.
        check_request(8, [digest], {digest}, compact=0)
        for flag in (0, 1):
            # A minimal client can serve full bytes and receive without a cache.
            assert check_wrapper_response(8, [digest], meta, reply_for(8, [item]), compact=flag) == []
        decoded_compact = decode(rlp(compact), strict=True)
        decoded_full = decode(rlp(item), strict=True)
        assert all(isinstance(entry, list) and len(entry) == 1 for entry in decoded_compact[0])
        assert all(isinstance(entry, bytes) for entry in decoded_full[0])
        expect_error("reference in full response", check_wrapper_response, 7, [digest], meta, reply, 0, cache)
        assert compact_wrapper(item, set()) == item
        mixed = compact_wrapper(item, {h(item[0][0])})
        assert isinstance(mixed[0][0], list) and isinstance(mixed[0][1], bytes)
        assert check_wrapper_response(7, [digest], meta, [7, [[digest, mixed]]], compact=1, cache=cache) == []
        partial_cache = dict(cache)
        del partial_cache[h(item[0][0])]
        assert check_wrapper_response(7, [digest], meta, reply, compact=1, cache=partial_cache) == [digest]
        wrong_cache = {**cache, h(item[0][0]): transaction(999)}
        expect_error("encoding hash", check_wrapper_response, 7, [digest], meta, reply, 1, wrong_cache)
        malformed = [[[bytes(31)], *compact[0][1:]], *compact[1:]]
        expect_error("encoding reference", check_wrapper_response, 7, [digest], meta,
                     [7, [[digest, malformed]]], 1, cache)
        false_digest = h(b"false canonical wrapper")
        expect_error("response hash", check_wrapper_response, 7, [false_digest],
                     {false_digest: meta[digest]}, [7, [[false_digest, compact]]], 1, cache)
    # Same consensus transaction hash does not identify the exact blob encoding.
    assert h(blob_encoded) != h(altered_blob)
    assert compact_wrapper([[blob_encoded], *mode1[1:]], {h(altered_blob)})[0] == [blob_encoded]
    # The compact byte count cannot bypass the canonical 2 MiB bound.
    compact_oversized = compact_wrapper(oversized, {h(tx) for tx in oversized[0]})
    assert len(rlp(compact_oversized)) < MAX_WRAPPER_BYTES
    expect_error("wrapper length", reconstruct, compact_oversized, 1,
                 {h(tx): tx for tx in oversized[0]}, MAX_WRAPPER_BYTES)

    # Each version selects one wire shape, even when sending mode 0.
    for item in (mode0, mode1):
        entry76 = describe(item[1], rlp(item), *coverage(item), inline_metadata(item))
        entry75 = entry76[:3] + [entry76[5]]
        check_versioned_shape(75, 0x18, [entry75])
        check_versioned_shape(76, 0x18, [entry76])
        expect_error("announcement fields", check_versioned_shape, 75, 0x18, [entry76])
        expect_error("announcement fields", check_versioned_shape, 76, 0x18, [entry75])
    for version, request in [(75, [7, hashes[:1]]), (76, [7, 0, hashes[:1]])]:
        check_versioned_shape(version, 0x19, request)
        expect_error("request fields", check_versioned_shape, 151 - version, 0x19, request)
    for code in (0x1b, 0x1c):
        check_versioned_shape(76, code, [7, []])
        expect_error("message version", check_versioned_shape, 75, code, [7, []])
    native_only = {LEANSPHINCS_SCHEME}
    generic_enabled = native_only | {0x11}
    assert can_send_wrapper(75, mode0, native_only)
    assert not can_send_wrapper(75, mode1, native_only)
    for item in (mode0, mode1):
        assert can_send_wrapper(76, item, native_only)
        for mixed in (False, True):
            deps = [uint(0x11 if i or not mixed else LEANSPHINCS_SCHEME, 32) + dep[32:]
                    for i, dep in enumerate(item[2][0])]
            generic = [item[0], item[1], [deps, item[2][1]]]
            check_wrapper_shape(generic)
            assert not can_send_wrapper(75, generic, generic_enabled)
            assert not can_send_wrapper(76, generic, native_only)
            assert can_send_wrapper(76, generic, generic_enabled)

    print("PASS: announcement, full-envelope and sparse-blob wrapper encoding vectors; "
          "compact reconstruction and full retries, message counts, ordering, metadata matching, "
          "transaction metadata and manifests, byte limits and response packing. "
          "Transaction/proof validity, KZG verification and client-state sequences are not tested.")


if __name__ == "__main__":
    main()
