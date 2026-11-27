"""Synthetic encoding helpers for EIP-8518 vectors; no execution or proof checks."""
from hashlib import sha256
from Crypto.Hash import keccak
from rlp import decode

SOFT_RESPONSE_LIMIT = 2**21
FRAME_TX_TYPE = b"\x06"
CELLS_PER_EXT_BLOB = 128
SYNTHETIC_FRAME_GAS = 100000

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

def check_claims(serving_peer, item, claims, expected):
    # Metadata is kept per peer: the wrapper is checked against its serving
    # peer's claim, and other peers' claims found false count against them.
    assert claims[serving_peer] == expected(item), "announced transaction metadata"
    return sorted(peer for peer, claim in claims.items() if claim != expected(item))

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
