from Crypto.Hash import keccak
import struct

# We implement the Keccak PRNG defined here:
# https://github.com/zhenfeizhang/falcon-go/blob/main/c/keccak_prng.c


# Constants
MAX_BUFFER_SIZE = 1024  # Adjust based on needs
KECCAK_OUTPUT = 32  # Keccak output size in bytes


class KeccakPRNG:
    def __init__(self):
        """ Initialize a Keccak PRNG context. """
        self.buffer = bytearray(MAX_BUFFER_SIZE)
        self.state = bytearray(KECCAK_OUTPUT)
        self.buffer_len = 0
        self.counter = 0
        self.finalized = False

        # Output buffer management
        self.out_buffer = bytearray(KECCAK_OUTPUT)
        self.out_buffer_pos = 0
        self.out_buffer_len = 0

    @classmethod
    def new(self):
        return self()

    def inject(self, data: bytes):
        """ Inject (absorb) data into the PRNG state. """
        if self.finalized:
            raise ValueError("Cannot inject after finalizing")

        if len(data) + self.buffer_len > MAX_BUFFER_SIZE:
            raise ValueError("Buffer overflow")

        self.buffer[self.buffer_len:self.buffer_len + len(data)] = data
        self.buffer_len += len(data)

    def flip(self):
        """ Finalize the PRNG state and prepare for output generation. """
        if self.finalized:
            raise ValueError("Already finalized")

        keccak_ctx = keccak.new(digest_bytes=KECCAK_OUTPUT)
        keccak_ctx.update(self.buffer[:self.buffer_len])

        # Generate initial state
        self.state = keccak_ctx.digest()
        self.finalized = True

        # Reset output buffer
        self.out_buffer_pos = 0
        self.out_buffer_len = 0

    def extract(self, length: int) -> bytes:
        """
        Generate pseudorandom output from the PRNG.
        """
        if not self.finalized:
            raise ValueError("PRNG not finalized")

        output = bytearray()

        # First, use any bytes remaining in the output buffer
        offset = 0

        if self.out_buffer_len > self.out_buffer_pos:
            available = self.out_buffer_len - self.out_buffer_pos
            to_copy = min(length, available)

            output.extend(
                self.out_buffer[self.out_buffer_pos:self.out_buffer_pos + to_copy])
            self.out_buffer_pos += to_copy
            offset += to_copy
            # If we've satisfied the request, return early
            if offset == length:
                return bytes(output)

        while offset < length:
            # Prepare input block: state || counter (big-endian)
            # block = self.state + struct.pack(">Q", self.counter)
            block = self.state + struct.pack(">Q", self.counter)

            # Generate next block using Keccak
            keccak_ctx = keccak.new(digest_bytes=KECCAK_OUTPUT)
            keccak_ctx.update(block)
            self.out_buffer = keccak_ctx.digest()

            # Update buffer state
            self.out_buffer_len = KECCAK_OUTPUT
            self.out_buffer_pos = 0

            # Copy output
            remaining = length - offset
            to_copy = min(remaining, KECCAK_OUTPUT)

            output.extend(self.out_buffer[:to_copy])
            self.out_buffer_pos = to_copy
            offset += to_copy

            # Increment counter for next block
            self.counter += 1

        return bytes(output)

    # Two functions to keep the structure of SHAKE256
    def update(self, data: bytes):
        """`update` is `inject` in Zhenfei specification."""
        self.inject(data)

    def read(self, length: int) -> bytes:
        """`read` is `extract` in Zhenfei specification."""
        return self.extract(length)
