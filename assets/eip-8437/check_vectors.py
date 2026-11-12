#!/usr/bin/env python3
"""Check EIP-8437 encoding fixtures and message rules on decoded values.

Scalars are represented as Python integers. This checks encoding, verifier identifiers
and blob metadata binding, not transaction/program execution, proof validity
or client state.

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
MAX_RAW_VERIFIERS = 64
MAX_RAW_PROFILES = 64
MAX_SUPPLIED_PROOFS = 1
# Fixture profiles only; this checker does not allocate consensus identifiers.
SYNTHETIC_EXECUTABLE_PROFILES = {1, 2}
LEANSPHINCS_SCHEME = 0x10
LEANSTARK_SCHEME = 0x11
FRAME_TX_TYPE = b"\x06"
CELLS_PER_EXT_BLOB = 128


def h(data):
    return keccak.new(digest_bits=256, data=data).digest()


def leanvm_verifier_id(package):
    return h(b"EIP8288:program:v1" + package)


def package_profile(package):
    assert isinstance(package, bytes), "raw program bytes"
    try:
        decoded = decode(package, strict=True)
    except Exception as error:
        raise AssertionError("raw program package") from error
    assert isinstance(decoded, list) and len(decoded) == 2, "raw program package"
    version, bytecode = decoded
    assert isinstance(version, bytes) and len(version) <= 8 and not version.startswith(b"\x00"), "raw profile id"
    assert isinstance(bytecode, bytes), "raw program bytecode"
    return int.from_bytes(version, "big")


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


def describe(mode, body, deps_hash, txs_hash):
    # Each entry is [mode, length, hash, deps-hash, txs-hash].
    if mode not in (0, 1, 2):
        raise ValueError("wrapper mode")
    if not 1 <= len(body) <= MAX_WRAPPER_BYTES:
        raise ValueError("wrapper size")
    return [mode, len(body), h(body), deps_hash, txs_hash]


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


def consensus_envelope(encoded):
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
    return FRAME_TX_TYPE + rlp(body)


def transaction_hash(encoded):
    return h(consensus_envelope(encoded))


def wrapper_items():
    deps = sorted(bytes(31) + bytes([LEANSPHINCS_SCHEME]) + h(b"message %d" % i) + uint(i + 1, 32)
                  for i in range(2))
    envelopes = sorted((transaction(i) for i in range(2)), key=transaction_hash)
    # Synthetic bytecode, but real content-addressed program identity.
    package = rlp([1, b"synthetic batch module" * 3])
    identifier = leanvm_verifier_id(package)
    raw_deps = deps[:1] + sorted(bytes(31) + bytes([LEANSTARK_SCHEME]) + h(b"claim %d" % i) + identifier
                                 for i in range(2))
    programs = [[identifier, package]]
    return {
        "mode2": [envelopes, 2, [raw_deps, [b"native signature"] +
                  [[h(b"example raw format v1"), i, b"alternative signature %d" % i] for i in range(2)], programs]],
        "mode0": [envelopes, 0, [deps, [b"witness 0", b"witness 1"]]],
        "mode1": [envelopes, 1, [deps, b"aggregate proof"]],
        "blob_mode1": [sorted(envelopes + [FRAME_TX_TYPE + rlp(blob_transaction())],
                              key=transaction_hash), 1, [deps, b"aggregate proof"]],
    }


def mixed_wrapper(item):
    # An opaque proof under a non-executable fixture profile, with no package.
    key = h(b"synthetic non-executable verifier")
    dep = uint(LEANSTARK_SCHEME, 32) + h(b"private claim") + key
    proof = rlp([9, b"synthetic singleton proof"])
    pairs = sorted(list(zip(item[2][0][:2], item[2][1][:2])) + [(dep, proof)])
    return [item[0], 2, [[d for d, _ in pairs], [w for _, w in pairs], item[2][2]]]


def coverage(item):
    # Wire hints bind full triples, independently of the circuit digest.
    deps_hash = h(b"".join(item[2][0]))
    txs_hash = h(b"".join(transaction_hash(tx) for tx in item[0]))
    return deps_hash, txs_hash


def metadata_for(item):
    return (item[1], len(rlp(item)), *coverage(item))


def may_skip_fetch(announcement, held_valid_wrappers):
    # Caller supplies only wrappers valid under the current rules.
    return any((item[1] != 2 or announcement[0] == 2)
               and tuple(announcement[3:]) == coverage(item) for item in held_valid_wrappers)


def wrapper_vectors():
    items = wrapper_items()
    items["mixed_mode2"] = mixed_wrapper(items["mode2"])
    out = {
        "deps": [d.hex() for d in items["mode0"][2][0]],
        "transactions": [x.hex() for x in items["mode0"][0]],
    }
    for name, item in items.items():
        body = rlp(item)
        announcement = describe(item[1], body, *coverage(item))
        out[name] = {
            "body": body.hex(),
            "content_hash": announcement[2].hex(),
            "deps_hash": announcement[3].hex(),
            "txs_hash": announcement[4].hex(),
            "announcement_rlp": rlp(announcement).hex(),
            "response_rlp": rlp(reply_for(7, [item])).hex(),
            "compact_response_rlp": rlp([7, [[announcement[2], compact_wrapper(item, {h(x) for x in wrapper_encodings(item)})]]]).hex(),
            "compact_request_rlp": rlp([7, 1, [announcement[2]]]).hex(),
            "full_request_rlp": rlp([8, 0, [announcement[2]]]).hex(),
            "encoding_hashes": [h(tx).hex() for tx in item[0]],
            "transaction_hashes": [transaction_hash(tx).hex() for tx in item[0]],
        }
        if item[1] == 2:
            out[name]["program_encoding_hashes"] = [h(code).hex() for _, code in item[2][2]]
            out[name]["verifier_ids"] = [identifier.hex() for identifier, _ in item[2][2]]
            out[name]["profile_policy_rlp"] = rlp([0, 0, [1], [identifier for identifier, _ in item[2][2]]]).hex()
            out[name]["wildcard_policy_rlp"] = rlp([1, 1, [1], []]).hex()
    return out


def check_announcements(entries):
    assert 1 <= len(entries) <= MAX_ANNOUNCEMENTS, "announcement count"
    for entry in entries:
        assert isinstance(entry, list) and len(entry) == 5, "announcement fields"
        mode, length, digest, deps_hash, txs_hash = entry
        assert isinstance(mode, int) and mode in (0, 1, 2), "announcement mode"
        assert isinstance(length, int) and 1 <= length <= MAX_WRAPPER_BYTES, "announcement length"
        assert isinstance(digest, bytes) and len(digest) == 32, "announcement hash"
        assert isinstance(deps_hash, bytes) and len(deps_hash) == 32, "announcement dependency hash"
        assert isinstance(txs_hash, bytes) and len(txs_hash) == 32, "announcement transaction hash"
    hashes = [entry[2] for entry in entries]
    assert hashes == sorted(set(hashes)), "announcement order"


def check_request(request_id, hashes, received_announcements, compact=0):
    assert type(compact) is int and compact in (0, 1), "request compact flag"
    assert isinstance(request_id, int) and 0 <= request_id < 2**64, "request id"
    assert 1 <= len(hashes) <= MAX_WRAPPERS_PER_REQUEST, "request count"
    assert all(isinstance(digest, bytes) and len(digest) == 32 for digest in hashes), "request hash"
    assert len(set(hashes)) == len(hashes), "request duplicates"
    assert all(digest in received_announcements for digest in hashes), "unannounced wrapper"


def check_raw_policy(policy):
    assert isinstance(policy, list) and len(policy) == 4, "policy fields"
    accept_new, proving, profiles, verifiers = policy
    assert type(accept_new) is int and accept_new in (0, 1), "policy flag"
    assert type(proving) is int and proving in (0, 1), "policy proving flag"
    assert isinstance(profiles, list) and len(profiles) <= MAX_RAW_PROFILES, "policy profile count"
    assert all(type(profile) is int and 0 <= profile < 2**64 for profile in profiles), "policy profile id"
    assert profiles == sorted(set(profiles)), "policy profile order"
    assert isinstance(verifiers, list) and len(verifiers) <= MAX_RAW_VERIFIERS, "policy verifier count"
    assert all(isinstance(key, bytes) and len(key) == 32 for key in verifiers), "policy verifier id"
    assert verifiers == sorted(set(verifiers)), "policy verifier order"
    assert not accept_new or not verifiers, "wildcard policy list"


def should_announce_raw(item, policy):
    if policy is None:
        return False
    check_raw_policy(policy)
    # Only raw dependencies need executable-profile policy permission.
    return ({package_profile(code) for _, code in item[2][2]} <= set(policy[2])
            and bool(policy[0] or {key for key, _ in item[2][2]} <= set(policy[3])))


def singleton_profile(witness):
    try:
        fields = decode(witness, strict=True)
    except Exception as error:
        raise AssertionError("singleton proof encoding") from error
    assert isinstance(fields, list) and len(fields) == 2, "singleton proof encoding"
    profile, proof = fields
    assert isinstance(profile, bytes) and len(profile) <= 8 and not profile.startswith(b"\x00"), "singleton profile id"
    assert isinstance(proof, bytes) and proof, "singleton proof bytes"
    return int.from_bytes(profile, "big")


def raw_records(item):
    # Caller checks dependency membership/claim binding during EIP-8288 validation.
    return [(dep, witness[0], witness[2], consensus_envelope(item[0][witness[1]]))
            for dep, witness in zip(item[2][0], item[2][1])
            if dep[:32] == uint(LEANSTARK_SCHEME, 32) and isinstance(witness, list)]


def check_wrapper_shape(item):
    # Envelope structure and blob metadata binding are checked; EIP-8141
    # execution, dependency-union equality and cryptographic validity are not.
    assert isinstance(item, list) and len(item) == 3, "wrapper fields"
    envelopes, mode, content = item
    assert isinstance(mode, int) and mode in (0, 1, 2), "wrapper mode"
    assert isinstance(content, list) and len(content) == (3 if mode == 2 else 2), "wrapper content"
    deps, proof = content[:2]
    assert isinstance(deps, list) and deps, "wrapper dependencies"
    assert all(isinstance(dep, bytes) and len(dep) == 96 for dep in deps), "dependency length"
    assert deps == sorted(set(deps)), "dependency order"
    if mode == 0:
        assert isinstance(proof, list) and len(proof) == len(deps), "direct proofs"
        assert all(isinstance(witness, bytes) for witness in proof), "direct witness"
    elif mode == 1:
        assert isinstance(proof, bytes) and proof, "aggregate proof"
    else:
        assert isinstance(proof, list) and len(proof) == len(deps), "raw witness count"
        assert sum(dep[:32] == uint(LEANSPHINCS_SCHEME, 32) for dep in deps) <= 16, "raw native count"
        required = set()
        supplied_proofs = 0
        for dep, witness in zip(deps, proof):
            if dep[:32] == uint(LEANSPHINCS_SCHEME, 32):
                assert isinstance(witness, bytes), "raw native witness"
            else:
                assert dep[:32] == uint(LEANSTARK_SCHEME, 32), "raw scheme"
                if isinstance(witness, bytes):
                    singleton_profile(witness)
                    supplied_proofs += 1
                else:
                    assert isinstance(witness, list) and len(witness) == 3, "raw witness fields"
                    format_id, index, data = witness
                    assert isinstance(format_id, bytes) and len(format_id) == 32, "raw format id"
                    assert type(index) is int and 0 <= index < len(envelopes), "raw transaction index"
                    assert isinstance(data, bytes), "raw witness bytes"
                    required.add(dep[64:])
        assert required, "raw generic witness"
        assert supplied_proofs <= MAX_SUPPLIED_PROOFS, "supplied proof bound"
        programs = content[2]
        assert isinstance(programs, list), "raw programs"
        for entry in programs:
            assert isinstance(entry, list) and len(entry) == 2, "raw program fields"
            key, code = entry
            assert isinstance(key, bytes) and len(key) == 32, "raw program id"
            profile = package_profile(code)
            if profile in SYNTHETIC_EXECUTABLE_PROFILES:
                assert key == leanvm_verifier_id(code), "raw program hash"
        assert [key for key, _ in programs] == sorted(required), "raw program set"
    assert isinstance(envelopes, list) and envelopes, "wrapper envelopes"
    hashes = [transaction_hash(tx) for tx in envelopes]
    assert hashes == sorted(set(hashes)), "transaction order"


def reply_for(request_id, wrappers):
    return [request_id, [[h(rlp(item)), item] for item in wrappers]]


def wrapper_encodings(item):
    return item[0] + ([code for _, code in item[2][2]] if item[1] == 2 else [])


def compact_wrapper(item, delivered):
    # delivered tracks exact encodings sent in full on this connection.
    def omit(encoded):
        return [h(encoded)] if h(encoded) in delivered and len(rlp([h(encoded)])) < len(rlp(encoded)) else encoded
    content = item[2]
    if item[1] == 2:
        content = content[:2] + [[[key, omit(code)] for key, code in content[2]]]
    return [[omit(tx) for tx in item[0]], item[1], content]


def reconstruct(item, compact, cache, length):
    assert isinstance(item, list) and len(item) == 3, "wrapper fields"
    assert isinstance(item[0], list), "wrapper envelopes"
    assert 1 <= len(rlp(item)) <= length <= MAX_WRAPPER_BYTES, "wrapper length"
    missing = False
    expanded_size = len(rlp(item))
    def resolve(entry):
        nonlocal missing, expanded_size
        if isinstance(entry, list):
            assert compact == 1, "reference in full response"
            assert len(entry) == 1 and isinstance(entry[0], bytes) and len(entry[0]) == 32, "encoding reference"
            encoded = cache.get(entry[0])
            if encoded is None:
                missing = True
                return None
            assert isinstance(encoded, bytes) and h(encoded) == entry[0], "encoding hash"
            assert len(rlp(entry)) < len(rlp(encoded)), "reference size"
            expanded_size += len(rlp(encoded)) - len(rlp(entry))
            assert expanded_size <= length, "wrapper length"
            return encoded
        return entry
    txs = [resolve(entry) for entry in item[0]]
    content = item[2]
    if item[1] == 2:
        assert isinstance(content, list) and len(content) == 3, "wrapper content"
        assert isinstance(content[2], list), "raw programs"
        programs = []
        for entry in content[2]:
            assert isinstance(entry, list) and len(entry) == 2, "raw program fields"
            programs.append([entry[0], resolve(entry[1])])
        content = content[:2] + [programs]
    if missing:
        return None
    result = [txs, item[1], content]
    assert len(rlp(result)) <= length, "wrapper length"
    return result


def check_wrapper_response(request_id, requested, announced_metadata, reply, compact=0, cache=None, verify=None):
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
        mode, length, deps_hash, txs_hash = announced_metadata[digest]
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
        if verify is not None:
            assert verify(item), "proof verification"
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
    # Repeated hashes/hints across modes are deliberate synthetic fixtures.
    announcement = describe(mode, pattern(size), h(b"dependency hint"), h(b"transaction hint"))
    return {
        "mode": mode,
        "size": size,
        "content_hash": announcement[2].hex(),
        "deps_hash": announcement[3].hex(),
        "txs_hash": announcement[4].hex(),
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

    # RLP prefix expansion makes the maximum entry 106 bytes in all three modes.
    assert MAX_WRAPPER_BYTES == SOFT_RESPONSE_LIMIT
    for mode in (0, 1, 2):
        assert len(rlp([mode, MAX_WRAPPER_BYTES, bytes(32), bytes(32), bytes(32)])) == 106

    # Announcement count, fields and strict hash ordering.
    announced = [[i % 2, MAX_WRAPPER_BYTES, uint(i + 1, 32), bytes(32), bytes(32)] for i in range(65)]
    check_announcements([[0, 1, bytes(32), bytes(32), bytes(32)]])
    check_announcements(announced[:64])
    expect_error("announcement count", check_announcements, [])
    expect_error("announcement count", check_announcements, announced)
    expect_error("announcement order", check_announcements, announced[:2][::-1])
    expect_error("announcement order", check_announcements, announced[:1] * 2)
    for length in (0, MAX_WRAPPER_BYTES + 1):
        expect_error("announcement length", check_announcements, [[0, length, bytes(32), bytes(32), bytes(32)]])
    for mode in (-1, 3, 256, b"\x01"):
        expect_error("announcement mode", check_announcements, [[mode, 1, bytes(32), bytes(32), bytes(32)]])
    expect_error("announcement hash", check_announcements, [[0, 1, bytes(31), bytes(32), bytes(32)]])
    expect_error("announcement fields", check_announcements, [[0, 1, bytes(32), b""]])
    expect_error("announcement fields", check_announcements, [[1, bytes(32)]])

    expect_error("announcement dependency hash", check_announcements,
                 [[0, 1, bytes(32), bytes(31), bytes(32)]])
    expect_error("announcement transaction hash", check_announcements,
                 [[0, 1, bytes(32), bytes(32), bytes(31)]])

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
    assert len(rlp(announced[:64])) == 6787
    assert len(rlp([max_id, 1, hashes[:32]])) == 1072

    # Complete envelopes are part of the canonical wrapper and its identity.
    mode2, mode0, mode1, blob_mode1 = wrapper_items().values()
    # Policies replace prior state; relay-only peers need no proving capability.
    verifier_ids = [key for key, _ in mode2[2][2]]
    assert not should_announce_raw(mode2, None)
    for proving in (0, 1):
        assert not should_announce_raw(mode2, [0, proving, [1], []])
        assert should_announce_raw(mode2, [0, proving, [1], verifier_ids])
        assert should_announce_raw(mode2, [1, proving, [1], []])
        assert not should_announce_raw(mode2, [0, proving, [1], [bytes(32)]])
        assert not should_announce_raw(mode2, [1, proving, [], []])
        assert not should_announce_raw(mode2, [1, proving, [2], []])
        assert not should_announce_raw(mode2, [0, proving, [2], verifier_ids])
        assert not should_announce_raw(mode2, [0, proving, [], verifier_ids])
    check_raw_policy([0, 1, list(range(64)), [uint(i, 32) for i in range(64)]])
    check_raw_policy([1, 0, [2**64 - 1], []])
    for bad in ([0], [0, []], [0, [], []], [0, 0, [], [], b"extra"]):
        expect_error("policy fields", check_raw_policy, bad)
    for flag in (-1, 2, b"", True):
        expect_error("policy flag", check_raw_policy, [flag, 0, [], []])
        expect_error("policy proving flag", check_raw_policy, [0, flag, [], []])
    expect_error("policy profile count", check_raw_policy, [1, 0, list(range(65)), []])
    expect_error("policy profile count", check_raw_policy, [1, 0, b"", []])
    for profile in (-1, 2**64, b"\x01", True):
        expect_error("policy profile id", check_raw_policy, [1, 0, [profile], []])
    for profiles in ([1, 1], [2, 1]):
        expect_error("policy profile order", check_raw_policy, [1, 0, profiles, []])
    expect_error("policy verifier count", check_raw_policy, [0, 0, [1], [uint(i, 32) for i in range(65)]])
    expect_error("policy verifier id", check_raw_policy, [0, 0, [1], [bytes(31)]])
    expect_error("policy verifier order", check_raw_policy, [0, 0, [1], verifier_ids * 2])
    expect_error("policy verifier order", check_raw_policy, [0, 0, [1], [uint(1, 32), uint(0, 32)]])
    expect_error("wildcard policy list", check_raw_policy, [1, 0, [1], verifier_ids])
    assert rlp([1, 1, [1], []]).hex() == "c50101c101c0"
    assert rlp([0, 0, [], []]).hex() == "c48080c0c0"
    for item in (mode0, mode1, blob_mode1, mode2):
        check_wrapper_shape(item)
        decoded = decode(rlp(item), strict=True)
        assert len(decoded) == 3 and decoded[0] == item[0]
        assert decoded[1] == uint(item[1], int(bool(item[1])))
        assert rlp(decoded) == rlp(item)
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
    items = [mode0, mode1, blob_mode1, mode2]
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
    wrong_length = {**metadata, requested[0]: (0, len(encoded[0]) + 1, *coverage(mode0))}
    expect_error("announced length", check_wrapper_response, 7, requested, wrong_length, reply_for(7, [mode0]))
    for i, item in enumerate(items):
        wrong_mode = {**metadata, requested[i]: (1 - item[1], len(encoded[i]), *coverage(item))}
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
    # Changing a scheme changes the wire digest, even if claim/key bytes match.
    changed_deps = [bytes(31) + b"\x11" + dep[32:] for dep in mode1[2][0]]
    changed_scheme = [mode1[0], 1, [changed_deps, mode1[2][1]]]
    assert coverage(changed_scheme)[0] != coverage(mode1)[0]
    # Different verifier outcomes cannot change hints over the same bytes.
    check_wrapper_response(7, requested, metadata, reply_for(7, [mode1]),
                           verify=lambda item: True)
    assert wrappers_response(7, encoded) == rlp(reply_for(7, items))

    # A full 32-hash request can be satisfied in one response for small wrappers.
    small_items = [[[transaction(i)], 0, mode0[2]] for i in range(32)]
    small = [rlp(item) for item in small_items]
    small_hashes = [h(body) for body in small]
    small_metadata = {h(body): metadata_for(item) for item, body in zip(small_items, small)}
    check_request(7, small_hashes, set(small_hashes))
    assert len(splice(7, small)) < SOFT_RESPONSE_LIMIT
    assert wrappers_response(7, small) == splice(7, small)
    check_wrapper_response(7, small_hashes, small_metadata, reply_for(7, small_items))

    # Byte-derived transaction count: no independent 4,096-envelope ceiling.
    many_envelopes = sorted((transaction(i) for i in range(4097)), key=transaction_hash)
    many = [many_envelopes, 1, mode1[2]]
    many_body = rlp(many)
    check_wrapper_response(7, [h(many_body)], {h(many_body): metadata_for(many)}, reply_for(7, [many]))

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

    # Compact transport preserves full identity, including blob metadata.
    for item in (mode0, mode1, blob_mode1, mode2):
        cache = {h(encoded): encoded for encoded in wrapper_encodings(item)}
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
    # Raw wrappers cannot establish or suppress proof-backed coverage.
    proven = [mode2[0], 1, [mode2[2][0], b"proof of alternative signatures"]]
    raw_hint = describe(2, rlp(mode2), *coverage(mode2))
    proof_hint = describe(1, rlp(proven), *coverage(proven))
    check_announcements([raw_hint])
    assert not may_skip_fetch(proof_hint, [mode2])
    assert may_skip_fetch(raw_hint, [proven])
    assert may_skip_fetch(raw_hint, [mode2])
    raw_deps, raw_witnesses, raw_programs = mode2[2]
    def with_raw(witnesses, programs=raw_programs):
        return [mode2[0], 2, [raw_deps, witnesses, programs]]
    expect_error("raw witness count", check_wrapper_shape, with_raw(raw_witnesses[:-1]))
    expect_error("raw witness count", check_wrapper_shape, with_raw(raw_witnesses + [b"extra"]))
    expect_error("raw native witness", check_wrapper_shape, with_raw([[b"bad"]] + raw_witnesses[1:]))
    expect_error("raw format id", check_wrapper_shape,
                 with_raw(raw_witnesses[:1] + [[bytes(31), 0, b"sig"]] + raw_witnesses[2:]))
    expect_error("raw witness fields", check_wrapper_shape,
                 with_raw(raw_witnesses[:1] + [[bytes(32), b"missing index"]] + raw_witnesses[2:]))
    expect_error("raw witness bytes", check_wrapper_shape,
                 with_raw(raw_witnesses[:1] + [[bytes(32), 0, []]] + raw_witnesses[2:]))
    expect_error("raw generic witness", check_wrapper_shape, [mode0[0], 2, mode0[2] + [[]]])
    # Witness decoding is program-judged, not transport validation.
    unknown = with_raw(raw_witnesses[:1] + [[bytes(32), 0, b"opaque"]] + raw_witnesses[2:])
    check_wrapper_shape(unknown)
    native_deps = [uint(LEANSPHINCS_SCHEME, 32) + uint(i, 32) + bytes(32) for i in range(17)]
    expect_error("raw native count", check_wrapper_shape,
                 [mode2[0], 2, [native_deps + raw_deps[1:], [b"sig"] * 17 + raw_witnesses[1:], raw_programs]])
    # Changed witness bytes leave coverage unchanged but change object identity.
    changed = with_raw(raw_witnesses[:1] + [[raw_witnesses[1][0], raw_witnesses[1][1], b"changed signature"]] + raw_witnesses[2:])
    assert coverage(changed) == coverage(mode2)
    assert h(rlp(changed)) != h(rlp(mode2))

    for index in (-1, len(mode2[0]), b"\x00", True):
        expect_error("raw transaction index", check_wrapper_shape,
                     with_raw(raw_witnesses[:1] + [[raw_witnesses[1][0], index, b"sig"]] + raw_witnesses[2:]))
    records = raw_records(mode2)
    assert len(records) == 2
    assert records[0][3] == consensus_envelope(mode2[0][0])
    assert records[1][3] == consensus_envelope(mode2[0][1])
    # Selecting another envelope changes context without duplicating its bytes.
    switched = with_raw(raw_witnesses[:1] + [[raw_witnesses[1][0], 1, raw_witnesses[1][2]]] + raw_witnesses[2:])
    assert raw_records(switched)[0][3] != records[0][3]
    assert raw_records(switched)[0][2] == records[0][2]
    blob_raw = [[blob_encoded], 2, [raw_deps, [raw_witnesses[0]] +
                [[w[0], 0, w[2]] for w in raw_witnesses[1:]], raw_programs]]
    check_wrapper_shape(blob_raw)
    assert all(record[3] == FRAME_TX_TYPE + rlp(blob[0]) for record in raw_records(blob_raw))

    # A supplied application proof needs neither raw data nor a program package.
    private_key = h(b"synthetic non-executable verifier")
    private_dep = uint(LEANSTARK_SCHEME, 32) + h(b"private claim") + private_key
    private_proof = rlp([9, b"synthetic singleton proof"])
    pairs = sorted(list(zip(raw_deps[:2], raw_witnesses[:2])) + [(private_dep, private_proof)])
    mixed_raw = mixed_wrapper(mode2)
    check_wrapper_shape(mixed_raw)
    assert should_announce_raw(mixed_raw, [0, 0, [1], verifier_ids])
    assert singleton_profile(private_proof) == 9
    assert len(raw_records(mixed_raw)) == 1
    all_proven = with_raw([raw_witnesses[0]] + [private_proof] * 2, [])
    expect_error("raw generic witness", check_wrapper_shape, all_proven)
    extra_dep = uint(LEANSTARK_SCHEME, 32) + h(b"another claim") + private_key
    excess_pairs = sorted(pairs + [(extra_dep, private_proof)])
    excess = [mode2[0], 2, [[d for d, _ in excess_pairs], [w for _, w in excess_pairs], raw_programs]]
    expect_error("supplied proof bound", check_wrapper_shape, excess)
    for witness in (b"", b"\xff", rlp([9]), rlp([9, b"proof", b"extra"])):
        expect_error("singleton proof encoding", singleton_profile, witness)
    for profile in (b"\x00", 2**64, []):
        expect_error("singleton profile id", singleton_profile, rlp([profile, b"proof"]))
    for proof in (b"", []):
        expect_error("singleton proof bytes", singleton_profile, rlp([9, proof]))
    # Mixed witnesses use the same complete/compact message and identity path.
    mixed_cache = {h(value): value for value in wrapper_encodings(mixed_raw)}
    mixed_digest = h(rlp(mixed_raw))
    mixed_meta = {mixed_digest: metadata_for(mixed_raw)}
    mixed_wire = compact_wrapper(mixed_raw, set(mixed_cache))
    assert check_wrapper_response(7, [mixed_digest], mixed_meta,
           [7, [[mixed_digest, mixed_wire]]], compact=1, cache=mixed_cache) == []

    # The table contains exactly the raw programs, shared within a wrapper.
    key, code = raw_programs[0]
    def with_program(package):
        identifier = leanvm_verifier_id(package)
        deps = [dep[:64] + identifier if dep[:32] == uint(LEANSTARK_SCHEME, 32) else dep for dep in raw_deps]
        return [mode2[0], 2, [deps, raw_witnesses, [[identifier, package]]]]
    code2 = rlp([2, b"synthetic batch module" * 3])
    key2 = leanvm_verifier_id(code2)
    assert leanvm_verifier_id(code) == key != key2 != h(code2)
    assert key != leanvm_verifier_id(rlp([1, b"different module"]))
    for programs in ([], raw_programs * 2, [[key2, code2]], sorted(raw_programs + [[key2, code2]])):
        expect_error("raw program set", check_wrapper_shape, with_raw(raw_witnesses, programs))
    expect_error("raw program hash", check_wrapper_shape, with_raw(raw_witnesses, [[bytes(32), code]]))
    expect_error("raw program fields", check_wrapper_shape, with_raw(raw_witnesses, [[key]]))
    expect_error("raw program id", check_wrapper_shape, with_raw(raw_witnesses, [[bytes(31), code]]))
    expect_error("raw program bytes", check_wrapper_shape, with_raw(raw_witnesses, [[key, [h(code)]]]))
    for malformed_code in (b"", b"\xff", rlp([1]), rlp([1, b"code", b"extra"])):
        expect_error("raw program package", check_wrapper_shape, with_raw(raw_witnesses, [[key, malformed_code]]))
    for version in (b"\x00", 2**64):
        expect_error("raw profile id", check_wrapper_shape,
                     with_raw(raw_witnesses, [[key, rlp([version, b"code"])]]))
    expect_error("raw program bytecode", check_wrapper_shape,
                 with_raw(raw_witnesses, [[key, rlp([1, []])]]))
    # Synthetic profile IDs share this fixture encoding; policy still filters them.
    unknown_profile = with_program(rlp([255, b"unknown profile"]))
    check_wrapper_shape(unknown_profile)
    # Unknown-profile derivations are not judged using leanVM hashing rules.
    foreign_id = bytes(32)
    foreign_deps = [d[:64] + foreign_id if d[:32] == uint(LEANSTARK_SCHEME, 32) else d
                    for d in raw_deps]
    check_wrapper_shape([mode2[0], 2, [foreign_deps, raw_witnesses, [[foreign_id, rlp([255, b"opaque"])]]]])
    assert not should_announce_raw(unknown_profile, [1, 0, [1], []])
    assert should_announce_raw(unknown_profile, [1, 0, [255], []])
    two_programs = [mode2[0], 2, [raw_deps[:2] + [raw_deps[2][:64] + key2],
                                raw_witnesses, sorted([[key2, code2], [key, code]])]]
    check_wrapper_shape(two_programs)
    assert not should_announce_raw(two_programs, [0, 0, [1, 2], [key]])
    assert not should_announce_raw(two_programs, [0, 0, [1], sorted([key, key2])])
    assert should_announce_raw(two_programs, [0, 0, [1, 2], sorted([key, key2])])
    assert not should_announce_raw(two_programs, [1, 0, [1], []])
    assert should_announce_raw(two_programs, [1, 0, [1, 2], []])
    expect_error("raw program set", check_wrapper_shape,
                 [two_programs[0], 2, two_programs[2][:2] + [two_programs[2][2][::-1]]])

    # Omission uses the plain encoding hash; program identity is domain-separated.
    code_cache = {h(code): code}
    raw_digest = h(rlp(mode2))
    raw_meta = {raw_digest: metadata_for(mode2)}
    code_compact = compact_wrapper(mode2, set(code_cache))
    assert code_compact[0] == mode2[0]
    assert code_compact[2][2] == [[key, [h(code)]]]
    assert compact_wrapper(mode2, {key}) == mode2
    code_reply = [7, [[raw_digest, code_compact]]]
    assert check_wrapper_response(7, [raw_digest], raw_meta, code_reply, 1, code_cache) == []
    assert check_wrapper_response(7, [raw_digest], raw_meta, code_reply, 1,
                                  {h(tx): tx for tx in mode2[0]}) == [raw_digest]
    expect_error("reference in full response", check_wrapper_response,
                 7, [raw_digest], raw_meta, code_reply, 0, code_cache)
    expect_error("encoding hash", check_wrapper_response,
                 7, [raw_digest], raw_meta, code_reply, 1, {h(code): code + b"changed"})
    malformed_program_ref = with_raw(raw_witnesses, [[key, [bytes(31)]]])
    expect_error("encoding reference", check_wrapper_response, 7, [raw_digest], raw_meta,
                 [7, [[raw_digest, malformed_program_ref]]], 1, code_cache)
    no_execution = []
    assert check_wrapper_response(7, [raw_digest], raw_meta, code_reply, compact=1,
                                  verify=lambda item: no_execution.append(item)) == [raw_digest]
    assert no_execution == []
    assert check_wrapper_response(8, [raw_digest], raw_meta, reply_for(8, [mode2])) == []
    changed_code = with_raw(raw_witnesses, [[key, rlp([1, b"other code"])]])
    assert coverage(changed_code) == coverage(mode2)
    expect_error("response hash", check_wrapper_response, 7, [raw_digest], raw_meta,
                 [7, [[raw_digest, changed_code]]])
    # Even with correct wrapper metadata, a false program ID fails before execution.
    changed_digest = h(rlp(changed_code))
    expect_error("raw program hash", check_wrapper_response, 7, [changed_digest],
                 {changed_digest: metadata_for(changed_code)}, reply_for(7, [changed_code]),
                 0, None, lambda item: no_execution.append(item))
    assert no_execution == []
    # Program bytes contribute to the reconstructed byte bound too.
    giant_code = rlp([1, bytes(MAX_WRAPPER_BYTES)])
    giant_program = with_program(giant_code)
    giant_compact = compact_wrapper(giant_program, {h(giant_code)})
    assert len(rlp(giant_compact)) < MAX_WRAPPER_BYTES
    expect_error("wrapper length", reconstruct, giant_compact, 1,
                 {h(giant_code): giant_code}, MAX_WRAPPER_BYTES)

    # Same consensus transaction hash does not identify the exact blob encoding.
    assert h(blob_encoded) != h(altered_blob)
    assert compact_wrapper([[blob_encoded], *mode1[1:]], {h(altered_blob)})[0] == [blob_encoded]
    # The compact byte count cannot bypass the canonical 2 MiB bound.
    compact_oversized = compact_wrapper(oversized, {h(tx) for tx in oversized[0]})
    assert len(rlp(compact_oversized)) < MAX_WRAPPER_BYTES
    expect_error("wrapper length", reconstruct, compact_oversized, 1,
                 {h(tx): tx for tx in oversized[0]}, MAX_WRAPPER_BYTES)

    print("PASS: announcement, full-envelope, raw-witness/program and sparse-blob wrapper encoding vectors; "
          "raw-policy routing, compact reconstruction and full retries, message counts, ordering, metadata matching, byte limits and response packing. "
          "Transaction/program execution, proof/KZG validity and client-state sequences are not tested.")


if __name__ == "__main__":
    main()
