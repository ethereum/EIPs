#!/usr/bin/env python3
"""Check EIP-8437 encoding fixtures and message rules on decoded values.

Scalars are represented as Python integers. This is not an RLP decoder, proof
verifier or client-state test suite; see conformance.md for the coverage boundary.

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


def wrapper_items():
    deps = sorted(bytes(31) + bytes([LEANSPHINCS_SCHEME]) + h(b"message %d" % i) + uint(i + 1, 32)
                  for i in range(2))
    hashes = sorted(h(b"transaction %d" % i) for i in range(2))
    return {
        "mode0": [hashes, 0, [deps, [b"witness 0", b"witness 1"]]],
        "mode1": [hashes, 1, [deps, b"aggregate proof"]],
    }


def wrapper_vectors():
    items = wrapper_items()
    out = {
        "deps": [d.hex() for d in items["mode0"][2][0]],
        "transactions": [x.hex() for x in items["mode0"][0]],
    }
    for name, item in items.items():
        body = rlp(item)
        announcement = describe(body)
        out[name] = {
            "body": body.hex(),
            "content_hash": announcement[1].hex(),
            "announcement_rlp": rlp(announcement).hex(),
            "response_rlp": rlp([7, [item]]).hex(),
        }
    return out


def check_announcements(entries):
    assert 1 <= len(entries) <= MAX_ANNOUNCEMENTS, "announcement count"
    for entry in entries:
        assert isinstance(entry, list) and len(entry) == 2, "announcement fields"
        length, digest = entry
        assert isinstance(length, int) and 1 <= length <= MAX_WRAPPER_BYTES, "announcement length"
        assert isinstance(digest, bytes) and len(digest) == 32, "announcement hash"
    hashes = [entry[1] for entry in entries]
    assert hashes == sorted(set(hashes)), "announcement order"


def check_request(request_id, hashes, announced):
    assert isinstance(request_id, int) and 0 <= request_id < 2**64, "request id"
    assert 1 <= len(hashes) <= MAX_WRAPPERS_PER_REQUEST, "request count"
    assert all(isinstance(digest, bytes) and len(digest) == 32 for digest in hashes), "request hash"
    assert len(set(hashes)) == len(hashes), "request duplicates"
    assert all(digest in announced for digest in hashes), "unannounced wrapper"


def check_wrapper_response(request_id, requested, announced_lengths, reply):
    assert isinstance(reply, list) and len(reply) == 2, "response fields"
    assert reply[0] == request_id, "response id"
    assert isinstance(reply[1], list), "response fields"
    positions = {digest: i for i, digest in enumerate(requested)}
    previous = -1
    for item in reply[1]:
        assert isinstance(item, list), "embedded wrapper"
        body = rlp(item)
        assert 1 <= len(body) <= MAX_WRAPPER_BYTES, "wrapper length"
        digest = h(body)
        assert digest in positions, "response hash"
        assert positions[digest] > previous, "response order"
        assert len(body) == announced_lengths[digest], "announced length"
        previous = positions[digest]
    assert len(reply[1]) <= 1 or len(rlp(reply)) <= SOFT_RESPONSE_LIMIT, "response size"


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
    announcement = describe(pattern(size))
    return {
        "size": size,
        "content_hash": announcement[1].hex(),
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
    vectors = json.loads(Path(__file__).with_name("announcement-vectors.json").read_text())
    for expected in vectors:
        assert vector(expected["size"]) == expected, expected["size"]
    wrappers = json.loads(Path(__file__).with_name("wrapper-vectors.json").read_text())
    assert wrapper_vectors() == wrappers

    # A maximum-length announcement entry encodes in 38 bytes.
    assert len(rlp([MAX_WRAPPER_BYTES, bytes(32)])) == 38

    # A1-A4: announcement count, fields and strict hash ordering.
    announced = [[MAX_WRAPPER_BYTES, uint(i + 1, 32)] for i in range(65)]
    check_announcements([[1, bytes(32)]])
    check_announcements(announced[:64])
    expect_error("announcement count", check_announcements, [])
    expect_error("announcement count", check_announcements, announced)
    expect_error("announcement order", check_announcements, announced[:2][::-1])
    expect_error("announcement order", check_announcements, announced[:1] * 2)
    for length in (0, MAX_WRAPPER_BYTES + 1):
        expect_error("announcement length", check_announcements, [[length, bytes(32)]])
    expect_error("announcement hash", check_announcements, [[1, bytes(31)]])
    expect_error("announcement fields", check_announcements, [[1, bytes(32), b""]])

    # Q1-Q4: request bounds, uniqueness and prior wrapper announcements.
    assert rlp([7, [bytes(32)]]).hex() == "e307e1a0" + "00" * 32
    max_id = 2**64 - 1
    hashes = [entry[1] for entry in announced]
    check_request(max_id, hashes[:64], set(hashes))
    check_request(0, hashes[:2][::-1], set(hashes))  # Requests need not be sorted.
    expect_error("request id", check_request, 2**64, hashes[:1], set(hashes))
    expect_error("request count", check_request, 7, [], set(hashes))
    expect_error("request count", check_request, 7, hashes, set(hashes))
    expect_error("request duplicates", check_request, 7, hashes[:1] * 2, set(hashes))
    expect_error("request hash", check_request, 7, [bytes(31)], set(hashes))
    expect_error("unannounced wrapper", check_request, 7, [bytes(32)], set(hashes))
    assert len(rlp(announced[:64])) == 2435
    assert len(rlp([max_id, hashes[:64]])) == 2127

    # R1-R6: decoded response items, correlation, hashes, lengths and ordering.
    mode0, mode1 = wrapper_items().values()
    items = [mode0, mode1]
    encoded = [rlp(item) for item in items]
    requested = [h(body) for body in encoded]
    lengths = {h(body): len(body) for body in encoded}
    for returned in (items, items[:1], items[1:], []):
        check_wrapper_response(7, requested, lengths, [7, returned])
    expect_error("response id", check_wrapper_response, 7, requested, lengths, [8, items])
    expect_error("response fields", check_wrapper_response, 7, requested, lengths, [7, items, b""])
    expect_error("embedded wrapper", check_wrapper_response, 7, requested, lengths, [7, encoded])
    expect_error("response order", check_wrapper_response, 7, requested, lengths, [7, items[::-1]])
    expect_error("response order", check_wrapper_response, 7, requested, lengths, [7, [mode0, mode0]])
    altered = [mode1[0], 1, [mode1[2][0], b"aggregate proog"]]
    expect_error("response hash", check_wrapper_response, 7, requested, lengths, [7, [altered]])
    wrong_lengths = {**lengths, requested[0]: lengths[requested[0]] + 1}
    expect_error("announced length", check_wrapper_response, 7, requested, wrong_lengths, [7, [mode0]])
    assert wrappers_response(7, encoded) == rlp([7, items])
    assert wrappers_response(7, encoded[1:]).hex() == "f9012407f90120" + encoded[1].hex()

    # R7: three distinct fixtures with 1,000,000-byte synthetic proofs.
    # Each fits the companion's provisional 1,310,720-byte proof bound; none is a valid proof.
    large_items = [[mode1[0], 1, [mode1[2][0], bytes([i]) * 1_000_000]] for i in range(3)]
    large = [rlp(item) for item in large_items]
    assert all(len(body) <= MAX_WRAPPER_BYTES for body in large)
    assert len(splice(7, large[:2])) <= SOFT_RESPONSE_LIMIT < len(splice(7, large))
    assert wrappers_response(7, large) == splice(7, large[:2])
    large_hashes = [h(body) for body in large]
    large_lengths = {h(body): len(body) for body in large}
    check_wrapper_response(7, large_hashes, large_lengths, [7, large_items[:2]])
    expect_error("response size", check_wrapper_response, 7, large_hashes, large_lengths, [7, large_items])

    print("PASS: announcement and wrapper encoding vectors; A1-A4, Q1-Q4, R1-R7 transport checks. "
          "Proof validity and client-state sequences are not tested.")


if __name__ == "__main__":
    main()
