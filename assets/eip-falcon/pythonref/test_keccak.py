from keccak import KeccakHash
from Crypto.Hash import keccak
import os
import unittest


class TestShake(unittest.TestCase):

    def test_vs_pycryptodome(self):
        for _ in range(10):
            message = os.urandom(123)

            # Using PyCryptoDome
            k = keccak.new(digest_bytes=32)
            k.update(message)
            output_1 = k.digest()

            # Using our implementation
            # dsbyte = 0x01 and not 0x1f as in shake...
            K = KeccakHash(rate=200-(512 // 8), dsbyte=0x01)
            K.absorb(message)
            K.pad()
            output_2 = K.squeeze(32)

            # Assert that it matches
            self.assertEqual(output_1, output_2)
