import unittest
import os
# , ZKDilithiumKB, ZKDilithiumBB
from dilithium_py.dilithium import Dilithium2, Dilithium3, Dilithium5
from dilithium_py.drbg.aes256_ctr_drbg import AES256_CTR_DRBG

from ..shake.shake_wrapper import shake128, shake256
from ..keccak_prng.keccak_prng_wrapper import Keccak256PRNG


def parse_kat_data(data):
    """
    Helper function to parse data from KAT
    file to bytes in a dictionary
    """
    parsed_data = {}
    count_blocks = data.split("\n\n")
    for block in count_blocks[1:-1]:
        block_data = block.split("\n")
        count, seed, mlen, msg, pk, sk, smlen, sm = [
            line.split(" = ")[-1] for line in block_data
        ]
        parsed_data[int(count)] = {
            "seed": bytes.fromhex(seed),
            "msg": bytes.fromhex(msg),
            "mlen": int(mlen),
            "pk": bytes.fromhex(pk),
            "sk": bytes.fromhex(sk),
            "sm": bytes.fromhex(sm),
        }
    return parsed_data


class TestDilithium(unittest.TestCase):
    """
    Test Dilithium for internal
    consistency by generating signatures
    and verifying them!
    """

    def generic_test_dilithium(self, Dilithium, xof, xof2):
        msg = b"Signed by dilithium" + os.urandom(16)

        # Perform signature process
        pk, sk = Dilithium.keygen(_xof=xof, _xof2=xof2)
        sig = Dilithium.sign(sk, msg, _xof=xof, _xof2=xof2)
        check_verify = Dilithium.verify(pk, msg, sig, _xof=xof, _xof2=xof2)

        # Generate some fail cases
        pk_bad, _ = Dilithium.keygen(_xof=xof, _xof2=xof2)
        check_wrong_pk = Dilithium.verify(
            pk_bad, msg, sig, _xof=xof, _xof2=xof2)
        check_wrong_msg = Dilithium.verify(pk, b"", sig, _xof=xof, _xof2=xof2)

        # Check that signature works
        self.assertTrue(check_verify)
        # Check changing the key breaks verify
        self.assertFalse(check_wrong_pk)
        # Check changing the message breaks verify
        self.assertFalse(check_wrong_msg)

    # def generic_test_ethdilithium(self, Dilithium, xof, xof2):
    #     msg = b"Signed by dilithium" + os.urandom(16)

    #     # Perform signature process
    #     pk, sk = Dilithium.keygen(_xof=xof, _xof2=xof2)
    #     sig = Dilithium.sign(sk, msg, _xof=xof, _xof2=xof2)
    #     check_verify = Dilithium.verify(pk, msg, sig, _xof=xof)

    #     # Generate some fail cases
    #     pk_bad, _ = Dilithium.keygen(_xof=xof, _xof2=xof2)
    #     check_wrong_pk = Dilithium.verify(pk_bad, msg, sig, _xof=xof)
    #     check_wrong_msg = Dilithium.verify(pk, b"", sig, _xof=xof)

    #     # Check that signature works
    #     self.assertTrue(check_verify)
    #     # Check changing the key breaks verify
    #     self.assertFalse(check_wrong_pk)
    #     # Check changing the message breaks verify
    #     self.assertFalse(check_wrong_msg)

    def test_dilithium2(self):
        for _ in range(3):
            self.generic_test_dilithium(Dilithium2, shake256, shake128)

    # def test_dilithium3(self):
    #     for _ in range(3):
    #         self.generic_test_dilithium(Dilithium3, shake256, shake128)

    # def test_dilithium5(self):
    #     for _ in range(3):
    #         self.generic_test_dilithium(Dilithium5, shake256, shake128)

    def test_dilithium2_keccak_prng(self):
        for _ in range(3):
            self.generic_test_dilithium(
                Dilithium2, Keccak256PRNG, Keccak256PRNG)

    # def test_dilithium3_keccak_prng(self):
    #     for _ in range(3):
    #         self.generic_test_dilithium(
    #             Dilithium3, Keccak256PRNG, Keccak256PRNG)

    # def test_dilithium5_keccak_prng(self):
    #     for _ in range(3):
    #         self.generic_test_dilithium(
    #             Dilithium5, Keccak256PRNG, Keccak256PRNG)

    # # TEST ETHDILITHIUM
    # def test_ethdilithium2_keccak_prng(self):
    #     for _ in range(3):
    #         self.generic_test_ethdilithium(
    #             ETHDilithium2, Keccak256PRNG, Keccak256PRNG)

    # # TEST ETHDILITHIUM with SHAKE
    # def test_ethdilithium2_shake(self):
    #     for _ in range(3):
    #         self.generic_test_ethdilithium(
    #             ETHDilithium2, shake256, Keccak256PRNG)


class TestDilithiumDRBG(unittest.TestCase):
    """
    Ensure that deterministic DRBG is deterministic!

    Uses AES256 CTR DRBG for randomness.
    Note: requires pycryptodome for AES impl.
    """

    def generic_test_dilithium(self, Dilithium):
        """
        First we generate five pk,sk pairs
        from the same seed and make sure
        they're all the same
        """
        seed = os.urandom(48)
        pk_output = []
        for _ in range(5):
            Dilithium.set_drbg_seed(seed)
            pk, sk = Dilithium.keygen()
            pk_output.append(pk + sk)
        self.assertEqual(len(pk_output), 5)
        self.assertEqual(len(set(pk_output)), 1)

        """
        Now given a fixed keypair make sure
        that all the signatures are the same
        and that they all verify correctly!
        """
        sig_output = []
        seed = os.urandom(48)
        msg = b"Signed by Dilithium" + os.urandom(32)
        pk, sk = Dilithium.keygen()
        for _ in range(5):
            Dilithium.set_drbg_seed(seed)
            sig = Dilithium.sign(sk, msg)
            verify = Dilithium.verify(pk, msg, sig)
            # Check signature worked
            self.assertTrue(verify)
            sig_output.append(sig)

        # Make sure all five signatures are the same
        self.assertEqual(len(sig_output), 5)
        self.assertEqual(len(set(sig_output)), 1)

    def test_dilithium2(self):
        for _ in range(5):
            self.generic_test_dilithium(Dilithium2)

    def test_dilithium3(self):
        for _ in range(5):
            self.generic_test_dilithium(Dilithium3)

    def test_dilithium5(self):
        for _ in range(5):
            self.generic_test_dilithium(Dilithium5)


class TestKnownTestValuesDilithium(unittest.TestCase):
    def generic_test_dilithium(self, Dilithium, file_name, _xof=shake256, _xof2=shake128):
        entropy_input = bytes([i for i in range(48)])
        drbg = AES256_CTR_DRBG(entropy_input)

        with open(f"assets/{file_name}") as f:
            # extract data from KAT
            kat_data = f.read()
            parsed_data = parse_kat_data(kat_data)

        for count in range(100):
            data = parsed_data[count]

            seed = drbg.random_bytes(48)
            self.assertEqual(data["seed"], seed)

            msg_len = data["mlen"]
            msg = drbg.random_bytes(msg_len)
            self.assertEqual(data["msg"], msg)

            Dilithium.set_drbg_seed(seed)
            pk, sk = Dilithium.keygen(_xof=_xof, _xof2=_xof2)

            # Check that the keygen matches
            self.assertEqual(data["pk"], pk)
            self.assertEqual(data["sk"], sk)

            # Check that the signature matches
            sm_KAT = data["sm"]
            sig_KAT = sm_KAT[:-msg_len]

            # sm_KAT has message as the last mlen bytes
            self.assertEqual(msg, sm_KAT[-msg_len:])

            # Ensure that a generated signature matches
            # the one extracted from the KAT
            sig = Dilithium.sign(sk, msg, _xof=_xof, _xof2=_xof2)
            self.assertEqual(sig, sig_KAT)

            # Finally, make sure that the signature is
            # valid for the message
            verify_KAT = Dilithium.verify(pk, msg, sig, _xof=_xof, _xof2=_xof2)
            self.assertTrue(verify_KAT)

    def test_dilithium2(self):
        self.generic_test_dilithium(Dilithium2, "PQCsignKAT_Dilithium2.rsp")

    def test_dilithium2_eth(self):
        self.generic_test_dilithium(
            Dilithium2, "PQCsignKAT_Dilithium2_ETH.rsp", _xof=Keccak256PRNG, _xof2=Keccak256PRNG)

    def test_dilithium3(self):
        self.generic_test_dilithium(Dilithium3, "PQCsignKAT_Dilithium3.rsp")

    def test_dilithium5(self):
        self.generic_test_dilithium(Dilithium5, "PQCsignKAT_Dilithium5.rsp")


if __name__ == "__main__":
    unittest.main()
