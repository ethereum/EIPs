from typing import List, Tuple

# from starkware.cairo.lang.vm.memory_segments import MemorySegmentManager
# from starkware.cairo.lang.vm.relocatable import RelocatableValue

PRIME = 2**251 + 17 * 2**192 + 1

IV = [
    0x6A09E667,
    0xBB67AE85,
    0x3C6EF372,
    0xA54FF53A,
    0x510E527F,
    0x9B05688C,
    0x1F83D9AB,
    0x5BE0CD19,
]

SIGMA = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
    [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
    [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
    [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
    [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
    [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
    [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
    [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
    [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
]


def right_rot(value, n):
    return (value >> n) | ((value & (2**n - 1)) << (32 - n))


# Helper function for the Cairo blake2s() implementation.
# Computes the blake2s compress function and fills the value in the right position.
# output_ptr should point to the middle of an instance, right after initial_state, message, t, f,
# which should all have a value at this point, and right before the output portion which will be
# written by this function.
# def compute_blake2s_func(segments: MemorySegmentManager, output_ptr: RelocatableValue):
#     h = segments.memory.get_range(output_ptr - 26, 8)
#     message = segments.memory.get_range(output_ptr - 18, 16)
#     t = segments.memory[output_ptr - 2]
#     f = segments.memory[output_ptr - 1]
#     new_state = blake2s_compress(
#         message=message,
#         h=h,
#         t0=t,
#         t1=0,
#         f0=f,
#         f1=0,
#     )
#     segments.write_arg(output_ptr, new_state)


def blake2s_compress(
    h: List[int], message: List[int], t0: int, t1: int, f0: int, f1: int
) -> List[int]:
    """
    h is a list of 8 32-bit words.
    message is a list of 16 32-bit words.
    """
    state = h + IV[:4] + [x % 2**32 for x in [IV[4]
                                              ^ t0, IV[5] ^ t1, IV[6] ^ f0, IV[7] ^ f1]]
    for i in range(10):
        state = blake_round(state, message, SIGMA[i])
    return [x ^ v0 ^ v1 for x, v0, v1 in zip(h, state[:8], state[8:])]


def blake_round(state: List[int], message: List[int], sigma: List[int]) -> List[int]:
    state = list(state)
    state[0], state[4], state[8], state[12] = mix(
        state[0], state[4], state[8], state[12], message[sigma[0]], message[sigma[1]]
    )
    state[1], state[5], state[9], state[13] = mix(
        state[1], state[5], state[9], state[13], message[sigma[2]], message[sigma[3]]
    )
    state[2], state[6], state[10], state[14] = mix(
        state[2], state[6], state[10], state[14], message[sigma[4]], message[sigma[5]]
    )
    state[3], state[7], state[11], state[15] = mix(
        state[3], state[7], state[11], state[15], message[sigma[6]], message[sigma[7]]
    )

    state[0], state[5], state[10], state[15] = mix(
        state[0], state[5], state[10], state[15], message[sigma[8]], message[sigma[9]]
    )
    state[1], state[6], state[11], state[12] = mix(
        state[1], state[6], state[11], state[12], message[sigma[10]
                                                          ], message[sigma[11]]
    )
    state[2], state[7], state[8], state[13] = mix(
        state[2], state[7], state[8], state[13], message[sigma[12]
                                                         ], message[sigma[13]]
    )
    state[3], state[4], state[9], state[14] = mix(
        state[3], state[4], state[9], state[14], message[sigma[14]
                                                         ], message[sigma[15]]
    )

    return state


def mix(a: int, b: int, c: int, d: int, m0: int, m1: int) -> Tuple[int, int, int, int]:
    a = (a + b + m0) % 2**32
    d = right_rot((d ^ a), 16)
    c = (c + d) % 2**32
    b = right_rot((b ^ c), 12)
    a = (a + b + m1) % 2**32
    d = right_rot((d ^ a), 8)
    c = (c + d) % 2**32
    b = right_rot((b ^ c), 7)

    return a, b, c, d


def blake_state_into_felt(state: List[int], prime: int = PRIME) -> int:
    digest_int = 0
    for idx, word in enumerate(state):
        digest_int |= (word & 0xFFFFFFFF) << (32 * idx)

    return digest_int % prime


def calculate_blake2s_hash_from_felt252s(
    data: List[int], encode: bool, little_endian: bool, prime: int = PRIME
) -> int:
    """
    Converts a list of Felt252s to the BLAKE2s input format and returns the BLAKE2s hash as
    a single Felt252 (combining the final state words into a 256 bit number and taking it
    modulo prime).

    • Each field element in `data` is reduced mod `prime`.
    • When `encode` is True, values < 2**63 are encoded in 2 32-bit words;
      otherwise they are encoded in 8 words with the 255-bit flag set.
      If `encode` is False, the 255-bit flag is not set, and all values are
      taken as 8 words.
    • When `little_endian` is True, the input is treated as little-endian.
    • The data stream is fed into `blake2s_compress` in 64-byte blocks (16 words).
    • `t0` is the running byte counter; `t1 = 0`, `f1 = 0`.
    • The final block is padded with zeros and flagged by `f0 = 0xffffffff`.
    """
    POW2_63 = 1 << 63
    POW2_255 = 1 << 255

    words: List[int] = []
    for felt in data:
        val = felt % prime
        word_cnt = 2 if encode and val < POW2_63 else 8
        if encode and word_cnt == 8:
            val += POW2_255  # Set the 255-bit flag.
        shifts = range(0, 32 * word_cnt, 32)
        if not little_endian:
            shifts = reversed(shifts)
        for shift in shifts:
            words.append((val >> shift) & 0xFFFFFFFF)

    state: List[int] = [
        0x6B08E647,
        0xBB67AE85,
        0x3C6EF372,
        0xA54FF53A,
        0x510E527F,
        0x9B05688C,
        0x1F83D9AB,
        0x5BE0CD19,
    ]
    total_bytes = len(words) * 4
    bytes_seen = 0

    for i in range(0, max(len(words), 1), 16):
        block = words[i: i + 16]
        if len(block) < 16:
            block += [0] * (16 - len(block))
        bytes_seen += min(64, total_bytes - bytes_seen)
        f0 = 0xFFFFFFFF if bytes_seen == total_bytes else 0
        state = blake2s_compress(
            h=state,
            message=block,
            t0=bytes_seen,
            t1=0,
            f0=f0,
            f1=0,
        )

    return blake_state_into_felt(state=state, prime=prime)
