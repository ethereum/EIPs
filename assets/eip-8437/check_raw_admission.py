#!/usr/bin/env python3
"""Raw-admission wire vectors, signed-field bindings and policy checks.

No EVM execution, account validation, signature/STARK/KZG verification or
performance measurements. Fixture key hashes and gas limits do not define
cryptographic encodings or recommended limits. Run alongside check_vectors.py.
"""
import copy
import json
from pathlib import Path
import unittest
from unittest.mock import patch
import check_vectors as wire

h, rlp, decode = wire.h, wire.rlp, wire.decode
announcements = wire.check_announcements
NATIVE, GENERIC = 0x10, 0x11
MAX_DEPS, MAX_NATIVE, MAX_GENERIC_TX, MAX_SUPPLIED = 4096, 16, 2, 1
BASE_SHAPE, BASE_RECONSTRUCT = wire.check_wrapper_shape, wire.reconstruct
ALLOWED = ({0x00, 0x20, 0xf3, 0xfa, 0xfd}
           | set(range(0x01, 0x0c)) | set(range(0x10, 0x1f))
           | set(range(0x34, 0x3a)) | set(range(0x3d, 0x3f))
           | set(range(0x50, 0x54)) | set(range(0x56, 0x5c))
           | set(range(0x5e, 0xa0)))


def scalar(value):
    assert isinstance(value, bytes) and len(value) <= 8, 'integer width'
    assert not value.startswith(b'\x00'), 'integer canonical'
    return int.from_bytes(value, 'big')


def package_fields(package):
    assert isinstance(package, bytes), 'package bytes'
    fields = decode(package, strict=True)
    assert isinstance(fields, list) and len(fields) == 3, 'package fields'
    sandbox, gas, code = fields
    sandbox, gas = scalar(sandbox), scalar(gas)
    assert gas > 0 and isinstance(code, bytes) and code, 'package values'
    return sandbox, gas, code


def admission_id(package):
    return h(b'EIP8437:admission:v1' + package)


def consensus_body(tx):
    wire.transaction_hash(tx)  # Check the envelope and any blob metadata.
    payload = decode(tx[1:], strict=True)
    return payload[0] if len(payload) == 5 else payload


def consensus_tx(tx):
    return wire.FRAME_TX_TYPE + rlp(consensus_body(tx))


def sighash(tx):
    # EIP-8141's current signature hash commits elided signature lengths.
    body = copy.deepcopy(consensus_body(tx))
    for signature in body[4]:
        if signature[2] == b'':
            signature[3] = len(signature[3])
    return h(wire.FRAME_TX_TYPE + rlp(body))


def dependencies(tx):
    result = set()
    for frame in consensus_body(tx)[3]:
        assert isinstance(frame, list) and len(frame) == 6, 'frame shape'
        if scalar(frame[0]) != 4:
            continue
        data = frame[5]
        assert isinstance(data, bytes) and data and len(data) % 96 == 0, 'dependency frame'
        for i in range(0, len(data), 96):
            dep = data[i:i + 96]
            assert int.from_bytes(dep[:32], 'big') in (NATIVE, GENERIC), 'scheme'
            if dep[32:64] == bytes(32):
                dep = dep[:32] + sighash(tx) + dep[64:]
            result.add(dep)
    assert sum(int.from_bytes(d[:32], 'big') == NATIVE for d in result) <= MAX_NATIVE, 'native tx bound'
    assert sum(int.from_bytes(d[:32], 'big') == GENERIC for d in result) <= MAX_GENERIC_TX, 'generic tx bound'
    return result


def binding_id(tx, binding):
    _, frame_index, offset = binding
    body = consensus_body(tx)
    assert 0 <= frame_index < len(body[3]), 'frame index'
    frame = body[3][frame_index]
    assert scalar(frame[0]) == 1 and scalar(frame[1]) & 2, 'authorizing frame'
    assert frame[2] in (b'', body[2]), 'authorizing target'
    assert isinstance(frame[5], bytes) and offset + 32 <= len(frame[5]), 'commitment offset'
    return frame[5][offset:offset + 32]


def raw_shape(item):
    if item[1] != 2:
        return BASE_SHAPE(item)
    assert isinstance(item, list) and len(item) == 3, 'wrapper fields'
    txs, _, content = item
    assert isinstance(content, list) and len(content) == 3, 'raw content'
    deps, witnesses, programs = content
    BASE_SHAPE([txs, 1, [deps, b'proof shape placeholder']])
    assert len(rlp(item)) <= wire.MAX_WRAPPER_BYTES, 'wrapper bytes'
    assert len(deps) <= MAX_DEPS, 'dependency bound'
    declared = [dependencies(tx) for tx in txs]
    assert deps == sorted(set().union(*declared)), 'dependency union'
    assert isinstance(witnesses, list) and len(witnesses) == len(deps), 'witness count'
    assert isinstance(programs, list), 'program list'
    supplied = {}
    for entry in programs:
        assert isinstance(entry, list) and len(entry) == 2, 'program entry'
        identifier, package = entry
        assert isinstance(identifier, bytes) and len(identifier) == 32, 'program id'
        package_fields(package)
        assert admission_id(package) == identifier, 'program hash'
        assert identifier not in supplied, 'program duplicate'
        supplied[identifier] = package
    assert [entry[0] for entry in programs] == sorted(supplied), 'program order'
    raw_count = proof_count = native_count = 0
    used, pairs, contexts = set(), set(), []
    for dep, witness in zip(deps, witnesses):
        scheme = int.from_bytes(dep[:32], 'big')
        if scheme == NATIVE:
            native_count += 1
            assert isinstance(witness, bytes), 'native witness'
        elif isinstance(witness, bytes):
            # Plain leanSTARK proof bytes: cryptographic validation is not modeled.
            proof_count += 1
        else:
            raw_count += 1
            assert isinstance(witness, list) and len(witness) == 3, 'raw witness'
            fmt, data, bindings = witness
            assert isinstance(fmt, bytes) and len(fmt) == 32, 'format id'
            assert isinstance(data, bytes), 'witness bytes'
            assert isinstance(bindings, list) and bindings, 'bindings'
            indices, identifiers = [], []
            for binding in bindings:
                assert isinstance(binding, list) and len(binding) == 3, 'binding fields'
                assert all(type(n) is int and n >= 0 for n in binding), 'binding integers'
                tx_index = binding[0]
                assert tx_index < len(txs), 'transaction index'
                identifier = binding_id(txs[tx_index], binding)
                indices.append(tx_index)
                identifiers.append(identifier)
                contexts.append((fmt, data, consensus_tx(txs[tx_index]), dep[32:64], identifier))
            assert indices == [i for i, ds in enumerate(declared) if dep in ds], 'declaring transactions'
            assert len(set(identifiers)) == 1, 'shared program'
            assert identifiers[0] in supplied, 'missing program'
            used.add(identifiers[0])
            pairs.add((dep[64:], identifiers[0]))
    assert raw_count, 'raw witness required'
    assert native_count <= MAX_NATIVE and proof_count <= MAX_SUPPLIED, 'direct witness bound'
    assert set(supplied) == used, 'program set'
    return pairs, {package_fields(supplied[i])[0] for i in used}, contexts


def policy_shape(policy):
    assert isinstance(policy, list) and len(policy) == 4, 'policy fields'
    accept, proving, sandboxes, pairs = policy
    assert type(accept) is int and accept in (0, 1), 'accept flag'
    assert type(proving) is int and proving in (0, 1), 'proving flag'
    assert isinstance(sandboxes, list) and len(sandboxes) <= 64, 'sandbox count'
    assert all(type(n) is int and 0 <= n < 2**64 for n in sandboxes), 'sandbox id'
    assert sandboxes == sorted(set(sandboxes)), 'sandbox order'
    assert isinstance(pairs, list) and len(pairs) <= 64, 'pair count'
    assert all(isinstance(p, list) and len(p) == 2 and
               all(isinstance(n, bytes) and len(n) == 32 for n in p) for p in pairs), 'policy pair'
    assert pairs == sorted([list(p) for p in set(map(tuple, pairs))]), 'pair order'
    assert not accept or not pairs, 'wildcard pairs'


def should_announce(item, policy):
    if policy is None:
        return False
    policy_shape(policy)
    pairs, sandboxes, _ = raw_shape(item)
    return sandboxes <= set(policy[2]) and (policy[0] == 1 or pairs <= set(map(tuple, policy[3])))


def may_skip_fetch(announcement, held):
    eligible = [item for item in held if announcement[0] == 2 or item[1] != 2]
    return wire.may_skip_fetch(announcement, eligible)


def encodings(item):
    return item[0] + [package for _, package in item[2][2]]


def compact(item, delivered):
    def omit(value):
        ref = [h(value)]
        return ref if h(value) in delivered and len(rlp(ref)) < len(rlp(value)) else value
    return [[omit(tx) for tx in item[0]], 2,
            [*item[2][:2], [[identifier, omit(package)] for identifier, package in item[2][2]]]]


def reconstruct(item, flag, cache, length):
    if item[1] != 2:
        return BASE_RECONSTRUCT(item, flag, cache, length)
    assert 1 <= len(rlp(item)) <= length <= wire.MAX_WRAPPER_BYTES, 'wrapper length'
    result = copy.deepcopy(item)
    missing = False
    def resolve(value):
        nonlocal missing
        if not isinstance(value, list):
            return value
        assert flag == 1, 'reference in full response'
        assert len(value) == 1 and isinstance(value[0], bytes) and len(value[0]) == 32, 'reference'
        found = cache.get(value[0])
        if found is None:
            missing = True
            return value
        assert isinstance(found, bytes) and h(found) == value[0], 'encoding hash'
        assert len(rlp(value)) < len(rlp(found)), 'reference size'
        return found
    for i, tx in enumerate(result[0]):
        result[0][i] = resolve(tx)
        assert len(rlp(result)) <= length, 'wrapper length'
    for entry in result[2][2]:
        entry[1] = resolve(entry[1])
        assert len(rlp(result)) <= length, 'wrapper length'
    return None if missing else result


def abi_call(fmt, witness, tx):
    def dynamic(value):
        return wire.uint(len(value), 32) + value + bytes((-len(value)) % 32)
    w = dynamic(witness)
    return (h(b'check(bytes32,bytes,bytes)')[:4] + fmt + wire.uint(96, 32)
            + wire.uint(96 + len(w), 32) + w + dynamic(tx))


def fixture(shared=False, mixed=False, sandbox=1, gas=50000, code=None):
    # Illustrative runtime returns its first ABI word; it is not a signature checker.
    code = bytes.fromhex('6004355f5260205ff3') + bytes(64) if code is None else code
    package = rlp([sandbox, gas, code])
    identifier = admission_id(package)
    key_hash = h(b'opaque fixture verifier')
    generic = wire.uint(GENERIC, 32) + (h(b'shared claim') if shared else bytes(32)) + key_hash
    private = wire.uint(GENERIC, 32) + h(b'private claim') + h(b'private verifier')
    txs = []
    for nonce in range(2):
        ds = generic + (private if mixed else b'')
        frames = [[4, 0, b'', [30000, 0], 0, ds],
                  [1, 3, b'', [10000, 0], 0, b'\x12\x34\x56\x78' + identifier]]
        body = [1, nonce, bytes(20), frames, [], [1, 1], []]
        txs.append(wire.FRAME_TX_TYPE + rlp(body))
    txs.sort(key=wire.transaction_hash)
    per_tx = [dependencies(tx) for tx in txs]
    deps = sorted(set().union(*per_tx))
    witnesses = []
    for dep in deps:
        if dep == private:
            witnesses.append(b'opaque singleton proof')
        else:
            bindings = [[i, 1, 4] for i, ds in enumerate(per_tx) if dep in ds]
            witnesses.append([h(b'format'), b'raw assertion', bindings])
    return [txs, 2, [deps, witnesses, [[identifier, package]]]]


def vectors():
    result = {'note': 'Synthetic encoding/commitment fixtures; no cryptographic validity or gas calibration.'}
    for name, item in [('raw', fixture()), ('shared', fixture(shared=True)), ('mixed', fixture(mixed=True))]:
        pairs, _, contexts = raw_shape(item)
        body = rlp(item)
        announcement = [2, len(body), h(body), *wire.coverage(item)]
        policy = [0, 1, [1], sorted([list(pair) for pair in pairs])]
        result[name] = {
            'body': body.hex(), 'hash': h(body).hex(),
            'announcement': rlp(announcement).hex(), 'policy': rlp(policy).hex(),
            'full_response': rlp(wire.reply_for(8, [item])).hex(),
            'signature_hashes': [sighash(tx).hex() for tx in item[0]],
            'admission_ids': [entry[0].hex() for entry in item[2][2]],
            'check_calldata': [abi_call(fmt, witness, tx).hex() for fmt, witness, tx, _, _ in contexts],
            'expected_claims': [claim.hex() for _, _, _, claim, _ in contexts],
        }
        # A compact response still names the canonical full wrapper hash.
        result[name]['compact_response'] = rlp([7, [[h(body), compact(item, {h(e) for e in encodings(item)})]]]).hex()
    return result


class AdmissionTests(unittest.TestCase):
    def test_raw_announcements(self):
        item = fixture()
        body = rlp(item)
        entry = [2, len(body), h(body), *wire.coverage(item)]
        announcements([entry])
        entries = sorted([[2, len(body), h(bytes([i])), *wire.coverage(item)]
                          for i in range(64)], key=lambda e: e[2])
        announcements(entries)
        with self.assertRaises(AssertionError):
            announcements(entries + [entry])
        for mode in (3, -1, True):
            with self.assertRaises(AssertionError):
                announcements([[mode, *entry[1:]]])

    def test_vectors(self):
        expected = json.loads(Path(__file__).with_name('raw-admission-vectors.json').read_text())
        self.assertEqual(vectors(), expected)

    def test_commitment_changes_signing_hash(self):
        a, b = fixture(), fixture(code=b'\x00' * 100)
        self.assertNotEqual(set(map(sighash, a[0])), set(map(sighash, b[0])))
        raw_shape(a)
        raw_shape(b)
        changed = copy.deepcopy(a)
        changed[2][2][0][1] = b[2][2][0][1]
        with self.assertRaisesRegex(AssertionError, 'program hash'):
            raw_shape(changed)

    def test_initial_gas_is_authenticated(self):
        a, b = fixture(gas=50000), fixture(gas=50001)
        self.assertNotEqual(a[2][2][0][0], b[2][2][0][0])
        self.assertNotEqual(set(map(sighash, a[0])), set(map(sighash, b[0])))
        self.assertEqual(package_fields(a[2][2][0][1])[1], 50000)

    def test_signature_elision_keeps_calldata_commitment(self):
        body = consensus_body(fixture()[0][0])
        body[4] = [[b'', b'', b'', b'raw-signature']]
        tx = wire.FRAME_TX_TYPE + rlp(body)
        body[4][0][3] = b'other-witness'
        changed = wire.FRAME_TX_TYPE + rlp(body)
        self.assertEqual(sighash(tx), sighash(changed))
        body[4][0][3] += b'!'
        self.assertNotEqual(sighash(tx), sighash(wire.FRAME_TX_TYPE + rlp(body)))
        body[4][0][3] = b'raw-signature'
        body[3][1][5] = b'\x00' + body[3][1][5][1:]
        self.assertNotEqual(sighash(tx), sighash(wire.FRAME_TX_TYPE + rlp(body)))

    def test_static_binding_bounds(self):
        for binding in ([2, 1, 4], [0, 2, 4], [0, 0, 4], [0, 1, 5], [0, 1, -1]):
            item = fixture(shared=True)
            item[2][1][0][2][0] = binding
            with self.assertRaises((AssertionError, ValueError)):
                raw_shape(item)

    def test_all_declaring_transactions_must_bind(self):
        item = fixture(shared=True)
        self.assertEqual(len(item[2][1][0][2]), 2)
        for bindings in (item[2][1][0][2][:1], item[2][1][0][2][::-1],
                         item[2][1][0][2] * 2):
            altered = copy.deepcopy(item)
            altered[2][1][0][2] = bindings
            with self.assertRaisesRegex(AssertionError, 'declaring transactions'):
                raw_shape(altered)

    def test_mixed_proof_needs_no_program(self):
        item = fixture(mixed=True)
        pairs, sandboxes, _ = raw_shape(item)
        self.assertEqual(len(pairs), 1)
        self.assertEqual(sandboxes, {1})
        self.assertTrue(should_announce(item, [0, 0, [1], sorted(map(list, pairs))]))
        # Proof bytes are opaque to networking.
        i = next(i for i, w in enumerate(item[2][1]) if isinstance(w, bytes))
        self.assertEqual(item[2][1][i], b'opaque singleton proof')
        altered = copy.deepcopy(item)
        altered[2][1][i] = b'\xff\x00opaque proof'
        raw_shape(altered)
        for witness in (7, [7, b'proof']):
            altered = copy.deepcopy(item)
            altered[2][1][i] = witness
            with self.assertRaises(AssertionError):
                raw_shape(altered)

    def test_policy_pairs_and_proving_flag(self):
        item = fixture()
        pairs, _, _ = raw_shape(item)
        pairs = sorted(map(list, pairs))
        self.assertFalse(should_announce(item, None))
        for proving in (0, 1):
            self.assertTrue(should_announce(item, [0, proving, [1], pairs]))
            self.assertTrue(should_announce(item, [1, proving, [1], []]))
            self.assertFalse(should_announce(item, [0, proving, [1], []]))
            self.assertFalse(should_announce(item, [0, proving, [], pairs]))
        for policy in ([2, 0, [], []], [0, 2, [], []], [1, 0, [1], pairs],
                       [0, 0, [1, 1], []], [0, 0, [1], pairs * 2],
                       [0, 0, list(range(65)), []]):
            with self.assertRaises(AssertionError):
                policy_shape(policy)
        unknown = fixture(sandbox=255)
        self.assertFalse(should_announce(unknown, [1, 0, [1], []]))

    def test_raw_cannot_suppress_proof(self):
        item = fixture()
        proven = [item[0], 1, [item[2][0], b'proof']]
        ann = [1, len(rlp(proven)), h(rlp(proven)), *wire.coverage(proven)]
        self.assertFalse(may_skip_fetch(ann, [item]))
        self.assertTrue(may_skip_fetch([2, *ann[1:]], [proven]))

    def test_compact_reconstruction_and_retry(self):
        item = fixture()
        cache = {h(e): e for e in encodings(item)}
        compacted = compact(item, set(cache))
        size = len(rlp(item))
        self.assertEqual(reconstruct(compacted, 1, cache, size), item)
        self.assertIsNone(reconstruct(compacted, 1, {}, size))
        with self.assertRaisesRegex(AssertionError, 'reference in full response'):
            reconstruct(compacted, 0, cache, size)
        digest = h(rlp(item))
        with patch.object(wire, 'check_wrapper_shape', raw_shape), patch.object(wire, 'reconstruct', reconstruct):
            self.assertEqual(wire.check_wrapper_response(7, [digest], {digest: wire.metadata_for(item)},
                             [7, [[digest, compacted]]], 1, cache), [])
            self.assertEqual(wire.check_wrapper_response(7, [digest], {digest: wire.metadata_for(item)},
                             [7, [[digest, compacted]]], 1, {}), [digest])
            self.assertEqual(wire.check_wrapper_response(8, [digest], {digest: wire.metadata_for(item)},
                             [8, [[digest, item]]], 0), [])

    def test_compact_byte_cap(self):
        oversized = fixture(code=b'\x00' * wire.MAX_WRAPPER_BYTES)
        with patch(__name__ + '.package_fields') as inspect_code:
            with self.assertRaisesRegex(AssertionError, 'wrapper bytes'):
                raw_shape(oversized)
            inspect_code.assert_not_called()
        code = oversized[2][2][0][1]
        sparse = compact(oversized, {h(code)})
        with self.assertRaisesRegex(AssertionError, 'wrapper length'):
            reconstruct(sparse, 1, {h(code): code}, wire.MAX_WRAPPER_BYTES)

    def test_package_canonical_and_exact_set(self):
        for package in (rlp([1, 0, b'code']), rlp([b'\x00', 1, b'code']),
                        rlp([1, 1, b'']), rlp([1, 1, []]), rlp([1, 1, b'code', b'extra'])):
            with self.assertRaises(AssertionError):
                package_fields(package)
        for programs in ([], fixture()[2][2] * 2):
            item = fixture()
            item[2][2] = programs
            with self.assertRaises(AssertionError):
                raw_shape(item)

    def test_context_and_abi(self):
        item = fixture()
        _, _, contexts = raw_shape(item)
        fmt, witness, tx, claim, _ = contexts[0]
        data = abi_call(fmt, witness, tx)
        self.assertEqual(data[:4], h(b'check(bytes32,bytes,bytes)')[:4])
        self.assertEqual(data[4:36], fmt)
        self.assertEqual(int.from_bytes(data[36:68], 'big'), 96)
        self.assertEqual(claim, sighash(tx))
        blob = wire.FRAME_TX_TYPE + rlp(wire.blob_transaction())
        self.assertNotEqual(consensus_tx(blob), blob)
        self.assertEqual(h(consensus_tx(blob)), wire.transaction_hash(blob))

    def test_sandbox_opcode_filter(self):
        # This checks the allowed set, not interpreter enforcement or gas charging.
        for op in (0x54, 0x55, 0x5c, 0x5d, 0x30, 0x31, 0x32, 0x33,
                   0x3b, 0x3c, 0x3f, 0x40, 0x42, 0x48, 0x49, 0xa0, 0xaa,
                   0xb0, 0xf0, 0xf1, 0xf2, 0xf4, 0xf5, 0xff):
            self.assertNotIn(op, ALLOWED)
        for op in (0x1e, 0x20, 0x34, 0x35, 0x5a, 0x5e, 0xfa, 0xf3, 0xfd):
            self.assertIn(op, ALLOWED)


if __name__ == '__main__':
    unittest.main(verbosity=2)
