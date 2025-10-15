from hashlib import shake_128, shake_256

"""
hashlib has implemented shake_128, shake_256 but they haven't designed it so you
can read bytes properly... every call generates all bytes without updating

shake_128.digest(1) == shake_128.digest(1)

and we have no shake_128.read() :(

So, here's a wrapper which calls to shake_128.digest and collects a bunch of
bytes which we can then read through.
"""


class Shake:
    def __init__(self, algorithm, block_length):
        self.algorithm = algorithm
        self.block_length = block_length
        self.buf = b""
        self.len_buf = 0

    def absorb(self, input_bytes):
        """
        Initialise the XOF with the seed and reset other init.
        """
        # Initalize the buffer
        self.index = 0

        # Set the reading method from hashlib digest
        self.xof_read = self.algorithm(input_bytes).digest

        # Start by requesting 5 blocks from the XOF
        self.buf = self.xof_read(5 * self.block_length)
        self.len_buf = 5 * self.block_length

    def read(self, n):
        """
        Read n bytes from the XOF
        """
        # Make sure there are enough bytes to read
        while self.index + n > self.len_buf:
            # double the size of the buffer
            self.len_buf *= 2
            self.buf = self.xof_read(self.len_buf)

        # Read from the buffer data the bytes requested
        send = self.buf[self.index: self.index + n]

        # Shift the index along the buffer
        self.index += n

        return send

    # SIMON ADDED THIS
    def flip(self):
        return

    def __call__(self, input_bytes):
        self.absorb(input_bytes)
        return self


shake128 = Shake(shake_128, 168)
shake256 = Shake(shake_256, 136)
