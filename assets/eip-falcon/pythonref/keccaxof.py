from Crypto.Hash import keccak
from eth_abi.packed import encode_packed


class KeccaXOF:
    def __init__(self) -> None:
        self.input = []
        self.last = None
        self.tmp = None

    @classmethod
    def new(self):
        return self()

    def update(self, data):
        if self.last is not None:
            raise ValueError('KeccaXOF.update() called after digest()')
        self.input.append(data)

    def read(self, bytes):
        to_slice = bytes * 2
        if self.last is None:
            keccak_hash = keccak.new(digest_bits=256)
            keccak_hash.update(encode_packed(
                ["bytes"] * len(self.input), self.input))
            self.last = keccak_hash.digest()
            self.tmp = keccak_hash.hexdigest()

        while len(self.tmp) < to_slice:
            keccak_hash = keccak.new(digest_bits=256)
            keccak_hash.update(self.last)
            self.last = keccak_hash.digest()
            self.tmp += keccak_hash.hexdigest()

        buff = self.tmp[:to_slice]
        self.tmp = self.tmp[to_slice:]
        return int(buff, 16).to_bytes(2, 'big')

    def flip(self):
        return

# THIS IMPLEMENTATION WILL BE REMOVED SOON
