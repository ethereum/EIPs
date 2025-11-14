from keccak import KeccakHash


class SHAKE:
    def __init__(self, data='', rate=200-(512//8), dsbyte=0x1f):
        self.shake = KeccakHash(rate=rate, b=data, dsbyte=dsbyte)

    @classmethod
    def new(self, data='', rate=200-(512//8), dsbyte=0x1f):
        return self(data, rate=rate, dsbyte=dsbyte)

    def update(self, data):
        self.shake.absorb(data)

    def read(self, length):
        return self.shake.squeeze(length)

    def flip(self):
        self.shake.pad()
        return
