# -*- coding: utf-8 -*-
from random import randint
from polyntt.ntt_iterative import NTTIterative
import unittest
from polyntt.params import PARAMS


class TestNTTIterative(unittest.TestCase):
    def shortDescription(self):
        return None  # This prevents unittest from printing docstrings

    def test_ntt_intt(self, iterations=100):
        """Test if ntt and intt are indeed inverses of each other."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                T = NTTIterative(q)
                for i in range(iterations):
                    f = [randint(0, T.q-1) for j in range(n)]
                    self.assertEqual(T.intt(T.ntt(f)), f)

    def test_ntt_linearity(self, iterations=100):
        """Test the linearity of NTT."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                T = NTTIterative(q)
                for i in range(iterations):
                    f = [randint(0, T.q - 1) for j in range(n)]
                    g = [randint(0, T.q - 1) for j in range(n)]
                    λ = randint(0, T.q-1)
                    μ = randint(0, T.q-1)
                    λ_f_plus_μ_g = [(λ*x+μ*y) % T.q for (x, y) in zip(f, g)]
                    f_ntt = T.ntt(f)
                    g_ntt = T.ntt(g)
                    self.assertEqual(
                        T.ntt(λ_f_plus_μ_g),
                        [(λ*x+μ*y) % T.q for (x, y) in zip(f_ntt, g_ntt)]
                    )

    # TODO TEST ADD AND SUB HERE
