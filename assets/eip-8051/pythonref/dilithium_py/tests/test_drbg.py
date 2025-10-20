import unittest
import os
from dilithium_py.drbg.aes256_ctr_drbg import AES256_CTR_DRBG


class TestDRBG(unittest.TestCase):
    """
    Some small tests, as the general check for the DRBG is that
    the KAT vectors match with the assets within the mlkem and
    kyber tests.
    """

    def test_no_seed(self):
        # If seed is none, os.urandom is used instead
        seed = None
        drbg = AES256_CTR_DRBG(seed)
        self.assertNotEqual(drbg.entropy_input, None)

    def test_bad_seed(self):
        # if the seed length is not 48, the code fails
        seed = b"1"
        self.assertRaises(ValueError, lambda: AES256_CTR_DRBG(seed))
        seed = b"1" * 49
        self.assertRaises(ValueError, lambda: AES256_CTR_DRBG(seed))

    def test_personalization(self):
        seed = os.urandom(48)
        personalization = os.urandom(24)
        drbg = AES256_CTR_DRBG(seed, personalization)
        self.assertEqual(AES256_CTR_DRBG, type(drbg))
        self.assertEqual(32, len(drbg.random_bytes(32)))
        self.assertEqual(bytes, type(drbg.random_bytes(32)))

    def test_bad_personalization(self):
        # if the personalization is longer than 48 bytes, fail
        seed = os.urandom(48)
        personalization = os.urandom(49)
        self.assertRaises(ValueError, lambda: AES256_CTR_DRBG(seed, personalization))

    def test_additional(self):
        drbg = AES256_CTR_DRBG()
        additional = os.urandom(24)
        self.assertEqual(32, len(drbg.random_bytes(32, additional)))
        self.assertEqual(bytes, type(drbg.random_bytes(32, additional)))

    def test_bad_additional(self):
        # if the additional data is longer than 48 bytes, fail
        drbg = AES256_CTR_DRBG()
        additional = os.urandom(49)
        self.assertRaises(ValueError, lambda: drbg.random_bytes(32, additional))
