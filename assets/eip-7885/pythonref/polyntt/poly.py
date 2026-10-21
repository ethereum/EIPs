"""This file contains the implementation of the polynomial arithmetic modulo the cyclotomic polynomial x**n+1 (where n is a power of 2)."""
from polyntt.ntt_iterative import NTTIterative
from polyntt.ntt_recursive import NTTRecursive
from polyntt.utils import batch_modular_inversion, bit_reverse_order


class Poly:
    def __init__(self, coeffs, q, ntt='NTTIterative'):
        self.coeffs = coeffs
        self.q = q
        if ntt == 'NTTIterative':
            self.NTT = NTTIterative(q)
        elif ntt == 'NTTRecursive':
            self.NTT = NTTRecursive(q)

    def __eq__(self, other):
        for (a, b) in zip(self.coeffs, other.coeffs):
            if (a-b) % self.q != 0:
                return False
        return True

    def __add__(self, other):
        f = self.coeffs
        g = other.coeffs
        assert len(f) == len(g)
        deg = len(f)
        return Poly([(f[i] + g[i]) % self.q for i in range(deg)], self.q)

    def __neg__(self):
        """Negation of a polynomials (any representation)."""
        f = self.coeffs
        deg = len(f)
        return Poly([(- f[i]) % self.q for i in range(deg)], self.q)

    def __sub__(self, other):
        """Substraction of two polynomials (any representation)."""
        return self + (-other)

    def __mul__(self, other):
        """Multiplication of two polynomials (coefficient representation)."""
        f = self.coeffs
        g = other.coeffs
        T = self.NTT
        f_ntt = T.ntt(f)
        g_ntt = T.ntt(g)
        return Poly(T.intt(T.vec_mul(f_ntt, g_ntt)), self.q)

    def mul_schoolbook(self, other):
        """Multiplication of two polynomials using the schoolbook algorithm."""
        f = self.coeffs
        g = other.coeffs
        n = len(f)
        assert n == len(g)
        C = [0] * (2 * n)
        D = [0] * (n)
        for j, f_j in enumerate(f):
            for k, g_k in enumerate(g):
                C[j+k] = (C[j+k] + f_j * g_k) % self.q
        # reduction modulo x^n  + 1
        for i in range(n):
            D[i] = (C[i] - C[i+n]) % self.q
        return Poly(D, self.q)

    def mul_pwc(self, other, NODE=False):
        """
        Multiplication of `self` by `other` modulo x^n -1 (and not x^n+1).
        PWC means Positive Wrapped Convolution.
        In this context, the multiplication is the same as when x^n+1, but
        with pre- and post-computation.
        """
        f = self.coeffs
        g = other.coeffs
        n = len(f)
        # pre-processing
        # list of roots for the precomputations
        if NODE:
            bit_rev_index = bit_reverse_order(
                range(0, len(self.NTT.ψ_inv), len(self.NTT.ψ_inv)//n))
            ψ0_inv = [self.NTT.ψ_inv_rev[j] for j in bit_rev_index]
        else:
            ψ0_inv = self.NTT.ψ_inv[::len(self.NTT.ψ_inv)//n]
        fp = Poly([(x * y) % self.q for (x, y) in zip(f, ψ0_inv)], self.q)
        gp = Poly([(x * y) % self.q for (x, y) in zip(g, ψ0_inv)], self.q)
        fp_mul_gp = fp*gp
        # post processing
        if NODE:
            bit_rev_index = bit_reverse_order(
                range(0, len(self.NTT.ψ_inv), len(self.NTT.ψ)//n))
            ψ0 = [self.NTT.ψ_rev[j] for j in bit_rev_index]
        else:
            ψ0 = self.NTT.ψ[::len(self.NTT.ψ)//n]
        f_mul_g = [(x * y) % self.q for (x, y) in zip(fp_mul_gp.coeffs, ψ0)]
        return Poly(f_mul_g, self.q)

    def mul_schoolbook_pwc(self, other):
        """Multiplication of two polynomials using the schoolbook algorithm."""
        f = self.coeffs
        g = other.coeffs
        n = len(f)
        assert n == len(g)
        C = [0] * (2 * n)
        D = [0] * (n)
        for j, f_j in enumerate(f):
            for k, g_k in enumerate(g):
                C[j+k] = (C[j+k] + f_j * g_k) % self.q
        # reduction modulo x^n  - 1
        for i in range(n):
            D[i] = (C[i] + C[i+n]) % self.q
        return Poly(D, self.q)

    def __truediv__(self, other):
        """Division of two polynomials (coefficient representation)."""
        try:
            f = self.coeffs
            g = other.coeffs
            T = self.NTT
            f_ntt = T.ntt(f)
            g_ntt = T.ntt(g)
            return Poly(T.intt(T.vec_div(f_ntt, g_ntt)), self.q)
        except ZeroDivisionError:
            raise

    def inverse(self):
        T = self.NTT
        f_ntt = T.ntt(self.coeffs)
        try:
            one_over_f_ntt = batch_modular_inversion(f_ntt, self.q)
        except ZeroDivisionError:
            raise
        return Poly(T.intt(one_over_f_ntt), self.q)

    def ntt(self):
        return self.NTT.ntt(self.coeffs)

    def mul_opt(self, other_ntt):
        f = self.coeffs
        T = self.NTT
        f_ntt = T.ntt(f)
        g_ntt = other_ntt
        return Poly(T.intt(T.vec_mul(f_ntt, g_ntt)), self.q)

    # def adj(f):
    #     """Ajoint of a polynomial (coefficient representation)."""
    #     return intt(adj_ntt(ntt(f)))
