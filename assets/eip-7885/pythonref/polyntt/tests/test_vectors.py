# This file import the json test vectors and verify the expected output.

import json
from polyntt.ntt_iterative import NTTIterative
from polyntt.poly import Poly
from polyntt.params import PARAMS
import unittest
from polyntt.scripts.generate_test_vectors import decode


class TestVectors(unittest.TestCase):
    def test_vectors(self):
        """Run tests on the test vectors."""
        for (q, two_adicity) in PARAMS:

            # for two sizes of polynomials
            for n in [1 << (two_adicity-2), 1 << (two_adicity-1)]:

                with open("../test_vectors/q{}_n{}.json".format(q, n), 'r') as file:
                    T = NTTIterative(q)
                    for test in json.load(file):
                        input = decode(test['Input'], q)
                        mid = len(input)//2
                        in1, in2 = input[:mid], input[mid:]

                        name = test['Name'].split('{')[1][:-1]

                        expected = decode(test['Expected'],  q)
                        gas = test['Gas']

                        if name == 'ntt':
                            mid = len(expected)//2
                            ex1, ex2 = expected[:mid], expected[mid:]
                            self.assertEqual(T.ntt(in1), ex1)
                            self.assertEqual(T.ntt(in2), ex2)
                        if name == 'intt':
                            mid = len(expected)//2
                            ex1, ex2 = expected[:mid], expected[mid:]
                            self.assertEqual(T.intt(in1), ex1)
                            self.assertEqual(T.intt(in2), ex2)
                        if name == 'vec_mul':
                            self.assertEqual(T.vec_mul(in1, in2), expected)
                        if name == 'pol_mul':
                            self.assertEqual(Poly(in1, q) *
                                             Poly(in2, q), Poly(expected, q))
                        if name == 'vec_add':
                            self.assertEqual(T.vec_add(in1, in2), expected)
                        if name == 'vec_sub':
                            self.assertEqual(T.vec_sub(in1, in2), expected)
