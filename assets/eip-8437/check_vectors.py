#!/usr/bin/env python3
"""Check EIP-8437 announcements, message encodings and response limits, not proof validity.

Requires Python 3.9+ and pycryptodome. Run with:
    python3 assets/eip-8437/check_vectors.py
"""

import json
from pathlib import Path

from Crypto.Hash import keccak

SOFT_RESPONSE_LIMIT = 2097152
MAX_WRAPPER_BYTES = SOFT_RESPONSE_LIMIT
MAX_ANNOUNCEMENTS = 64
MAX_WRAPPERS_PER_REQUEST = 64
MAX_TXS_PER_WRAPPER = 4096
MAX_DEPS_PER_AGGREGATE_WRAPPER = 4096
LEANSPHINCS_SCHEME = 0x10


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


def describe(body):
    # Each NewProofWrapperHashes entry is [length, hash].
    if not 1 <= len(body) <= MAX_WRAPPER_BYTES:
        raise ValueError("wrapper size")
    return [len(body), h(body)]


def encode_dep(scheme, data_hash, key):
    # EIP-8288 96-byte dependency encoding, after zero data_hash substitution.
    return bytes(31) + bytes([scheme]) + data_hash + key


def placeholder_deps_hash(encoded_deps):
    # Keccak-256 stands in for the fork's DEPS_HASH; only the encoding is normative.
    return h(b"".join(encoded_deps))


def wrapper_vectors():
    deps = sorted(encode_dep(LEANSPHINCS_SCHEME, h(b"message %d" % i), uint(i + 1, 32))
                  for i in range(2))
    hashes = sorted(h(b"transaction %d" % i) for i in range(2))
    bodies = {
        "mode0": rlp([hashes, 0, [deps, [b"witness 0", b"witness 1"]]]),
        "mode1": rlp([hashes, 1, [deps, b"aggregate proof"]]),
    }
    out = {
        "deps": [d.hex() for d in deps],
        "placeholder_deps_hash": placeholder_deps_hash(deps).hex(),
        "placeholder_empty_deps_hash": placeholder_deps_hash([]).hex(),
        "transactions": [x.hex() for x in hashes],
    }
    for name, body in bodies.items():
        descriptor = describe(body)
        out[name] = {
            "body": body.hex(),
            "content_hash": descriptor[1].hex(),
            "descriptor_rlp": rlp(descriptor).hex(),
        }
    return out


def response(request_id, items):
    # Requested items in order: the first always, then stop before passing the soft limit.
    served = []
    for item in items:
        if served and len(rlp([request_id, served + [item]])) > SOFT_RESPONSE_LIMIT:
            break
        served.append(item)
    return rlp([request_id, served])


def check_envelopes(requested_hashes, envelopes):
    # PooledTransactions may omit entries, but may not repeat or reorder them.
    remaining = iter(requested_hashes)
    for envelope in envelopes:
        envelope_hash = h(envelope)
        if not any(requested == envelope_hash for requested in remaining):
            raise ValueError("unrequested or misordered envelope")


def wrappers_response(request_id, wrappers):
    # A wrapper is embedded as its RLP item: splice its exact bytes into the list.
    served = []
    for wrapper in wrappers:
        if served and len(splice(request_id, served + [wrapper])) > SOFT_RESPONSE_LIMIT:
            break
        served.append(wrapper)
    return splice(request_id, served)


def splice(request_id, encoded_items):
    return rlp_list(rlp(request_id) + rlp_list(b"".join(encoded_items)))


def rlp_list(payload):
    if len(payload) < 56:
        return bytes([0xc0 + len(payload)]) + payload
    size = uint(len(payload), (len(payload).bit_length() + 7) // 8)
    return bytes([0xf7 + len(size)]) + size + payload


def vector(size):
    descriptor = describe(pattern(size))
    return {
        "size": size,
        "content_hash": descriptor[1].hex(),
        "descriptor_rlp": rlp(descriptor).hex(),
    }


def expect_error(fn, *args):
    try:
        fn(*args)
    except (ValueError, AssertionError):
        return
    raise AssertionError("accepted invalid input")


def main():
    assert h(b"").hex() == "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    assert rlp(0) == b"\x80" and rlp([]) == b"\xc0"
    assert rlp(b"dog").hex() == "83646f67"
    vectors = json.loads(Path(__file__).with_name("announcement-vectors.json").read_text())
    for expected in vectors:
        assert vector(expected["size"]) == expected, expected["size"]
    wrappers = json.loads(Path(__file__).with_name("wrapper-vectors.json").read_text())
    assert wrapper_vectors() == wrappers

    for size in (1, 65536, 131073, MAX_WRAPPER_BYTES):
        # A one-byte change gives a different content hash, hence a different object.
        corrupted = bytes([pattern(size)[0] ^ 1]) + pattern(size)[1:]
        assert h(corrupted) != describe(pattern(size))[1]
    expect_error(describe, b"")
    expect_error(describe, bytes(MAX_WRAPPER_BYTES + 1))
    # A maximum-length descriptor encodes in 38 bytes.
    assert len(rlp([MAX_WRAPPER_BYTES, bytes(32)])) == 38

    # GetProofWrappers (0x17) and NewProofWrapperHashes (0x16) at their 64-entry limits.
    assert rlp([7, [bytes(32)]]).hex() == "e307e1a0" + "00" * 32
    max_id = 2**64 - 1
    announced = [[MAX_WRAPPER_BYTES, uint(i + 1, 32)] for i in range(MAX_ANNOUNCEMENTS)]
    requested_hashes = [uint(i + 1, 32) for i in range(MAX_WRAPPERS_PER_REQUEST)]
    assert len(rlp(announced)) == 2435
    assert len(rlp([max_id, requested_hashes])) == 2127

    # ProofWrappers (0x18): wrappers are embedded as RLP items, hashed as sent.
    mode1 = bytes.fromhex(wrappers["mode1"]["body"])
    assert wrappers_response(7, [mode1]) == bytes.fromhex("f9012407f90120") + mode1
    # A wrapper of exactly MAX_WRAPPER_BYTES is served alone: the first item is always included.
    hashes = [uint(i + 1, 32) for i in range(MAX_TXS_PER_WRAPPER)]
    deps = [bytes(31) + bytes([LEANSPHINCS_SCHEME]) + uint(i, 32) + bytes(32)
            for i in range(MAX_DEPS_PER_AGGREGATE_WRAPPER)]
    proof_room = MAX_WRAPPER_BYTES - len(rlp([hashes, 1, [deps, b""]]))
    while len(rlp([hashes, 1, [deps, bytes(proof_room)]])) > MAX_WRAPPER_BYTES:
        proof_room -= 1
    largest = rlp([hashes, 1, [deps, bytes(proof_room)]])
    assert len(largest) == MAX_WRAPPER_BYTES and proof_room == 1560555
    assert len(rlp(hashes)) + len(rlp(deps)) == 536584
    assert len(wrappers_response(max_id, [largest, mode1])) == MAX_WRAPPER_BYTES + 17
    # Responses stop before the wrapper that would pass the soft limit.
    medium = rlp([hashes[:1], 1, [deps[:1], bytes(600000)]])
    assert wrappers_response(7, [medium] * 4) == splice(7, [medium] * 3)

    # Existing PooledTransactions (0x0a) encoding for typed transaction envelopes.
    assert rlp([7, [b"\x02\xc0"]]).hex() == "c507c38202c0"
    assert len(response(max_id, [bytes(SOFT_RESPONSE_LIMIT)] * 2)) == SOFT_RESPONSE_LIMIT + 21
    envelopes = [bytes(600000)] * 4
    assert response(7, envelopes) == rlp([7, envelopes[:3]])
    assert response(7, envelopes[3:]) == rlp([7, envelopes[3:]])

    # Transport fixtures only: hashes bind envelope bytes independently of pool admission.
    a, b, c = [b"\x06" + rlp([i]) for i in range(3)]
    requested = [h(a), h(b), h(c)]
    check_envelopes(requested, [a, b, c])
    check_envelopes(requested, [a, c])  # Missing middle entry is allowed.
    check_envelopes(requested, [c])     # Missing prefix is allowed.
    check_envelopes(requested, [a])     # Truncated response is allowed.
    check_envelopes(requested, [])
    expect_error(check_envelopes, requested, [a, a])
    expect_error(check_envelopes, requested, [c, a])
    expect_error(check_envelopes, requested, [b"\x06\xc0"])
    expect_error(check_envelopes, requested, [a, b, c, a])

    print(f"PASS: {len(vectors)} vectors, content hashes, message encodings, response limits, "
          f"pooled-envelope matching, wrapper placeholders; proof room at list ceilings {proof_room} bytes")


if __name__ == "__main__":
    main()
