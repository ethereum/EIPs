import unittest

from blake2s_prng import Blake2sPRNG
from falcon import PublicKey, SecretKey
from keccak_prng import KeccakPRNG
from keccaxof import KeccaXOF
from scripts.sign_KAT import sign_KAT
from shake import SHAKE
from timeit import default_timer as timer
from polyntt.ntt_iterative import NTTIterative
from polyntt.ntt_recursive import NTTRecursive


class TestFalcon(unittest.TestCase):

    def test_signature_shake(self):
        n = 512
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = SecretKey(n, [f, g, F, G])
        pk = PublicKey(n, sk.h)
        message = b"abc"
        sig = sk.sign(message, xof=SHAKE)
        self.assertTrue(pk.verify(message, sig, xof=SHAKE))

    def test_signature(self):
        """
        Test Falcon.
        """
        n = 512
        iterations = 10
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = SecretKey(n, [f, g, F, G])
        pk = PublicKey(n, sk.h)
        for i in range(iterations):
            message = b"abc"
            sig = sk.sign(message)
            if pk.verify(message, sig) is False:
                self.assertTrue(False)
        self.assertTrue(True)

    def test_keygen_different_ntt(self):
        """Test Falcon key generation."""
        n = 512
        iterations = 1
        d = {True: "OK    ", False: "Not OK"}
        for (ntt, ntt_str) in [(NTTIterative, 'Iterative'), (NTTRecursive, 'Recursive')]:
            start = timer()
            for i in range(iterations):
                sk = SecretKey(n, polys=None, ntt=ntt)
            rep = True
            end = timer()

            msg = "Test keygen ({})".format(ntt_str)
            msg = msg.ljust(20) + ": " + d[rep]
            if rep is True:
                diff = end - start
                msec = round(diff * 1000 / iterations, 3)
                msg += " ({msec} msec / execution)".format(msec=msec).rjust(30)
            print(msg)

    def test_verif_different_ntt(self):
        """Test Falcon signature verification."""
        n = 512
        iterations = 10
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = SecretKey(n, [f, g, F, G])
        pk = PublicKey(n, sk.h)
        message = b"abc"
        sig = sk.sign(message)

        d = {True: "OK    ", False: "Not OK"}
        for (ntt, ntt_str) in [(NTTIterative, 'Iterative'), (NTTRecursive, 'Recursive')]:
            start = timer()
            for i in range(iterations):
                if pk.verify(message, sig, ntt=ntt) is False:
                    rep = False
            rep = True
            end = timer()

            msg = "Test verif ({})".format(ntt_str)
            msg = msg.ljust(20) + ": " + d[rep]
            if rep is True:
                diff = end - start
                msec = round(diff * 1000 / iterations, 3)
                msg += " ({msec} msec / execution)".format(msec=msec).rjust(30)
            print(msg)

    def test_signing_different_xof(self):
        """Test Falcon signature verification."""
        n = 512
        iterations = 10
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = SecretKey(n, [f, g, F, G])
        pk = PublicKey(n, sk.h)
        message = b"abc"

        d = {True: "OK    ", False: "Not OK"}
        for (xof, xof_str) in [(SHAKE, 'SHAKE'), (KeccaXOF, 'KeccaXOF'), (KeccakPRNG, 'KeccakPRNG'), (Blake2sPRNG, 'Blake2sPRNG')]:
            start = timer()
            for i in range(iterations):
                sig = sk.sign(message, xof=xof)
            rep = True
            end = timer()

            msg = "Test sign ({})".format(xof_str)
            msg = msg.ljust(20) + ": " + d[rep]
            if rep is True:
                diff = end - start
                msec = round(diff * 1000 / iterations, 3)
                msg += " ({msec} msec / execution)".format(msec=msec).rjust(30)

    def test_verif_different_xof(self):
        """Test Falcon signature verification."""
        n = 512
        iterations = 10
        f = sign_KAT[n][0]["f"]
        g = sign_KAT[n][0]["g"]
        F = sign_KAT[n][0]["F"]
        G = sign_KAT[n][0]["G"]
        sk = SecretKey(n, [f, g, F, G])
        pk = PublicKey(n, sk.h)
        message = b"I like to change hash functions"
        d = {True: "OK    ", False: "Not OK"}
        for (xof, xof_str) in [(SHAKE, 'SHAKE'), (KeccaXOF, 'KeccaXOF'), (KeccakPRNG, 'KeccakPRNG'), (Blake2sPRNG, 'Blake2sPRNG')]:
            sig = sk.sign(message, xof=xof)
            start = timer()
            for i in range(iterations):
                if pk.verify(message, sig, xof=xof) is False:
                    rep = False
            rep = True
            end = timer()

            msg = "Test verif ({})".format(xof_str)
            msg = msg.ljust(20) + ": " + d[rep]
            if rep is True:
                diff = end - start
                msec = round(diff * 1000 / iterations, 3)
                msg += " ({msec} msec / execution)".format(msec=msec).rjust(30)
            print(msg)
