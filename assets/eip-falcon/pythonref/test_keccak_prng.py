import unittest
from keccak_prng import KeccakPRNG

# Values obtained from `./c/test_prng` in Zhenfei Zhang's repository:
# https://github.com/zhenfeizhang/falcon-go/blob/main/c/test_prng

# Test vector 1:
# with extract(32)
# input "test input"
# input in hex: "7465737420696e707574"
output_test_input_32 = "5b9e99370fa4b753ac6bf0d246b3cec353c84a67839f5632cb2679b4ae565601"

# Test vector 2:
# extract(64), last half
# input "test input"
# input in hex: "7465737420696e707574"
output_test_input_64 = "569857b781dd8b81dd9cb45d06999916742043ff52f1cf165e161bcc9938b705"

# Test vector 3:
# extract(32)
# input "testinput"
# input in hex: "74657374696e707574"
output_testinput_32 = "120f76b5b7198706bc294a942f8d17467aadb2bb1fa2cc1fecadbaba93c0dd74"

# Test vectors 4:
# extract(32) three times (only 16 bytes)
# input "test sequence"
# input in hex: "746573742073657175656e6365"
output_test_sequence_32_1 = "9e96b1e50719da6f0ea5b664ac8bbac5"
output_test_sequence_32_2 = "eb409b4db770b124363b393a0c96b5d6"
output_test_sequence_32_3 = "1be071eca45961aca979e88e3784a751"


class TestKeccakPRNG(unittest.TestCase):
    """
    We follow the tests provided by Zhenfei Zhang here:
    https://github.com/zhenfeizhang/falcon-go/blob/main/c/test_prng.c
    """

    def shortDescription(self):
        return None  # This prevents unittest from printing docstrings

    def test_deterministic(self):
        """The PRNG is deterministic."""
        prng1 = KeccakPRNG()
        prng1.inject(b"test input")
        prng1.flip()
        output1 = prng1.extract(32)
        prng2 = KeccakPRNG()
        prng2.inject(b"test input")
        prng2.flip()
        output2 = prng2.extract(32)
        self.assertEqual(output1, output2)
        self.assertEqual(output1.hex(), output_test_input_32)

    def test_change_with_size(self):
        """The PRNG is outputs different values for different sizes of output."""
        prng1 = KeccakPRNG()
        prng1.inject(b"test input")
        prng1.flip()
        output1 = prng1.extract(32)
        prng2 = KeccakPRNG()
        prng2.inject(b"test input")
        prng2.flip()
        output2 = prng2.extract(64)
        self.assertNotEqual(output1, output2)
        self.assertEqual(output2.hex()[64:], output_test_input_64)

    def test_inject_decomposition(self):
        """Check that injecting `testinput` or `test` and ten `input` produces the same output."""
        prng1 = KeccakPRNG()
        prng1.inject(b"testinput")
        prng1.flip()
        output1 = prng1.extract(32)

        prng2 = KeccakPRNG()
        prng2.inject(b"test")
        prng2.inject(b"input")
        prng2.flip()
        output2 = prng2.extract(32)

        self.assertEqual(output1, output2)
        self.assertEqual(output1.hex(), output_testinput_32)

    def test_extraction(self):
        """Check that three extractions lead to different outputs."""
        prng = KeccakPRNG()
        prng.inject(b"test sequence")
        prng.flip()
        output1 = prng.extract(16)
        output2 = prng.extract(16)
        output3 = prng.extract(16)
        self.assertNotEqual(output1, output2)
        self.assertNotEqual(output2, output3)
        self.assertNotEqual(output1, output3)
        self.assertEqual(output1.hex(), output_test_sequence_32_1)
        self.assertEqual(output2.hex(), output_test_sequence_32_2)
        self.assertEqual(output3.hex(), output_test_sequence_32_3)

    def test_small_read(self):
        """Check that we can read two bytes as in Falcon."""
        prng = KeccakPRNG()
        prng.update(b"Test of update")
        prng.flip()
        prng.read(2)
        self.assertTrue(True)

    def test_extract_2_2_vs_4(self):
        prng1 = KeccakPRNG()
        prng1.update(b"Danette")
        prng1.flip()
        prng2 = KeccakPRNG()
        prng2.update(b"Danette")
        prng2.flip()
        self.assertEqual(prng1.read(2) + prng1.read(2), prng2.read(4))
