import random
import timeit

random.seed(0)
coeffs = [random.randint(0, 2**10) for _ in range(256)]

"""
Implementation of bitpacking of various polynomials
following section 5.2 of the Dilithium specification

https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf
"""


def bit_pack_t1_old(coeffs):
    packed_bytes = []
    lim = 256 // 4
    for i in range(lim):
        packed_bytes.append((coeffs[4 * i + 0] >> 0) % 256)
        packed_bytes.append(((coeffs[4 * i + 0] >> 8) | (coeffs[4 * i + 1] << 2)) % 256)
        packed_bytes.append(((coeffs[4 * i + 1] >> 6) | (coeffs[4 * i + 2] << 4)) % 256)
        packed_bytes.append(((coeffs[4 * i + 2] >> 4) | (coeffs[4 * i + 3] << 6)) % 256)
        packed_bytes.append((coeffs[4 * i + 3] >> 2) % 256)
    return bytes(packed_bytes)


def bit_pack_1(coeffs):
    """
    Takes the coefficients of the polynomial and packs them
    as `n_bits` length bit strings
    """
    s = "".join(bin(c)[2:].zfill(10) for c in coeffs[::-1])
    return int(s, 2).to_bytes((len(s) + 7) // 8, byteorder="little")


def bit_pack_2(coeffs):
    r = 0
    for c in reversed(coeffs):
        r <<= 10
        r |= c
    return r.to_bytes(320, "little")


assert bit_pack_1(coeffs) == bit_pack_2(coeffs)


def bit_unpack_1(input_bytes):
    bytes_int = int.from_bytes(input_bytes, "little")
    s = bin(bytes_int)[2:].zfill(8 * len(input_bytes))
    coefficients = [int(s[i : i + 10], 2) for i in range(0, len(s), 10)][::-1]
    return coefficients


def bit_unpack_2(input_bytes):
    r = int.from_bytes(input_bytes, "little")
    mask = (1 << 10) - 1
    coefficients = []
    for _ in range(256):
        coefficients.append(r & mask)
        r >>= 10
    return coefficients


def bit_unpack_3(input_bytes):
    r = int.from_bytes(input_bytes, "little")
    mask = (1 << 10) - 1
    return [(r >> 10 * i) & mask for i in range(256)]


packed = bit_pack_2(coeffs)
assert coeffs == bit_unpack_1(packed)
assert coeffs == bit_unpack_2(packed)
assert coeffs == bit_unpack_3(packed)

print("Packing with binary strings")
print(timeit.timeit("bit_pack_1(coeffs)", globals=globals(), number=10_000))
print("Packing with bitshifts")
print(timeit.timeit("bit_pack_2(coeffs)", globals=globals(), number=10_000))

print("Unpacking with binary strings")
print(timeit.timeit("bit_unpack_1(packed)", globals=globals(), number=10_000))
print("Unpacking with bitshifts")
print(timeit.timeit("bit_unpack_2(packed)", globals=globals(), number=10_000))
print("Unpacking with bitshifts")
print(timeit.timeit("bit_unpack_3(packed)", globals=globals(), number=10_000))
