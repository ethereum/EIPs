from hashlib import shake_128, shake_256
from dilithium_py.shake.shake_wrapper import Shake, shake128, shake256
from Crypto.Hash.SHAKE128 import SHAKE128_XOF
from Crypto.Hash.SHAKE256 import SHAKE256_XOF

import unittest
import random


class TestShakeHashlib(unittest.TestCase):
    def hashlib_test_long_calls(self, Shake, shake_hashlib):
        absorb_bytes = b"testing_shake_long"
        for l in [1, 100, 1000, 2000, 5000, 1_000_000]:
            Shake.absorb(absorb_bytes)
            self.assertEqual(shake_hashlib(
                absorb_bytes).digest(l), Shake.read(l))

    def hashlib_test_many_calls(self, Shake, shake_hashlib):
        absorb_bytes = b"testing_shake_one"
        for l in [1, 100, 1000, 2000, 5000, 1_000_000]:
            Shake.absorb(absorb_bytes)
            output = b"".join([Shake.read(1) for _ in range(l)])
            self.assertEqual(shake_hashlib(absorb_bytes).digest(l), output)

    def test_hashlib_shake128(self):
        self.hashlib_test_long_calls(shake128, shake_128)
        self.hashlib_test_many_calls(shake128, shake_128)

    def test_hashlib_shake256(self):
        self.hashlib_test_long_calls(shake256, shake_256)
        self.hashlib_test_many_calls(shake256, shake_256)


class TestShakeCrypto(unittest.TestCase):
    def pycryptodome_test_read_chunks(self, Shake, ShakeCrypto):
        absorb_bytes = b"testing_shake_chunks"
        chunk = random.randint(50, 100)
        Shake.absorb(absorb_bytes)
        ShakeCrypto.update(absorb_bytes)
        for _ in range(1000):
            self.assertEqual(Shake.read(chunk), ShakeCrypto.read(chunk))

    def test_pycryptodome_shake(self):
        self.pycryptodome_test_read_chunks(shake128, SHAKE128_XOF())
        self.pycryptodome_test_read_chunks(shake256, SHAKE256_XOF())
