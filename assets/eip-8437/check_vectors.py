#!/usr/bin/env python3
"""Pooled dependency-transaction encoding and wrapper translation vectors.

Requires pycryptodome and rlp. Synthetic witnesses and blob sidecars test bytes,
not signatures, proofs, KZG, execution, peer state or complete core validation.
Run: python3 assets/eip-8437/check_vectors.py
"""
import json
from hashlib import sha256
from pathlib import Path

from Crypto.Hash import keccak
from rlp import encode, decode

FRAME_TX_TYPE = b"\x06"
PROOF_FRAME_MODE = 4


def h(data):
    return keccak.new(digest_bits=256, data=data).digest()


def dependency(scheme, message, key):
    return bytes(31) + bytes([scheme]) + message + key


def payload(nonce, deps, commitments=()):
    return [1, nonce, bytes(20), [[4, 0, b"", [3000 * len(deps), 0], 0, b"".join(deps)]],
            [], [1000000, 1], [b"\x01" + sha256(c).digest()[1:] for c in commitments]]


def resolved_deps(body):
    # All fixtures have an empty signatures list, so EIP-8141's signature hash
    # equals the consensus hash. This is not a general compute_sig_hash.
    assert body[4] == [], "fixture signatures"
    sig_hash = h(FRAME_TX_TYPE + encode(body))
    out = []
    for frame in body[3]:
        if int.from_bytes(frame[0], 'big') != PROOF_FRAME_MODE:
            continue
        data = frame[5]
        assert len(data) > 0 and len(data) % 96 == 0, "dependency encoding"
        for i in range(0, len(data), 96):
            dep = data[i:i+96]
            assert dep[:31] == bytes(31), "scheme padding"
            if dep[32:64] == bytes(32):
                dep = dep[:32] + sig_hash + dep[64:]
            out.append(dep)
    return sorted(set(out))


def pooled(body, witnesses, sidecar=None):
    data = [body, witnesses] if sidecar is None else [body, *sidecar, witnesses]
    return FRAME_TX_TYPE + encode(data)


def unpack(data):
    assert isinstance(data, bytes) and data[:1] == FRAME_TX_TYPE, "transaction type"
    form = decode(data[1:], strict=True)
    assert isinstance(form, list) and len(form) in (2, 6), "pooled fields"
    body, witnesses = form[0], form[-1]
    assert isinstance(body, list) and len(body) == 7, "payload"
    assert isinstance(witnesses, list) and all(isinstance(w, bytes) for w in witnesses), "witness encoding"
    deps = resolved_deps(body)
    assert deps and len(deps) == len(witnesses), "witness count"
    if body[6]:
        assert len(form) == 6, "missing blob sidecar"
        version, blobs, commitments, proofs = form[1:5]
        assert version == b"\x01" and blobs == [], "blob form"
        assert len(commitments) == len(body[6]), "commitment count"
        assert all(len(c) == 48 for c in commitments), "commitment size"
        assert body[6] == [b"\x01" + sha256(c).digest()[1:] for c in commitments], "commitment hash"
        assert len(proofs) == 128 * len(commitments) and all(len(p) == 48 for p in proofs), "cell proofs"
        plain = FRAME_TX_TYPE + encode(form[:-1])
    else:
        assert len(form) == 2, "nonblob fields"
        plain = FRAME_TX_TYPE + encode(body)
    return body, deps, witnesses, plain


def transaction_hash(data):
    return h(FRAME_TX_TYPE + encode(unpack(data)[0]))


def wrap(data):
    _, deps, witnesses, plain = unpack(data)
    return [[plain], 0, [deps, witnesses]]


def unwrapped(wrapper):
    txs, mode, content = wrapper
    assert mode == 0, "direct witnesses required"
    deps, witnesses = content
    assert len(deps) == len(witnesses) and deps == sorted(set(deps)), "wrapper dependencies"
    mapping = dict(zip(deps, witnesses))
    output, union = [], set()
    for tx in txs:
        raw = decode(tx[1:], strict=True)
        body = raw[0] if len(raw) == 5 else raw
        own = resolved_deps(body)
        assert set(own) <= mapping.keys(), "missing dependency"
        union.update(own)
        selected = [mapping[d] for d in own]
        data = pooled(body, selected, raw[1:] if len(raw) == 5 else None)
        unpack(data)
        output.append(data)
    assert union == set(deps), "extra dependency"
    hashes = [transaction_hash(data) for data in output]
    assert hashes == sorted(set(hashes)), "wrapper transaction order"
    return output


def match_response(requested, returned, announced_sizes):
    position = 0
    for data in returned:
        digest = transaction_hash(data)
        assert digest in requested[position:], "response order"
        position = requested.index(digest, position) + 1
        if digest in announced_sizes:
            assert len(data) == announced_sizes[digest], "announced size"


def fixtures():
    a = dependency(0x10, bytes(32), bytes([1])*32)
    shared = dependency(0x10, h(b"shared explicit claim"), bytes([2])*32)
    # Repeated declarations deduplicate; witness order follows resolved bytes.
    tx = payload(1, [shared, a, shared])
    witnesses = [b"synthetic witness A", b"synthetic witness B"]
    commitments = [bytes([3])*48]
    blob = payload(2, [a], commitments)
    sidecar = [1, [], commitments, [bytes(48)]*128]
    return {
        "nonblob": pooled(tx, witnesses),
        "blob": pooled(blob, [b"synthetic blob witness"], sidecar),
        "unknown_scheme": pooled(payload(3, [dependency(0xfe, h(b"unknown"), bytes(32))]), [b"opaque witness"]),
        "shared": pooled(payload(4, [shared]), [b"synthetic shared witness"]),
    }


def vectors():
    return [{"name": name, "pooled_hex": data.hex(), "transaction_hash": transaction_hash(data).hex(),
             "size": len(data), "mode0_rlp": encode(wrap(data)).hex()}
            for name, data in fixtures().items()]


def reject(fn, *args):
    try:
        fn(*args)
    except (AssertionError, ValueError):
        return
    raise AssertionError("accepted invalid fixture")


def main():
    assert vectors() == json.loads(Path(__file__).with_name("pooled-vectors.json").read_text())
    f = fixtures()
    for data in f.values():
        assert unwrapped(wrap(data)) == [data]
        _, deps, witnesses, plain = unpack(data)
        assert len(deps) == len(witnesses)
        assert h(data) != transaction_hash(data)
        form = decode(data[1:], strict=True)
        for ws in (witnesses[:-1], witnesses + [b"extra"], [witnesses]):
            reject(unpack, FRAME_TX_TYPE + encode(form[:-1] + [ws]))
        reject(unpack, FRAME_TX_TYPE + encode(form + [b"extra"]))
        changed = FRAME_TX_TYPE + encode(form[:-1] + [[w + b"changed" for w in witnesses]])
        assert transaction_hash(data) == transaction_hash(changed)
        assert h(encode(wrap(data))) != h(encode(wrap(changed)))
        reject(match_response, [transaction_hash(data)], [changed], {transaction_hash(data): len(data)})
    assert len(unpack(f['nonblob'])[1]) == 2
    assert unpack(f['unknown_scheme'])[1][0][31] == 0xfe
    # A shared dependency needs one wrapper witness, but is duplicated when
    # translating back to independently verifiable pooled transactions.
    parts = [wrap(f['nonblob']), wrap(f['shared']), wrap(f['blob'])]
    all_deps = sorted({d for p in parts for d in p[2][0]})
    mapping = {d: w for p in parts for d, w in zip(*p[2])}
    canonical = []
    for name in ('nonblob', 'shared', 'blob'):
        data = f[name]; form = decode(data[1:], strict=True)
        canonical.append(FRAME_TX_TYPE + encode(form[:-1] + [[mapping[d] for d in unpack(data)[1]]]))
    canonical.sort(key=transaction_hash)
    merged = [[unpack(d)[3] for d in canonical], 0, [all_deps, [mapping[d] for d in all_deps]]]
    assert unwrapped(merged) == canonical
    reject(unwrapped, [merged[0], 1, [all_deps, b"recursive proof"]])
    requested = [transaction_hash(d) for d in canonical]
    sizes = {transaction_hash(d): len(d) for d in canonical}
    match_response(requested, canonical, sizes)
    match_response(requested, canonical[1:], sizes)
    reject(match_response, requested, canonical[::-1], sizes)
    reject(match_response, requested, canonical[:1]*2, sizes)
    # Existing eth messages carry the pooled bytes as typed transaction strings.
    assert decode(encode([7, canonical]), strict=True)[1] == canonical
    print("PASS: pooled forms, sidecar preservation, witness ordering/counts, consensus hashes, "
          "response matching and lossless mode 0 translation. Cryptographic validity and peer state are not tested.")


if __name__ == '__main__':
    main()
