# -*- coding: utf-8 -*-
from random import randint
from polyntt.ntt_iterative import NTTIterative
from polyntt.poly import Poly
import unittest
from polyntt.params import PARAMS


class TestPoly(unittest.TestCase):

    def shortDescription(self):
        return None  # This prevents unittest from printing docstrings

    # def add_sub(self, q, n):
    #     with self.subTest(msg="Test of add_sub with q={} and n = {}".format(q, n)):
    #         f = Poly([randint(0, q-1) for _ in range(n)], q)
    #         g = Poly([randint(0, q-1) for _ in range(n)], q)
    #         f_plus_g = f+g
    #         self.assertEqual(f_plus_g - g, f)

    # def test_all(self, iterations=100):
    #     for (q, k) in PARAMS:
    #         n = 1 << (k-1)
    #         self.add_sub(q, n)

    def test_add_sub(self, iterations=100):
        """Test if ntt and intt are indeed inverses of each other."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                for i in range(iterations):
                    f = Poly([randint(0, q-1) for _ in range(n)], q)
                    g = Poly([randint(0, q-1) for _ in range(n)], q)
                    f_plus_g = f+g
                    self.assertEqual(f_plus_g - g, f)

    def test_mod_q(self, iterations=100):
        """ Test if the reduction mod q works."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                zero = Poly([0 for _ in range(n)], q)
                for i in range(iterations):
                    f = Poly([q*randint(0, q-1) for _ in range(n)], q)
                    self.assertEqual(f, zero)

    def test_mul(self, iterations=10):
        """Compare FFT multiplication with schoolbook multiplication."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                for i in range(iterations):
                    f = Poly([randint(0, q-1) for _ in range(n)], q)
                    g = Poly([randint(0, q-1) for _ in range(n)], q)
                    f_mul_g = f*g
                    self.assertEqual(f_mul_g, f.mul_schoolbook(g))

    def test_div(self, iterations=10):
        """Test the division."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                for i in range(iterations):
                    # random f
                    f = Poly([randint(0, q-1) for _ in range(n)], q)
                    # invertible random g
                    g = Poly(f.NTT.intt([randint(1, q-1)
                                         for _ in range(n)]), q)
                    h = f/g
                    self.assertEqual(h * g, f)

    def test_inv(self, iterations=10):
        """Test the division."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                T = NTTIterative(q)
                one = Poly([1]+[0 for i in range(n-1)], q)
                for i in range(iterations):
                    # invertible random f
                    f = Poly(T.intt([randint(1, q-1)
                                     for _ in range(n)]), q)
                    inv_f = f.inverse()
                    self.assertEqual(inv_f * f, one)

    def test_mul_pwc(self, iterations=10):
        """Test the multiplication modulo x^n+1."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                for i in range(1, iterations):
                    # random f,g
                    f = Poly([randint(0, q-1) for _ in range(n)], q)
                    g = Poly([randint(0, q-1) for _ in range(n)], q)
                    self.assertEqual(f.mul_pwc(g), f.mul_schoolbook_pwc(g))

    def test_mul_pwc_one_table(self, iterations=100):
        """Compare NTT with one and four tables."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                for i in range(iterations):
                    f = Poly([randint(0, q-1) for _ in range(n)], q)
                    g = Poly([randint(0, q-1) for _ in range(n)], q)
                    f_mul_g_1 = f.mul_pwc(g)
                    f_mul_g_2 = f.mul_pwc(g, NODE=True)
                    self.assertEqual(f_mul_g_1, f_mul_g_2)

    def test_mul_opt(self, iterations=100):
        """Compare mul_opt with __mul__."""
        for (q, k) in PARAMS:
            n = 1 << (k-1)
            with self.subTest(q=q, k=k):
                for i in range(iterations):
                    f = Poly([randint(0, q-1) for _ in range(n)], q)
                    g = Poly([randint(0, q-1) for _ in range(n)], q)
                    f_mul_g_1 = f*g
                    f_mul_g_2 = f.mul_opt(g.ntt())
                    self.assertEqual(f_mul_g_1, f_mul_g_2)
