import unittest

from falcon_epervier import EpervierPublicKey, EpervierSecretKey
from scripts.sign_KAT import sign_KAT
from shake import SHAKE


class TestEpervier(unittest.TestCase):
    def test_signature_epervier(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = EpervierSecretKey(n, [f, g, F, G])
        pk = EpervierPublicKey(n, sk.pk)
        message = b"abc"
        sig = sk.sign(message)
        self.assertTrue(pk.verify(message, sig))

    def test_signature_epervier_shake(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = EpervierSecretKey(n, [f, g, F, G])
        pk = EpervierPublicKey(n, sk.pk)
        message = b"abc"
        sig = sk.sign(message, xof=SHAKE)
        self.assertTrue(pk.verify(message, sig, xof=SHAKE))
