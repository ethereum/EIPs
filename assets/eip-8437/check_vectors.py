#!/usr/bin/env python3
"""Check EIP-8437 transport commitments, not EIP-8288 proof validity.

Requires Python 3.9+ and pycryptodome. Run with:
    python3 assets/eip-8437/check_vectors.py
"""

import json
from pathlib import Path

from Crypto.Hash import keccak


CHUNK_BYTES = 65536
MAX_OBJECT_BYTES = 67108864


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


def tree_levels(leaves):
    levels = [leaves]
    while len(levels[-1]) > 1:
        level = len(levels) - 1
        nodes = levels[-1]
        levels.append([
            h(domain("node") + uint(level, 1) + nodes[i] + nodes[i + 1])
            for i in range(0, len(nodes), 2)
        ])
    return levels


def commit(body, kind=1, profile=bytes(32), context=None):
    if not 1 <= len(body) <= MAX_OBJECT_BYTES:
        raise ValueError("object size")
    if context is None:
        context = []
    count = (len(body) + CHUNK_BYTES - 1) // CHUNK_BYTES
    width = 1 << (count - 1).bit_length()
    content_hash = h(body)
    context_hash = h(domain("context") + rlp(context))
    scope = (uint(kind, 1) + profile + context_hash + content_hash
             + uint(len(body), 8) + uint(count, 4))
    leaves = []
    for index in range(width):
        if index < count:
            chunk = body[index * CHUNK_BYTES:(index + 1) * CHUNK_BYTES]
            leaf = h(domain("leaf") + scope + uint(index, 4)
                     + uint(len(chunk), 4) + chunk)
        else:
            leaf = h(domain("empty") + scope + uint(index, 4))
        leaves.append(leaf)
    levels = tree_levels(leaves)
    root = h(domain("root") + scope + levels[-1][0])
    descriptor = [kind, profile, context, len(body), content_hash, root]
    return descriptor, scope, levels


def branch_at(levels, index):
    return [nodes[(index >> level) ^ 1]
            for level, nodes in enumerate(levels[:-1])]


def check_branch(descriptor, scope, index, chunk, branch):
    size = descriptor[3]
    count = (size + CHUNK_BYTES - 1) // CHUNK_BYTES
    if not 0 <= index < count or len(branch) != (count - 1).bit_length():
        return False
    if len(chunk) != min(CHUNK_BYTES, size - index * CHUNK_BYTES):
        return False
    if any(len(sibling) != 32 for sibling in branch):
        return False
    current = h(domain("leaf") + scope + uint(index, 4)
                + uint(len(chunk), 4) + chunk)
    for level, sibling in enumerate(branch):
        sibling_start = ((index >> level) ^ 1) << level
        if sibling_start >= count:
            empty_leaves = [h(domain("empty") + scope + uint(i, 4))
                            for i in range(sibling_start, sibling_start + (1 << level))]
            if sibling != tree_levels(empty_leaves)[-1][0]:
                return False
        left, right = ((sibling, current) if index & (1 << level)
                       else (current, sibling))
        current = h(domain("node") + uint(level, 1) + left + right)
    return h(domain("root") + scope + current) == descriptor[5]


def vector(size):
    body = pattern(size)
    descriptor, scope, levels = commit(body)
    count = (size + CHUNK_BYTES - 1) // CHUNK_BYTES
    return {
        "size": size,
        "chunk_count": count,
        "content_hash": descriptor[4].hex(),
        "context_hash": h(domain("context") + rlp([])).hex(),
        "last_leaf": levels[0][count - 1].hex(),
        "padding_leaf": levels[0][count].hex() if count < len(levels[0]) else None,
        "chunk_root": descriptor[5].hex(),
        "object_id": h(domain("object") + rlp(descriptor)).hex(),
        "last_index": count - 1,
        "branch": [node.hex() for node in branch_at(levels, count - 1)],
    }


def main():
    # Anchor the hash primitive and RLP encoding independently of the vectors.
    assert h(b"").hex() == "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
    assert rlp(0) == b"\x80" and rlp([]) == b"\xc0"
    assert rlp(b"dog").hex() == "83646f67"
    vectors = json.loads(Path(__file__).with_name("commitment-vectors.json").read_text())
    for expected in vectors:
        assert vector(expected["size"]) == expected, expected["size"]

    # Exercise both sides of chunk/tree boundaries, including maximum geometry.
    sizes = (1, 65535, 65536, 65537, 131072, 131073, 262145, MAX_OBJECT_BYTES)
    for size in sizes:
        body = pattern(size)
        descriptor, scope, levels = commit(body)
        count = (size + CHUNK_BYTES - 1) // CHUNK_BYTES
        assert len(rlp(descriptor)) <= 512
        for index in sorted({0, count // 2, count - 1}):
            chunk = body[index * CHUNK_BYTES:(index + 1) * CHUNK_BYTES]
            branch = branch_at(levels, index)
            assert check_branch(descriptor, scope, index, chunk, branch)
            assert not check_branch(descriptor, scope, count, chunk, branch)
            assert not check_branch(descriptor, scope, index, chunk[:-1], branch)
            changed = bytes([chunk[0] ^ 1]) + chunk[1:]
            assert not check_branch(descriptor, scope, index, changed, branch)
            assert not check_branch(descriptor, scope, index, chunk, branch + [bytes(32)])
            if branch:
                bad = [bytes([branch[0][0] ^ 1]) + branch[0][1:]] + branch[1:]
                assert not check_branch(descriptor, scope, index, chunk, bad)
        # Bind kind, profile, context, content hash, length and chunk count.
        index = count - 1
        chunk = body[index * CHUNK_BYTES:]
        branch = branch_at(levels, index)
        for position in (0, 1, 33, 65, 97, 105):
            changed = scope[:position] + bytes([scope[position] ^ 1]) + scope[position + 1:]
            assert not check_branch(descriptor, changed, index, chunk, branch)
        if count < len(levels[0]):
            # Even a branch matching an attacker-chosen root must use canonical padding.
            leaves = list(levels[0])
            leaves[count] = bytes(32)
            altered_levels = tree_levels(leaves)
            altered_descriptor = list(descriptor)
            altered_descriptor[5] = h(domain("root") + scope + altered_levels[-1][0])
            assert not check_branch(altered_descriptor, scope, index, chunk,
                                    branch_at(altered_levels, index))
    try:
        commit(b"")
        raise AssertionError("accepted empty object")
    except ValueError:
        pass

    object_id = bytes.fromhex(next(v["object_id"] for v in vectors if v["size"] == 131073))
    assert rlp([7, object_id, [0, 2]]).hex() == (
        "e507a0f0d141fc8ee27459e661bd8459f51199967afdcb76b0155459b660954be94fe2c28002")
    assert rlp([7]).hex() == "c107"
    assert rlp([[[0, bytes.fromhex("7f00")]], 0, [[], []]]).hex() == "cac5c480827f0080c2c0c0"

    # Maximum legal Chunk and announcement sizes fit the capability ceiling.
    largest_chunk = rlp([2**64 - 1, bytes(32), 1023, bytes(CHUNK_BYTES), [bytes(32)] * 10])
    assert len(largest_chunk) < 131072
    context = [bytes(32), 2**64 - 1, bytes(32), bytes(32), bytes(32)]
    descriptor = [2, bytes(32), context, MAX_OBJECT_BYTES, bytes(32), bytes(32)]
    assert len(rlp(descriptor)) <= 512
    assert len(rlp([descriptor] * 64)) < 131072

    # Synthetic header checks only the skeleton algorithm, not a fork's schema.
    fields = [bytes(32), 42, bytes(32), [b"proof", bytes(32)], b"extra"]
    encodings = [rlp(field) for field in fields]
    encodings[3] = b""
    skeleton = [3, encodings]
    skeleton_hash = h(domain("skeleton") + rlp(skeleton))
    restored = list(encodings)
    restored[3] = rlp([b"proof", bytes(32)])
    payload = b"".join(restored)
    canonical = rlp(fields)
    length = uint(len(payload), (len(payload).bit_length() + 7) // 8)
    prefix = (bytes([0xc0 + len(payload)]) if len(payload) < 56
              else bytes([0xf7 + len(length)]) + length)
    reconstructed = prefix + payload
    assert reconstructed == canonical
    assert h(rlp(restored)) != h(canonical), "double encoding must change the header hash"
    encodings[1] = rlp(43)
    assert h(domain("skeleton") + rlp(skeleton)) != skeleton_hash
    fields[1] = 43
    assert h(rlp(fields)) != h(reconstructed)
    print(f"PASS: {len(vectors)} published vectors; {len(sizes)} boundary sizes; "
          f"tampering, message encodings and header reconstruction; maximum Chunk {len(largest_chunk)} bytes")


if __name__ == "__main__":
    main()
