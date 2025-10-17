import unittest
from dilithium_py.utilities.utils import decompose, reduce_mod_pm, use_hint
from random import randint


class TestUtils(unittest.TestCase):
    def test_reduce_mod_pm_even(self):
        for _ in range(100):
            modulus = 2 * randint(0, 100)
            for i in range(modulus):
                x = reduce_mod_pm(i, modulus)
                self.assertTrue(x <= modulus // 2)
                self.assertTrue(x > -modulus // 2)

    def test_reduce_mod_pm_odd(self):
        for _ in range(100):
            modulus = 2 * randint(0, 100) + 1
            for i in range(modulus):
                x = reduce_mod_pm(i, modulus)
                self.assertTrue(x <= (modulus - 1) // 2)
                self.assertTrue(x >= -(modulus - 1) // 2)

    def test_use_hint(self):
        # in dilithium we use hint for a=2γ2
        a = 2 * 95232
        q = 8380417
        h = 2345433
        r = 5432321
        assert use_hint(h, r, a, q) == 29
