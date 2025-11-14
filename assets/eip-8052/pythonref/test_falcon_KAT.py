import unittest
from falcon import PublicKey, SecretKey
from scripts.sign_KAT import sign_KAT
from shake import SHAKE


class TestFalconKAT(unittest.TestCase):

    # def test_generation_KAT(self):
    #     # THIS WORKS BUT IT IS VERY SLOW BECAUSE OUR IMPLEMENTATION OF KECCAK IS SLOWER THAN PYCRYPTODOME.
    #     """
    #     Test the signing procedure against test vectors obtained from
    #     the Round 3 implementation of Falcon.

    #     Starting from the same private key, same message, and same SHAKE256
    #     context (for randomness generation), we check that we obtain the
    #     same signatures.
    #     """
    #     message = b"data1"
    #     shake = SHAKE.new(b"external")
    #     shake.flip()
    #     for n in sign_KAT:
    #         sign_KAT_n = sign_KAT[n]
    #         for D in sign_KAT_n:
    #             f = D["f"]
    #             g = D["g"]
    #             F = D["F"]
    #             G = D["G"]
    #             print(1)
    #             sk = SecretKey(n, [f, g, F, G])
    #             print(2)
    #             # The next line is done to synchronize the SHAKE256 context
    #             # with the one in the Round 3 C implementation of Falcon.
    #             _ = shake.read(8 * D["read_bytes"])
    #             print(3)
    #             sig = sk.sign(message, shake.read, xof=SHAKE)
    #             print(4)
    #             if sig != bytes.fromhex(D["sig"]):
    #                 self.assertTrue(False)
    #     self.assertTrue(True)

    def test_verification_KAT(self):
        """
        Test the verification procedure against test vectors obtained from
        the Round 3 implementation of Falcon.

        Starting from the same public key and message, we check that the
        signature passes the verification.
        """
        message = b"data1"
        for n in sign_KAT:
            sign_KAT_n = sign_KAT[n]
            for D in sign_KAT_n:
                f = D["f"]
                g = D["g"]
                F = D["F"]
                G = D["G"]
                sk = SecretKey(n, [f, g, F, G])
                pk = PublicKey(n, sk.h)
                sig = bytes.fromhex(D["sig"])
                self.assertTrue(pk.verify(message, sig, xof=SHAKE))
