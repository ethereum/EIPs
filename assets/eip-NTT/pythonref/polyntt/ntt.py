from polyntt.utils import batch_modular_inversion


class NTT():
    """Base class for Number Theoretic Transform"""

    def __init__(self, q):
        """Implements Number Theoretic Transform for fast polynomial multiplication."""
        self.q = q
        # ratio between degree n and number of complex coefficients of the NTT
        # while here this ratio is 1, it is possible to develop a short NTT such that it is 2.
        self.ntt_ratio = 1

    def ntt(self, poly):
        raise NotImplementedError("Subclasses must implement NTT")

    def intt(self, poly):
        raise NotImplementedError(
            "Subclasses must implement inverse NTT")

    def vec_add(self, f_ntt, g_ntt):
        """Addition of two polynomials (NTT representation)."""
        return [(x+y) % self.q for (x, y) in zip(f_ntt, g_ntt)]

    def vec_sub(self, f_ntt, g_ntt):
        """Substraction of two polynomials (NTT representation)."""
        return self.vec_add(f_ntt, [(-x) % self.q for x in g_ntt])

    def vec_mul(self, f_ntt, g_ntt):
        """Multiplication of two polynomials (NTT representation)."""
        assert len(f_ntt) == len(g_ntt)
        deg = len(f_ntt)
        return [(f_ntt[i] * g_ntt[i]) % self.q for i in range(deg)]

    def vec_div(self, f_ntt, g_ntt):
        """Division of two polynomials (NTT representation)."""
        assert len(f_ntt) == len(g_ntt)
        deg = len(f_ntt)
        if any(elt == 0 for elt in g_ntt):
            raise ZeroDivisionError
        inv_g_ntt = batch_modular_inversion(g_ntt, self.q)
        return self.vec_mul(f_ntt, inv_g_ntt)
