"""
Implementation of the RNG used during the signing procedure.
This RNG is based on ChaCha20. The 56-bytes seed is split into
14 words s[0], ..., s[13] of 32 bits each. s[12], s[13] define
a 64-bit counter ctr = s[12] + s[13] << 32

Random bits are generated as follow:
- fill the ChaCha20 matrix as follows:
    CW[0]  CW[1]  CW[2]  CW[3]
     s[0]   s[1]   s[2]   s[3]
     s[4]   s[5]   s[6]   s[7]
     s[8]   s[9]   s[1]   s[1]
- generate 512 bits of randomness by applying the block function as
  in "regular" ChaCha20 (e.g. https://tools.ietf.org/html/rfc7539)
- increment ctr
For efficiency reasons, the reference code generates 8 chunks of randomness
at a time (hence 512 * 8 = 4096 bits), and interleave the outputs by blocks
of 32 bits. For reproducibility, we do the same here.
"""

# ChaCha20 constants
CW = [0x61707865, 0x3320646e, 0x79622d32, 0x6b206574]


def roll(x, n):
    """
    The roll function
    Lifted from https://www.johndcook.com/blog/2019/03/03/do-the-chacha/
    """
    return ((x << n) & 0xffffffff) + (x >> (32 - n))


class ChaCha20:

    def __init__(self, src):
        """
        Initialize the PRG. src is the initial seed, ctr is the counter,
        and hexbytes is a buffer for the pseudorandom output.
        """
        self.s = [int.from_bytes(src[4 * i: 4 * (i + 1)], "little") for i in range(14)]
        self.ctr = self.s[12] + (self.s[13] << 32)
        self.hexbytes = ""

    def __repr__(self):
        """
        Print the PRG state.
        """
        rep = "s = ["
        for elt in self.s:
            rep += '0x{:08x}, '.format(elt)
        rep = rep[:-2] + "]\n"
        rep += "ctr = " + str(self.ctr)
        return rep

    def qround(self, A, B, C, D):
        """
        Quarter-round function.
        Lifted from https://www.johndcook.com/blog/2019/03/03/do-the-chacha/,
        then modified.
        """
        a = self.state[A]
        b = self.state[B]
        c = self.state[C]
        d = self.state[D]
        a = (a + b) & 0xffffffff
        d = roll(d ^ a, 16)
        c = (c + d) & 0xffffffff
        b = roll(b ^ c, 12)
        a = (a + b) & 0xffffffff
        d = roll(d ^ a, 8)
        c = (c + d) & 0xffffffff
        b = roll(b ^ c, 7)
        self.state[A] = a
        self.state[B] = b
        self.state[C] = c
        self.state[D] = d

    def update(self):
        """
        One update of the ChaCha20 PRG.
        """
        self.state = [0] * 16
        self.state[0:4] = CW[:]
        self.state[4:14] = [self.s[i] for i in range(10)]
        self.state[14] = self.s[10] ^ (self.ctr & 0xffffffff)
        self.state[15] = self.s[11] ^ (self.ctr >> 32)
        state = self.state[:]
        for _ in range(10):
            self.qround(0, 4, 8, 12)
            self.qround(1, 5, 9, 13)
            self.qround(2, 6, 10, 14)
            self.qround(3, 7, 11, 15)
            self.qround(0, 5, 10, 15)
            self.qround(1, 6, 11, 12)
            self.qround(2, 7, 8, 13)
            self.qround(3, 4, 9, 14)
        for i in range(16):
            self.state[i] = (self.state[i] + state[i]) & 0xffffffff
        self.ctr += 1
        return self.state

    def block_update(self):
        """
        Produces 8 consecurite updates, and interleave the results.
        """
        block = [None] * 16 * 8
        for i in range(8):
            block[i::8] = self.update()
        return "".join(elt.to_bytes(4, "little").hex() for elt in block)

    def randombytes(self, k):
        """
        Generate random bytes.
        Perform some shenanigans to match the reference code PRG.
        """
        if (2 * k > len(self.hexbytes)):
            self.hexbytes = self.block_update()
        out = self.hexbytes[:(2 * k)]
        out = "".join(out[i:i + 2] for i in range(2 * k - 2, -1, -2))
        self.hexbytes = self.hexbytes[(2 * k):]
        return bytes.fromhex(out)[::-1]
