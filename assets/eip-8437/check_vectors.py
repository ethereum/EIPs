#!/usr/bin/env python3
"""Check EIP-8437 content commitments and wire bounds, not proof validity.

Requires Python 3.9+ and pycryptodome. Run with:
    python3 assets/eip-8437/check_vectors.py
"""

import json
from pathlib import Path

from Crypto.Hash import keccak

CHUNK_BYTES = 65536
MAX_OBJECT_BYTES = 9437184
MAX_CHUNKS = (MAX_OBJECT_BYTES + CHUNK_BYTES - 1) // CHUNK_BYTES
MAX_MESSAGE_BYTES = 131072
MAX_ENVELOPE_RESPONSE_BYTES = 2097152
MAX_ENVELOPES_PER_REQUEST = 1024
MAX_TXS_PER_WRAPPER = 4096
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


def domain(name):
    return b"lean/1/" + name.encode("ascii") + b"\0"


def pattern(size):
    return (bytes(range(251)) * ((size + 250) // 251))[:size]


def commit(body, profile=bytes(32)):
    if not 1 <= len(body) <= MAX_OBJECT_BYTES:
        raise ValueError("object size")
    return [profile, len(body), h(body)]


def object_id(descriptor):
    return h(domain("object") + rlp(descriptor))


def encode_dep(scheme, data_hash, key):
    # EIP-8288 96-byte dependency encoding, after zero data_hash substitution.
    return bytes(31) + bytes([scheme]) + data_hash + key


def placeholder_deps_hash(encoded_deps):
    # Keccak-256 stands in for the fork's DEPS_HASH; only the encoding is normative.
    return h(b"".join(encoded_deps))


def wrapper_vectors():
    profile = h(domain("profile") + b"dummy AGGREGATED_VK")
    deps = sorted(encode_dep(LEANSPHINCS_SCHEME, h(b"message %d" % i), uint(i + 1, 32))
                  for i in range(2))
    hashes = sorted(h(b"transaction %d" % i) for i in range(2))
    bodies = {
        "mode0": rlp([hashes, 0, [deps, [b"witness 0", b"witness 1"]]]),
        "mode1": rlp([hashes, 1, [deps, b"aggregate proof"]]),
    }
    out = {
        "profile_vk": b"dummy AGGREGATED_VK".hex(),
        "profile_id": profile.hex(),
        "deps": [d.hex() for d in deps],
        "placeholder_deps_hash": placeholder_deps_hash(deps).hex(),
        "placeholder_empty_deps_hash": placeholder_deps_hash([]).hex(),
        "transactions": [x.hex() for x in hashes],
    }
    for name, body in bodies.items():
        descriptor = commit(body, profile)
        out[name] = {
            "body": body.hex(),
            "content_hash": descriptor[2].hex(),
            "object_id": object_id(descriptor).hex(),
        }
    return out


def envelope_response(request_id, envelopes):
    # Longest prefix of the requested envelopes that fits MAX_ENVELOPE_RESPONSE_BYTES.
    served = []
    for envelope in envelopes:
        if len(rlp([request_id, served + [envelope]])) > MAX_ENVELOPE_RESPONSE_BYTES:
            break
        served.append(envelope)
    if not served:
        raise ValueError("envelope does not fit alone")
    return rlp([request_id, served])


def vector(size):
    descriptor = commit(pattern(size))
    return {
        "size": size,
        "chunk_count": (size + CHUNK_BYTES - 1) // CHUNK_BYTES,
        "content_hash": descriptor[2].hex(),
        "descriptor_rlp": rlp(descriptor).hex(),
        "object_id": object_id(descriptor).hex(),
        "last_chunk_bytes": (size - 1) % CHUNK_BYTES + 1,
    }


def main():
    assert h(b"").hex() == "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    assert rlp(0) == b"\x80" and rlp([]) == b"\xc0"
    assert rlp(b"dog").hex() == "83646f67"
    vectors = json.loads(Path(__file__).with_name("commitment-vectors.json").read_text())
    for expected in vectors:
        assert vector(expected["size"]) == expected, expected["size"]
    wrappers = json.loads(Path(__file__).with_name("wrapper-vectors.json").read_text())
    assert wrapper_vectors() == wrappers

    sizes = (1, 65535, 65536, 65537, 131072, 131073, MAX_OBJECT_BYTES)
    for size in sizes:
        body = pattern(size)
        descriptor = commit(body)
        chunks = [body[i:i + CHUNK_BYTES] for i in range(0, size, CHUNK_BYTES)]
        assert 1 <= len(chunks) <= MAX_CHUNKS == 144
        assert all(len(c) == CHUNK_BYTES for c in chunks[:-1])
        assert len(chunks[-1]) == (size - 1) % CHUNK_BYTES + 1
        assert h(b"".join(chunks)) == descriptor[2]
        corrupted = [bytes([chunks[0][0] ^ 1]) + chunks[0][1:]] + chunks[1:]
        assert h(b"".join(corrupted)) != descriptor[2]
        # Every metadata field participates in object identity.
        for field, value in ((0, h(b"profile")), (1, size + 1), (2, bytes(32))):
            changed = list(descriptor)
            changed[field] = value
            assert object_id(changed) != object_id(descriptor)
    for body in (b"", bytes(MAX_OBJECT_BYTES + 1)):
        try:
            commit(body)
        except ValueError:
            pass
        else:
            raise AssertionError("accepted invalid object length")

    # Published request and chunk encodings.
    assert rlp([7]).hex() == "c107"
    assert rlp([7, bytes(32), [0, 2]]).hex() == "e507a0" + "00" * 32 + "c28002"
    assert rlp([7, bytes(32), 0, b"a"]).hex() == "e407a0" + "00" * 32 + "8061"
    largest_chunk = rlp([2**64 - 1, bytes(32), MAX_CHUNKS - 1, bytes(CHUNK_BYTES)])
    assert len(largest_chunk) < MAX_MESSAGE_BYTES
    descriptor = [bytes(32), MAX_OBJECT_BYTES, bytes(32)]
    assert len(rlp([descriptor] * 64)) < MAX_MESSAGE_BYTES

    # GetWrapperEnvelopes (0x06) and WrapperEnvelopes (0x07) encodings and bounds.
    assert rlp([7, bytes(32), [0, 2]]).hex() == "e507a0" + "00" * 32 + "c28002"
    assert rlp([7, [b"\x02\xc0"]]).hex() == "c507c38202c0"
    indices = list(range(MAX_TXS_PER_WRAPPER - MAX_ENVELOPES_PER_REQUEST, MAX_TXS_PER_WRAPPER))
    assert len(rlp([2**64 - 1, bytes(32), indices])) < MAX_MESSAGE_BYTES
    # Largest envelope that fits alone: the response is then exactly at the ceiling.
    largest = MAX_ENVELOPE_RESPONSE_BYTES - 21  # 9-byte request ID, three 4-byte headers
    assert len(envelope_response(2**64 - 1, [bytes(largest)])) == MAX_ENVELOPE_RESPONSE_BYTES
    try:
        envelope_response(2**64 - 1, [bytes(largest + 1)])
    except ValueError:
        pass
    else:
        raise AssertionError("served an envelope above the response ceiling")
    # Truncation keeps the longest fitting prefix; the requester re-requests the rest.
    envelopes = [bytes(600000)] * 4
    response = envelope_response(7, envelopes)
    assert len(response) <= MAX_ENVELOPE_RESPONSE_BYTES
    assert response == rlp([7, envelopes[:3]])
    assert envelope_response(7, envelopes[3:]) == rlp([7, envelopes[3:]])
    # A 64-bit byte_length bounds every canonical descriptor at 77 bytes.
    assert len(rlp([bytes(32), 2**64 - 1, bytes(32)])) == 77

    # The aggregate wrapper fits without embedding any transaction envelopes.
    hashes = [uint(i, 32) for i in range(4096)]
    deps = [bytes(31) + b"\x10" + uint(i, 32) + bytes(32) for i in range(4096)]
    maximum_wrapper = rlp([hashes, 1, [deps, bytes(8388608)]])
    assert len(maximum_wrapper) <= MAX_OBJECT_BYTES

    print(f"PASS: {len(vectors)} vectors, {len(sizes)} boundaries, identity mutations, "
          f"message bounds, envelope truncation, wrapper placeholders; maximum wrapper {len(maximum_wrapper)} bytes")


if __name__ == "__main__":
    main()
