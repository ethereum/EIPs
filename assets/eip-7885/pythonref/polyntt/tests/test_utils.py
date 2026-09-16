# -*- coding: utf-8 -*-
from random import randint
import unittest
from polyntt.ntt import batch_modular_inversion
from polyntt.utils import batch_modular_inversion


class TestUtils(unittest.TestCase):
    def shortDescription(self):
        return None  # This prevents unittest from printing docstrings

    def test_batched_modular_multiplication(self, iterations=100):
        """Test the batched modular multiplication."""
        q = 3329
        n = 256
        for i in range(iterations):
            L = [randint(1, q-1) for i in range(n)]  # non-zeros!
            M = batch_modular_inversion(L, q)
            for (l, m) in zip(L, M):
                self.assertEqual((l*m) % q, 1)
