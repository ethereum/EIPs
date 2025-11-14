import unittest

from falcon_recovery import RecoveryModePublicKey, RecoveryModeSecretKey
from scripts.sign_KAT import sign_KAT
from shake import SHAKE


class TestRecoveryMode(unittest.TestCase):
    def test_signature_recovery_mode(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = RecoveryModeSecretKey(n, [f, g, F, G])
        pk = RecoveryModePublicKey(n, sk.pk)
        message = b"abc"
        sig = sk.sign(message)
        self.assertTrue(pk.verify(message, sig))
        # pk_rec = pk.recover(message, sig)
        # self.assertEqual(sk.pk, pk_rec)

    def test_signature_recovery_mode_shake(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = RecoveryModeSecretKey(n, [f, g, F, G])
        pk = RecoveryModePublicKey(n, sk.pk)
        message = b"abc"
        sig = sk.sign(message, xof=SHAKE)
        self.assertTrue(pk.verify(message, sig, xof=SHAKE))
        # pk_rec = pk.recover(message, sig, xof=SHAKE)
        # self.assertEqual(sk.pk, pk_rec)
