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


def commit(body, kind=1, profile=bytes(32), context=None):
    if not 1 <= len(body) <= MAX_OBJECT_BYTES:
        raise ValueError("object size")
    if context is None:
        context = []
    return [kind, profile, context, len(body), h(body)]


def object_id(descriptor):
    return h(domain("object") + rlp(descriptor))


def vector(size):
    descriptor = commit(pattern(size))
    return {
        "size": size,
        "chunk_count": (size + CHUNK_BYTES - 1) // CHUNK_BYTES,
        "content_hash": descriptor[4].hex(),
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

    sizes = (1, 65535, 65536, 65537, 131072, 131073, MAX_OBJECT_BYTES)
    for size in sizes:
        body = pattern(size)
        descriptor = commit(body)
        chunks = [body[i:i + CHUNK_BYTES] for i in range(0, size, CHUNK_BYTES)]
        assert 1 <= len(chunks) <= 144
        assert all(len(c) == CHUNK_BYTES for c in chunks[:-1])
        assert len(chunks[-1]) == (size - 1) % CHUNK_BYTES + 1
        assert h(b"".join(chunks)) == descriptor[4]
        corrupted = [bytes([chunks[0][0] ^ 1]) + chunks[0][1:]] + chunks[1:]
        assert h(b"".join(corrupted)) != descriptor[4]
        # Every metadata field participates in object identity.
        for field, value in ((0, 2), (1, h(b"profile")), (2, [h(b"block")]),
                             (3, size + 1), (4, bytes(32))):
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

    # Published wire values include a request-ID gap and no Merkle branch.
    assert rlp([7]).hex() == "c107"
    assert rlp([7, bytes(32), [0, 2]]).hex() == "e507a0" + "00" * 32 + "c28002"
    assert rlp([7, bytes(32), 0, b"a"]).hex() == "e407a0" + "00" * 32 + "8061"
    largest_chunk = rlp([2**64 - 1, bytes(32), 143, bytes(CHUNK_BYTES)])
    assert len(largest_chunk) < 131072
    descriptor = [1, bytes(32), [], MAX_OBJECT_BYTES, bytes(32)]
    assert len(rlp(descriptor)) <= 256
    assert len(rlp([descriptor] * 64)) < 131072

    # The aggregate wrapper fits without embedding any transaction envelopes.
    hashes = [uint(i, 32) for i in range(4096)]
    deps = [bytes(31) + b"\x10" + uint(i, 32) + bytes(32) for i in range(4096)]
    maximum_wrapper = rlp([hashes, 1, [deps, bytes(8388608)]])
    assert len(maximum_wrapper) <= MAX_OBJECT_BYTES

    print(f"PASS: {len(vectors)} vectors, {len(sizes)} boundaries, identity mutations, "
          f"message bounds; maximum wrapper {len(maximum_wrapper)} bytes")


if __name__ == "__main__":
    main()
