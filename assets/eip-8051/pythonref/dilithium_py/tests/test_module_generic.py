import unittest
from random import randint
from dilithium_py.polynomials.polynomials_generic import PolynomialRing
from dilithium_py.modules.modules_generic import Module


class TestModule(unittest.TestCase):
    R = PolynomialRing(11, 5)
    M = Module(R)

    def test_random_element(self):
        for _ in range(100):
            m = randint(1, 5)
            n = randint(1, 5)
            A = self.M.random_element(m, n)
            self.assertEqual(type(A), self.M.matrix)
            self.assertEqual(type(A[0, 0]), self.R.element)
            self.assertEqual(A.dim(), (m, n))

    def test_print(self):
        s = "Module over the commutative ring: Univariate Polynomial Ring in x over Finite Field of size 11 with modulus x^5 + 1"
        self.assertEqual(str(self.M), s)
        self.assertEqual(self.M.__repr__(), s)

    def test_non_list_error(self):
        self.assertRaises(TypeError, lambda: self.M("1"))

    def test_non_ring_list_error(self):
        one = self.R(1)
        self.assertRaises(TypeError, lambda: self.M([one, "2", "3"]))
        self.assertRaises(TypeError, lambda: self.M(["2", one, "3"]))
        self.assertRaises(TypeError, lambda: self.M(
            [[one, "2", "3"], [one, "2", "3"]]))
        self.assertRaises(TypeError, lambda: self.M(
            [["1", one, "3"], [one, "2", "3"]]))

    def test_non_rectangular(self):
        one = self.R(1)
        self.assertRaises(ValueError, lambda: self.M([[one, one], [one]]))


class TestMatrix(unittest.TestCase):
    R = PolynomialRing(11, 5)
    R_prime = PolynomialRing(11, 2)
    M = Module(R)
    M_prime = Module(R)
    R_dilithium = PolynomialRing(8380417, 256)
    M_dilithium = Module(R_dilithium)

    def test_equality(self):
        for _ in range(100):
            A = self.M.random_element(2, 2)
            B = self.M.random_element(2, 3)

            self.assertEqual(A, A)
            self.assertNotEqual(A, B)

    def test_add_errors(self):
        A = self.M.random_element(2, 2)
        B = self.M.random_element(2, 3)
        A_prime = self.M_prime.random_element(2, 2)

        self.assertRaises(TypeError, lambda: A + "B")
        self.assertRaises(ValueError, lambda: A + B)
        self.assertRaises(TypeError, lambda: A + A_prime)

    def test_matrix_add(self):
        zero = self.R(0)
        Z = self.M([[zero, zero], [zero, zero]])
        for _ in range(100):
            A = self.M.random_element(2, 2)
            B = self.M.random_element(2, 2)
            C = self.M.random_element(2, 2)

            self.assertEqual(A + Z, A)
            self.assertEqual(A + B, B + A)
            self.assertEqual(A + (B + C), (A + B) + C)

            B = C
            B += C
            self.assertEqual(B, C + C)

    def test_sub_errors(self):
        A = self.M.random_element(2, 2)
        B = self.M.random_element(2, 3)
        A_prime = self.M_prime.random_element(2, 2)

        self.assertRaises(TypeError, lambda: A - "B")
        self.assertRaises(ValueError, lambda: A - B)
        self.assertRaises(TypeError, lambda: A - A_prime)

    def test_matrix_sub(self):
        zero = self.R(0)
        Z = self.M([[zero, zero], [zero, zero]])
        for _ in range(100):
            A = self.M.random_element(2, 2)
            B = self.M.random_element(2, 2)
            C = self.M.random_element(2, 2)

            self.assertEqual(A - Z, A)
            self.assertEqual(A - B, -(B - A))
            self.assertEqual(A - (B - C), (A - B) + C)

            B = C
            B -= C
            self.assertEqual(B, Z)

    def test_mul_errors(self):
        A = self.M.random_element(2, 2)
        B = self.M.random_element(5, 5)
        A_prime = self.M_prime.random_element(2, 2)

        self.assertRaises(TypeError, lambda: A @ "B")
        self.assertRaises(ValueError, lambda: A @ B)
        self.assertRaises(TypeError, lambda: A @ A_prime)

    def test_matrix_mul_square(self):
        zero = self.R(0)
        one = self.R(1)
        Z = self.M([[zero, zero], [zero, zero]])
        I = self.M([[one, zero], [zero, one]])
        for _ in range(100):
            A = self.M.random_element(2, 2)
            B = self.M.random_element(2, 2)
            C = self.M.random_element(2, 2)
            d = self.R.random_element()
            D = self.M([[d, zero], [zero, d]])

            self.assertEqual(A @ Z, Z)
            self.assertEqual(A @ I, A)
            self.assertEqual(A @ D, D @ A)  # Diagonal matrices commute
            self.assertEqual(A @ (B + C), A @ B + A @ C)

    def test_matrix_mul_rectangle(self):
        for _ in range(100):
            A = self.M.random_element(7, 3)
            B = self.M.random_element(3, 2)
            C = self.M.random_element(3, 2)

            self.assertEqual(A @ (B + C), A @ B + A @ C)

    def test_matrix_transpose_id(self):
        zero = self.R(0)
        one = self.R(1)
        I = self.M([[one, zero], [zero, one]])

        self.assertEqual(I, I.transpose())

    def test_matrix_transpose(self):
        for _ in range(100):
            A = self.M.random_element(7, 3)
            At = A.transpose()
            AAt = A @ At

            # Should always be symmetric
            self.assertEqual(AAt, AAt.transpose())

            # Assert transpose in place works
            At.transpose_self()
            self.assertEqual(A, At)

    def test_matrix_dot(self):
        for _ in range(100):
            u = [self.R.random_element() for _ in range(5)]
            v = [self.R.random_element() for _ in range(5)]
            dot = sum([ui * vi for ui, vi in zip(u, v)])

            U = self.M.vector(u)
            V = self.M.vector(v)

            self.assertEqual(dot, U.dot(V))
        self.assertRaises(TypeError, lambda: U.dot("A"))

    def test_print(self):
        A = self.M(
            [self.R([1, 2]), self.R([3, 4, 5, 6])],
            [self.R([0, 0, 0, 0, 3]), self.R([0, 1, 0, 3])],
        )
        u = self.M([self.R([1, 2]), self.R([3, 4, 5, 6])])

        sA = "[                1 + 2*x]\n[3 + 4*x + 5*x^2 + 6*x^3]"
        su = "[1 + 2*x, 3 + 4*x + 5*x^2 + 6*x^3]"
        self.assertEqual(str(A), sA)
        self.assertEqual(str(u), su)

    def test_compact_256(self):
        from random import randint

        A = self.M_dilithium(
            [[self.R_dilithium([randint(0, 2**32-1) for i in range(256)])
             for j in range(4)],
             [self.R_dilithium([randint(0, 2**32-1) for i in range(256)])
             for j in range(4)],
             [self.R_dilithium([randint(0, 2**32-1) for i in range(256)])
             for j in range(4)],
             [self.R_dilithium([randint(0, 2**32-1) for i in range(256)])
             for j in range(4)]]
        )
        A_compact = A.compact_256(32)
        A_back = A.parent.uncompact_256(A_compact, 32)
        for i in range(4):
            for j in range(4):
                assert A_back[i][j] == A[i, j].coeffs
