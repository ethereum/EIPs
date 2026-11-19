#!/usr/bin/env python3
# SPDX-License-Identifier: CC0-1.0
"""Reference implementation of CHUNKING_SCHEME_RS in EIP-8411.

compute_rs_chunks splits a serialized envelope and generates its parity.
reconstruct_rs recovers candidate envelope bytes from verified chunks.
Run python3 rs_scheme.py to check the code and scheme vectors (about 35 s).

rs_encode and rs_decode use the Leopard-RS layout and one parity chunk per
data chunk. Leopard-RS computes its values with the fast transform of Lin,
Al-Naffouri, Han and Chung, "Novel Polynomial Basis with Fast Fourier
Transform and Its Application to Reed-Solomon Erasure Codes", IEEE Trans.
Inf. Theory, 2016. This file computes the same values by Lagrange
interpolation, written for reading, not for speed. Its interpolation
routines also support P parity chunks for K data chunks when P >= K.

Let m be the least power of two at least P. Each symbol position has its
own polynomial of degree below m. Its value at point m + i is the symbol
from data chunk i for i < K and zero for K <= i < m. Its value at point j
gives the symbol in parity chunk j. Any K distinct chunks and the m - K
known zeros determine the polynomial. Field.element maps a point number
or a symbol to its field element.
"""
import hashlib
import random

# The scheme's constants, as in the EIP.
RS_CHUNK_SIZE = 2**14
LENGTH_PREFIX = 8
MAX_EXECUTION_PAYLOAD_CHUNKS = 2**11
RS_MAX_GF8_DATA_CHUNKS = 2**7
MAX_PAYLOAD_SIZE = 10 * 2**20  # the networking specification's limit on an uncompressed message

BASIS = {
    8: (0x11D, [1, 214, 152, 146, 86, 200, 88, 230]),
    16: (0x1002D, [0x0001, 0xACCA, 0x3C0E, 0x163E, 0xC582, 0xED2E, 0x914C, 0x4012,
                   0x6C98, 0x10D8, 0x6A72, 0xB900, 0xFDB8, 0xFB34, 0xFF38, 0x991E]),
}


class Field:
    """Store field elements as integers whose bit i is the coefficient of x^i."""

    def __init__(self, bits):
        self.bits, self.order = bits, 1 << bits
        self.poly, basis = BASIS[bits]
        self.exp, self.log = [0] * (2 * self.order), [0] * self.order
        x = 1
        for i in range(self.order - 1):  # x generates the multiplicative group for both polynomials
            self.exp[i], self.log[x] = x, i
            x <<= 1
            if x & self.order:
                x ^= self.poly
        for i in range(self.order - 1, 2 * self.order):
            self.exp[i] = self.exp[i - (self.order - 1)]
        # A number names the element that is the XOR of the basis elements at its set bits.
        self.element = [0] * self.order
        for v in range(self.order):
            e = 0
            for b in range(bits):
                if v >> b & 1:
                    e ^= basis[b]
            self.element[v] = e
        self.name = [0] * self.order
        for v, e in enumerate(self.element):
            self.name[e] = v

    def mul(self, a, b):
        return 0 if a == 0 or b == 0 else self.exp[self.log[a] + self.log[b]]

    def inv(self, a):
        return self.exp[self.order - 1 - self.log[a]]


FIELDS = {}


def field(bits):
    if bits not in FIELDS:
        FIELDS[bits] = Field(bits)
    return FIELDS[bits]


# Over GF(2^8), one byte names one symbol. Over GF(2^16), each 64-byte
# block holds 32 low bytes followed by the corresponding 32 high bytes.
# Collecting each half in its own byte plane lets us scale a whole chunk
# with byte lookups. XOR of the names adds the field elements they name.

def planes(bits, chunk):
    if bits == 8:
        return [chunk]
    return [b"".join(chunk[i + h:i + h + 32] for i in range(0, len(chunk), 64)) for h in (0, 32)]


def unplanes(bits, ps):
    if bits == 8:
        return ps[0]
    lo, hi = ps
    return b"".join(lo[i:i + 32] + hi[i:i + 32] for i in range(0, len(lo), 32))


def scale_tables(f, w):
    """tables[s][d][v] is output byte d after scaling by w.

    The input symbol has v in byte plane s and zero in any other plane.
    """
    tables = []
    for s in range(f.bits // 8):
        products = [f.name[f.mul(w, f.element[v << 8 * s])] for v in range(256)]
        tables.append([bytes((r >> 8 * d) & 0xFF for r in products) for d in range(f.bits // 8)])
    return tables


def lagrange_weights(f, xs):
    """A function giving, for a target point number t, the weights w_a with
    p(point t) = sum of w_a p(point xs[a]), for any p of degree below len(xs) (barycentric form)."""
    pts = [f.element[i] for i in xs]
    dens = []
    for a, xa in enumerate(pts):
        den = 1
        for b, xb in enumerate(pts):
            if a != b:
                den = f.mul(den, xa ^ xb)
        dens.append(den)

    def weights(t):
        x = f.element[t]
        if x in pts:
            return [1 if xa == x else 0 for xa in pts]
        whole = 1
        for xb in pts:
            whole = f.mul(whole, x ^ xb)
        return [f.mul(whole, f.inv(f.mul(x ^ xa, den))) for xa, den in zip(pts, dens)]

    return weights


def interpolate(bits, known, targets, length):
    """Evaluate the polynomial at each target, independently at each symbol position.

    known maps point numbers to chunks of length bytes, one per coefficient.
    The result maps each target point number to its chunk.
    """
    f = field(bits)
    xs = [x for x, c in known.items()]
    src = [planes(bits, c) for c in known.values()]
    nplanes = bits // 8
    weights = lagrange_weights(f, xs)
    out = {}
    for t in targets:
        acc = [0] * nplanes
        for w, ps in zip(weights(t), src):
            if w == 0:
                continue
            tables = scale_tables(f, w)
            for s in range(nplanes):
                for d in range(nplanes):
                    acc[d] ^= int.from_bytes(ps[s].translate(tables[s][d]), "little")
        n = length // nplanes
        out[t] = unplanes(bits, [a.to_bytes(n, "little") for a in acc])
    return out


def transform_size(parity):
    m = 1
    while m < parity:
        m <<= 1
    return m


def encode(bits, data, parity):
    """The parity chunks for data chunks of one length, a multiple of 64 bytes."""
    k, m, length = len(data), transform_size(parity), len(data[0])
    assert 0 < k <= parity and length % 64 == 0 and (bits == 16 or 2 * m <= 256)
    known = {m + i: data[i] for i in range(k)}
    known.update({m + i: bytes(length) for i in range(k, m)})
    values = interpolate(bits, known, range(parity), length)
    return [values[j] for j in range(parity)]


def decode(bits, chunks, k, parity):
    """Recover the k data chunks from indexed chunks. Indices below k hold data."""
    m = transform_size(parity)
    held = dict(sorted(chunks.items())[:k])
    assert len(held) == k
    length = len(next(iter(held.values())))
    known = {(m + i if i < k else i - k): c for i, c in held.items()}
    known.update({m + i: bytes(length) for i in range(k, m)})
    missing = [i for i in range(k) if i not in held]
    values = interpolate(bits, known, [m + i for i in missing], length)
    return [held[i] if i in held else values[m + i] for i in range(k)]


def compute_rs_data_chunk_count(length):
    return (LENGTH_PREFIX + length + RS_CHUNK_SIZE - 1) // RS_CHUNK_SIZE


def rs_field_bits(k):
    return 8 if k <= RS_MAX_GF8_DATA_CHUNKS else 16


def rs_encode(data_chunks):
    """Return one parity chunk per data chunk, in index order."""
    k = len(data_chunks)
    return encode(rs_field_bits(k), data_chunks, k)


def rs_decode(chunks, k):
    """Recover the k data chunks from any k distinct indices of a coded set."""
    return decode(rs_field_bits(k), chunks, k, k)


def compute_rs_chunks(serialized):
    """Prefix the serialized envelope with its length, pad, split and append parity."""
    if not 0 < len(serialized) <= MAX_PAYLOAD_SIZE:
        raise ValueError("the serialized envelope is empty or above MAX_PAYLOAD_SIZE")
    k = compute_rs_data_chunk_count(len(serialized))
    data = len(serialized).to_bytes(LENGTH_PREFIX, "little") + serialized
    data += bytes(k * RS_CHUNK_SIZE - len(data))
    chunks = [data[i * RS_CHUNK_SIZE:(i + 1) * RS_CHUNK_SIZE] for i in range(k)]
    return chunks + rs_encode(chunks)


def reconstruct_rs(chunks, chunk_count):
    """Recover candidate serialized bytes, or return None if either length check fails.

    chunks maps at least chunk_count // 2 indices to individually verified chunks
    of a valid RS descriptor. Before accepting the envelope, the caller must
    deserialize the bytes, derive the full descriptor and compare it with the bid.
    """
    k = chunk_count // 2
    data = b"".join(rs_decode(chunks, k))
    length = int.from_bytes(data[:LENGTH_PREFIX], "little")
    if not 0 < length <= MAX_PAYLOAD_SIZE or compute_rs_data_chunk_count(length) != k:
        return None
    return data[LENGTH_PREFIX:LENGTH_PREFIX + length]


def chunks_root(chunks):
    """Compute the SSZ vector root from chunk hashes followed by zero leaves."""
    layer = [hashlib.sha256(c).digest() for c in chunks]
    layer += [bytes(32)] * (MAX_EXECUTION_PAYLOAD_CHUNKS - len(layer))
    while len(layer) > 1:
        layer = [hashlib.sha256(layer[i] + layer[i + 1]).digest() for i in range(0, len(layer), 2)]
    return layer[0]


def formula_bytes(n):
    """The vectors' input: byte o is the top byte of (o + 1) * 2654435761 modulo 2^32."""
    return bytes(((o + 1) * 2654435761 & 0xFFFFFFFF) >> 24 for o in range(n))


# The code at small chunk sizes: (bits, data chunks, chunk length, parity chunks, SHA-256 of the
# parity chunks concatenated), for data chunks cut from formula_bytes(data chunks * chunk length).
# Computed with klauspost/reedsolomon v1.12.5's Leopard codecs.
CODE_VECTORS = [
    (16, 4, 64, 4, "249d92041b21c3689ab1bb66d675fb86d3e0f7af801a32b06875e1d7d0294460"),
    (8, 4, 64, 4, "6934c58c3cabc9c125d48e411e671e85f8eb6f0b47cd3737fe05d2af4bd88093"),
]

# The scheme: (length L of a synthetic serialized envelope, which is formula_bytes(L); chunk_count;
# chunks_root; SHA-256 of the parity chunks concatenated). Computed with klauspost/reedsolomon v1.12.5
# (reedsolomon.New(K, K, reedsolomon.WithLeopardGF(true))). The shapes: one data chunk; a few; the
# most over GF(2^8); the fewest over GF(2^16).
SCHEME_VECTORS = [
    (1, 2,
     "5fde95771263a8154b5a4aba0e029fb51a6c3e848eefea00b6affe1cdf5f8023",
     "4d9883b039c325c3d35bbc970cf7c6d4e40c0b11fbd141259f9a506104c200cb"),
    (100000, 14,
     "2adf8c2fd5d248d8de7fd35ef60ff886ac6973e811edfe2118de31aab5124c66",
     "63f0ae9c76b2229a6ead3b8ee53aee115c783d663ebaf1dfb82a3fa9f3e4912c"),
    (2097144, 256,
     "7e755ea8b9cdff73100a7e69a55c66b4ab8ba6b6bd184ec39fbaa64909eb3696",
     "13353f226384de2616b4aa041b2a76efcd77b7e47bec8b31c8f421986f3c09e9"),
    (2097145, 258,
     "43d112f538c02d9a8763263df616fbc5d31a32cc5f73ba203a8b4e6f00df6af6",
     "0d5ec456cc3e65e00b651355e28b4a80087924192007af1a5d2b038cb436e2e0"),
]


def check_code_vectors():
    for bits, k, size, parity, want in CODE_VECTORS:
        payload = formula_bytes(k * size)
        data = [payload[i * size:(i + 1) * size] for i in range(k)]
        got = hashlib.sha256(b"".join(encode(bits, data, parity))).hexdigest()
        assert got == want, f"GF(2^{bits}) {k}+{parity}: parity {got}, want {want}"
        print(f"code: GF(2^{bits}), {k} + {parity} chunks of {size} bytes: as the vector")


def check_scheme_vectors():
    rng = random.Random(1)
    for length, count, root, parity_hash in SCHEME_VECTORS:
        serialized = formula_bytes(length)
        chunks = compute_rs_chunks(serialized)
        k = count // 2
        assert len(chunks) == count, (length, len(chunks), count)
        assert all(len(c) == RS_CHUNK_SIZE for c in chunks)
        assert chunks_root(chunks).hex() == root, (length, chunks_root(chunks).hex())
        assert hashlib.sha256(b"".join(chunks[k:])).hexdigest() == parity_hash
        for held in (range(k, count), rng.sample(range(count), k)):
            assert reconstruct_rs({i: chunks[i] for i in held}, count) == serialized
        # A committed set with a parity chunk altered: the check after reconstruction fails, from a
        # half that holds the altered chunk and from the data chunks alone.
        altered = dict(enumerate(chunks))
        altered[k] = bytes([altered[k][0] ^ 1]) + altered[k][1:]
        committed = chunks_root([altered[i] for i in range(count)])
        for held in ([k] + list(range(1, k)), range(k)):
            back = reconstruct_rs({i: altered[i] for i in held}, count)
            assert back is None or chunks_root(compute_rs_chunks(back)) != committed
        print(f"scheme: {length} bytes, {k} + {k} chunks over GF(2^{rs_field_bits(k)}): as the vector; "
              f"decoded from parity alone and from a random half; an altered parity chunk fails the check")


if __name__ == "__main__":
    check_code_vectors()
    check_scheme_vectors()
    print("ok")
